import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pfs2/models/pfs_model.dart';

class CountdownSheet extends StatelessWidget {
  const CountdownSheet({super.key});

  static const animationEffects = <Effect>[
    FadeEffect(
      begin: 0,
      end: 1,
      duration: Duration(milliseconds: 100),
    ),
    SlideEffect(
      duration: Duration(milliseconds: 200),
      curve: Curves.easeOutQuint,
    )
  ];

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 120,
      color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(0x99),
      fontWeight: FontWeight.bold,
    );

    final counter = PfsAppModel.of(context);

    return ListenableBuilder(
        listenable: counter.countdownChangedListenable,
        builder: (_, __) {
          if (!counter.isCountingDown) {
            return const SizedBox.shrink();
          }

          final countdownNumber = counter.countdownLeft;
          final countdownString = countdownNumber.toString();

          return Stack(
            children: [
              ModalBarrier(
                color: Theme.of(context).colorScheme.surface,
                dismissible: false,
              ),
              Center(
                child: Text(
                  countdownString,
                  style: style,
                ).animate(
                  key: Key('count$countdownString'),
                  effects: animationEffects,
                ),
              ),
            ],
          );
        });
  }
}
