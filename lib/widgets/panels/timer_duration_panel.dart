import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pfs2/models/phtimer_model.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';
import 'package:pfs2/widgets/animation/phanimations.dart';
import 'package:pfs2/widgets/modal_underlay.dart';

class TimerDurationPanel extends StatelessWidget {
  static const double diameter = 350;
  static const double radius = diameter * 0.5;
  static const double bottomOffset = 20;
  static const double rightMarginNormal = 160;
  static const double rightMarginNarrow = 20;

  final Function()? onDismiss;

  final TextEditingController timerTextEditorController =
      TextEditingController(text: '');

  final FocusNode timerTextEditorFocusNode =
      FocusNode(debugLabel: 'Timer Text Editor');

  TimerDurationPanel({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return _setTimerDurationWidget();
  }

  void setActive(bool active, int currentTimerDuration) {
    timerTextEditorController.text = currentTimerDuration.toString();

    if (active) {
      timerTextEditorFocusNode.requestFocus();
      _selectAllText(timerTextEditorController);
    }
  }

  Widget _setTimerDurationWidget() {
    return PhtimerModel.scope((context, __, model) {
      final windowSize = MediaQuery.of(context).size;

      const double narrowWindowWidth = 600;
      const double minimumWindowWidth = 450;

      double inverseLerp(double a, double b, double v) => (v - a) / (b - a);
      double remap(
          double iMin, double iMax, double oMin, double oMax, double v) {
        double t = inverseLerp(iMin, iMax, v);
        return lerpDouble(oMin, oMax, t) ?? oMin;
      }

      final bool isWindowNarrow = windowSize.width < narrowWindowWidth;
      final double rightOffset = isWindowNarrow
          ? remap(minimumWindowWidth, narrowWindowWidth, rightMarginNarrow,
              rightMarginNormal, windowSize.width)
          : rightMarginNormal;

      const presetButtonStyle = ButtonStyle(
        shape: MaterialStatePropertyAll(CircleBorder()),
        fixedSize: MaterialStatePropertyAll(Size(50, 50)),
        padding: MaterialStatePropertyAll(EdgeInsets.zero),
      );

      Widget preset(String text, int seconds, double left, double top) {
        final isCurrentSelectedButton =
            (seconds == model.currentDurationSeconds);
        if (isCurrentSelectedButton) {
          var selectedButtonStyle = presetButtonStyle.copyWith(
            backgroundColor:
                MaterialStatePropertyAll(Theme.of(context).primaryColor),
          );

          return Positioned(
            left: left,
            top: top,
            child: FilledButton(
              style: selectedButtonStyle,
              onPressed: () {
                model.setDurationSeconds(seconds);
                onDismiss?.call();
              },
              child: Text(text),
            ),
          );
        }

        return Positioned(
          left: left,
          top: top,
          child: TextButton(
            style: presetButtonStyle,
            onPressed: () {
              model.setDurationSeconds(seconds);
              onDismiss?.call();
            },
            child: Text(text),
          ),
        );
      }

      final secondsTextField = SizedBox(
        width: 100,
        child: TextField(
          controller: timerTextEditorController,
          focusNode: timerTextEditorFocusNode,
          autofocus: true,
          autocorrect: false,
          maxLength: 4,
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          decoration: PfsTheme.largeTextFieldInputDecoration,
          style: PfsTheme.largeTextFieldTextStyle,
          onSubmitted: (value) {
            model.trySetDurationSecondsInput(value);
            onDismiss?.call();
          },
        ),
      );

      Widget tapToDismiss({Widget? child}) {
        return GestureDetector(
          onTap: () => onDismiss?.call(),
          behavior: HitTestBehavior.translucent,
          child: child,
        );
      }

      const double leftOffset = 75;
      const double topOffset = 70;

      final labelStyle = TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );

      final bigLabelStyle = Theme.of(context)
          .textTheme
          .headlineSmall
          ?.copyWith(color: labelStyle.color);

      return Stack(
        children: [
          ModalUnderlay(onDismiss: () => onDismiss?.call()),
          Positioned(
            right: rightOffset,
            bottom: (-radius) + bottomOffset,
            child: Stack(
              alignment: Alignment.center,
              children: [
                tapToDismiss(
                  child: PfsTheme.popupPanelPawMaterial(
                    child: SizedBox(
                      width: diameter,
                      height: diameter,
                      child: DefaultTextStyle(
                        style: labelStyle,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child:
                                  Text('Timer duration', style: bigLabelStyle),
                            ),
                            secondsTextField,
                            const SizedBox(height: 3),
                            const Text('seconds'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                tapToDismiss(
                  child: SizedBox(
                    height: 500,
                    width: 500,
                    child: Stack(
                      children: [
                        preset('15s', 15, leftOffset + 13, topOffset + 84),
                        preset('30s', 30, leftOffset + 54, topOffset + 34),
                        preset('45s', 45, leftOffset + 113, topOffset + 3),
                        preset('60s', 60, leftOffset + 187, topOffset + 4),
                        preset('90s', 90, leftOffset + 246, topOffset + 38),
                        preset('2m', 2 * 60, leftOffset + 283, topOffset + 84),
                        preset('3m', 3 * 60, leftOffset + 298, topOffset + 140),
                      ].animate(
                        interval: const Duration(milliseconds: 40),
                        delay: const Duration(milliseconds: 120),
                        effects: const [
                          Phanimations.slideUpEffect,
                          Phanimations.fadeInEffect,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ).animate(
              effects: const [
                Phanimations.slideUpEffect,
                Phanimations.growBottomEffect,
              ],
            ),
          ),
        ],
      );
    });
  }

  static void _selectAllText(TextEditingController controller) {
    controller.selection =
        TextSelection(baseOffset: 0, extentOffset: controller.text.length);
  }
}
