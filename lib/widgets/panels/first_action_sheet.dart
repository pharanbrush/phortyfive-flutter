import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pfs2/ui/pfs_theme.dart';
import 'package:pfs2/widgets/animation/phanimations.dart';

class FirstActionSheet extends StatelessWidget {
  const FirstActionSheet({super.key});

  static const _windowAlignmentMargin = EdgeInsets.fromLTRB(0, 0, 25, 45);

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
          child: _box(),
        ),
      ),
    );
  }

  Widget _box() {
    return SizedBox(
      width: 350,
      height: 250,
      child: Material(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          decoration: PfsTheme.firstActionBoxDecoration,
          child: Stack(children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 25,
                ),
                PfsTheme.firstActionIcon,
                Text(
                  'Get started by loading images!',
                  style: PfsTheme.firstActionTextStyle,
                  textAlign: TextAlign.center,
                ),
                Text(
                  'You can also drag & drop images into the window.',
                  style: PfsTheme.firstActionTextStyleSecondary,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                child: Animate(
                  effects: const [Phanimations.slideUpEffect],
                  onPlay: (controller) => controller.repeat(reverse: true),
                  child: PfsTheme.downIcon,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
