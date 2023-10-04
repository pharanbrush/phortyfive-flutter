import 'package:flutter/material.dart';
import 'package:pfs2/screens/main_screen.dart';
import 'package:pfs2/widgets/modal_underlay.dart';

class TimerDurationPanel extends StatelessWidget {
  static const double diameter = 350;
  static const double radius = diameter * 0.5;
  static const double containerPadding = 100;
  static const double bottomOffset = 90 - (containerPadding * 0.5);
  static const double rightMargin = 110 - (containerPadding * 0.5);
  static const Color backgroundColor = Color(0xDD81B6E0);
  static const Color textColor = Colors.white;
  static const Color outlineColor = Color(0xFF0F6892);

  final Function()? onCloseIntent;

  final TextEditingController timerTextEditorController =
      TextEditingController(text: '');

  final FocusNode timerTextEditorFocusNode =
      FocusNode(debugLabel: 'Timer Text Editor');

  TimerDurationPanel({super.key, required this.onCloseIntent});

  @override
  Widget build(BuildContext context) {
    return _setTimerDurationWidget();
  }

  void setActive(bool active, int currentTimerDuration) {
    timerTextEditorController.text = currentTimerDuration.toString();
    
    if (active) {
      timerTextEditorFocusNode.requestFocus();
      _selectAllText();
    }
  }

  Widget _setTimerDurationWidget() {
    return Phbuttons.appModelWidget((_, __, model) {
      Widget preset(String text, int seconds, double left, double top) {
        if (seconds == model.currentTimerDuration) {
          return Positioned(
            left: left,
            top: top,
            child: FilledButton(
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(10)),
              onPressed: () {
                model.setTimerSeconds(seconds);
                onCloseIntent!();
              },
              child: Text(text),
            ),
          );
        }

        return Positioned(
          left: left,
          top: top,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(10)),
            onPressed: () {
              model.setTimerSeconds(seconds);
              onCloseIntent!();
            },
            child: Text(text),
          ),
        );
      }

      return Stack(
        children: [
          ModalUnderlay(onTapDown: () => onCloseIntent!()),
          Positioned(
            right: rightMargin,
            bottom: (-radius) + bottomOffset,
            child: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: diameter + containerPadding,
                height: diameter + containerPadding,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    GestureDetector(
                      onTapDown: (details) {
                        onCloseIntent!();
                      },
                      child: Container(
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: backgroundColor),
                        child: SizedBox(
                          width: diameter,
                          height: diameter,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'Timer duration',
                                  style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                              ),
                              SizedBox(
                                  width: 100,
                                  child: TextField(
                                    controller: timerTextEditorController,
                                    focusNode: timerTextEditorFocusNode,
                                    autocorrect: false,
                                    maxLength: 4,
                                    textAlign: TextAlign.center,
                                    textAlignVertical: TextAlignVertical.center,
                                    style: const TextStyle(fontSize: 32),
                                    autofocus: true,
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 5),
                                      border: OutlineInputBorder(),
                                      focusColor: outlineColor,
                                      filled: true,
                                      fillColor: Colors.white,
                                      counterText: '',
                                      counterStyle: TextStyle(fontSize: 1),
                                    ),
                                    onSubmitted: (value) {
                                      model.trySetTimerSecondsInput(value);
                                      onCloseIntent!();
                                    },
                                  )),
                              const SizedBox(height: 3),
                              const Text(
                                'seconds',
                                style: TextStyle(color: textColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: diameter,
                      width: diameter,
                      child: Stack(
                        children: [
                          preset('15s', 15, 5, 80),
                          preset('30s', 30, 50, 30),
                          preset('45s', 45, 115, 0),
                          preset('60s', 60, 195, 5),
                          preset('90s', 90, 255, 35),
                          preset('2m', 2 * 60, 290, 80),
                          preset('3m', 3 * 60, 293, 130),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  void _selectAllText() {
    timerTextEditorController.selection = TextSelection(
        baseOffset: 0, extentOffset: timerTextEditorController.text.length);
  }
}
