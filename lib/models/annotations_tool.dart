import 'dart:math' as math;

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:pfs2/main_screen/main_screen.dart';
import 'package:pfs2/main_screen/panels/modal_panel.dart';
import 'package:pfs2/phlutter/centered_vertically.dart';
import 'package:pfs2/phlutter/model_scope.dart';
import 'package:pfs2/phlutter/scroll_listener.dart';
import 'package:pfs2/phlutter/simple_notifier.dart';
import 'package:pfs2/phlutter/sized_box_fitted.dart';
import 'package:pfs2/phlutter/value_notifier_extensions.dart';
import 'package:pfs2/ui/phanimations.dart';
import 'package:pfs2/ui/phshortcuts.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';
import 'package:pfs2/widgets/phbuttons.dart';
import 'package:undo/undo.dart';

enum AnnotationTool {
  none,
  draw,
  line,
  rulers,
  erase,
}

class Stroke {
  Path path = Path();
}

enum RulerType {
  line,
  circle,
  box,
}

class RulerStroke extends Stroke {
  Offset start = Offset.zero;
  Offset end = Offset.zero;
  RulerType type = RulerType.line;
  int division = 2;

  Offset startUserPosition = Offset.zero;
  Offset endUserPosition = Offset.zero;
  bool isCentered = false;
  bool isCounterclockwise = false;

  RulerStroke? comparisonRuler;
  double? comparisonLength;

  List<(Offset p1, Offset p2, bool thin)>? lineCache;

  bool get isInvalid {
    return start == end || !start.isFinite || !end.isFinite;
  }

  void startAt(Offset userPointer) {
    startUserPosition = userPointer;
    endUserPosition = userPointer;

    start = userPointer;
    end = userPointer;
  }

  void updateEnd(Offset userPointer) {
    endUserPosition = userPointer;

    if (isCentered) {
      final delta = userPointer - startUserPosition;
      start = startUserPosition - delta;
      end = userPointer;
    } else if (isCounterclockwise) {
      final delta = userPointer - startUserPosition;
      final deltaPerpendicularCcwHalf = Offset(delta.dy, -delta.dx) * 0.5;
      start = startUserPosition + deltaPerpendicularCcwHalf;
      end = userPointer + deltaPerpendicularCcwHalf;
    } else {
      end = userPointer;
    }
  }

  void setComparisonRulerFrom(RulerStroke source) {
    if (source == this) return;
    if (source.isInvalid) return;

    comparisonRuler = RulerStroke()
      ..start = source.start
      ..end = source.end
      ..type = source.type
      ..division = source.division
      ..comparisonRuler = null;
    comparisonLength = (source.end - source.start).distance;
  }

  /// Path is used to determine how the ruler is erased. Not for drawing.
  void updatePath() {
    super.path.reset();
    //comparisonRuler?.updatePath();

    lineCache = null;

    switch (type) {
      case RulerType.box:
        lineCache = [...getBoxLines(start, end, division)];

        for (final (p1, p2, _) in lineCache!) {
          path.addPath(
            Path()
              ..reset()
              ..moveTo(p1.dx, p1.dy)
              ..lineTo(p2.dx, p2.dy),
            Offset.zero,
          );
        }

      case RulerType.circle:
        final c = getCircleParams(
          start: start,
          end: end,
        );

        final rect = Rect.fromCircle(center: c.center, radius: c.radius);
        super.path
          ..addArc(rect, 0, 2 * math.pi)
          ..addPath(
            Path()
              ..moveTo(c.outputStart.dx, c.outputStart.dy)
              ..lineTo(end.dx, end.dy),
            Offset.zero,
          )
          ..addPath(
            Path()
              ..moveTo(
                c.center.dx + c.radiusPerpendicular.dx,
                c.center.dy + c.radiusPerpendicular.dy,
              )
              ..lineTo(
                c.center.dx - c.radiusPerpendicular.dx,
                c.center.dy - c.radiusPerpendicular.dy,
              ),
            Offset.zero,
          );

      default:
        super.path
          ..moveTo(start.dx, start.dy)
          ..lineTo(end.dx, end.dy);
    }
  }

  void updateComparisonRuler() {
    if (isInvalid) return;

    final cr = comparisonRuler;
    final cLength = comparisonLength;

    if (cr == null) return;
    if (cLength == null) return;

    cr.start = start;
    final delta = end - start;
    final length = delta.distance;
    final originalLengthInUpdatedDirection = (delta / length) * cLength;
    cr.end = start + originalLengthInUpdatedDirection;
  }

