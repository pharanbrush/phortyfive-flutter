import 'dart:math' as math;

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:pfs2/main_screen/main_screen.dart';
import 'package:pfs2/main_screen/panels/modal_panel.dart';
import 'package:pfs2/phlutter/centered_vertically.dart';
import 'package:pfs2/phlutter/model_scope.dart';
import 'package:pfs2/phlutter/scroll_listener.dart';
import 'package:pfs2/phlutter/simple_notifier.dart';
import 'package:pfs2/ui/phanimations.dart';
import 'package:pfs2/ui/phshortcuts.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';
import 'package:pfs2/widgets/phbuttons.dart';
import 'package:undo/undo.dart';

enum AnnotationTool {
  none,
  draw,
  erase,
}

class Stroke {
  Stroke({
    //required this.paint,
    required this.path,
  });
  Path path;
  //Paint paint;
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
  final changes = ChangeStack(limit: 30);
  final lastErasedStrokes = <Stroke>[];

  final currentTool = ValueNotifier<AnnotationTool>(AnnotationTool.draw);
  late final color = ValueNotifier<Color>(colorChoices.first);
  late final underlayColor = ValueNotifier<Color>(underlayColorChoices.first);
  final opacity = ValueNotifier<double>(0.2);
  final strokeWidth = ValueNotifier<double>(3.0);
  final isStrokesVisible = ValueNotifier(true);
  final undoRedoListenable = SimpleNotifier();

  static const colorChoices = <Color>[
    Colors.red,
    Colors.orange,
    Colors.blue,
    Color(0xFF5644B3),
    Colors.white,
    Colors.black,
  ];

  static const underlayColorChoices = <Color>[
    Colors.transparent,
    Colors.black,
    Colors.white,
    Colors.blueGrey,
    Color(0xFFDEC4A5),
  ];

  bool get isStrokesLocked {
    return !isStrokesVisible.value;
  }

  static AnnotationsModel of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ModelScope<AnnotationsModel>>()!
        .model;
  }

  void toggleStrokesVisibility() {
    isStrokesVisible.value = !isStrokesVisible.value;
  }

  void setTool(AnnotationTool newTool) {
    currentTool.value = newTool;
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

  void startNewStroke(Offset position) {
    if (isStrokesLocked) return;
    // debugPrint(strokes.length.toString());
    currentStrokePath = Path()..moveTo(position.dx, position.dy);
    strokes.add(Stroke(path: currentStrokePath));
  }

  void addPointToStroke(Offset point) {
    if (isStrokesLocked) return;
    currentStrokePath.lineTo(point.dx, point.dy);
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
    for (final metric in stroke.path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += tolerance) {
        final pos = metric.getTangentForOffset(d)!.position;
        if ((pos - point).distance <= tolerance) {
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
      return AnnotationsBottomBar();
    },
  );
}

class AnnotationsBottomBar extends StatelessWidget {
  const AnnotationsBottomBar({
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
    const double barItemSpacing = 3;

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
          Phshortcuts.drawToolAnnotations: () =>
              model.setTool(AnnotationTool.draw),
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
                            tooltip: "Stroke Eraser  (E)",
                            isSelected:
                                currentToolValue == AnnotationTool.erase,
                            onPressed: () =>
                                model.setTool(AnnotationTool.erase),
                            icon: currentToolValue == AnnotationTool.erase
                                ? Icon(FluentIcons.eraser_segment_20_filled)
                                : Icon(FluentIcons.eraser_segment_20_regular),
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
                        icon: isStrokesVisibleValue
                            ? Icon(
                                Icons.visibility_outlined,
                                size: visibilityIconSize,
                              )
                            : Icon(
                                size: visibilityIconSize,
                                Icons.visibility_off,
                                color: Colors.red,
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

    final bottomPanel = Positioned(
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
                child: Row(
                  spacing: barItemSpacing,
                  children: [
                    Text(
                      "Annotations",
                      style: theme.textTheme.labelLarge,
                    ),
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
                              icon: Icon(Icons.undo),
                            ),
                            IconButton(
                              tooltip: "Redo",
                              onPressed:
                                  model.changes.canRedo ? model.redo : null,
                              icon: Icon(Icons.redo),
                            ),
                          ],
                        );
                      },
                    ),
                    IconButton(
                      tooltip: "Clear all strokes  (Del)",
                      onPressed: () => model.clearAllStrokes(),
                      icon: Icon(
                        Icons.delete,
                      ),
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
