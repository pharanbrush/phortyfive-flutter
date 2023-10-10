import 'package:flutter/material.dart';
import 'package:pfs2/models/pfs_model.dart';

class TimerBar extends StatelessWidget {
  const TimerBar({super.key});
  static const double almostZeroThreshold = 0.1;
  static const double barWidth = 200;

  @override
  Widget build(BuildContext context) {
    final timerTheme = Theme.of(context).extension<PhtimerTheme>() ?? PhtimerTheme.defaultTheme;

    return SizedBox(
      width: TimerBar.barWidth,
      height: 2,
      child: PfsAppModel.scope(
        (_, __, model) {
          final barValueFromModel = (1.0 - model.progressPercent);
          Color barColor = model.timer.isActive
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