import 'package:flutter/material.dart';

class Phtoasts {
  static const double iconSize = 16;
  
  static void showToast(
    BuildContext? context, {
    required String message,
    IconData? icon,
  }) {
    if (context == null) return;

    // final theme = Theme.of(context);
    // //final colorScheme = theme.colorScheme;
    // final snackbarTheme = theme.snackBarTheme;

    if (icon == null) {
      showToastWidget(context, child: Text(message));
    } else {
      showToastWidget(
        context,
        child: Row(
          children: [
            Icon(icon, size: iconSize,),
            Text(message),
          ],
        ),
      );
    }
  }

  static void showToastWidget(BuildContext? context, {required Widget child}) {
    if (context == null) return;

    const duration = Duration(milliseconds: 1800);

    final theme = Theme.of(context);
    //final colorScheme = theme.colorScheme;
    final snackbarTheme = theme.snackBarTheme;

    // context.showToast<bool>(
    //   child,
    //   queue: false,
    //   duration: duration,
    //   textStyle: snackbarTheme.contentTextStyle,
    //   backgroundColor: snackbarTheme.backgroundColor,
    //   alignment: const Alignment(0, -0.85),
    //   padding: snackbarTheme.insetPadding,
    // );
  }
}