  void draw(Canvas canvas, Paint paint) {
    if (isInvalid) return;

    if (comparisonRuler != null) {
      final comparisonPaint = Paint.from(paint)
        ..color = paint.color.withValues(alpha: 0.25);
      comparisonRuler!.draw(canvas, comparisonPaint);
    }

    const double tickMarkHalfLength = 7;

    const oneThird = 1.0 / 3.0;
    const twoThirds = 2.0 / 3.0;
    final rulerPaint = Paint.from(paint)..strokeWidth = paint.strokeWidth * 0.6;
    final thinnerPaint = Paint.from(paint)
      ..strokeWidth = paint.strokeWidth * oneThird
      ..color = paint.color.withValues(alpha: paint.color.a * twoThirds);

    final delta = end - start;
    final distance = delta.distance;
    final normalizedDelta = delta / distance;
    final perpedicular = Offset(normalizedDelta.dy, -normalizedDelta.dx);

    void drawTickMark(Offset position, double halfLength) {
      final to = perpedicular * halfLength;
      canvas.drawLine(position + to, position - to, thinnerPaint);
    }

    final double lerpIncrement = 1.0 / division;

    void drawTickmarksForLine() {
      final usedStart = start;

      for (int i = 1; i < division; i++) {
        final tickPosition =
            Offset.lerp(usedStart, end, i * lerpIncrement) ?? start;
        drawTickMark(tickPosition, tickMarkHalfLength);
      }
    }

    switch (type) {
      case RulerType.line:
        canvas.drawLine(start, end, rulerPaint);

        drawTickMark(start, tickMarkHalfLength);
        drawTickmarksForLine();
        drawTickMark(end, tickMarkHalfLength);

      case RulerType.circle:
        final c = getCircleParams(
          start: start,
          end: end,
        );

        canvas.drawLine(c.outputStart, c.outputEnd, thinnerPaint);
        canvas.drawLine(c.center + c.radiusPerpendicular,
            c.center - c.radiusPerpendicular, thinnerPaint);
        drawTickmarksForLine();
        canvas.drawCircle(c.center, c.radius, rulerPaint);

      case RulerType.box:
        final lines = lineCache ?? getBoxLines(start, end, division);
        for (final (p1, p2, thin) in lines) {
          canvas.drawLine(p1, p2, thin ? thinnerPaint : rulerPaint);
        }

      // default:
      //   canvas.drawLine(start, end, rulerPaint);
    }
  }

  static ({
    double radius,
    Offset center,
    Offset outputStart,
    Offset outputEnd,
    Offset delta,
    Offset radiusPerpendicular,
  }) getCircleParams({
    required Offset start,
    required Offset end,
  }) {
    final delta = end - start;
    final double radius = delta.distance * 0.5;
    final Offset center = (start + end) * 0.5;
    final Offset radiusPerpendicular = Offset(delta.dy, -delta.dx) * 0.5;

    return (
      center: center,
      delta: delta,
      outputEnd: end,
      outputStart: start,
      radius: radius,
      radiusPerpendicular: radiusPerpendicular,
    );
  }

  static Iterable<(Offset a, Offset b, bool thin)> getBoxLines(
    Offset start,
    Offset end,
    int divisions,
  ) sync* {
    final delta = end - start;
    final deltaPerpendicular = Offset(delta.dy, -delta.dx);
    final halfDeltaPerpendicular = deltaPerpendicular * 0.5;

    final double lerpIncrement = 1.0 / divisions;

    final p0 = start - halfDeltaPerpendicular;
    final p1 = start + halfDeltaPerpendicular;
    final p2 = end + halfDeltaPerpendicular;
    final p3 = end - halfDeltaPerpendicular;
    yield (p0, p1, false);
    yield (p1, p2, false);
    yield (p2, p3, false);
    yield (p3, p0, false);

    for (int i = 1; i < divisions; i++) {
      final pos = Offset.lerp(p1, p2, i * lerpIncrement) ?? start;
      final pos2 = Offset.lerp(p1, p0, i * lerpIncrement) ?? start;

      yield (pos, pos - deltaPerpendicular, true);
      yield (pos2, pos2 + delta, true);
    }
  }
}

