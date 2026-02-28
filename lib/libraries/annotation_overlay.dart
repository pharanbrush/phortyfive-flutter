import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pfs2/main_screen/image_phviewer.dart';
import 'package:pfs2/main_screen/annotations_tool.dart';
import 'package:pfs2/ui/phshortcuts.dart';

// Heavily modified code from image_annotation by Mikita Drazdou

// MIT License

// Copyright (c) 2023 Mikita Drazdou

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

enum AnnotationType {
  line,
  rect,
  oval,
}

class PointerToolCallbacks {
  const PointerToolCallbacks({
    this.onPointerDown,
    this.onPointerUpdate,
    this.onPointerUp,
  });

  final void Function(Offset position)? onPointerDown;
  final void Function()? onPointerUp;
  final void Function(Offset position)? onPointerUpdate;

  static const none = PointerToolCallbacks();
}

class AnnotationOverlay extends StatefulWidget {
  const AnnotationOverlay({
    super.key,
    required this.child,
    required this.image,
    required this.annotationType,
    required this.zoomPanner,
  });

  final Image image;
  final Widget child;
  final AnnotationType annotationType;
  final ImageZoomPanner zoomPanner;

  @override
  State<AnnotationOverlay> createState() => _AnnotationOverlayState();
}

class _AnnotationOverlayState extends State<AnnotationOverlay> {
  Size? imageSize; // Size of the image
  Offset? imageOffset; // Offset of the image on the screen
  late final AnnotationsModel model;

  bool initialized = false;

  bool currentDragIsTool = false;

  late final drawTool = PointerToolCallbacks(
    onPointerDown: (position) => setState(() => model.startNewStroke(position)),
    onPointerUpdate: (position) =>
        setState(() => model.addPointToStroke(position)),
    onPointerUp: () => model.commitCurrentStroke(),
  );

  late final lineTool = PointerToolCallbacks(
    onPointerDown: (position) => setState(() => model.startNewStroke(position)),
    onPointerUpdate: (position) =>
        setState(() => model.resetCurrentStrokeWithSecondPoint(position)),
    onPointerUp: () => model.commitCurrentStroke(),
  );

  late final rulerTool = PointerToolCallbacks(
    onPointerDown: (position) => setState(() => model.startNewRuler(position)),
    onPointerUpdate: (position) =>
        setState(() => model.updateRulerEnd(position)),
    onPointerUp: () => model.commitCurrentRuler(),
  );

  late final eraseTool = PointerToolCallbacks(
    onPointerDown: (position) => model.startEraseStrokeDoNothing(position),
    onPointerUpdate: (position) => setState(() => model.tryEraseAt(position)),
    onPointerUp: () => model.commitCurrentEraseStroke(),
  );

  PointerToolCallbacks currentToolCallbacks = PointerToolCallbacks.none;

  @override
  void initState() {
    super.initState();
    loadImageSize();
  }

  @override
  void dispose() {
    model.color.removeListener(_handleUpdateState);
    model.strokeWidth.removeListener(_handleUpdateState);
    model.undoRedoListenable.removeListener(_handleUpdateState);
    model.currentTool.removeListener(_handleToolSwitch);
    super.dispose();
  }

  void _handleUpdateState() => setState(() {});

