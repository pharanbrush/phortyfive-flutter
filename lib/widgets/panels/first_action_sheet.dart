import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';
import 'package:pfs2/widgets/animation/phanimations.dart';

class FirstActionSheet extends StatelessWidget {
  const FirstActionSheet({super.key});

  static const _windowAlignmentMargin = EdgeInsets.fromLTRB(0, 0, 25, 45);
  static const TextStyle _bigBold = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        margin: _windowAlignmentMargin,
        child: Animate(
          effects: const [
            Phanimations.slideUpEffect,
            Phanimations.growBottomEffect
          ],
          child: _box(context),
        ),
      ),
    );
  }

  Widget _box(BuildContext context) {
    return SizedBox(
      width: 350,
      height: 250,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Stack(children: [
            DefaultTextStyle(
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Spacer(flex: 3),
                  PfsTheme.firstActionIcon,
                  Text(
                    'Get started by loading images!',
                    style: _bigBold,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'You can also drag & drop images into the window.',
                    textAlign: TextAlign.center,
                  ),
                  Spacer(flex: 5),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                child: PfsTheme.downIcon.animate(
                  effects: const [Phanimations.slideUpEffect],
                  onPlay: (controller) => controller.repeat(reverse: true),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