Color _cycleColorFrom({
  required Color currentColor,
  required List<Color> list,
}) {
  int index = list.indexOf(currentColor);
  if (index < 0) {
    debugPrint("color not found");
    index = -1;
  }
  index++;
  if (index >= list.length) index = 0;
  return list[index];
}

class AnnotationsModel {
  final annotationsFocus = FocusNode();
  final List<Stroke> strokes = [];
  Path currentStrokePath = Path();
  RulerStroke currentRulerStroke = RulerStroke();
  final changes = ChangeStack(limit: 30);
  final lastErasedStrokes = <Stroke>[];

  final currentTool = ValueNotifier(AnnotationTool.draw);
  final currentRulerType = ValueNotifier(RulerType.line);
  final currentRulerDivisions = ValueNotifier<int>(2);
  late final color = ValueNotifier<Color>(colorChoices.first);
  late final underlayColor = ValueNotifier<Color>(underlayColorChoices.first);
  final opacity = ValueNotifier<double>(0.2);
  final strokeWidth = ValueNotifier<double>(3.0);
  final isStrokesVisible = ValueNotifier(true);
  final undoRedoListenable = SimpleNotifier();

  final isNextRulerAddsComparison = ValueNotifier(false);

  final comparisonAddedPulseListenable = SimpleNotifier();
  final visibilityPulseListenable = SimpleNotifier();
  final eraserPulseListenable = SimpleNotifier();

  Offset currentStrokeStartPosition = Offset.zero;

  static const colorChoices = <Color>[
    Colors.orange,
    Colors.blue,
    Colors.red,
    Color(0xFF5644B3),
    Colors.white,
    Colors.black,
  ];

  static const underlayColorChoices = <Color>[
    Colors.transparent,
    Color(0xFF888888),
    Colors.white,
    Colors.blueGrey,
    Color(0xFFDEC4A5),
    Colors.black,
  ];

  bool get isStrokesLocked {
    return !isStrokesVisible.value;
  }

