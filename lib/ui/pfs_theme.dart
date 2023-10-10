import 'package:flutter/material.dart';

class PfsTheme {
  static ThemeData get themeData => _getThemeData();

  static const Color primaryColor = Color.fromARGB(255, 105, 91, 87);
  static const Color accentColor = Color.fromARGB(255, 146, 109, 88);
  static const Color seedColor = Color.fromARGB(255, 255, 174, 0);
  static const Color backgroundColor = Color.fromARGB(255, 255, 255, 255);

  static ThemeData _getThemeData() {
    var newData = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: PfsTheme.backgroundColor,
      //snackBarTheme: const SnackBarThemeData(backgroundColor: primaryColor),
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.light,
        seedColor: PfsTheme.seedColor,
        background: PfsTheme.backgroundColor,
        primary: PfsTheme.primaryColor,
        secondary: Colors.brown,
        onSecondary: Colors.white,
        outline: const Color.fromARGB(82, 94, 76, 53),
      ),
      extensions: const {
        PhtimerStyle(
          pausedColor: Color.fromARGB(150, 255, 198, 73),
          runningColor: Color.fromARGB(131, 167, 148, 140),
          almostZeroColor: Color.fromARGB(195, 206, 12, 12),
          disabledColor: Color(0xFF9E9E9E),
          barBackgroundColor: Colors.black12,
        )
      },
    );

    return newData;
  }

  static const double bottomBarButtonOpacity = 0.4;
  static const double timerBarIconSize = 18;

  static const double _nextPreviousLargeButtonSize = 100;
  static const Icon beforeGestureIcon =
      Icon(Icons.navigate_before, size: _nextPreviousLargeButtonSize);
  static const Icon nextGestureIcon =
      Icon(Icons.navigate_next, size: _nextPreviousLargeButtonSize);

  static const topRightWatermarkTextStyle =
      TextStyle(color: PfsTheme.watermarkColor, fontSize: 12);

  static const Color firstActionBoxColor = Color(0xFFF5F5F5);
  static const Color firstActionBorderColor = Color(0xFFEEEEEE);
  static const Color firstActionContentColor = Colors.black38;
  static const TextStyle firstActionTextStyle = TextStyle(
    color: firstActionContentColor,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle firstActionTextStyleSecondary =
      TextStyle(color: firstActionContentColor);

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

  static const int bottomBarButtonOpacityByte = 100;
  static const Color bottomBarButtonContentColor =
      Color.fromARGB(bottomBarButtonOpacityByte, 158, 158, 158);
  static const Color bottomBarButtonActiveColor =
      Color.fromARGB(120, 231, 173, 85);
  static const Color bottomBarButtonHoverColor =
      Color.fromARGB(169, 29, 29, 29);

  static Color getBottomBarIconColor(Set<MaterialState> states) {
    if (states.contains(MaterialState.hovered)) {
      return PfsTheme.bottomBarButtonHoverColor;
    } else if (states.contains(MaterialState.selected)) {
      return PfsTheme.bottomBarButtonActiveColor;
    }

    return PfsTheme.bottomBarButtonContentColor;
  }

  static final ButtonStyle bottomBarButtonStyle = ButtonStyle(
    foregroundColor: MaterialStateProperty.resolveWith(getBottomBarIconColor),
  );

  static const Color timerBarButtonContentColor = Colors.grey;

  static const Color topBarButtonColor = Colors.black12;
  static const Color topBarButtonActiveColor = Color.fromARGB(49, 196, 117, 0);

  static Color getTopIconColor(Set<MaterialState> states) {
    if (states.contains(MaterialState.hovered)) {
      return Colors.black;
    } else if (states.contains(MaterialState.selected)) {
      return PfsTheme.topBarButtonActiveColor;
    }

    return PfsTheme.topBarButtonColor;
  }

  static const double topControlDiameter = 15;
  static const Size topControlSize =
      Size(topControlDiameter, topControlDiameter);
  static final topControlStyle = ButtonStyle(
    fixedSize: const MaterialStatePropertyAll(topControlSize),
    iconColor: MaterialStateProperty.resolveWith(getTopIconColor),
    backgroundColor: const MaterialStatePropertyAll(Colors.transparent),
    padding: const MaterialStatePropertyAll(EdgeInsets.zero),
  );

  static const TextStyle subtleHeadingStyle =
      TextStyle(fontSize: 14, color: Colors.grey);
  static const Color subtleHeadingIconColor = Color(0xFFE4E4E4);
  static const double subtleHeadingIconSize = 14;

  static const Color minorWindowControlColor = Colors.black38;
  static const double minorWindowControlIconSize = 20;
  static const minorWindowControlButtonSize = Size(25, 25);
  static const minorWindowControlButtonStyle = ButtonStyle(
    shape: MaterialStatePropertyAll(CircleBorder()),
    minimumSize: MaterialStatePropertyAll(minorWindowControlButtonSize),
    maximumSize: MaterialStatePropertyAll(minorWindowControlButtonSize),
    padding: MaterialStatePropertyAll(EdgeInsets.all(0)),
    foregroundColor: MaterialStatePropertyAll(PfsTheme.minorWindowControlColor),
  );

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
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(30)),
    ),
    focusColor: PfsTheme.accentColor,
    filled: true,
    fillColor: Colors.white,
    counterText: '',
    counterStyle: TextStyle(fontSize: 1),
  );
}

class PhtimerStyle extends ThemeExtension<PhtimerStyle> {
  const PhtimerStyle({
    required this.pausedColor,
    required this.runningColor,
    required this.almostZeroColor,
    required this.disabledColor,
    required this.barBackgroundColor,
  });
  
  static const defaultStyle = PhtimerStyle(
    pausedColor: Colors.orange,
    runningColor: Colors.blue,
    almostZeroColor: Colors.red,
    disabledColor: Color(0xFF9E9E9E),
    barBackgroundColor: Colors.black12,
  );

  @override
  ThemeExtension<PhtimerStyle> copyWith({
    Color? pausedColor,
    Color? runningColor,
    Color? almostZeroColor,
    Color? disabledColor,
    Color? barBackgroundColor,
  }) {
    return PhtimerStyle(
      pausedColor: pausedColor ?? this.pausedColor,
      runningColor: runningColor ?? this.runningColor,
      almostZeroColor: almostZeroColor ?? this.almostZeroColor,
      disabledColor: disabledColor ?? this.disabledColor,
      barBackgroundColor: barBackgroundColor ?? this.barBackgroundColor,
    );
  }

  @override
  ThemeExtension<PhtimerStyle> lerp(
      covariant ThemeExtension<PhtimerStyle>? other, double t) {
    if (other is! PhtimerStyle) {
      return this;
    }

    return PhtimerStyle(
      pausedColor: Color.lerp(pausedColor, other.pausedColor, t)!,
      runningColor: Color.lerp(runningColor, other.runningColor, t)!,
      almostZeroColor: Color.lerp(almostZeroColor, other.almostZeroColor, t)!,
      disabledColor: Color.lerp(disabledColor, other.disabledColor, t)!,
      barBackgroundColor:
          Color.lerp(barBackgroundColor, other.barBackgroundColor, t)!,
    );
  }

  final Color pausedColor;
  final Color runningColor;
  final Color almostZeroColor;
  final Color disabledColor;
  final Color barBackgroundColor;
}
