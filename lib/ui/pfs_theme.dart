import 'package:flutter/material.dart';

class PfsTheme {
  static ThemeData get themeData => _getThemeData();

  static ThemeData _getThemeData() {
    return ThemeData(
      snackBarTheme:
          const SnackBarThemeData(backgroundColor: Color(0x00000000)),
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.light,
        seedColor: Colors.blue,
        secondary: Colors.brown,
        background: Colors.white,
        outline: const Color(0x44000000),
      ),
      //textTheme: TextTheme()
    );
  }

  static const Color watermarkColor = Color(0x55555555);

  static const Color timerPausedColor = Color(0xFFB99700);
  static const Color timerRunningColor = Colors.blueGrey;
  static const Color timerAlmostZeroColor = Color(0xFFCE0C0C);
  static const Color timerDisabledColor = Color(0xFF9E9E9E);
  static const Color timerBarBackgroundColor = Colors.black12;

  static const Color bottomBarButtonContentColor = Colors.grey;
  static const Color bottomBarButtonActiveColor = Colors.orange;

  static const TextStyle subtleHeadingStyle =
      TextStyle(fontSize: 14, color: Colors.grey);
  static const Color subtleHeadingIconColor = Color(0xFFE4E4E4);
  static const double subtleHeadingIconSize = 14;

  static const Color minorWindowControlColor = Colors.black38;
  static const Color filledButtonContentColor = Colors.white;

  static const popupPanelBoxDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.all(Radius.circular(10)),
    boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 2)],
  );

  static const Color hyperlinkColorHovered = Colors.blue;

  static const largeBoxInputDecoration = InputDecoration(
    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
    border: OutlineInputBorder(),
    focusColor: Color(0xFF0F6892),
    filled: true,
    fillColor: Colors.white,
    counterText: '',
    counterStyle: TextStyle(fontSize: 1),
  );
}
