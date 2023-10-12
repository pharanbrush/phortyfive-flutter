import 'package:flutter/material.dart';
import 'package:pfs2/widgets/phtimer_widgets.dart';

class PfsTheme {
  static ThemeData get themeData => _getKPhashionTheme();

  static const Color watermarkColor = Color(0x55555555);
  static const Color hyperlinkColorHovered = Colors.blue;

  static ThemeData _getKPhashionTheme() {
    const Color seedColor = Color.fromARGB(255, 255, 174, 0);
    const Color background = Colors.white;

    const Color primary = Color.fromARGB(255, 105, 91, 87);
    const Color secondary = Color.fromARGB(255, 146, 109, 88);
    const Color tertiary = Color.fromARGB(255, 236, 179, 92);
    const Color bottomBarButtonContentColor =
        Color.fromARGB(110, 158, 158, 158);
    const Color bottomBarButtonActiveColor = Color.fromARGB(120, 231, 173, 85);
    const Color bottomBarButtonHoverColor = Color.fromARGB(169, 29, 29, 29);

    Color getIconColor(Set<MaterialState> states) {
      if (states.contains(MaterialState.hovered)) {
        return bottomBarButtonHoverColor;
      } else if (states.contains(MaterialState.selected)) {
        return bottomBarButtonActiveColor;
      }

      return bottomBarButtonContentColor;
    }

    Color getButtonColor(Set<MaterialState> states) {
      if (states.contains(MaterialState.hovered)) {
        return background.withAlpha(33);
      }

      return background.withAlpha(00);
    }

    final ButtonStyle buttonStyle = ButtonStyle(
      foregroundColor: MaterialStateProperty.resolveWith(getIconColor),
      backgroundColor: MaterialStateProperty.resolveWith(getButtonColor),
    );

    var newData = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.light,
        seedColor: seedColor,
        background: background,
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
        onSecondary: Colors.white,
        outline: const Color.fromARGB(82, 94, 76, 53),
      ),
      textButtonTheme: TextButtonThemeData(style: buttonStyle),
      iconButtonTheme: IconButtonThemeData(style: buttonStyle),
      badgeTheme: const BadgeThemeData(backgroundColor: bottomBarButtonActiveColor),
      menuButtonTheme: const MenuButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStatePropertyAll(Colors.white),
        ),
      ),
      extensions: const {
        PhtimerTheme(
          pausedColor: tertiary,
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

  static const double _nextPreviousLargeButtonSize = 100;
  static const Icon beforeGestureIcon =
      Icon(Icons.navigate_before, size: _nextPreviousLargeButtonSize);
  static const Icon nextGestureIcon =
      Icon(Icons.navigate_next, size: _nextPreviousLargeButtonSize);

  // FIRST ACTION
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

  static const double timerButtonIconSize = 18;

  // TOP BAR
  static const topRightWatermarkTextStyle =
      TextStyle(color: PfsTheme.watermarkColor, fontSize: 12);

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

  // DROP TARGET
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

  // POPUP PANEL
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

  // LARGE TEXT FIELD
  static const largeTextFieldTextStyle = TextStyle(fontSize: 32);

  static const largeTextFieldInputDecoration = InputDecoration(
    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(30)),
    ),
    filled: true,
    //fillColor: Colors.white,
    counterText: '',
    counterStyle: TextStyle(fontSize: 1),
  );
}
