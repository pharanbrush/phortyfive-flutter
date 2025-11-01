import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pfs2/libraries/color_meter_cyclop.dart';

import 'package:pfs2/ui/phanimations.dart';

enum ColorDifference {
  allLighterOrEqual,
  allDarkerOrEqual,
  same,
  mixed,
  invalid,
}

mixin MainScreenColorMeter {
  late final startColor = ValueNotifier(Colors.white);
  late final endColor = ValueNotifier(Colors.white);

  late final startEndColorDifference = ValueNotifier(ColorDifference.mixed);

  late final terminalAlphaBlendColor = ValueNotifier(Colors.white);
  late final alphaBlendColorPercent = ValueNotifier(0.0);

  late final multiplyColor = ValueNotifier(Colors.white);
  late final dodgeColor = ValueNotifier(Colors.black);
  late final linearBurnColor = ValueNotifier(Colors.white);
  // late final overlayColor = ValueNotifier(
  //   Color.from(alpha: 1, red: 0.5, green: 0.5, blue: 0.5),
  // );
  // late final canColorOverlay = ValueNotifier(false);

  late final canColorDodge = ValueNotifier(false);

  late final addColor = ValueNotifier(Colors.black);
  late final screenColor = ValueNotifier(Colors.black);

  late final lastPickKey = ValueNotifier("defaultKey");
  void Function()? onColorMeterSecondaryTap;

  final keyRng = Random();
  final eyeDropKey = GlobalKey();

  late final loupe = ColorLoupe(
    onColorHover: onColorHover,
    onColorClicked: onColorSelected,
    onSecondaryTap: onColorMeterSecondaryTap,
  );

  bool isColorMetering = false;

  void onColorSelected(Color newColor) {
    startColor.value = newColor;
    lastPickKey.value = "pick${keyRng.nextInt(1000).toString()}";
  }

  void onColorHover(Color value) {
    endColor.value = value;

    _updateColorDifference();
    _updateTerminalColor();
    _updateBlendModeColors();
  }

  void _updateColorDifference() {
    final start = startColor.value;
    final end = endColor.value;

    final r1 = start.r;
    final g1 = start.g;
    final b1 = start.b;

    final r2 = end.r;
    final g2 = end.g;
    final b2 = end.b;

    if (r1.isNaN || r2.isNaN || g1.isNaN || g2.isNaN || b1.isNaN || b2.isNaN) {
      startEndColorDifference.value = ColorDifference.invalid;
    } else if (r1.isInfinite ||
        r2.isInfinite ||
        g1.isInfinite ||
        g2.isInfinite ||
        b1.isInfinite ||
        b2.isInfinite) {
      startEndColorDifference.value = ColorDifference.invalid;
    } else if (r2 == r1 && g2 == g1 && b2 == b1) {
      startEndColorDifference.value = ColorDifference.same;
    } else if (r2 >= r1 && g2 >= g1 && b2 >= b1) {
      startEndColorDifference.value = ColorDifference.allLighterOrEqual;
    } else if (r2 <= r1 && g2 <= g1 && b2 <= b1) {
      startEndColorDifference.value = ColorDifference.allDarkerOrEqual;
    } else {
      startEndColorDifference.value = ColorDifference.mixed;
    }
  }

  static double calculateSafeStretchFactor(
      double r, double g, double b, double vr, double vg, double vb) {
    // Distance to colorspace edge (candidate factors for stretching the vector)
    final dr = vr > 0 ? 1.0 - r : -r;
    final dg = vg > 0 ? 1.0 - g : -g;
    final db = vb > 0 ? 1.0 - b : -b;

    final double rDistanceFactor = vr == 0 ? double.infinity : dr / vr;
    final double gDistanceFactor = vg == 0 ? double.infinity : dg / vg;
    final double bDistanceFactor = vb == 0 ? double.infinity : db / vb;

    double minOfThree(double a, double b, double c) {
      if (a <= b && a <= c && a.isFinite) {
        return a;
      } else if (b <= a && b <= c && b.isFinite) {
        return b;
      } else if (c <= a && c <= b && c.isFinite) {
        return c;
      } else {
        return 0;
      }
    }

    return minOfThree(rDistanceFactor, gDistanceFactor, bDistanceFactor);
  }

  void _updateBlendModeColors() {
    final start = startColor.value;
    final end = endColor.value;

    final r1 = start.r;
    final g1 = start.g;
    final b1 = start.b;

    final r2 = end.r;
    final g2 = end.g;
    final b2 = end.b;

    switch (startEndColorDifference.value) {
      case ColorDifference.same:
      case ColorDifference.allDarkerOrEqual:
        // Divide end color with start color. Assumes start color is lighter.
        final double mr = r1 == 0 ? 0 : r2 / r1;
        final double mg = g1 == 0 ? 0 : g2 / g1;
        final double mb = b1 == 0 ? 0 : b2 / b1;
        final outputMultiplyColor =
            Color.from(alpha: 1, red: mr, green: mg, blue: mb);

        multiplyColor.value = outputMultiplyColor;

        final double subr = r1 - r2;
        final double subg = g1 - g2;
        final double subb = b1 - b2;
        final outputLinearBurnColor = Color.from(
            alpha: 1, red: 1 - subr, green: 1 - subg, blue: 1 - subb);

        linearBurnColor.value = outputLinearBurnColor;

      case ColorDifference.allLighterOrEqual:
        final double ar = r2 - r1;
        final double ag = g2 - g1;
        final double ab = b2 - b1;
        final outputAddColor =
            Color.from(alpha: 1, red: ar, green: ag, blue: ab);
        addColor.value = outputAddColor;

        final double sr = 1 - (1 - r2) / (1 - r1);
        final double sg = 1 - (1 - g2) / (1 - g1);
        final double sb = 1 - (1 - b2) / (1 - b1);
        final outputScreenColor =
            Color.from(alpha: 1, red: sr, green: sg, blue: sb);
        screenColor.value = outputScreenColor;

        const double tooSmallToDodge = 4.0 / 255.0;

        double safeDodgeDivide(double startValue, double endValue) {
          if (startValue == 0) {
            // 1. Color is the same so don't dodge.
            if (endValue == 0) {
              return 1;
            }

            // 2. Color can't be dodged so pretend it has a small value.
            return tooSmallToDodge / endValue;
          } else {
            // 3. Normal dodge
            return startValue / endValue;
          }
        }

        final double dr = safeDodgeDivide(r1, r2);
        final double dg = safeDodgeDivide(g1, g2);
        final double db = safeDodgeDivide(b1, b2);

        final cannotDoDodgeOperation = (
            // Color dodge becomes wildly inaccurate if the start color has very low values.
            (r1 < tooSmallToDodge && r2 != r1) ||
                (g1 < tooSmallToDodge && g2 != g1) ||
                (b1 < tooSmallToDodge && b2 != b1) ||
                // Color dodge doesn't work if the division results in a giant number
                (dr > 1 || dg > 1 || db > 1));

        canColorDodge.value = !cannotDoDodgeOperation;

        final double cdr = 1 - dr;
        final double cdg = 1 - dg;
        final double cdb = 1 - db;
        final outputDodgeColor =
            Color.from(alpha: 1, red: cdr, green: cdg, blue: cdb);
        dodgeColor.value = outputDodgeColor;
      // case ColorDifference.mixed:
      // double inverseOverlayChannel(double start, double end) {
      //   if (start > 0.5) {
      //     return end * start * 0.5;
      //   }

      //   return 1.0 - ((1.0 - end) / (2.0 * (1.0 - start)));
      // }

      // final ovr = inverseOverlayChannel(r1, r2);
      // final ovg = inverseOverlayChannel(g1, g2);
      // final ovb = inverseOverlayChannel(b1, b2);

      // final cannotOverlay = (ovr > 1 || ovr < 0) ||
      //     (ovg > 1 || ovg < 0) ||
      //     (ovb > 1 || ovb < 0);

      // canColorOverlay.value = !cannotOverlay;

      // if (!cannotOverlay) {
      //   overlayColor.value = Color.from(
      //     alpha: 1,
      //     red: ovr,
      //     green: ovg,
      //     blue: ovb,
      //   );
      // }

      default:
        multiplyColor.value = Colors.transparent;
        return;
    }
  }

  void _updateTerminalColor() {
    final start = startColor.value;
    final end = endColor.value;

    final r1 = start.r;
    final g1 = start.g;
    final b1 = start.b;

    final r2 = end.r;
    final g2 = end.g;
    final b2 = end.b;

    // Color difference vector. An arrow pointing towards where the color is moving.
    final vr = r2 - r1;
    final vg = g2 - g1;
    final vb = b2 - b1;

    final vectorScaleToEdge =
        calculateSafeStretchFactor(r1, g1, b1, vr, vg, vb);

    // Scaled color difference vector that brings the base color to the edge of the colorspace when combined.
    final svr = vr * vectorScaleToEdge;
    final svg = vg * vectorScaleToEdge;
    final svb = vb * vectorScaleToEdge;

    try {
      final tr = r1 + svr;
      final tg = g1 + svg;
      final tb = b1 + svb;

      final outputColor = Color.from(alpha: 1.0, red: tr, green: tg, blue: tb);

      terminalAlphaBlendColor.value = outputColor;
      alphaBlendColorPercent.value = vectorScaleToEdge;
    } catch (err) {
      debugPrint("color error? $err");
    }
  }

  Widget colorMeterModeButton({void Function()? onPressed}) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(Icons.colorize),
      tooltip: "Color meter",
    );
  }

  Iterable<Widget> colorMeterHSLItems() {
    return [
      ValueListenableBuilder(
        valueListenable: endColor,
        builder: (_, __, ___) {
          return ValueListenableBuilder(
            valueListenable: startColor,
            builder: (_, __, ___) {
              final reference = startColor.value.hsl;
              final current = endColor.value.hsl;

              var hueDifference = current.hue - reference.hue;
              if (hueDifference < -180) {
                hueDifference += 180;
              } else if (hueDifference > 180) {
                hueDifference -= 180;
              }
              hueDifference *= 100.0 / 180.0;

              // double deg2rad(double deg) {
              //   return deg / 180.0 * pi;
              // }
              //hueDifference = deg2rad(hueDifference);

              var saturationPercent =
                  (current.saturation / reference.saturation) * 100;
              final sPercentText =
                  (saturationPercent.isInfinite || saturationPercent.isNaN)
                      ? "-"
                      : saturationPercent.toStringAsFixed(0);

              var lightnessPercent =
                  (current.lightness / reference.lightness) * 100;
              final lPercentText =
                  (lightnessPercent.isInfinite || lightnessPercent.isNaN)
                      ? "-"
                      : lightnessPercent.toStringAsFixed(0);

              final hueDiffText = sPercentText == "-" || current.saturation == 0
                  ? "-"
                  : (hueDifference > 0 ? "+" : "") +
                      hueDifference.toStringAsFixed(1);

              return Container(
                // decoration: BoxDecoration(
                //   borderRadius: BorderRadius.all(Radius.circular(3)),
                //   color: Colors.black.withValues(alpha: 0.25),
                // ),
                child: SizedBox(
                  width: 340,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Tooltip(
                          message:
                              "Hue movement.\n100% means the exact opposite color.\nPositive is clockwise in a color wheel where\nRed, Yellow, Green, Cyan, Blue, Violet is clockwise.",
                          child: Text("hue  ", style: numberLabel),
                        ),
                        SizedBox(width: 65, child: Text("$hueDiffText%")),
                        Tooltip(
                            message:
                                "Relative saturation percent.\nThe amount of saturation color B has in proportion to color A",
                            child: Text("sat × ", style: numberLabel)),
                        SizedBox(width: 58, child: Text("$sPercentText%")),
                        Tooltip(
                            message:
                                "Relative lightness percent.\nThe amount of lightness color B in proportion to color A",
                            child: Text("lightness × ", style: numberLabel)),
                        SizedBox(width: 45, child: Text("$lPercentText%")),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      //SizedBox(width: 10),
    ];
  }

  static const double smallTextSize = 10.5;
  static const double numberLabelSize = 13;
  static const double grayTone = 0.64;
  static const Color textGray = Color.from(
    alpha: 1,
    red: grayTone,
    green: grayTone,
    blue: grayTone,
  );

  static const smallText = TextStyle(fontSize: smallTextSize);
  static const blendModeText = TextStyle(
    fontSize: smallTextSize,
    color: textGray,
  );
  static const numberLabel = TextStyle(
    fontSize: numberLabelSize,
    color: textGray,
  );

  Widget colorMeterBottomBar({void Function()? onCloseButtonPressed}) {
    return Positioned(
      bottom: 0,
      right: 0,
      child: SizedBox(
        height: 100,
        child: Row(
          children: [
            // Leftmost block
            Container(
              //color: Colors.red,
              child: Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _startColorBoxWidget(),
                      Text("start", style: blendModeText),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsetsGeometry.only(bottom: 15),
                    child: _rightArrow,
                  ),
                  SizedBox(width: 10),
                ],
              ),
            ),
            // Main middle block
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                //
                // Title bar
                //
                Container(
                  //color: Colors.red.withValues(alpha: 0.5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 10,
                    children: [
                      Text(
                        "COLOR CHANGE METER",
                        style: TextStyle(
                          color: Colors.grey.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(3.0),
                        child: SizedBox(
                          width: 25,
                          height: 25,
                          child: IconButton.filled(
                            padding: EdgeInsets.all(2.0),
                            onPressed: onCloseButtonPressed,
                            icon: Icon(Icons.close, size: 14),
                            hoverColor: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  // color: Colors.lightBlueAccent,
                  child: Column(
                    spacing: 4,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      //
                      // Top row
                      //
                      Container(
                        // color: Colors.green,
                        child: Row(
                          children: [
                            ...colorMeterHSLItems(),
                          ],
                        ),
                      ),

                      //
                      // Divider
                      //
                      Container(
                          width: 280,
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.15)),

                      //
                      // Bottom row
                      //
                      Row(
                        children: [
                          SizedBox(width: 100, child: _normalColorBox()),
                          SizedBox(width: 25),
                          SizedBox(width: 220, child: _blendModeBoxes()),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
            //
            // Rightmost block
            //
            Row(
              children: [
                Padding(
                  padding: EdgeInsetsGeometry.only(bottom: 15),
                  child: _rightArrow,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _endColorBoxWidget(),
                    Container(
                      //color: Colors.red,
                      child: Text("end", style: blendModeText),
                    )
                  ],
                ),
              ],
            ),
            SizedBox(width: 20),
          ],
        ),
      ),
    );
  }

  Row _normalColorBox() {
    return Row(
      children: [
        Text("normal ", style: blendModeText),
        SizedBox(
          width: 35,
          child: ValueListenableBuilder(
            valueListenable: alphaBlendColorPercent,
            builder: (_, value, ___) {
              if (value.isInfinite || value.isNaN || value == 0) {
                return Text(" - ");
              }

              return Text(
                "${(100.0 / value).floor()}%",
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 12),
              );
            },
          ),
        ),
        valueListeningColorBox(terminalAlphaBlendColor),
      ],
    );
  }

  Widget _blendModeBoxes() {
    const double boxSpacing = 12;

    return ValueListenableBuilder(
      valueListenable: startEndColorDifference,
      builder: (_, difference, __) {
        if (difference == ColorDifference.allDarkerOrEqual) {
          return Row(
            spacing: boxSpacing,
            children: [
              _labeledListeningColorBox(
                  label: "multiply", colorListenable: multiplyColor),
              _labeledListeningColorBox(
                  label: "linear burn", colorListenable: linearBurnColor),
            ],
          );
        } else if (difference == ColorDifference.allLighterOrEqual) {
          return Row(
            spacing: boxSpacing,
            children: [
              _labeledListeningColorBox(
                  label: "screen", colorListenable: screenColor),
              _colorDodgeBox(),
              _labeledListeningColorBox(
                  label: "add", colorListenable: addColor),
            ],
          );
        }

        return Row(
          spacing: boxSpacing,
          children: [
            _disabledLabeledColorBox(),
            _disabledLabeledColorBox(),
          ],
        );
      },
    );
  }

  Widget _colorDodgeBox() {
    return ValueListenableBuilder(
      valueListenable: canColorDodge,
      builder: (_, __, ___) {
        return _labeledColorBox(
          label: "color dodge",
          strikethrough: !canColorDodge.value,
          boxWidget: valueListeningColorBox(dodgeColor),
        );
      },
    );
  }

  Widget _disabledLabeledColorBox() {
    return _labeledColorBox(
      label: "             ",
      boxWidget: _colorBox(
        Colors.transparent,
        borderColor: Colors.grey.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _labeledColorBox({
    String label = "",
    bool strikethrough = false,
    required Widget boxWidget,
  }) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 0.5, right: 2),
          child: Text(
            label,
            style: strikethrough
                ? blendModeText.copyWith(decoration: TextDecoration.lineThrough)
                : blendModeText,
          ),
        ),
        boxWidget,
      ],
    );
  }

  Widget _labeledListeningColorBox({
    required String label,
    required ValueListenable<Color> colorListenable,
  }) {
    return _labeledColorBox(
      label: label,
      boxWidget: valueListeningColorBox(colorListenable),
    );
  }

  static const double bigColorBoxSize = 40;
  static const double colorBoxSize = 18;

  Widget _endColorBoxWidget() {
    return valueListeningColorBox(endColor, size: bigColorBoxSize);
  }

  Widget _startColorBoxWidget() {
    return ValueListenableBuilder(
      valueListenable: lastPickKey,
      builder: (_, __, ___) {
        return Animate(
          key: Key(lastPickKey.value),
          effects: const [Phanimations.itemPulseEffect],
          child: valueListeningColorBox(startColor, size: bigColorBoxSize),
        );
      },
    );
  }

  Widget get _rightArrow {
    return _barIcon(Icons.arrow_right_alt);
  }

  Widget _barIcon(IconData iconData) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Icon(iconData),
    );
  }

  Widget valueListeningColorBox(
    ValueListenable<Color> listenableColor, {
    double size = colorBoxSize,
  }) {
    return ValueListenableBuilder(
      valueListenable: listenableColor,
      builder: (_, colorValue, __) {
        return _colorBox(
          colorValue,
          size: size,
        );
      },
    );
  }

  Widget _colorBox(
    Color color, {
    double size = colorBoxSize,
    Color borderColor = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Material(
        elevation: 1,
        shape: RoundedRectangleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              color: color,
              border: Border.all(color: borderColor)),
        ),
      ),
    );
  }

  void startColorMeter(BuildContext context) {
    // debugPrint("startColorMeter");
    isColorMetering = true;
    // TODO: Register escape key to exit color meter mode.

    loupe.startOverlay(context, eyeDropKey);
  }

  void endColorMeter() {
    // debugPrint("endColorMeter");
    if (isColorMetering == false) return;
    // TODO: Unregister escape key to exit color meter mode.

    isColorMetering = false;
    loupe.endOverlay();
  }
}

class ColorLoupe {
  final ValueChanged<Color> onColorClicked;
  final ValueChanged<Color> onColorHover;
  final void Function()? onSecondaryTap;

  ColorLoupe({
    required this.onColorClicked,
    required this.onColorHover,
    this.onSecondaryTap,
  });

  Color color = Colors.white;

  void startOverlay(BuildContext context, GlobalKey eyeDropKey) {
    try {
      var currentEyeDrop = eyeDropKey.currentWidget as EyeDrop?;
      if (currentEyeDrop != null) {
        currentEyeDrop.startEyeDropper(
          context,
          _handleOnColorClicked,
          _handleOnColorHover,
          _handleSecondaryTap,
        );
      }
    } catch (err) {
      debugPrint('ERROR !!! showOverlay $err');
    }
  }

  void endOverlay() {
    EyeDrop.endEyeDrop();
  }

  void _handleSecondaryTap() {
    onSecondaryTap?.call();
  }

  void _handleOnColorHover(Color value) {
    onColorHover(value);
  }

  void _handleOnColorClicked(Color value) {
    color = value;
    onColorClicked(value);
  }
}
