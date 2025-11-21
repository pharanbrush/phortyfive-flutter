import 'package:flutter/material.dart';
import 'package:pfs2/main_screen/main_screen.dart';
import 'package:pfs2/main_screen/panels/modal_panel.dart';
import 'package:pfs2/phlutter/model_scope.dart';
import 'package:pfs2/ui/phanimations.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';
import 'package:pfs2/widgets/phbuttons.dart';

class Stroke {
  Stroke({
    //required this.paint,
    required this.path,
  });
  Path path;
  //Paint paint;
}

class AnnotationsModel {
  final List<Stroke> strokes = [];
  Path currentStrokePath = Path();

  late final color = ValueNotifier<Color>(Colors.red);
  final opacity = ValueNotifier<double>(0.2);
  final strokeWidth = ValueNotifier<double>(1.0);

  static const colorChoices = <Color>[
    Colors.red,
    Colors.orange,
    Colors.blue,
    Colors.deepPurpleAccent,
    Colors.white,
    Colors.black,
  ];

  void cycleColor() {
    int index = colorChoices.indexOf(color.value);
    if (index < 0) {
      debugPrint("color not found");
      return;
    }
    index++;
    if (index >= colorChoices.length) index = 0;
    color.value = colorChoices[index];
  }

  static AnnotationsModel of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ModelScope<AnnotationsModel>>()!
        .model;
  }

  void startNewStroke(Offset position) {
    debugPrint(strokes.length.toString());
    currentStrokePath = Path()..moveTo(position.dx, position.dy);
    strokes.add(Stroke(path: currentStrokePath));
  }

  void addPointToStroke(Offset point) {
    currentStrokePath.lineTo(point.dx, point.dy);
  }

  void removeLastStroke() {
    if (strokes.isEmpty) return;

    strokes.removeLast();
  }

  void clearAllStrokes() {
    strokes.clear();
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
    const double brushSizeMax = 6;
    final int brushSizeDivisions = (brushSizeMax / brushSizeIntervals).floor();

    return Stack(
      children: [
        Align(
          alignment: AlignmentGeometry.centerLeft,
          child: panelMaterial(
            child: SizedBox(
              height: 250,
              width: 50,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Flex(
                  direction: Axis.vertical,
                  children: [
                    ListenableSlider(
                      listenable: model.strokeWidth,
                      min: brushSizeMin,
                      max: brushSizeMax,
                      divisions: brushSizeDivisions,
                      icon: Icons.brush,
                      direction: Axis.vertical,
                    ),
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
              height: 200,
              width: 50,
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
                        IconButton(
                          tooltip: "Undo",
                          onPressed: () {
                            model.removeLastStroke();
                          },
                          icon: Icon(Icons.undo),
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
    final theme = Theme.of(context);
    final panelMaterial = PfsAppTheme.boxPanelFrom(theme);

    final padding = direction == Axis.horizontal
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 0)
        : const EdgeInsets.symmetric(horizontal: 0, vertical: 10);

    return panelMaterial(
      child: Padding(
        padding: padding,
        child: Flex(
          spacing: 0,
          direction: direction,
          children: [
            Icon(icon),
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
                }),
          ],
        ),
      ),
    );
  }
}
