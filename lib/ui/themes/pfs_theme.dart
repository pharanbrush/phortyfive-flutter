import 'package:flutter/material.dart';
import 'package:pfs2/widgets/phtimer_widgets.dart';

class PfsTheme {
  static ThemeData get themeData => _getKPhashionTheme();

  static const Color hyperlinkColorHovered = Colors.blue;

  static ThemeData _getKPhashionTheme() {
    const Color seedColor = Color.fromARGB(255, 255, 174, 0);
    const Color background = Colors.white;

    const Color primary = Color.fromARGB(255, 105, 91, 87);
    const Color secondary = Color.fromARGB(255, 146, 109, 88);
    const Color tertiary = Color.fromARGB(255, 236, 179, 92);
    const Color buttonContentColor = Color.fromARGB(110, 158, 158, 158);
    const Color buttonActiveColor = Color.fromARGB(120, 231, 173, 85);
    const Color buttonHoverColor = Color.fromARGB(169, 29, 29, 29);

    final ButtonStyle buttonStyle = ButtonStyle(
      foregroundColor: hoverActiveColors(
        idle: buttonContentColor,
        hover: buttonHoverColor,
        active: buttonActiveColor,
      ),
      backgroundColor: hoverColors(
        idle: background.withAlpha(00),
        hover: background.withAlpha(33),
      ),
    );

    const Color cardColor = Color.fromARGB(255, 250, 249, 247);
    const Color cardOutlineColor = Color(0xFFEEEEEE);
    const Color outline = Color.fromARGB(82, 94, 76, 53);

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
        outline: outline,
        surface: cardColor,
        onSurfaceVariant: primary.withAlpha(0xAA),
      ),
      textButtonTheme: TextButtonThemeData(style: buttonStyle),
      iconButtonTheme: IconButtonThemeData(style: buttonStyle),
      badgeTheme: const BadgeThemeData(backgroundColor: buttonActiveColor),
      menuButtonTheme: const MenuButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStatePropertyAll(background),
        ),
      ),
      cardTheme: const CardTheme(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: cardOutlineColor),
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
  static const IconData downIcon = Icons.keyboard_double_arrow_down_rounded;

  static const double timerButtonIconSize = 18;

  // TOP BAR

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

  static MaterialStateProperty<T> hoverProperty<T>({
    required T idle,
    required T hover,
  }) {
    return MaterialStateProperty.resolveWith(
        (states) => states.contains(MaterialState.hovered) ? hover : idle);
  }

  static MaterialStateProperty<Color> hoverActiveColors({
    required Color idle,
    required Color hover,
    required Color active,
  }) {
    return MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.hovered)) {
        return hover;
      } else if (states.contains(MaterialState.selected)) {
        return active;
      }

      return idle;
    });
  }
}
