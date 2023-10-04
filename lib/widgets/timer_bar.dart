import 'package:flutter/material.dart';
import 'package:pfs2/screens/main_screen.dart';

class TimerBar extends StatelessWidget {
  const TimerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return _timeElapsedBar(200);
  }

  Widget _timeElapsedBar(double width) {
    return SizedBox(
      width: width,
      height: 2,
      child: Phbuttons.appModelWidget(
        (_, __, model) {
          Color barColor = model.timer.isActive ? Colors.blueAccent : Colors.yellow.shade600;
          return LinearProgressIndicator(
            backgroundColor: Colors.black12,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            value: (1.0 - model.progressPercent),
          );
        },
      ),
    );
  }
}
