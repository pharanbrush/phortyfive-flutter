import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class Phanimations {
  static const slideUpEffect = SlideEffect(
    duration: Duration(milliseconds: 200),
    begin: Offset(0, 0.2),
    end: Offset.zero,
    curve: Curves.easeOutQuart,
  );

  static const growBottomEffect = ScaleEffect(
    duration: Duration(milliseconds: 110),
    alignment: FractionalOffset(.5, .5),
    begin: Offset(0.5, 0.5),
    end: Offset(1, 1),
    curve: Curves.easeOutQuad,
  );

  static const List<Effect> bottomMenuEffects = [
    slideUpEffect,
  ];
}
