import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class Phanimations {
  static const zoomTransitionDuration = Duration(milliseconds: 400);
  static const zoomTransitionCurve = Curves.easeOutExpo;

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

  static const double _imageSlideOriginX = 0.05;
  static const _imageSwapDuration = Duration(milliseconds: 300);
  static const _imageSwapCurve = Curves.easeOutQuint;
  static const imageNext = <Effect>[
    SlideEffect(
      begin: Offset(_imageSlideOriginX, 0),
      end: Offset.zero,
      duration: _imageSwapDuration,
      curve: _imageSwapCurve,
    )
  ];
  static const imagePrevious = <Effect>[
    SlideEffect(
      begin: Offset(-_imageSlideOriginX, 0),
      end: Offset.zero,
      duration: _imageSwapDuration,
      curve: _imageSwapCurve,
    )
  ];
}