  static AnnotationsModel of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ModelScope<AnnotationsModel>>()!
        .model;
  }

  /// Returns true if modes were restored to their default.
  bool tryRestoreBaselineMode() {
    bool didRestoreMode = false;
    if (!isStrokesVisible.value) {
      isStrokesVisible.value = true;
      didRestoreMode = true;
    }

    if (isNextRulerAddsComparison.value) {
      isNextRulerAddsComparison.value = false;
      didRestoreMode = true;
    }

    if (opacity.value == 0) {
      opacity.value = 0.2;
      didRestoreMode = true;
    }

    return didRestoreMode;
  }

  void showVisibilityUnusualHint() {
    visibilityPulseListenable.notify();
  }

  void toggleStrokesVisibility() {
    isStrokesVisible.value = !isStrokesVisible.value;
  }

  void setTool(AnnotationTool newTool) {
    currentTool.value = newTool;
  }

  void setToolDraw() {
    currentTool.value = switch (currentTool.value) {
      AnnotationTool.draw => AnnotationTool.line,
      _ => AnnotationTool.draw,
    };
  }

  void setToolRuler() {
    if (currentTool.value == AnnotationTool.rulers) {
      currentRulerType.value = switch (currentRulerType.value) {
        RulerType.line => RulerType.box,
        RulerType.box => RulerType.circle,
        _ => RulerType.line,
      };

      return;
    }

    isNextRulerAddsComparison.value = false;
    currentTool.value = AnnotationTool.rulers;
  }

  void cycleUnderlayColor() {
    underlayColor.value = _cycleColorFrom(
      currentColor: underlayColor.value,
      list: underlayColorChoices,
    );
  }

  void cycleColor() {
    color.value = _cycleColorFrom(
      currentColor: color.value,
      list: colorChoices,
    );
  }

  void showStrokesLockedHint() {
    if (!isStrokesVisible.value) showVisibilityUnusualHint();
  }

  void startNewStroke(Offset position) {
    if (isStrokesLocked) {
      showStrokesLockedHint();
      return;
    }
    currentStrokePath = Path()..moveTo(position.dx, position.dy);
    strokes.add(Stroke()..path = currentStrokePath);
    currentStrokeStartPosition = position;
  }

  void startNewRuler(Offset position) {
    if (isStrokesLocked) {
      showStrokesLockedHint();
      return;
    }

    currentRulerStroke = RulerStroke()
      ..type = currentRulerType.value
      ..division = currentRulerDivisions.value
      ..startAt(position);

    if (currentRulerStroke.type == RulerType.box &&
        Phshortcuts.isCounterclockwiseModifierPressed()) {
      currentRulerStroke.isCounterclockwise = true;
    } else if (Phshortcuts.isCenteredModifierPressed()) {
      currentRulerStroke.isCentered = true;
    }

    if (isNextRulerAddsComparison.value) {
      for (int i = strokes.length - 1; i >= 0; i--) {
        final top = strokes[i];
        if (top is RulerStroke) {
          currentRulerStroke.setComparisonRulerFrom(top);
          comparisonAddedPulseListenable.notify();
          break;
        }
      }
    }

    strokes.add(currentRulerStroke);
  }

  void updateRulerEnd(Offset position) {
    if (isStrokesLocked) return;

    currentRulerStroke.updateEnd(position);

    currentRulerStroke.updateComparisonRuler();
  }

  void resetCurrentStrokeWithSecondPoint(Offset point) {
    if (isStrokesLocked) return;
    currentStrokePath
      ..reset()
      ..moveTo(currentStrokeStartPosition.dx, currentStrokeStartPosition.dy)
      ..lineTo(point.dx, point.dy);
  }

  void addPointToStroke(Offset point) {
    if (isStrokesLocked) return;
    currentStrokePath.lineTo(point.dx, point.dy);
  }

  void startEraseStrokeDoNothing(Offset point) {
    if (isStrokesLocked) {
      showStrokesLockedHint();
      return;
    }

    if (strokes.isEmpty) {
      eraserPulseListenable.notify();
      return;
    }
  }

  void commitCurrentRuler() {
    if (isStrokesLocked) return;
    if (strokes.isEmpty) return;
    isNextRulerAddsComparison.value = false;

    if (currentRulerStroke.isInvalid) {
      strokes.remove(currentRulerStroke);
      return;
    }

    currentRulerStroke.updatePath();

    final latestStroke =
        currentRulerStroke; // This needs to be a local variable so the value can be captured by the undo closure.
    changes.add(
      Change(
        latestStroke,
        () {
          strokes.remove(latestStroke);
          strokes.add(latestStroke);
        },
        (oldValue) {
          strokes.remove(oldValue);
        },
      ),
    );
    undoRedoListenable.notify();
  }

  void commitCurrentStroke() {
    if (isStrokesLocked) return;
    if (strokes.isEmpty) return;
    final lastStroke = strokes.last;

    changes.add(
      Change(
        lastStroke,
        () {
          strokes.remove(lastStroke);
          strokes.add(lastStroke);
        },
        (oldValue) {
          strokes.remove(oldValue);
        },
      ),
    );
    undoRedoListenable.notify();
  }

  void commitCurrentEraseStroke() {
    if (isStrokesLocked) return;
    if (lastErasedStrokes.isEmpty) return;

    final undoableStrokes = [...lastErasedStrokes];

    changes.add(
      Change(
        undoableStrokes,
        () {
          for (final stroke in undoableStrokes) {
            strokes.remove(stroke);
          }
        },
        (oldValue) {
          strokes.addAll(oldValue);
        },
      ),
    );

    lastErasedStrokes.clear();
    undoRedoListenable.notify();
  }

  void undo() {
    if (changes.canUndo) {
      changes.undo();
      undoRedoListenable.notify();
    }
  }

  void redo() {
    if (changes.canRedo) {
      changes.redo();
      undoRedoListenable.notify();
    }
  }

  void tryEraseAt(Offset point) {
    if (isStrokesLocked) return;

    const eraserSize = 3.0;
    final eraseableStrokes =
        strokes.where((stroke) => hitTestStroke(stroke, point, eraserSize));

    final toEraseStrokes = eraseableStrokes.toList(growable: false);
    if (toEraseStrokes.isEmpty) return;

    for (final stroke in toEraseStrokes) {
      lastErasedStrokes.add(stroke);
      strokes.remove(stroke);
    }
  }

  static bool hitTestStroke(Stroke stroke, Offset point, double tolerance) {
    final squaredTolerance = tolerance * tolerance;

    for (final metric in stroke.path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += tolerance) {
        final pos = metric.getTangentForOffset(d)!.position;
        if ((pos - point).distanceSquared <= squaredTolerance) {
          return true;
        }
      }
    }
    return false;
  }

  void clearAllStrokes() {
    if (isStrokesLocked) return;

    final historyStrokes = [...strokes];
    changes.add(
      Change(
        historyStrokes,
        () {
          strokes.clear();
        },
        (oldValue) {
          strokes.clear();
          strokes.addAll(oldValue);
        },
      ),
    );
  }
}

