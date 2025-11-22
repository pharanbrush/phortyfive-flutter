import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pfs2/models/phtimer_model.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';
import 'package:pfs2/ui/phanimations.dart';
import 'package:pfs2/main_screen/panels/modal_panel.dart';
import 'package:pfs2/widgets/phbuttons.dart';

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

  static const List<Offset> presetPositions = [
    Offset(-5, 140),
    Offset(12, 84),
    Offset(54, 34),
    Offset(113, 3),
    Offset(187, 4),
    Offset(246, 38),
    Offset(283, 84),
    Offset(298, 140),
  ];

  static const List<(String, int)> timerPresets = [
    ('15s', 15),
    ('30s', 30),
    ('45s', 45),
    ('60s', 60),
    ('90s', 90),
    ('2m', 2 * 60),
    ('3m', 3 * 60),
    ('5m', 5 * 60),
  ];

  Iterable<Widget> presetButtons() sync* {
    Widget preset(String text, int seconds, Offset offset) {
      const double leftOffset = 75;
      const double topOffset = 70;

      return Positioned(
        key: Key('$seconds seconds button'),
        left: leftOffset + offset.dx,
        top: topOffset + offset.dy,
        child: TimerPresetButton(text, seconds),
      );
    }

    final n = min(timerPresets.length, presetPositions.length);
    for (var i = 0; i < n; i++) {
      final (String text, int seconds) = timerPresets[i];
      yield preset(text, seconds, presetPositions[i]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onDismiss = ModalDismissContext.of(context)?.onDismiss ?? () {};
    final timerModel = PhtimerModel.of(context);

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

    final textFieldBuilder = PfsAppTheme.giantTextFieldFrom(Theme.of(context));
    final secondsTextField = textFieldBuilder(
      focusNode: timerTextEditorFocusNode,
      controller: timerTextEditorController,
      onSubmitted: (value) {
        timerModel.trySetDurationSecondsInput(value);
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
                            child: Text('Timer duration', style: bigLabelStyle),
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
                  children: presetButtons().toList().animate(
                    interval: const Duration(milliseconds: 30),
                    delay: const Duration(milliseconds: 100),
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
      shape: WidgetStatePropertyAll(CircleBorder()),
      fixedSize: WidgetStatePropertyAll(Size(50, 50)),
      padding: WidgetStatePropertyAll(EdgeInsets.zero),
    );

    final onDismiss = ModalDismissContext.of(context)?.onDismiss ?? () {};

    Widget button;
    final model = PhtimerModel.of(context);
    
    void onPressed() {
      model.setDurationSeconds(seconds);
      onDismiss.call();
    }

    final isCurrentSelectedButton = (seconds == model.currentDurationSeconds);
    if (isCurrentSelectedButton) {
      final selectedColor = WidgetStatePropertyAll(
        Theme.of(context).colorScheme.primary,
      );
      final selectedButtonStyle = presetButtonStyle.copyWith(
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