  void _handleToolSwitch() {
    currentToolCallbacks = switch (model.currentTool.value) {
      AnnotationTool.draw => drawTool,
      AnnotationTool.line => lineTool,
      AnnotationTool.rulers => rulerTool,
      AnnotationTool.erase => eraseTool,
      _ => PointerToolCallbacks.none,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (!initialized) {
      model = AnnotationsModel.of(context);
      model.color.addListener(_handleUpdateState);
      model.currentTool.addListener(_handleToolSwitch);
      model.strokeWidth.addListener(_handleUpdateState);
      model.undoRedoListenable.addListener(_handleUpdateState);
      _handleToolSwitch();
      initialized = true;
    }

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   calculateImageOffset();
    // });

    final usableImageSize = imageSize;

    if (usableImageSize == null) {
      return const CircularProgressIndicator(); // Placeholder or loading indicator while the image size and offset are being retrieved
    }

    return RepaintBoundary(
      child: Stack(
        children: [
          Positioned.fill(
            child: ValueListenableBuilder(
              valueListenable: model.underlayColor,
              builder: (_, modelUnderlayColor, __) {
                return AnimatedContainer(
                  color: modelUnderlayColor,
                  duration: Duration(milliseconds: 600),
                );
              },
            ),
          ),
          Center(
            child: ValueListenableBuilder(
              valueListenable: model.opacity,
              builder: (_, opacityValue, __) {
                return Opacity(
                  opacity: opacityValue,
                  child: widget.child,
                );
              },
            ),
          ),
          Center(
            // left: imageOffset!.dx,
            // top: imageOffset!.dy,
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (details) {
                if (Phshortcuts.isPanModifierPressed()) {
                  return;
                }

                if (details.buttons != kPrimaryMouseButton) {
                  return;
                }

                currentDragIsTool = true;
                currentToolCallbacks.onPointerDown?.call(details.localPosition);
              },
              onPointerMove: (details) {
                if (Phshortcuts.isPanModifierPressed()) {
                  // debugPrint("trying to pan");
                  ImagePhviewerPanListener.handlePanUpdate(
                    pointerDelta: details.delta,
                    zoomPanner: widget.zoomPanner,
                    useZoomPannerScale: true,
                  );

                  return;
                }

                if (!currentDragIsTool &&
                    details.buttons != kPrimaryMouseButton) {
                  final isPressingPanButton =
                      details.buttons == kTertiaryButton ||
                          details.buttons == kSecondaryButton;

                  if (isPressingPanButton) {
                    widget.zoomPanner.panImage(details.delta);
                  }

                  return;
                }

                currentToolCallbacks.onPointerUpdate
                    ?.call(details.localPosition);
              },
              onPointerUp: (details) {
                if (Phshortcuts.isPanModifierPressed()) {
                  ImagePhviewerPanListener.handlePanEnd(
                    zoomPanner: widget.zoomPanner,
                  );
                  return;
                }

                if (!currentDragIsTool) {
                  widget.zoomPanner.panRelease();
                }

                currentDragIsTool = false;
                currentToolCallbacks.onPointerUp?.call();
              },
              child: ValueListenableBuilder(
                valueListenable: model.isStrokesVisible,
                builder: (_, isStrokesVisibleValue, ___) {
                  return CustomPaint(
                    painter: AnnotationPainter(
                      repaint: model.strokesChangedListenable,
                      strokeWidth: model.strokeWidth.value,
                      strokes: model.strokes,
                      color: model.color.value,
                      isStrokesVisible: isStrokesVisibleValue,
                    ),
                    size: usableImageSize,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Load image size asynchronously and set imageSize state
  void loadImageSize() async {
    final image = widget.image;
    final completer = Completer<ui.Image>();

    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(info.image);
      }),
    );

    final loadedImage = await completer.future;
    if (!mounted) return; //Prevents unmounted widget error from async call.

    setState(() => imageSize = calculateImageSize(loadedImage));
  }

  // Calculate the image size to fit the screen while maintaining the aspect ratio
  Size calculateImageSize(ui.Image image) {
    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    final imageRatio = image.width / image.height;
    final screenRatio = screenWidth / screenHeight;

    double width;
    double height;

    if (imageRatio > screenRatio) {
      width = screenWidth;
      height = screenWidth / imageRatio;
    } else {
      height = screenHeight;
      width = screenHeight * imageRatio;
    }

    final returnSize = Size(width, height);

    //print("image size calculated: $returnSize");
    return returnSize;
  }

  // Calculate the offset of the image on the screen
  void calculateImageOffset() {
    if (imageSize != null) {
      final imageWidget = context.findRenderObject() as RenderBox?;
      final imagePosition = imageWidget?.localToGlobal(Offset.zero);
      final widgetPosition =
          (context.findRenderObject() as RenderBox).localToGlobal(Offset.zero);
      final offsetX = imagePosition!.dx - widgetPosition.dx;
      final offsetY = imagePosition.dy - widgetPosition.dy;
      setState(() {
        imageOffset = Offset(offsetX, offsetY);
      });
    }
  }

  void clearAllAnnotations() {
    setState(() => model.clearAllStrokes());
  }

  //
  //
  //
  //
}

//

class AnnotationPainter extends CustomPainter {
  AnnotationPainter({
    required super.repaint,
    required this.strokes,
    required this.color,
    required this.strokeWidth,
    required this.isStrokesVisible,
  });

  final List<Stroke> strokes;
  final Color color;
  final double strokeWidth;
  final bool isStrokesVisible;

  // Paint annotations and text on the canvas
  @override
  void paint(Canvas canvas, Size size) {
    if (!isStrokesVisible) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke is RulerStroke) {
        stroke.draw(canvas, paint);
      } else {
        canvas.drawPath(stroke.path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(AnnotationPainter old) {
    return false;
  }
}
