import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pfs2/main_screen/image_phviewer.dart';
import 'package:pfs2/models/annotations_tool.dart';
import 'package:pfs2/ui/phshortcuts.dart';

// Heavily modified code from image_annotation by Mikita Drazdou

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
  final void Function(Offset position)? onPointerUp;
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

  late final drawTool = PointerToolCallbacks(
    onPointerDown: (position) => setState(() => model.startNewStroke(position)),
    onPointerUpdate: (position) =>
        setState(() => model.addPointToStroke(position)),
    onPointerUp: (position) => model.commitCurrentStroke(),
  );

  late final lineTool = PointerToolCallbacks(
    onPointerDown: (position) => setState(() => model.startNewStroke(position)),
    onPointerUpdate: (position) =>
        setState(() => model.resetCurrentStrokeWithSecondPoint(position)),
    onPointerUp: (position) => model.commitCurrentStroke(),
  );

  late final rulerTool = PointerToolCallbacks(
    onPointerDown: (position) => setState(() => model.startNewRuler(position)),
    onPointerUpdate: (position) =>
        setState(() => model.updateRulerEnd(position)),
    onPointerUp: (position) => model.commitCurrentRuler(),
  );

  late final eraseTool = PointerToolCallbacks(
    onPointerDown: (position) => model.startEraseStrokeDoNothing(position),
    onPointerUpdate: (position) => setState(() => model.tryEraseAt(position)),
    onPointerUp: (position) => model.commitCurrentEraseStroke(),
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      calculateImageOffset();
    });

    final usableImageSize = imageSize;

    if (usableImageSize == null || imageOffset == null) {
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
                  duration: Durations.medium1,
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
            child: GestureDetector(
              onPanDown: (details) {
                if (Phshortcuts.isPanModifierPressed()) {
                  return;
                }

                currentToolCallbacks.onPointerDown?.call(details.localPosition);
              },
              onPanUpdate: (details) {
                //debugPrint("onPanUpdate");
                if (Phshortcuts.isPanModifierPressed()) {
                  // debugPrint("trying to pan");
                  ImagePhviewerPanListener.handlePanUpdate(
                    details: details,
                    zoomPanner: widget.zoomPanner,
                    useZoomPannerScale: true,
                  );

                  return;
                }

                currentToolCallbacks.onPointerUpdate
                    ?.call(details.localPosition);
              },
              onPanEnd: (details) {
                if (Phshortcuts.isPanModifierPressed()) {
                  ImagePhviewerPanListener.handlePanEnd(
                    details: details,
                    zoomPanner: widget.zoomPanner,
                  );
                  return;
                }

                currentToolCallbacks.onPointerUp?.call(details.localPosition);
              },
              child: ValueListenableBuilder(
                valueListenable: model.isStrokesVisible,
                builder: (_, isStrokesVisibleValue, ___) {
                  return CustomPaint(
                    painter: AnnotationPainter(
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
    return true;
  }
}
