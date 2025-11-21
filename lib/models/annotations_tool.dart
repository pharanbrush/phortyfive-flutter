import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:pfs2/main_screen/main_screen.dart';
import 'package:pfs2/main_screen/panels/modal_panel.dart';
import 'package:pfs2/phlutter/model_scope.dart';
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

class AnnotationsModel {
  final annotationsFocus = FocusNode();
  final List<Stroke> strokes = [];
  Path currentStrokePath = Path();
  final changes = ChangeStack(limit: 30);
  final lastErasedStrokes = <Stroke>[];

  final currentTool = ValueNotifier<AnnotationTool>(AnnotationTool.draw);
  late final color = ValueNotifier<Color>(Colors.red);
  final opacity = ValueNotifier<double>(0.2);
  final strokeWidth = ValueNotifier<double>(3.0);
  final undoRedoListenable = SimpleNotifier();

  static const colorChoices = <Color>[
    Colors.red,
    Colors.orange,
    Colors.blue,
    Colors.deepPurpleAccent,
    Colors.white,
    Colors.black,
  ];

  static AnnotationsModel of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ModelScope<AnnotationsModel>>()!
        .model;
  }

  void setTool(AnnotationTool newTool) {
    currentTool.value = newTool;
  }

  void cycleColor() {
    int index = colorChoices.indexOf(color.value);
    if (index < 0) {
      debugPrint("color not found");
      index = -1;
    }
    index++;
    if (index >= colorChoices.length) index = 0;
    color.value = colorChoices[index];
  }

  void startNewStroke(Offset position) {
    // debugPrint(strokes.length.toString());
    currentStrokePath = Path()..moveTo(position.dx, position.dy);
    strokes.add(Stroke(path: currentStrokePath));
  }

  void addPointToStroke(Offset point) {
    currentStrokePath.lineTo(point.dx, point.dy);
  }

  void commitCurrentStroke() {
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

    final model = AnnotationsModel.of(context);

    const double bottomOverflow = 10;
    const double barHeight = 60;
    const double barItemSpacing = 3;

    const double brushSizeMin = 0.5;
    const double brushSizeIntervals = brushSizeMin;
    const double brushSizeMax = 8;
    final int brushSizeDivisions = (brushSizeMax / brushSizeIntervals).floor();

    return Stack(
      children: [
        CallbackShortcuts(
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
        Align(
          alignment: AlignmentGeometry.centerLeft,
          child: panelMaterial(
            child: SizedBox(
              height: 350,
              width: 50,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
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
                              tooltip: "Draw",
                              isSelected:
                                  currentToolValue == AnnotationTool.draw,
                              onPressed: () =>
                                  model.setTool(AnnotationTool.draw),
                              icon: currentToolValue == AnnotationTool.draw
                                  ? Icon(FluentIcons.edit_20_filled)
                                  : Icon(FluentIcons.edit_20_regular),
                            ),
                            IconButton.filled(
                              tooltip: "Erase",
                              isSelected:
                                  currentToolValue == AnnotationTool.erase,
                              onPressed: () =>
                                  model.setTool(AnnotationTool.erase),
                              icon: currentToolValue == AnnotationTool.erase
                                  ? Icon(FluentIcons.eraser_20_filled)
                                  : Icon(FluentIcons.eraser_20_regular),
                            ),
                          ],
                        );
                      },
                    ),
                    //SizedBox(height: 8),
                    Divider(),
                    ListenableSlider(
                      listenable: model.strokeWidth,
                      min: brushSizeMin,
                      max: brushSizeMax,
                      divisions: brushSizeDivisions,
                      icon: Icons.brush,
                      direction: Axis.vertical,
                    ),
                    Divider(),
                    ValueListenableBuilder(
                      valueListenable: model.color,
                      builder: (_, modelColorValue, __) {
                        return IconButton.filled(
                          tooltip: "Cycle stroke color",
                          onPressed: () {
                            model.cycleColor();
                          },
                          icon: Icon(Icons.circle),
                          color: model.color.value,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Align(
          alignment: AlignmentGeometry.centerRight,
          child: panelMaterial(
            child: SizedBox(
              height: 220,
              width: 60,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Tooltip(
                  waitDuration: Duration(seconds: 1),
                  message: "Image Opacity",
                  child: ListenableSlider(
                    listenable: model.opacity,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    icon: Icons.copy_all,
                    direction: Axis.vertical,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -bottomOverflow,
          left: 10,
          right: 10,
          child: panelMaterial(
            child: SizedBox(
              height: barHeight + bottomOverflow,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 8,
                      right: 8,
                      bottom: 8 + bottomOverflow,
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
                          tooltip: "Clear all strokes",
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
        ),
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
    required this.divisions,
    required this.icon,
    this.direction = Axis.horizontal,
    this.labelType = PfsSliderLabelType.none,
  });

  final Axis direction;
  final ValueNotifier<double> listenable;
  final double min;
  final double max;
  final int divisions;
  final IconData icon;
  final PfsSliderLabelType labelType;

  @override
  Widget build(BuildContext context) {
    //final theme = Theme.of(context);
    //final panelMaterial = PfsAppTheme.boxPanelFrom(theme);

    final padding = direction == Axis.horizontal
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 0)
        : const EdgeInsets.symmetric(horizontal: 0, vertical: 10);

    return Padding(
      padding: padding,
      child: Flex(
        spacing: 0,
        direction: direction,
        children: [
          Icon(icon, size: 20),
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
                  width: 150,
                  child: Slider(
                    value: listenableValue,
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
    );
  }
}
