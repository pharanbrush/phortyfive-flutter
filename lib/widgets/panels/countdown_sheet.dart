import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pfs2/models/pfs_model.dart';

class CountdownSheet extends StatelessWidget {
  const CountdownSheet({super.key});

  @override
  Widget build(BuildContext context) {
    const countdownStyle = TextStyle(
      fontSize: 120,
      color: Colors.grey,
      fontWeight: FontWeight.bold,
    );

    return PfsAppModel.scope((_, __, model) {
      if (!model.isCountingDown) {
        return const SizedBox.shrink();
      }

      int countdownNumber = model.countdownLeft;
      String countdownString = countdownNumber.toString();

      return Stack(
        children: [
          const ModalBarrier(
            color: Colors.white,
            dismissible: false,
          ),
          Center(
            child: Animate(
              key: Key('count$countdownString'),
              effects: const [
                FadeEffect(
                  begin: 0,
                  end: 1,
                  duration: Duration(milliseconds: 100),
                ),
                SlideEffect(
                  duration: Duration(milliseconds: 200),
                  curve: Curves.easeOutQuint,
                ),
              ],
              child: Text(
                countdownString,
                style: countdownStyle,
              ),
            ),
          ),
        ],
      );
    });
  }
}