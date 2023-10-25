import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class Phanimations {
  static const zoomTransitionDuration = Duration(milliseconds: 400);
  static const zoomTransitionCurve = Curves.easeOutExpo;

  static const toastCurve = Curves.easeOutExpo;
  static const toastAnimationDuration = Duration(milliseconds: 300);

  static const defaultDuration = Duration(milliseconds: 200);
  static const fastDuration = Duration(milliseconds: 100);
  static const slowDuration = Duration(milliseconds: 300);

  static const bottomBarSlideUpEffect = SlideEffect(
    duration: fastDuration,
    curve: Curves.easeOutQuart,
    begin: Offset(0, 1),
    end: Offset(0, 0),
  );

  static const largeRightPanelSlideInEffect = SlideEffect(
    duration: slowDuration,
    curve: Curves.easeOutQuint,
    begin: Offset(0.1, 0),
    end: Offset(0, 0),
  );

  static const bottomBarItemsSlideUpEffect = SlideEffect(
    duration: Duration(milliseconds: 1000),
    begin: Offset(0, 3),
    end: Offset.zero,
    curve: Curves.easeOutQuint,
  );

  static const slideUpEffect = SlideEffect(
    duration: defaultDuration,
    begin: Offset(0, 0.2),
    end: Offset.zero,
    curve: Curves.easeOutQuart,
  );

  static const fadeInEffect = FadeEffect(
    duration: fastDuration,
    begin: 0,
    end: 1,
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

  static Widget bottomMenuTransition(
      Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

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

class AnimatedSizedBoxWidth extends StatelessWidget {
  const AnimatedSizedBoxWidth(
      {super.key,
      required this.child,
      required this.width,
      this.height,
      required this.duration,
      required this.defaultWidth});

  final Widget child;
  final double width;
  final Duration duration;
  final double defaultWidth;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween<double>(begin: defaultWidth, end: width),
      builder: (_, value, __) {
        return SizedBox(
          width: value,
          height: height,
          child: child,
        );
      },
    );
  }
}
