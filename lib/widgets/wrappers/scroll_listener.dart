import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ScrollListener extends StatelessWidget {
  const ScrollListener({
    super.key,
    this.onScrollDown,
    this.onScrollUp,
    required this.child,
  });

  final Function()? onScrollUp, onScrollDown;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (pointerEvent) {
        if (pointerEvent is PointerScrollEvent) {
          final dy = pointerEvent.scrollDelta.dy;
          if (dy > 0) {
            onScrollDown?.call();
          } else if (dy < 0) {
            onScrollUp?.call();
          }
        }
      },
      child: child,
    );
  }
}
