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

  static const Color firstActionBoxColor = Color(0xFFF5F5F5);
  static const Color firstActionBorderColor = Color(0xFFEEEEEE);
  static const Color firstActionContentColor = Colors.black38;
  static const TextStyle firstActionTextStyle = TextStyle(
    color: firstActionContentColor,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle firstActionTextStyleSecondary = TextStyle(
    color: firstActionContentColor,
  );

  static const Border firstActionBoxBorder = Border(
    bottom: BorderSide(color: firstActionBorderColor),
    top: BorderSide(color: firstActionBorderColor),
    left: BorderSide(color: firstActionBorderColor),
    right: BorderSide(color: firstActionBorderColor),
  );

  static const double firstActionIconSize = 100;
  static const Icon firstActionIcon = Icon(Icons.image,
      size: firstActionIconSize, color: firstActionContentColor);
  static const Icon downIcon = Icon(Icons.keyboard_double_arrow_down_rounded,
      color: firstActionContentColor);
  static const firstActionBoxDecoration = BoxDecoration(
    borderRadius: BorderRadius.all(Radius.circular(20)),
    border: firstActionBoxBorder,
    color: PfsTheme.firstActionBoxColor,
  );

  static const Color watermarkColor = Color(0x55555555);

  static const Color timerPausedColor = Color(0xFFB99700);
  static const Color timerRunningColor = Colors.blueGrey;
  static const Color timerAlmostZeroColor = Color(0xFFCE0C0C);
  static const Color timerDisabledColor = Color(0xFF9E9E9E);
  static const Color timerBarBackgroundColor = Colors.black12;

  static const Color bottomBarButtonContentColor = Colors.grey;
  static const Color bottomBarButtonActiveColor = Colors.orange;

  static const Color accentColor = Color(0xFF634E42);
  static const Color topBarButtonColor = Colors.black12;

  static const TextStyle subtleHeadingStyle =
      TextStyle(fontSize: 14, color: Colors.grey);
  static const Color subtleHeadingIconColor = Color(0xFFE4E4E4);
  static const double subtleHeadingIconSize = 14;

  static const Color minorWindowControlColor = Colors.black38;
  static const Color filledButtonContentColor = Colors.white;

  static const Color hyperlinkColorHovered = Colors.blue;

  static const Color dropTargetBoxColor = Color(0xAA000000);
  static const Color dropTargetTextColor = Colors.white60;
  static const BoxDecoration dropActiveBoxDecoration = BoxDecoration(
    color: dropTargetBoxColor,
    borderRadius: BorderRadius.all(Radius.circular(5)),
  );
  static const BoxDecoration dropHiddenBoxDecoration = BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.all(Radius.circular(15)));
  static const TextStyle dropTargetTextStyle =
      TextStyle(fontSize: 40, color: dropTargetTextColor, inherit: true);

  static const popupPanelBoxDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.all(Radius.circular(10)),
    boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 2)],
  );

  static const popupPanelBoxDecorationPaw = BoxDecoration(
    shape: BoxShape.rectangle,
    borderRadius: BorderRadius.vertical(top: Radius.circular(300)),
    color: Colors.white,
    boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 2)],
  );

  static const largeTextFieldTextStyle = TextStyle(fontSize: 32);

  static const largeTextFieldInputDecoration = InputDecoration(
    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
    border: OutlineInputBorder(),
    focusColor: Color(0xFF0F6892),
    filled: true,
    fillColor: Colors.white,
    counterText: '',
    counterStyle: TextStyle(fontSize: 1),
  );
}
