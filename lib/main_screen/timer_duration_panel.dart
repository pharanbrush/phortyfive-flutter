import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pfs2/models/phtimer_model.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';
import 'package:pfs2/ui/phanimations.dart';
import 'package:pfs2/widgets/modal_panel.dart';
import 'package:pfs2/widgets/phbuttons.dart';
import 'package:scoped_model/scoped_model.dart';

class TimerDurationPanel extends StatelessWidget {
  const TimerDurationPanel({
    super.key,
    required this.timerTextEditorController,
    required this.timerTextEditorFocusNode,
  });

  static const double diameter = 350;
  static const double radius = diameter * 0.5;
  static const double bottomOffset = 20;

  final TextEditingController timerTextEditorController;
  final FocusNode timerTextEditorFocusNode;

  @override
  Widget build(BuildContext context) {
    final onDismiss = ModalDismissContext.of(context)?.onDismiss ?? () {};

    return PhtimerModel.scope((context, __, model) {
      final windowSize = MediaQuery.of(context).size;

      const double widestNarrowWidth = 600;
      const double narrowestNarrowWidth = 450;
      const double rightMarginNormal = 160;
      const double squeezeOffset = 5;
      const double rightMarginNarrow = rightMarginNormal -
          (widestNarrowWidth - narrowestNarrowWidth) +
          squeezeOffset;

      final double rightOffset = Phbuttons.squeezeRemap(
        inputValue: windowSize.width,
        iMin: narrowestNarrowWidth,
        iThreshold: widestNarrowWidth,
        oMin: rightMarginNarrow,
        oRegular: rightMarginNormal,
      );

      final textFieldBuilder =
          PfsAppTheme.giantTextFieldFrom(Theme.of(context));
      final secondsTextField = textFieldBuilder(
        focusNode: timerTextEditorFocusNode,
        controller: timerTextEditorController,
        onSubmitted: (value) {
          model.trySetDurationSecondsInput(value);
          onDismiss.call();
        },
      );

      Widget tapToDismiss({Widget? child}) {
        return GestureDetector(
          onTap: () => onDismiss.call(),
          behavior: HitTestBehavior.translucent,
          child: child,
        );
      }

      Widget preset(String text, int seconds, double left, double top) {
        return Positioned(
          key: Key('$seconds seconds button'),
          left: left,
          top: top,
          child: TimerPresetButton(text, seconds),
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

      final panelMaterial = PfsAppTheme.pawPanelFrom(Theme.of(context));

      return Stack(
        children: [
          Positioned(
            right: rightOffset,
            bottom: (-radius) + bottomOffset,
            child: Stack(
              alignment: Alignment.center,
              children: [
                tapToDismiss(
                  child: panelMaterial(
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
                SizedBox(
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
              ],
            ).animate(
              effects: const [
                Phanimations.growBottomEffect,
              ],
            ),
          ),
        ],
      );
    });
  }
}

class TimerPresetButton extends StatelessWidget {
  const TimerPresetButton(
    this.text,
    this.seconds, {
    super.key,
  });

  final String text;
  final int seconds;

  @override
  Widget build(BuildContext context) {
    const presetButtonStyle = ButtonStyle(
      shape: MaterialStatePropertyAll(CircleBorder()),
      fixedSize: MaterialStatePropertyAll(Size(50, 50)),
      padding: MaterialStatePropertyAll(EdgeInsets.zero),
    );

    final onDismiss = ModalDismissContext.of(context)?.onDismiss ?? () {};

    Widget button;

    final model = ScopedModel.of<PhtimerModel>(context, rebuildOnChange: true);
    void onPressed() {
      model.setDurationSeconds(seconds);
      onDismiss.call();
    }

    final isCurrentSelectedButton = (seconds == model.currentDurationSeconds);
    if (isCurrentSelectedButton) {
      final selectedColor = MaterialStatePropertyAll(
        Theme.of(context).colorScheme.primary,
      );
      var selectedButtonStyle = presetButtonStyle.copyWith(
        backgroundColor: selectedColor,
      );

      button = FilledButton(
        style: selectedButtonStyle,
        onPressed: onPressed,
        child: Text(text),
      );
    } else {
      button = TextButton(
        style: presetButtonStyle,
        onPressed: onPressed,
        child: Text(text),
      );
    }

    return button;
  }
}

class TimerDurationEditor {
  TimerDurationEditor();

  final TextEditingController _textEditingController =
      TextEditingController(text: '');
  final FocusNode _textFieldFocusNode =
      FocusNode(debugLabel: 'Timer Text Editor');

  Widget widget() {
    return TimerDurationPanel(
      timerTextEditorController: _textEditingController,
      timerTextEditorFocusNode: _textFieldFocusNode,
    );
  }

  void setActive(bool active, int currentTimerDuration) {
    _textEditingController.text = currentTimerDuration.toString();

    if (active) {
      _textFieldFocusNode.requestFocus();
      _selectAllText(_textEditingController);
    }
  }

  static void _selectAllText(TextEditingController controller) {
    controller.selection =
        TextSelection(baseOffset: 0, extentOffset: controller.text.length);
  }
}
