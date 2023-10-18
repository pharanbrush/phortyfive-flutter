import 'package:flutter/material.dart';
import 'package:pfs2/widgets/phtimer_widgets.dart';

class PfsTheme {
  static ThemeData getTheme(String theme) {
    return themeMap[theme]?.call() ??
        themeMap[defaultTheme]?.call() ??
        getKPhashionTheme();
  }

  static const defaultTheme = 'phashion';
  static final themeMap = <String, ThemeData Function()>{
    'phashion': getKPhashionTheme,
    'phriends': getPhriendsDarkTheme,
    'phaint': getClipDarkTheme,
    'philes': getPhilesTenTheme,
    'phish': getLysarisTheme,
  };

  //

  static const Color hyperlinkColorHovered = Colors.blue;

  static ThemeData getLysarisTheme() {
    const Brightness themeBrightness = Brightness.light;
    const Color seedColor = Color.fromARGB(255, 0, 226, 177);
    const Color panelBackground = Color.fromARGB(255, 97, 107, 110);
    const Color appBackground = Color.fromARGB(255, 97, 97, 97);

    const Color primary = Color.fromARGB(255, 33, 177, 165);
    const Color secondary = Color.fromARGB(255, 228, 169, 134);
    const Color tertiary = Color.fromARGB(255, 179, 119, 190);
    const Color buttonContentColor = Color.fromARGB(108, 197, 212, 212);
    const Color buttonActiveColor = Color.fromARGB(149, 85, 185, 189);
    const Color buttonHoverColor = Color.fromARGB(220, 8, 70, 112);
    const Color buttonHoverOverlayColor = Color.fromARGB(45, 112, 138, 144);
    const Color buttonHoverBackgroundColor = Color.fromARGB(75, 140, 208, 224);
    
    const Color snackbarBackground = Color.fromARGB(255, 8, 116, 107);

    final ButtonStyle buttonStyle = ButtonStyle(
      foregroundColor: hoverActiveColors(
        idle: buttonContentColor,
        hover: buttonHoverColor,
        active: buttonActiveColor,
      ),
      backgroundColor: hoverColors(
        idle: buttonHoverBackgroundColor.withAlpha(0x00),
        hover: buttonHoverBackgroundColor,
      ),
      overlayColor: hoverColors(
        idle: buttonHoverOverlayColor.withAlpha(0x00),
        hover: buttonHoverOverlayColor,
      ),
    );

    const Color cardColor = Color.fromARGB(255, 244, 251, 255);
    const Color cardOutlineColor = Color(0xFFEEEEEE);
    const Color outline = Color.fromARGB(64, 144, 192, 192);
    
    const Color textColor = Color.fromARGB(221, 219, 226, 228);
    const Color textBoxColor = Color.fromARGB(255, 58, 58, 58);

    const Color selectedButton = Color.fromARGB(255, 56, 156, 173);
    const Color selectedButtonContentColor = Color.fromARGB(255, 211, 235, 231);

    const Color tooltipBackgroundColor = Color(0xFF111214);
    const Color tooltipTextColor = Color(0xEEDBDEE1);
    const Color scrim = Color.fromARGB(195, 40, 56, 51);

    var newData = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: appBackground,
      colorScheme: ColorScheme.fromSeed(
        brightness: themeBrightness,
        seedColor: seedColor,
        background: panelBackground,
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
        onSecondary: Colors.white,
        outline: outline,
        surface: cardColor,
        onSurfaceVariant: primary.withAlpha(0xAA),
        scrim: scrim,
        
        // Most text
        onSurface: textColor,

        // Selected button text, slider value label text
        onPrimary: selectedButtonContentColor,

        primaryContainer: textBoxColor,

        // Selected Segmented button
        secondaryContainer: selectedButton,
        onSecondaryContainer: selectedButtonContentColor,

        // Text field background, slider background
        surfaceVariant: const Color(0xFFACCEBE),
      ),
      textTheme: const TextTheme(
        titleMedium: TextStyle(color: outline),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: snackbarBackground,
        actionTextColor: tertiary,
        contentTextStyle: TextStyle(fontSize: 14),
        insetPadding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
      ),
      sliderTheme: SliderThemeData(
        tickMarkShape: SliderTickMarkShape.noTickMark,
      ),
      textButtonTheme: TextButtonThemeData(style: buttonStyle),
      iconButtonTheme: IconButtonThemeData(style: buttonStyle),
      badgeTheme: const BadgeThemeData(backgroundColor: buttonActiveColor),
      menuButtonTheme: const MenuButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStatePropertyAll(panelBackground),
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
          pausedColor: Color.fromARGB(201, 24, 131, 117),
          runningColor: Color.fromARGB(126, 89, 151, 187),
          almostZeroColor: Color.fromARGB(195, 249, 76, 255),
          disabledColor: Color.fromARGB(150, 158, 158, 158),
          barBackgroundColor: Color.fromARGB(15, 0, 0, 0),
          pausedButton: Color.fromARGB(161, 51, 129, 119),
          runningButton: Color.fromARGB(117, 95, 164, 185),
        )
      },
    );

    return newData;
  }


  static ThemeData getPhilesTenTheme() {
    const Brightness themeBrightness = Brightness.light;
    const Color seedColor = Color(0xFF26A0DA);
    const Color panelBackground = Color(0xFFEEEEEE);
    const Color appBackground = Color(0xFFFFFFFF);

    // APP SPECIFIC
    const Color barBlue = Color(0xFF26A0DA);
    const Color barBackground = Color(0xFFE6E6E6);
    const Color sliderBlue = Color(0xFF2972B1);
    const Color sliderBackground = Color(0xFF999999);

    const Color primary = Color(0xFF409AE0);
    const Color secondary = barBlue;
    const Color tertiary = Color(0xFF23A55A);
    const Color buttonContentColor = Colors.black38;
    const Color buttonActiveColor = primary;

    const Color buttonHoverBackground = Color(0x44BEE6FD);
    const Color buttonHoverOutline = Color(0x443C7FB1);
    const double buttonRadius = 0;
    const buttonMaterialShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(buttonRadius)),
    );

    const ButtonStyle buttonShapeStyle = ButtonStyle(
      shape: MaterialStatePropertyAll(buttonMaterialShape),
    );

    final ButtonStyle buttonColorStyle = ButtonStyle(
      foregroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return buttonActiveColor;
        }

        return buttonContentColor;
      }),
      backgroundColor: hoverColors(
        idle: buttonHoverBackground.withAlpha(0x00),
        hover: buttonHoverBackground,
      ),
      side: hoverProperty(
        idle: const BorderSide(color: Colors.transparent),
        hover: const BorderSide(color: buttonHoverOutline),
      ),
    );

    final ButtonStyle buttonShapeAndColors =
        buttonColorStyle.copyWith(shape: buttonShapeStyle.shape);

    const Color selectedButton = Color.fromARGB(200, 150, 208, 255);
    const Color textColor = Color(0xEE000000);
    const Color textHighlightColor = Color(0xFF0078D7);
    const Color textBoxColor = Color(0xFFFFFFFF);

    const Color selectedButtonContentColor = Colors.white;

    const Color cardColor = panelBackground;
    const Color outline = Color.fromARGB(255, 192, 192, 192);

    const Color tooltipBackgroundColor = Color(0xFFFFFFFF);
    const Color tooltipTextColor = Color(0xFF575757);

    const Color filledbuttonContentColor = appBackground;
    const double panelElevation = 20;

    var newData = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: appBackground,
      colorScheme: ColorScheme.fromSeed(
        brightness: themeBrightness,
        seedColor: seedColor,
        background: panelBackground,
        primary: primary,
        tertiary: tertiary,
        onSecondary: Colors.white,
        outline: outline,
        surface: cardColor,
        onSurfaceVariant: textColor.withAlpha(0xAA),
        secondary: secondary,
        scrim: const Color(0xB7FFFFFF),

        // Most text
        onSurface: textColor,

        // Selected button text, slider value label text
        onPrimary: selectedButtonContentColor,

        // Selected Segmented button
        secondaryContainer: selectedButton,
        onSecondaryContainer: textColor.withAlpha(0xFF),

        // Text field background, slider background
        surfaceVariant: textBoxColor,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        selectionColor: textHighlightColor,
      ),
      tooltipTheme: const TooltipThemeData(
        verticalOffset: 26,
        textStyle: TextStyle(
          color: tooltipTextColor,
          fontSize: 12,
        ),
        decoration: BoxDecoration(
            color: tooltipBackgroundColor,
            border: Border.fromBorderSide(
                BorderSide(width: 1, color: Color(0xFF767676)))),
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
        thumbColor: sliderBlue,
        trackShape: const RectangularSliderTrackShape(),
        trackHeight: 3,
        tickMarkShape: SliderTickMarkShape.noTickMark,
        activeTrackColor: sliderBlue,
        inactiveTrackColor: sliderBackground,
        valueIndicatorColor: sliderBlue,
        valueIndicatorTextStyle: const TextStyle(color: Colors.white),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        elevation: 10,
        actionTextColor: tertiary,
        shape: Border(),
        contentTextStyle: TextStyle(fontSize: 14, color: Color(0xFF767676)),
        insetPadding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
      ),
      badgeTheme: const BadgeThemeData(backgroundColor: barBlue),
      textButtonTheme: TextButtonThemeData(style: buttonShapeAndColors),
      iconButtonTheme: IconButtonThemeData(style: buttonShapeAndColors),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: buttonShapeStyle.copyWith(
          iconColor: const MaterialStatePropertyAll(Color(0xBB333333)),
        ),
      ),
      iconTheme: const IconThemeData(
        color: filledbuttonContentColor,
      ),
      menuButtonTheme: const MenuButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStatePropertyAll(panelBackground),
        ),
      ),
      cardTheme: const CardTheme(
        elevation: 2,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          //side: BorderSide(color: cardOutlineColor),
        ),
      ),
      extensions: {
        const PhtimerTheme(
          pausedColor: Color(0xFFFFDE95),
          runningColor: Color(0xFF26A0DA),
          almostZeroColor: Color(0xDDF23F42),
          disabledColor: Color(0xFF9E9E9E),
          barBackgroundColor: barBackground,
          pausedButton: Color(0xB2FDEFBE),
          runningButton: Color(0xB2BEE6FD),
        ),
        PfsAppTheme(
          boxPanelMaterialBuilder: ({required Widget child}) {
            return Material(
              type: MaterialType.canvas,
              elevation: panelElevation,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5))),
              child: child,
            );
          },
        )
      },
    );

    return newData;
  }

  static ThemeData getPhriendsDarkTheme() {
    const Brightness themeBrightness = Brightness.dark;
    const Color seedColor = Color(0xFF313338);
    const Color panelBackground = Color(0xFF2B2D31);
    const Color appBackground = Color(0xFF313338);

    // APP SPECIFIC
    const Color discordBlue = Color(0xFF5865F2);
    const Color discordBlueHoverDark = Color(0xFF4752C4);
    const Color chatMention = Color(0x4B5865F2);

    const Color primary = discordBlue;
    const Color secondary = discordBlue;
    const Color tertiary = Color(0xFF23A55A);
    const Color buttonContentColor = Color(0xCC80848E);
    const Color buttonHoverColor = Color(0xFFDBDEE1);
    final Color buttonActiveColor =
        discordBlue.withAlpha(0x77); //Color(0x783D507C);
    final Color buttonDisabledColor = buttonContentColor.withAlpha(0x55);

    const Color buttonHoverOverlayColor = Color(0x11D4D4D4);
    const buttonRadius = 5.0;
    const buttonMaterialShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(buttonRadius)),
    );

    const ButtonStyle buttonShapeStyle = ButtonStyle(
      shape: MaterialStatePropertyAll(buttonMaterialShape),
    );

    final ButtonStyle buttonColorStyle = ButtonStyle(
      foregroundColor: hoverActiveDisabledProperty(
        idle: buttonContentColor,
        hover: buttonHoverColor,
        active: buttonActiveColor,
        disabled: buttonDisabledColor,
      ),
      backgroundColor: hoverColors(
        idle: appBackground.withAlpha(0x00),
        hover: appBackground.withAlpha(0x0A),
      ),
      overlayColor: hoverColors(
        idle: buttonHoverOverlayColor.withAlpha(0x00),
        hover: buttonHoverOverlayColor,
      ),
    );

    final ButtonStyle buttonShapeAndColors =
        buttonColorStyle.copyWith(shape: buttonShapeStyle.shape);

    const Color textColor = Color(0xDDF2F3F5);
    const Color textBoxColor = Color(0xFF383A40);

    const Color selectedButton = chatMention;
    const Color selectedButtonContentColor = textColor;

    const Color cardColor = Color(0xFF232428);
    const Color outline = Color(0xC7868686);

    const Color tooltipBackgroundColor = Color(0xFF111214);
    const Color tooltipTextColor = Color(0xEEDBDEE1);

    const Color filledbuttonContentColor = buttonContentColor;
    const double panelElevation = 10;
    const panelOutline = BorderSide(width: 1.0, color: Color(0xFF282A2E));

    var newData = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: appBackground,
      colorScheme: ColorScheme.fromSeed(
        brightness: themeBrightness,
        seedColor: seedColor,
        background: panelBackground,
        primary: primary,
        tertiary: tertiary,
        secondary: secondary,

        onSecondary: Colors.white,
        onSurfaceVariant: textColor.withAlpha(0xAA),
        outline: outline,
        surface: cardColor,
        scrim: const Color(0xB7000000),

        // Most text
        onSurface: textColor,

        // Selected button text, slider value label text
        onPrimary: selectedButtonContentColor,

        // Slider thumb hover color (slider track uses primary)
        primaryContainer: discordBlueHoverDark,

        // Selected Segmented button
        secondaryContainer: selectedButton,
        onSecondaryContainer: textColor.withAlpha(0xFF),

        // Text field background, slider background
        surfaceVariant: textBoxColor,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        selectionColor: Color(0xFF0B69D9),
      ),
      tooltipTheme: const TooltipThemeData(
        verticalOffset: 26,
        textStyle: TextStyle(
          color: tooltipTextColor,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        padding: EdgeInsets.symmetric(
          vertical: 7,
          horizontal: 13,
        ),
        decoration: BoxDecoration(
          color: tooltipBackgroundColor,
          borderRadius: BorderRadius.all(Radius.circular(5)),
        ),
      ),
      filledButtonTheme: const FilledButtonThemeData(
        style: buttonShapeStyle,
      ),
      textTheme: const TextTheme(
        titleMedium: TextStyle(color: outline),
        labelLarge: TextStyle(fontWeight: FontWeight.normal), // Control labels
      ),
      sliderTheme: SliderThemeData(
        thumbColor: Colors.white,
        trackShape: const RoundedRectSliderTrackShape(),
        trackHeight: 7,
        tickMarkShape: SliderTickMarkShape.noTickMark,
        activeTrackColor: discordBlue,
        inactiveTrackColor: const Color(0xFF4E5058),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF1E1F22),
        actionTextColor: tertiary,
        contentTextStyle: TextStyle(fontSize: 14, color: Color(0xFFB4B9C0)),
        insetPadding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
      ),
      badgeTheme: const BadgeThemeData(backgroundColor: discordBlue),
      textButtonTheme: TextButtonThemeData(style: buttonShapeAndColors),
      iconButtonTheme: IconButtonThemeData(style: buttonShapeAndColors),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: buttonShapeStyle.copyWith(
          iconColor: const MaterialStatePropertyAll(Color(0xBBB5BAC1)),
        ),
      ),
      iconTheme: const IconThemeData(
        color: filledbuttonContentColor,
      ),
      menuButtonTheme: const MenuButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStatePropertyAll(panelBackground),
        ),
      ),
      cardTheme: const CardTheme(
        elevation: 2,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          //side: BorderSide(color: cardOutlineColor),
        ),
      ),
      extensions: {
        const PhtimerTheme(
          pausedColor: Color(0x77F0B132),
          runningColor: Color(0xDD5865F2),
          almostZeroColor: Color(0xDDF23F42),
          disabledColor: Color(0xFF9E9E9E),
          barBackgroundColor: Color(0xDD707070),
          runningButton: Color(0x7852545C),
          pausedButton: Color(0x7852545C),
        ),
        PfsAppTheme(
          boxPanelMaterialBuilder: ({required Widget child}) {
            return Material(
              type: MaterialType.canvas,
              elevation: panelElevation,
              shape: const RoundedRectangleBorder(
                side: panelOutline,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              surfaceTintColor: null,
              child: child,
            );
          },
          pawPanelMaterialBuilder: ({required Widget child}) {
            return Material(
              type: MaterialType.canvas,
              elevation: panelElevation,
              shape: const RoundedRectangleBorder(
                side: panelOutline,
                borderRadius: BorderRadius.vertical(top: Radius.circular(300)),
              ),
              surfaceTintColor: null,
              child: child,
            );
          },
        )
      },
    );

    return newData;
  }

  static ThemeData getClipDarkTheme() {
    const Brightness themeBrightness = Brightness.dark;
    const Color seedColor = Color(0xFF808080);
    const Color panelBackground = Color(0xFF474747);
    const Color appBackground = Color(0xFF323232);

    const Color primary = Color(0xFF707A90);
    const Color secondary = Color(0xFF707A90);
    const Color tertiary = Color(0xFF5F687D);
    const Color buttonContentColor = Color(0x6D9E9E9E);
    const Color buttonActiveColor = Color(0x783D507C);
    const Color buttonHoverColor = Color(0xDCD8D8D8);

    //const Color clipLighterSelected = Color(0xFF7C89A3);
    const Color clipDarkerSelected = Color(0xFF5F687D);

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
        idle: appBackground.withAlpha(0x00),
        hover: appBackground.withAlpha(0x22),
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
    const Color outline = Color(0xC5A1A1A1);

    const cspWindowBorderSide = BorderSide(
      color: cspWindowBorderColor,
      width: 3,
    );
    final cspWindowBorderSideTop = cspWindowBorderSide.copyWith(width: 6);

    const Color filledbuttonContentColor = buttonContentColor;
    const double cspPanelElevation = 20;

    var newData = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: appBackground,
      colorScheme: ColorScheme.fromSeed(
        brightness: themeBrightness,
        seedColor: seedColor,
        background: panelBackground,
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

        primaryContainer: clipDarkerSelected,

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
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 8,
          disabledThumbRadius: 6,
        ),
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
          backgroundColor: MaterialStatePropertyAll(panelBackground),
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
          runningColor: Color(0x99586788),
          almostZeroColor: Color(0xDD6C7CA1),
          disabledColor: Color(0xFF9E9E9E),
          barBackgroundColor: Colors.black12,
          pausedButton: Color(0x996F6F6F),
          runningButton: Color(0x665F687D),
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
    const Color panelBackground = Colors.white;
    const Color appBackground = panelBackground;

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
        idle: appBackground.withAlpha(0x00),
        hover: appBackground.withAlpha(0x22),
      ),
    );

    const Color cardColor = Color.fromARGB(255, 250, 249, 247);
    const Color cardOutlineColor = Color(0xFFEEEEEE);
    const Color outline = Color.fromARGB(82, 94, 76, 53);

    var newData = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: appBackground,
      colorScheme: ColorScheme.fromSeed(
        brightness: themeBrightness,
        seedColor: seedColor,
        background: panelBackground,
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
      sliderTheme: SliderThemeData(
        tickMarkShape: SliderTickMarkShape.noTickMark,
      ),
      textButtonTheme: TextButtonThemeData(style: buttonStyle),
      iconButtonTheme: IconButtonThemeData(style: buttonStyle),
      badgeTheme: const BadgeThemeData(backgroundColor: buttonActiveColor),
      menuButtonTheme: const MenuButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStatePropertyAll(panelBackground),
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
          pausedButton: tertiary,
          runningButton: Color.fromARGB(140, 167, 148, 140),
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

  static MaterialStateProperty<T> hoverActiveDisabledProperty<T>({
    required T idle,
    required T hover,
    required T active,
    required T disabled,
  }) {
    return MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.hovered)) {
        return hover;
      } else if (states.contains(MaterialState.selected)) {
        return active;
      } else if (states.contains(MaterialState.disabled)) {
        return disabled;
      }

      return idle;
    });
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
