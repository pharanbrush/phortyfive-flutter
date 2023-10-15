import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:pfs2/widgets/animation/phanimations.dart';

class Phtoasts {
  static const double iconSize = 16;

  static Alignment topControlsAlign = Alignment.topCenter;

  static void show(
    BuildContext? context, {
    required String message,
    IconData? icon,
    Alignment alignment = Alignment.bottomCenter,
  }) {
    if (context == null) return;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final snackbarTheme = theme.snackBarTheme;

    if (icon == null) {
      showWidget(context, child: Text(message));
    } else {
      showWidget(
        context,
        alignment: alignment,
        child: Wrap(
          direction: Axis.horizontal,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: snackbarTheme.contentTextStyle?.color ??
                  colorScheme.onPrimary,
            ),
            Text(message),
            const SizedBox(width: 2),
          ],
        ),
      );
    }
  }

  static void showWidget(
    BuildContext? context, {
    required Widget child,
    Alignment alignment = Alignment.bottomCenter,
  }) {
    if (context == null) return;

    final theme = Theme.of(context);
    //final colorScheme = theme.colorScheme;
    final snackbarTheme = theme.snackBarTheme;

    Widget toastWidget = DefaultTextStyle(
      style: snackbarTheme.contentTextStyle ??
          theme.primaryTextTheme.bodyMedium ??
          const TextStyle(fontSize: 16),
      child: Container(
        padding: snackbarTheme.insetPadding,
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          color: snackbarTheme.backgroundColor,
          borderRadius: BorderRadius.circular(7),
        ),
        child: child,
      ),
    );

    const duration = Duration(milliseconds: 1800);
    const double offsetFromEdge = 70;

    bool isTop = alignment.y < 0;
    final animation = isTop
        ? StyledToastAnimation.slideFromTopFade
        : StyledToastAnimation.slideFromBottomFade;
        
    final reverseAnimation = isTop
        ? StyledToastAnimation.slideToTopFade
        : StyledToastAnimation.slideToBottomFade;

    showToastWidget(
      toastWidget,
      duration: duration,
      context: context,
      position: StyledToastPosition(align: alignment, offset: offsetFromEdge),
      //
      animDuration: Phanimations.toastAnimationDuration,
      animation: animation,
      curve: Phanimations.toastCurve,
      //
      reverseAnimation: reverseAnimation,
      reverseCurve: Curves.easeInQuad,
    );
  }
}
