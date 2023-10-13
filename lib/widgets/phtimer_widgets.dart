import 'package:flutter/material.dart';
import 'package:pfs2/models/pfs_model.dart';
import 'package:pfs2/models/phtimer_model.dart';
import 'package:pfs2/ui/pfs_localization.dart';
import 'package:pfs2/ui/phshortcuts.dart';

class TimerBar extends StatelessWidget {
  const TimerBar({super.key});
  static const double almostZeroThreshold = 0.1;
  static const double barWidth = 200;

  @override
  Widget build(BuildContext context) {
    final timerTheme = Theme.of(context).extension<PhtimerTheme>() ??
        PhtimerTheme.defaultTheme;

    return SizedBox(
      width: TimerBar.barWidth,
      height: 2,
      child: PhtimerModel.scope(
        (_, __, timerModel) {
          final barValueFromModel = (1.0 - timerModel.progressPercent);
          Color barColor = timerModel.isRunning
              ? (barValueFromModel < TimerBar.almostZeroThreshold
                  ? timerTheme.almostZeroColor
                  : timerTheme.runningColor)
              : timerTheme.pausedColor;

          return TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutQuart,
            tween: Tween<double>(begin: 0, end: barValueFromModel),
            builder: (_, value, __) {
              return LinearProgressIndicator(
                backgroundColor: timerTheme.barBackgroundColor,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
                value: value,
              );
            },
          );
        },
      ),
    );
  }
}

class PlayPauseTimerButton extends StatelessWidget {
  const PlayPauseTimerButton({super.key, required this.iconProgress});

  final Animation<double> iconProgress;

  @override
  Widget build(BuildContext context) {
    final timerTheme = Theme.of(context).extension<PhtimerTheme>() ??
        PhtimerTheme.defaultTheme;

    final shortcutLabel =
        PfsLocalization.tooltipShortcut(Phshortcuts.playPause);
    final pressLabel = PfsLocalization.pressCapital;

    return PfsAppModel.scope((_, __, model) {
      return PhtimerModel.scope((_, __, timerModel) {
        final playButtonTooltip =
            'Timer paused. $pressLabel to resume ($shortcutLabel)';
        final pauseButtonTooltip =
            'Timer running. $pressLabel to pause ($shortcutLabel)';
        final icon = AnimatedIcon(
          icon: AnimatedIcons.play_pause,
          progress: iconProgress,
        );

        bool allowTimerControl = model.allowTimerPlayPause;
        Color buttonColor = allowTimerControl
            ? (timerModel.isRunning
                ? timerTheme.runningColor
                : timerTheme.pausedColor)
            : timerTheme.disabledColor;

        final style = ButtonStyle(
          animationDuration: const Duration(milliseconds: 300),
          backgroundColor:
              MaterialStateProperty.resolveWith((Set<MaterialState> states) {
            if (states.contains(MaterialState.hovered)) {
              return buttonColor.withOpacity(1);
            }
            return buttonColor;
          }),
          overlayColor: const MaterialStatePropertyAll(Colors.transparent),
          elevation: const MaterialStatePropertyAll(0),
        );

        final tooltipText =
            timerModel.isRunning ? pauseButtonTooltip : playButtonTooltip;

        return Tooltip(
          message: tooltipText,
          child: FilledButton(
            style: style,
            onPressed: () => model.tryTogglePlayPauseTimer(),
            child: Container(
              alignment: Alignment.center,
              width: 50,
              child: icon,
            ),
          ),
        );
      });
    });
  }
}

class PhtimerTheme extends ThemeExtension<PhtimerTheme> {
  const PhtimerTheme({
    required this.pausedColor,
    required this.runningColor,
    required this.almostZeroColor,
    required this.disabledColor,
    required this.barBackgroundColor,
  });

  static const defaultTheme = PhtimerTheme(
    pausedColor: Colors.orange,
    runningColor: Colors.blue,
    almostZeroColor: Colors.red,
    disabledColor: Color(0xFF9E9E9E),
    barBackgroundColor: Colors.black12,
  );

  @override
  ThemeExtension<PhtimerTheme> copyWith({
    Color? pausedColor,
    Color? runningColor,
    Color? almostZeroColor,
    Color? disabledColor,
    Color? barBackgroundColor,
  }) {
    return PhtimerTheme(
      pausedColor: pausedColor ?? this.pausedColor,
      runningColor: runningColor ?? this.runningColor,
      almostZeroColor: almostZeroColor ?? this.almostZeroColor,
      disabledColor: disabledColor ?? this.disabledColor,
      barBackgroundColor: barBackgroundColor ?? this.barBackgroundColor,
    );
  }

  @override
  ThemeExtension<PhtimerTheme> lerp(
      covariant ThemeExtension<PhtimerTheme>? other, double t) {
    if (other is! PhtimerTheme) {
      return this;
    }

    return PhtimerTheme(
      pausedColor: Color.lerp(pausedColor, other.pausedColor, t)!,
      runningColor: Color.lerp(runningColor, other.runningColor, t)!,
      almostZeroColor: Color.lerp(almostZeroColor, other.almostZeroColor, t)!,
      disabledColor: Color.lerp(disabledColor, other.disabledColor, t)!,
      barBackgroundColor:
          Color.lerp(barBackgroundColor, other.barBackgroundColor, t)!,
    );
  }

  final Color pausedColor;
  final Color runningColor;
  final Color almostZeroColor;
  final Color disabledColor;
  final Color barBackgroundColor;
}
