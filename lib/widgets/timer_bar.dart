import 'package:flutter/material.dart';
import 'package:pfs2/models/pfs_model.dart';
import 'package:pfs2/ui/pfs_theme.dart';

class TimerBar extends StatelessWidget {
  const TimerBar({super.key});
  static const double almostZeroThreshold = 0.1;
  static const double barWidth = 200;

  @override
  Widget build(BuildContext context) {
    final timerStyle = Theme.of(context).extension<PhtimerStyle>() ?? PhtimerStyle.defaultStyle;

    return SizedBox(
      width: TimerBar.barWidth,
      height: 2,
      child: PfsAppModel.scope(
        (_, __, model) {
          final barValueFromModel = (1.0 - model.progressPercent);
          Color barColor = model.timer.isActive
              ? (barValueFromModel < TimerBar.almostZeroThreshold
                  ? timerStyle.almostZeroColor
                  : timerStyle.runningColor)
              : timerStyle.pausedColor;

          return TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutQuart,
            tween: Tween<double>(begin: 0, end: barValueFromModel),
            builder: (_, value, __) {
              return LinearProgressIndicator(
                backgroundColor: timerStyle.barBackgroundColor,
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
