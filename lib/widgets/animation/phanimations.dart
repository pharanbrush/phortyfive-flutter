import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class Phanimations {
  static const bottomMenuSlideEffect = SlideEffect(
    duration: Duration(milliseconds: 200),
    begin: Offset(0, 0.2),
    end: Offset.zero,
    curve: Curves.easeOutQuart,
  );

  static const List<Effect> bottomMenuEffects = [
    bottomMenuSlideEffect,
  ];
}
