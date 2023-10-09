import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pfs2/widgets/animation/phanimations.dart';

class FirstActionSheet extends StatelessWidget {
  const FirstActionSheet({super.key});

  static const _windowAlignmentMargin = EdgeInsets.fromLTRB(0, 0, 25, 45);

  static const double _iconSize = 100;
  static const Color _boxColor = Color(0xFFF5F5F5);
  static const Color _borderColor = Color(0xFFEEEEEE);
  static const Color _contentColor = Colors.black38;
  static const TextStyle _textStyleMain = TextStyle(
    color: _contentColor,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle _textStyleSecondary = TextStyle(
    color: _contentColor,
  );

  static const Icon _icon =
      Icon(Icons.image, size: _iconSize, color: _contentColor);
  static const Icon _downIcon =
      Icon(Icons.keyboard_double_arrow_down_rounded, color: _contentColor);

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
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            border: Border.all(color: _borderColor),
            color: _boxColor,
          ),
          child: Stack(children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 25,
                ),
                _icon,
                Text(
                  'Get started by loading images!',
                  style: _textStyleMain,
                  textAlign: TextAlign.center,
                ),
                Text(
                  'You can also drag & drop images into the window.',
                  style: _textStyleSecondary,
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
                  child: _downIcon,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
