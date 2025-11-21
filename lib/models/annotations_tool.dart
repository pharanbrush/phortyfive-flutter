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

  late final ModalPanel annotationPanel = ModalPanel(
    onBeforeOpen: () => closeAllPanels(except: annotationPanel),
    onClosed: () {
      //colorMeterModel.endColorMeter();
      //onColorMeterExit?.call();
      onAnnotationToolExit?.call();
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

    return Stack(
      children: [
        Positioned(
          bottom: -bottomOverflow,
          left: 10,
          right: 10,
          child: panelMaterial(
            child: SizedBox(
              height: barHeight + bottomOverflow,
              child: Padding(
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
                        model.removeLastAnnotation();
                      },
                      icon: Icon(Icons.undo),
                    ),
                    IconButton(
                      tooltip: "Clear all strokes",
                      onPressed: () => model.clearAllAnnotations(),
                      icon: Icon(
                        Icons.delete,
                      ),
                    ),
                    ValueListenableBuilder(
                      valueListenable: model.color,
                      builder: (_, modelColorValue, __) {
                        return IconButton.filled(
                          tooltip: "Cycle stroke color",
                          onPressed: () {
                            model.cycleColor();
                          },
                          icon: Icon(Icons.color_lens),
                          color: model.color.value,
                        );
                      },
                    ),
                    ListenableSlider(
                      listenable: model.opacity,
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      icon: Icons.visibility,
                    ),
                    ListenableSlider(
                      listenable: model.strokeWidth,
                      min: 0.5,
                      max: 2,
                      divisions: 4,
                      icon: Icons.brush,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ListenableSlider extends StatelessWidget {
  const ListenableSlider({
    super.key,
    required this.listenable,
    required this.min,
    required this.max,
    required this.divisions,
    required this.icon,
  });

  final ValueNotifier<double> listenable;
  final double min;
  final double max;
  final int divisions;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final panelMaterial = PfsAppTheme.boxPanelFrom(theme);

    return panelMaterial(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        child: Flex(
          direction: Axis.horizontal,
          children: [
            Icon(icon),
            ValueListenableBuilder(
                valueListenable: listenable,
                builder: (_, listenableValue, __) {
                  return Slider(
                    value: listenableValue,
                    divisions: divisions,
                    //label: "${(opacityValue * 100).toStringAsFixed(0)}%",
                    min: min,
                    max: max,
                    onChanged: (newValue) {
                      listenable.value = newValue;
                    },
                  );
                }),
          ],
        ),
      ),
    );
  }
}
