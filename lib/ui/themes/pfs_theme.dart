import 'package:flutter/material.dart';
import 'package:pfs2/widgets/phtimer_widgets.dart';

class PfsTheme {
  static ThemeData get themeData => getClipDarkTheme();

  static const Color hyperlinkColorHovered = Colors.blue;

  static ThemeData getClipDarkTheme() {
    const Brightness themeBrightness = Brightness.dark;
    const Color seedColor = Color(0xFF808080);
    const Color background = Color(0xFF474747);
    const Color canvasBackground = Color(0xFF323232);

    const Color primary = Color(0xFF707A90);
    const Color secondary = Color(0xFF707A90);
    const Color tertiary = Color(0xFF5F687D);
    const Color buttonContentColor = Color(0x6D9E9E9E);
    const Color buttonActiveColor = Color(0x783D507C);
    const Color buttonHoverColor = Color(0xDCD8D8D8);

    const Color buttonHoverOverlayColor = Color(0x66707A90);
    const cspButtonRadius = 3.0;
    const buttonMaterialShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(cspButtonRadius)),
    );

    const ButtonStyle buttonShapeStyle = ButtonStyle(
      shape: MaterialStatePropertyAll(buttonMaterialShape),
    );

    final ButtonStyle buttonColorStyle = ButtonStyle(
      foregroundColor: hoverActiveColors(
        idle: buttonContentColor,
        hover: buttonHoverColor,
        active: buttonActiveColor,
      ),
      backgroundColor: hoverColors(
        idle: background.withAlpha(0x00),
        hover: background.withAlpha(0x22),
      ),
      overlayColor: hoverColors(
        idle: buttonHoverOverlayColor.withAlpha(0x00),
        hover: buttonHoverOverlayColor,
      ),
      side: hoverProperty(
        idle: const BorderSide(color: Color(0x00767B85)),
        hover: const BorderSide(color: Color(0x33767B85)),
      ),
    );

    final ButtonStyle buttonShapeAndColors =
        buttonColorStyle.copyWith(shape: buttonShapeStyle.shape);

    const Color cspSelectedButton = Color(0xFF707A90);
    const Color cspTextColor = Color(0xDDE1E1E1);
    const Color cspTextBoxColor = Color(0xFF6F6F6F);

    const Color cspWindowBorderColor = Color(0xFF3F3F3F);
    const Color selectedButtonContentColor = cspTextColor;

    const Color cardColor = Color(0xFF565656);
    //const Color cardOutlineColor = Color(0xFF3F3F3F);
    const Color outline = Color(0xC7868686);

    const cspWindowBorderSide = BorderSide(
      color: cspWindowBorderColor,
      width: 3,
    );
    final cspWindowBorderSideTop = cspWindowBorderSide.copyWith(width: 6);

    const Color filledbuttonContentColor = buttonContentColor;
    const double cspPanelElevation = 20;

    var newData = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: canvasBackground,
      colorScheme: ColorScheme.fromSeed(
        brightness: themeBrightness,
        seedColor: seedColor,
        background: background,
        primary: primary,
        tertiary: tertiary,
        onSecondary: Colors.white,
        outline: outline,
        surface: cardColor,
        onSurfaceVariant: cspTextColor.withAlpha(0xAA),
        secondary: secondary,
        scrim: Colors.black38,

        // Most text
        onSurface: cspTextColor,

        // Selected button text, slider value label text
        onPrimary: selectedButtonContentColor,

        // Selected Segmented button
        secondaryContainer: cspSelectedButton,
        onSecondaryContainer: cspTextColor.withAlpha(0xFF),

        // Text field background, slider background
        surfaceVariant: cspTextBoxColor,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        selectionColor: Color(0xFF5B75A1),
      ),
      filledButtonTheme: const FilledButtonThemeData(
        style: buttonShapeStyle,
      ),
      textTheme: const TextTheme(
        titleMedium: TextStyle(color: outline),
        labelLarge: TextStyle(
            fontWeight: FontWeight.normal, fontSize: 12), // Control labels
      ),
      sliderTheme: SliderThemeData(
        trackShape: const RectangularSliderTrackShape(),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8, disabledThumbRadius: 6,),
        tickMarkShape: SliderTickMarkShape.noTickMark,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: primary,
        actionTextColor: tertiary,
        contentTextStyle: TextStyle(fontSize: 14, color: cspTextColor),
        insetPadding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
      ),
      badgeTheme: const BadgeThemeData(backgroundColor: buttonActiveColor),
      textButtonTheme: TextButtonThemeData(style: buttonShapeAndColors),
      iconButtonTheme: IconButtonThemeData(style: buttonShapeAndColors),
      segmentedButtonTheme:
          const SegmentedButtonThemeData(style: buttonShapeStyle),
      iconTheme: const IconThemeData(
        color: filledbuttonContentColor,
      ),
      menuButtonTheme: const MenuButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStatePropertyAll(background),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        surfaceTintColor: Colors.transparent,
        shape: Border(
          top: cspWindowBorderSideTop,
          bottom: cspWindowBorderSide,
          left: cspWindowBorderSide,
          right: cspWindowBorderSide,
        ),
      ),
      extensions: {
        const PhtimerTheme(
          pausedColor: Color(0x996F6F6F),
          runningColor: Color(0x665F687D),
          almostZeroColor: Color(0xDD6C7CA1),
          disabledColor: Color(0xFF9E9E9E),
          barBackgroundColor: Colors.black12,
        ),
        PfsAppTheme(
            appWindowBorderSide: cspWindowBorderSide.copyWith(width: 4),
            boxPanelMaterialBuilder: ({required Widget child}) {
              return Material(
                type: MaterialType.canvas,
                elevation: cspPanelElevation,
                shape: const Border.fromBorderSide(cspWindowBorderSide),
                child: child,
              );
            },
            pawPanelMaterialBuilder: ({required Widget child}) {
              return Material(
                type: MaterialType.canvas,
                elevation: cspPanelElevation,
                shape: const RoundedRectangleBorder(
                  side: cspWindowBorderSide,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(300)),
                ),
                child: child,
              );
            })
      },
    );

    return newData;
  }

  static ThemeData getKPhashionTheme() {
    const Brightness themeBrightness = Brightness.light;
    const Color seedColor = Color.fromARGB(255, 255, 174, 0);
    const Color background = Colors.white;
    const Color canvasBackground = background;

    const Color primary = Color.fromARGB(255, 105, 91, 87);
    const Color secondary = Color.fromARGB(255, 146, 109, 88);
    const Color tertiary = Color.fromARGB(255, 236, 179, 92);
    const Color buttonContentColor = Color.fromARGB(110, 158, 158, 158);
    const Color buttonActiveColor = Color.fromARGB(120, 231, 173, 85);
    const Color buttonHoverColor = Color.fromARGB(220, 29, 29, 29);

    final ButtonStyle buttonStyle = ButtonStyle(
      foregroundColor: hoverActiveColors(
        idle: buttonContentColor,
        hover: buttonHoverColor,
        active: buttonActiveColor,
      ),
      backgroundColor: hoverColors(
        idle: background.withAlpha(0x00),
        hover: background.withAlpha(0x22),
      ),
    );

    const Color cardColor = Color.fromARGB(255, 250, 249, 247);
    const Color cardOutlineColor = Color(0xFFEEEEEE);
    const Color outline = Color.fromARGB(82, 94, 76, 53);

    var newData = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: canvasBackground,
      colorScheme: ColorScheme.fromSeed(
        brightness: themeBrightness,
        seedColor: seedColor,
        background: background,
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
        onSecondary: Colors.white,
        outline: outline,
        surface: cardColor,
        onSurfaceVariant: primary.withAlpha(0xAA),
        scrim: Colors.white60,
      ),
      textTheme: const TextTheme(
        titleMedium: TextStyle(color: outline),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: primary,
        actionTextColor: tertiary,
        contentTextStyle: TextStyle(fontSize: 14),
        insetPadding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
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

class PfsAppTheme extends ThemeExtension<PfsAppTheme> {
  PfsAppTheme({
    this.appWindowBorderSide,
    this.boxPanelMaterialBuilder,
    this.pawPanelMaterialBuilder,
  });

  final Material Function({required Widget child})? boxPanelMaterialBuilder;
  final Material Function({required Widget child})? pawPanelMaterialBuilder;
  final BorderSide? appWindowBorderSide;

  Material Function({required Widget child}) get boxPanel =>
      boxPanelMaterialBuilder ?? defaultBoxPanelMaterial;
  Material Function({required Widget child}) get pawPanel =>
      pawPanelMaterialBuilder ?? defaultPawPanelMaterial;

  @override
  ThemeExtension<PfsAppTheme> copyWith() {
    return this;
  }

  @override
  ThemeExtension<PfsAppTheme> lerp(
      covariant ThemeExtension<PfsAppTheme>? other, double t) {
    return other ?? this;
  }

  // LARGE TEXT FIELD
  static const defaultLargeTextFieldTextStyle = TextStyle(fontSize: 32);
  static const defaultLargeTextFieldInputDecoration = InputDecoration(
    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(30)),
    ),
    filled: true,
    counterText: '',
    counterStyle: TextStyle(fontSize: 1),
  );

  // POPUP PANEL
  static Material Function({required Widget child}) boxPanelFrom(
      ThemeData? theme) {
    if (theme == null) return defaultBoxPanelMaterial;
    final appTheme = theme.extension<PfsAppTheme>();

    if (appTheme == null) return defaultBoxPanelMaterial;
    return appTheme.boxPanel;
  }

  static Material Function({required Widget child}) pawPanelFrom(
      ThemeData? theme) {
    if (theme == null) return defaultPawPanelMaterial;
    final appTheme = theme.extension<PfsAppTheme>();

    if (appTheme == null) return defaultPawPanelMaterial;
    return appTheme.pawPanel;
  }

  static const double popupPanelElevation = 10;
  static const MaterialType _popupPanelMaterialType = MaterialType.canvas;

  static Material defaultBoxPanelMaterial({required Widget child}) {
    return Material(
      type: _popupPanelMaterialType,
      elevation: popupPanelElevation,
      borderRadius: BorderRadius.circular(10),
      child: child,
    );
  }

  static Material defaultPawPanelMaterial({required Widget child}) {
    return Material(
      type: _popupPanelMaterialType,
      elevation: popupPanelElevation,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(300)),
      child: child,
    );
  }
}
