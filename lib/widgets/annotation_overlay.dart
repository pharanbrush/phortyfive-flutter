import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pfs2/main_screen/image_phviewer.dart';
import 'package:pfs2/models/annotations_tool.dart';
import 'package:pfs2/phlutter/escape_route.dart';
import 'package:pfs2/ui/phshortcuts.dart';

// Based on image_annotation by Mikita Drazdou

enum AnnotationType {
  line,
  rect,
  oval,
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

  @override
  void initState() {
    super.initState();
    loadImageSize();
  }

  @override
  Widget build(BuildContext context) {
    if (!initialized) {
      model = AnnotationsModel.of(context);
      model.color.addListener(() => setState(() {}));
      model.strokeWidth.addListener(() => setState(() {}));
      initialized = true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      calculateImageOffset();
    });

    final usableImageSize = imageSize;

    if (usableImageSize == null || imageOffset == null) {
      return const CircularProgressIndicator(); // Placeholder or loading indicator while the image size and offset are being retrieved
    }

    return GestureDetector(
      // onLongPress: clearAllAnnotations,
      // onDoubleTap: clearLastAnnotation,
      onPanDown: (details) {
        if (Phshortcuts.isPanModifierPressed()) {
          return;
        }

        startNewAnnotation();
        //print("starting annotation");
        // if (widget.annotationType == 'text') {
        //   _showTextAnnotationDialog(context, details.localPosition);
        // } else {

        // }
      },
      onSecondaryTap: () {
        EscapeNavigator.of(context)?.tryEscape();
      },
      child: RepaintBoundary(
        child: Stack(
          children: [
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
              child: ImagePhviewerZoomOnScrollListener(
                zoomPanner: widget.zoomPanner,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    //debugPrint("onPanUpdate");
                    if (Phshortcuts.isPanModifierPressed()) {
                      debugPrint("trying to pan");
                      ImagePhviewerPanListener.handlePanUpdate(
                        details: details,
                        zoomPanner: widget.zoomPanner,
                        useZoomPannerScale: true,
                      );

                      return;
                    }

                    drawShape(details.localPosition);
                  },
                  onPanEnd: (details) {
                    if (Phshortcuts.isPanModifierPressed()) {
                      ImagePhviewerPanListener.handlePanEnd(
                        details: details,
                        zoomPanner: widget.zoomPanner,
                      );
                      return;
                    }
                  },
                  child: CustomPaint(
                    painter: AnnotationPainter(
                      strokeWidth: model.strokeWidth.value,
                      annotations: model.annotations,
                      annotationType: widget.annotationType,
                      color: model.color.value,
                    ),
                    size: usableImageSize,
                  ),
                ),
              ),
            ),
          ],
        ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

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

  // Start a new annotation
  void startNewAnnotation() {
    setState(() {
      //print("startNewAnnotation");
      model.startNewAnnotation();
      model.commitCurrentAnnotation();
    });
  }

  // Draw shape based on the current position
  void drawShape(Offset position) {
    //debugPrint("drawShape");
    // final isWithinImageBounds = (position.dx >= 0 &&
    //     position.dy >= 0 &&
    //     position.dx <= imageSize!.width &&
    //     position.dy <= imageSize!.height);
    // if (isWithinImageBounds) {}

    setState(() => model.addPoint(position));
  }

  // Clear the last added annotation
  void clearLastAnnotation() {
    setState(() => model.removeLastAnnotation());
  }

  // Clear all annotations
  void clearAllAnnotations() {
    setState(() => model.clearAllAnnotations());
  }

  //
  //
  //
  //
}

//

class AnnotationPainter extends CustomPainter {
  AnnotationPainter({
    required this.annotations,
    required this.annotationType,
    required this.color,
    required this.strokeWidth,
  });

  final List<List<Offset>> annotations;
  final AnnotationType annotationType;
  final Color color;
  final double strokeWidth;

  // Paint annotations and text on the canvas
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final annotation in annotations) {
      if (annotation.isNotEmpty) {
        if (annotationType == AnnotationType.line) {
          for (var i = 0; i < annotation.length - 1; i++) {
            canvas.drawLine(annotation[i], annotation[i + 1], paint);
          }
        } else if (annotationType == AnnotationType.rect) {
          final rect = Rect.fromPoints(annotation.first, annotation.last);
          canvas.drawRect(rect, paint);
        } else if (annotationType == AnnotationType.oval) {
          final oval = Rect.fromPoints(annotation.first, annotation.last);
          canvas.drawOval(oval, paint);
        }
      }
    }

    // drawTextAnnotations(canvas); // Draw text annotations
  }

  // // Draw text annotations on the canvas
  // void drawTextAnnotations(Canvas canvas) {
  //   for (var annotation in textAnnotations) {
  //     final textSpan = TextSpan(
  //       text: annotation.text,
  //       style: TextStyle(
  //           color: annotation.textColor, fontSize: annotation.fontSize),
  //     );
  //     final textPainter = TextPainter(
  //       text: textSpan,
  //       textDirection: TextDirection.ltr,
  //     );
  //     textPainter.layout();
  //     final textPosition = Offset(
  //       annotation.position.dx - textPainter.width / 2,
  //       annotation.position.dy - textPainter.height / 2,
  //     );
  //     textPainter.paint(canvas, textPosition);
  //   }
  // }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
