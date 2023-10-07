import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ScrollListener extends StatelessWidget {
  const ScrollListener(
      {super.key, this.onScrollDown, this.onScrollUp, required this.child});

  final Function()? onScrollUp, onScrollDown;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (pointerEvent) {
        if (pointerEvent is PointerScrollEvent) {
          PointerScrollEvent scroll = pointerEvent;
          final dy = scroll.scrollDelta.dy;
          final bool isScrollDown = dy > 0;
          final bool isScrollUp = dy < 0;
          if (isScrollDown) {
            onScrollDown?.call();
          } else if (isScrollUp) {
            onScrollUp?.call();
          }
        }
      },
      child: child,
    );
  }
}