mixin MainScreenAnnotations on MainScreenPanels {
  void Function()? onAnnotationToolExit;
  static const annotationPanelId = "annotation panel";

  late final ModalPanel annotationPanel = ModalPanel(
    onBeforeOpen: () {
      closeAllPanels(except: annotationPanel);
    },
    onClosed: () {
      onAnnotationToolExit?.call();
      returnToHomeMode();
    },
    useUnderlay: false,
    transitionBuilder: Phanimations.bottomMenuTransition,
    builder: () {
      return AnnotationsInterface();
    },
  );
}

class AnnotationsInterface extends StatelessWidget {
  const AnnotationsInterface({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final panelMaterial = PfsAppTheme.boxPanelFrom(theme);

    final smallNumberLabelStyle =
        theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.outline);

    final model = AnnotationsModel.of(context);

    const double edgeOverflow = 10;
    const double barHeight = 60;
    //const double barItemSpacing = 3;

    const double brushSizeMin = 0.5;
    const double brushSizeIntervals = brushSizeMin;
    const double brushSizeMax = 8;

    const double panelPadding = 4;
    const double sidePanelWidth = 52;

    final shortcuts = Center(
      child: CallbackShortcuts(
        bindings: {
          Phshortcuts.redo: model.redo,
          Phshortcuts.undo: model.undo,
          Phshortcuts.drawToolAnnotations: () => model.setToolDraw(),
          Phshortcuts.rulerToolAnnotations: () => model.setToolRuler(),
          Phshortcuts.eraserToolAnnotations: () =>
              model.setTool(AnnotationTool.erase),
          Phshortcuts.cycleAnnotationColors: model.cycleColor,
          Phshortcuts.clearAnnotations: model.clearAllStrokes,
        },
        child: Focus(
          focusNode: model.annotationsFocus,
          child: Text(""),
        ),
      ),
    );

    final leftPanel = Positioned(
      left: -edgeOverflow,
      top: 0,
      bottom: 0,
      child: CenteredVertically(
        child: panelMaterial(
          child: SizedBox(
            width: sidePanelWidth + edgeOverflow,
            child: Padding(
              padding: const EdgeInsets.only(
                left: edgeOverflow + panelPadding,
                right: panelPadding,
                top: panelPadding,
                bottom: panelPadding,
              ),
              child: Flex(
                direction: Axis.vertical,
                children: [
                  ValueListenableBuilder(
                    valueListenable: model.currentTool,
                    builder: (_, currentToolValue, __) {
                      return Flex(
                        direction: Axis.vertical,
                        children: [
                          IconButton.filled(
                            tooltip: "Draw  (B)",
                            isSelected: currentToolValue == AnnotationTool.draw,
                            onPressed: () => model.setTool(AnnotationTool.draw),
                            icon: currentToolValue == AnnotationTool.draw
                                ? Icon(FluentIcons.edit_20_filled)
                                : Icon(FluentIcons.edit_20_regular),
                          ),
                          IconButton.filled(
                            tooltip: "Straight line\n(B to cycle)",
                            isSelected: currentToolValue == AnnotationTool.line,
                            onPressed: () => model.setTool(AnnotationTool.line),
                            icon: currentToolValue == AnnotationTool.line
                                ? Icon(FluentIcons.line_20_filled)
                                : Icon(FluentIcons.line_20_regular),
                          ),
                          IconButton.filled(
                            tooltip: "Proportion rulers\n(R to cycle)",
                            isSelected:
                                currentToolValue == AnnotationTool.rulers,
                            onPressed: () => model.setToolRuler(),
                            icon: currentToolValue == AnnotationTool.rulers
                                ? Icon(FluentIcons.ruler_20_filled)
                                : Icon(FluentIcons.ruler_20_regular),
                          ),
                          IconButton.filled(
                            tooltip: "Stroke Eraser  (E)",
                            isSelected:
                                currentToolValue == AnnotationTool.erase,
                            onPressed: () =>
                                model.setTool(AnnotationTool.erase),
                            icon: AnimateOnListenable(
                              listenable: model.eraserPulseListenable,
                              effects: [Phanimations.toolPulseEffect],
                              child: currentToolValue == AnnotationTool.erase
                                  ? Icon(FluentIcons.eraser_segment_20_filled)
                                  : Icon(FluentIcons.eraser_segment_20_regular),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  Divider(),
                  ValueListenableBuilder(
                    valueListenable: model.color,
                    builder: (_, modelColorValue, __) {
                      return ValueListenableBuilder(
                        valueListenable: model.strokeWidth,
                        builder: (_, modelStrokeWidthValue, __) {
                          const double minScale = 0.2;
                          const double maxScale = 1.5;

                          double remap(double value, double iMin, double iMax,
                              double oMin, double oMax) {
                            return (value - iMin) /
                                    (iMax - iMin) *
                                    (oMax - oMin) +
                                oMin;
                          }

                          return IconButton(
                            tooltip: "Cycle stroke color  (C)",
                            onPressed: () {
                              model.cycleColor();
                            },
                            icon: Transform.scale(
                              scale: remap(
                                modelStrokeWidthValue,
                                brushSizeMin,
                                brushSizeMax,
                                minScale,
                                maxScale,
                              ),
                              child: Icon(Icons.circle),
                            ),
                            color: modelColorValue,
                          );
                        },
                      );
                    },
                  ),
                  ValueListenableBuilder(
                    valueListenable: model.strokeWidth,
                    builder: (_, modelStrokeWidthValue, __) {
                      return Text(
                        modelStrokeWidthValue.toStringAsFixed(1),
                        style: smallNumberLabelStyle,
                      );
                    },
                  ),
                  ListenableSlider(
                    listenable: model.strokeWidth,
                    min: brushSizeMin,
                    max: brushSizeMax,
                    interval: brushSizeIntervals,
                    direction: Axis.vertical,
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final rightPanel = Positioned(
      top: 0,
      bottom: 0,
      right: -edgeOverflow,
      child: CenteredVertically(
        child: panelMaterial(
          child: SizedBox(
            width: sidePanelWidth + edgeOverflow,
            child: Padding(
              padding: const EdgeInsets.only(
                right: edgeOverflow + panelPadding,
                left: panelPadding,
                top: panelPadding,
                bottom: panelPadding,
              ),
              child: Flex(
                direction: Axis.vertical,
                children: [
                  SizedBox(height: 10),
                  Icon(
                    FluentIcons.ink_stroke_20_regular,
                    size: 15,
                  ),
                  ValueListenableBuilder(
                    valueListenable: model.isStrokesVisible,
                    builder: (_, isStrokesVisibleValue, __) {
                      const double visibilityIconSize = 20;

                      return IconButton(
                        tooltip: "Toggle strokes visibility",
                        onPressed: () => model.toggleStrokesVisibility(),
                        icon: AnimateOnListenable(
                          listenable: model.visibilityPulseListenable,
                          effects: [Phanimations.toolPulseEffect],
                          child: isStrokesVisibleValue
                              ? Icon(
                                  Icons.visibility_outlined,
                                  size: visibilityIconSize,
                                )
                              : Icon(
                                  size: visibilityIconSize,
                                  Icons.visibility_off,
                                  color: Colors.red,
                                ),
                        ),
                      );
                    },
                  ),
                  Divider(),
                  ListenableSlider(
                    listenable: model.opacity,
                    min: 0.0,
                    max: 1.0,
                    interval: 0.1,
                    icon: Icons.image,
                    direction: Axis.vertical,
                  ),
                  ValueListenableBuilder(
                    valueListenable: model.underlayColor,
                    builder: (context, underlayColorValue, __) {
                      final theme = Theme.of(context);

                      return IconButton(
                        tooltip: "Cycle underlay color",
                        onPressed: () {
                          model.cycleUnderlayColor();
                        },
                        icon: Stack(
                          children: [
                            Icon(
                              FluentIcons.square_16_filled,
                              color: underlayColorValue,
                            ),
                            Icon(
                              FluentIcons.square_16_regular,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  //SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final bottomPanel = Builder(builder: (context) {
      final windowSize = MediaQuery.sizeOf(context);

      final windowIsNarrow = windowSize.width < 550;
      final windowIsCompressed = windowSize.width < 640;

      return Positioned(
        bottom: -edgeOverflow,
        left: 10,
        right: 10,
        child: panelMaterial(
          child: SizedBox(
            height: barHeight + edgeOverflow,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: 8,
                    right: 8,
                    bottom: 8 + edgeOverflow,
                    top: 8,
                  ),
                  child: Flex(
                    direction: Axis.horizontal,
                    //spacing: barItemSpacing,
                    children: [
                      SizedBox(width: 5),
                      ListenableBuilder(
                        listenable: model.undoRedoListenable,
                        builder: (_, __) {
                          return Flex(
                            direction: Axis.horizontal,
                            children: [
                              IconButton(
                                tooltip: "Undo",
                                onPressed:
                                    model.changes.canUndo ? model.undo : null,
                                icon: Icon(Icons.undo, size: 18),
                              ),
                              IconButton(
                                tooltip: "Redo",
                                onPressed:
                                    model.changes.canRedo ? model.redo : null,
                                icon: Icon(Icons.redo, size: 18),
                              ),
                            ],
                          );
                        },
                      ),
                      IconButton(
                        tooltip: "Clear all strokes  (Del)",
                        onPressed: () => model.clearAllStrokes(),
                        icon: Icon(Icons.delete, size: 20),
                      ),
                      VerticalDivider(),
                      ValueListenableBuilder(
                        valueListenable: model.currentTool,
                        builder: (context, currentToolValue, _) {
                          if (currentToolValue != AnnotationTool.rulers) {
                            return SizedBox.shrink();
                          }

                          return Row(
                            children: [
                              ValueListenableBuilder(
                                valueListenable: model.currentRulerType,
                                builder: (context, rulerTypeValue, _) {
                                  final label = Text(
                                    "Rulers",
                                    style: theme.textTheme.labelSmall,
                                  );
                                  return Row(
                                    children: [
                                      Tooltip(
                                        message:
                                            "Press R to cycle between rulers",
                                        child: TextButton(
                                          onPressed: null,
                                          child: label,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 42 * 3,
                                        child: SegmentedButton(
                                          expandedInsets: EdgeInsets.all(0),
                                          emptySelectionAllowed: false,
                                          multiSelectionEnabled: false,
                                          showSelectedIcon: false,
                                          style: const ButtonStyle(
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                          segments: const [
                                            ButtonSegment(
                                                value: RulerType.line,
                                                tooltip: "Line",
                                                icon: Icon(FluentIcons
                                                    .line_20_regular)),
                                            ButtonSegment(
                                                value: RulerType.box,
                                                tooltip: "Box",
                                                icon: Icon(FluentIcons
                                                    .border_all_16_regular)),
                                            ButtonSegment(
                                              value: RulerType.circle,
                                              tooltip: "Circle",
                                              icon: Stack(
                                                children: [
                                                  Icon(Icons.circle_outlined),
                                                  Icon(Icons.add),
                                                ],
                                              ),
                                            ),
                                          ],
                                          selected: {rulerTypeValue},
                                          onSelectionChanged: (newSelection) {
                                            model.currentRulerType.value =
                                                newSelection.first;
                                          },
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                    ],
                                  );
                                },
                              ),
                              ValueListenableBuilder(
                                valueListenable:
                                    model.isNextRulerAddsComparison,
                                builder:
                                    (context, addComparisonRulerValue, child) {
                                  return Tooltip(
                                    message:
                                        "Toggle to add a comparison overlay to the next ruler.\nFor comparing with the last created ruler.",
                                    child: AnimateOnListenable(
                                      listenable:
                                          model.comparisonAddedPulseListenable,
                                      effects: [Phanimations.toolPulseEffect],
                                      child: SizedBoxFitted(
                                        height: 32,
                                        width: 32,
                                        child: IconButton.outlined(
                                          onPressed: () => model
                                              .isNextRulerAddsComparison
                                              .toggle(),
                                          icon:
                                              Icon(Icons.splitscreen, size: 25),
                                          isSelected: addComparisonRulerValue,
                                          selectedIcon: Icon(
                                            Icons.splitscreen,
                                            size: 20,
                                          ),
                                          color: addComparisonRulerValue
                                              ? theme.colorScheme.tertiary
                                              : null,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              VerticalDivider(),
                              SizedBox(width: 10),
                              if (windowIsNarrow)
                                Tooltip(
                                  message: "... bottom bar items are hidden.",
                                  child: Icon(
                                    Icons.more_horiz,
                                    size: 20,
                                  ),
                                )
                              else
                                ValueListenableBuilder(
                                  valueListenable: model.currentRulerDivisions,
                                  builder: (context, divisionsValue, _) {
                                    const min = 2;
                                    const max = 8;

                                    final divisionsText =
                                        divisionsValue.toStringAsFixed(0);

                                    return ScrollListener(
                                      onScrollDown: () => model
                                          .currentRulerDivisions
                                          .incrementClamped(-1, min, max),
                                      onScrollUp: () => model
                                          .currentRulerDivisions
                                          .incrementClamped(1, min, max),
                                      child: Flex(
                                        direction: Axis.horizontal,
                                        children: [
                                          windowIsCompressed
                                              ? SizedBox.shrink()
                                              : Text(
                                                  "Divisions",
                                                  style: theme
                                                      .textTheme.labelMedium,
                                                ),
                                          SizedBox(
                                            width:
                                                windowIsCompressed ? 60 : 100,
                                            child: SliderTheme(
                                              data: theme.sliderTheme.copyWith(
                                                trackHeight: 3,
                                                thumbShape:
                                                    RoundSliderThumbShape(
                                                  enabledThumbRadius: 8,
                                                ),
                                              ),
                                              child: Slider(
                                                padding:
                                                    EdgeInsets.only(left: 22),
                                                value:
                                                    divisionsValue.toDouble(),
                                                min: min.toDouble(),
                                                max: max.toDouble(),
                                                divisions: max - min,
                                                onChanged: (newValue) {
                                                  model.currentRulerDivisions
                                                      .value = newValue.toInt();
                                                },
                                              ),
                                            ),
                                          ),
                                          IgnorePointer(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 15.0),
                                              child: Text(
                                                divisionsText,
                                                style:
                                                    theme.textTheme.labelMedium,
                                              ),
                                            ),
                                          ),
                                          windowIsCompressed
                                              ? SizedBox.shrink()
                                              : VerticalDivider(),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ).animate(
                            effects: const [
                              Phanimations.slideRightWideEffect,
                              Phanimations.fadeInEffect
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 5,
                  right: 5,
                  child: PanelCloseButton(
                    onPressed: () {
                      ModalDismissContext.of(context)?.onDismiss?.call();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });

    return Stack(
      children: [
        shortcuts,
        leftPanel,
        rightPanel,
        bottomPanel,
      ],
    );
  }
}

enum PfsSliderLabelType {
  none,
  percent,
  fixedOneDecimal,
}

class ListenableSlider extends StatelessWidget {
  const ListenableSlider({
    super.key,
    required this.listenable,
    required this.min,
    required this.max,
    required this.interval,
    this.icon,
    this.direction = Axis.horizontal,
    this.labelType = PfsSliderLabelType.none,
  });

  final Axis direction;
  final ValueNotifier<double> listenable;
  final double min;
  final double max;
  final double interval;
  final IconData? icon;
  final PfsSliderLabelType labelType;

  @override
  Widget build(BuildContext context) {
    //final theme = Theme.of(context);
    //final panelMaterial = PfsAppTheme.boxPanelFrom(theme);

    const double outerPadding = 10;

    final padding = icon == null
        ? const EdgeInsets.all(0)
        : direction == Axis.horizontal
            ? const EdgeInsets.only(left: outerPadding)
            : const EdgeInsets.only(top: outerPadding);

    final int divisions = ((max - min) / interval).floor();

    void setListenableValueClamped(double newValue) {
      listenable.value = math.min(max, math.max(min, newValue));
    }

    return ScrollListener(
      onScrollDown: () =>
          setListenableValueClamped(listenable.value - interval),
      onScrollUp: () => setListenableValueClamped(listenable.value + interval),
      child: Padding(
        padding: padding,
        child: Flex(
          spacing: 0,
          direction: direction,
          children: [
            icon == null ? const SizedBox.shrink() : Icon(icon, size: 20),
            ValueListenableBuilder(
              valueListenable: listenable,
              builder: (___, listenableValue, __) {
                final label = switch (labelType) {
                  PfsSliderLabelType.percent =>
                    "${(listenableValue * 100).toStringAsFixed(0)}%",
                  PfsSliderLabelType.fixedOneDecimal =>
                    listenableValue.toStringAsFixed(1),
                  _ => null
                };

                return RotatedBox(
                  quarterTurns: direction == Axis.horizontal ? 0 : 3,
                  child: SizedBox(
                    height: 15,
                    width: 160,
                    child: Slider(
                      value: listenableValue,
                      padding: const EdgeInsets.only(right: 15, left: 10),
                      divisions: divisions,
                      label: label,
                      min: min,
                      max: max,
                      onChanged: (newValue) {
                        listenable.value = newValue;
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
