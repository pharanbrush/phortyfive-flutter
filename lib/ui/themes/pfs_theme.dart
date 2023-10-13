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

    final ButtonStyle buttonStyle = ButtonStyle(
      foregroundColor: MaterialStateProperty.resolveWith(getIconColor),
      backgroundColor: hoverColors(
        idle: background.withAlpha(00),
        hover: background.withAlpha(33),
      ),
    );

    const Color firstActionBoxColor = Color.fromARGB(255, 250, 249, 247);

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
        surface: firstActionBoxColor,
      ),
      textButtonTheme: TextButtonThemeData(style: buttonStyle),
      iconButtonTheme: IconButtonThemeData(style: buttonStyle),
      badgeTheme:
          const BadgeThemeData(backgroundColor: bottomBarButtonActiveColor),
      menuButtonTheme: const MenuButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStatePropertyAll(Colors.white),
        ),
      ),
      cardTheme: const CardTheme(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: firstActionBorderColor),
        ),
      ),
      extensions: const {
        PhtimerTheme(
          pausedColor: tertiary,
          runningColor: Color.fromARGB(140, 167, 148, 140),
          almostZeroColor: Color.fromARGB(195, 206, 12, 12),
          disabledColor: Color(0xFF9E9E9E),
          barBackgroundColor: Colors.black12,
        )
      },
    );

    return newData;
  }

  static const double _nextPreviousLargeButtonSize = 100;
  static const Icon beforeGestureIcon =
      Icon(Icons.navigate_before, size: _nextPreviousLargeButtonSize);
  static const Icon nextGestureIcon =
      Icon(Icons.navigate_next, size: _nextPreviousLargeButtonSize);

  // FIRST ACTION

  static const Color firstActionBorderColor = Color(0xFFEEEEEE);
  static const Color firstActionContentColor = Colors.black54;

  static const Border firstActionBoxBorder = Border.fromBorderSide(
    BorderSide(color: firstActionBorderColor),
  );

  static const double firstActionIconSize = 100;
  static const Icon firstActionIcon = Icon(Icons.image,
      size: firstActionIconSize, color: firstActionContentColor);
  static const Icon downIcon = Icon(Icons.keyboard_double_arrow_down_rounded,
      color: firstActionContentColor);

  static const TextStyle firstActionTextStyle = TextStyle(
    color: firstActionContentColor,
  );

  static Material firstActionBoxMaterial({required Widget child}) {
    return Material(
      type: MaterialType.card,
      textStyle: firstActionTextStyle,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        side: BorderSide(color: firstActionBorderColor),
      ),
      child: child,
    );
  }

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

  static final minorWindowControlForegroundColors = hoverColors(
    idle: PfsTheme.minorWindowControlColor,
    hover: Colors.black87,
  );

  static const Color minorWindowControlColor = Color.fromARGB(90, 0, 0, 0);
  static const double minorWindowControlIconSize = 20;
  static const minorWindowControlButtonSize = Size(20, 20);
  static final minorWindowControlButtonStyle = ButtonStyle(
    shape: const MaterialStatePropertyAll(CircleBorder()),
    minimumSize: const MaterialStatePropertyAll(minorWindowControlButtonSize),
    maximumSize: const MaterialStatePropertyAll(minorWindowControlButtonSize),
    padding: const MaterialStatePropertyAll(EdgeInsets.all(0)),
    foregroundColor: minorWindowControlForegroundColors,
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
  static const double popupPanelElevation = 10;
  static const MaterialType _popupPanelMaterialType = MaterialType.canvas;

  static Material popupPanelRectangleMaterial({required Widget child}) {
    return Material(
      type: _popupPanelMaterialType,
      elevation: popupPanelElevation,
      borderRadius: BorderRadius.circular(10),
      child: child,
    );
  }

  static Material popupPanelPawMaterial({required Widget child}) {
    return Material(
      type: _popupPanelMaterialType,
      elevation: popupPanelElevation,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(300)),
      textStyle: const TextStyle(color: Colors.grey),
      child: child,
    );
  }

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

  // THEME UTILITIES
  static MaterialStateProperty<Color> hoverColors({
    required Color idle,
    required Color hover,
  }) {
    return MaterialStateProperty.resolveWith(
        (states) => states.contains(MaterialState.hovered) ? hover : idle);
  }
}
