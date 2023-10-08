import 'package:flutter/material.dart';
import 'package:pfs2/models/pfs_model.dart';

class TimerBar extends StatelessWidget {
  const TimerBar({super.key});

  static const Color pausedColor = Color(0xFFFDD835);
  static const Color runningColor = Colors.blueAccent;
  static const Color almostZeroColor = Color(0xFF0D47A1);
  static const double almostZeroThreshold = 0.1;

  static const double barWidth = 200;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: TimerBar.barWidth,
      height: 2,
      child: PfsAppModel.scope(
        (_, __, model) {
          final barValueFromModel = (1.0 - model.progressPercent);
          Color barColor = model.timer.isActive
              ? (barValueFromModel < TimerBar.almostZeroThreshold
                  ? TimerBar.almostZeroColor
                  : TimerBar.runningColor)
              : TimerBar.pausedColor;

          return TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutQuart,
            tween: Tween<double>(begin: 0, end: barValueFromModel),
            builder: (_, value, __) {
              return LinearProgressIndicator(
                backgroundColor: Colors.black12,
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
