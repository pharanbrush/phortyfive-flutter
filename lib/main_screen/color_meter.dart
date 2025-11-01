// Some code based on Cyclop by RX Labz

// MIT License

// Copyright (c) 2020 RX Labz

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import 'dart:math';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image/image.dart' as img;
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
    debugPrint("startColorMeter");
    isColorMetering = true;
    // TODO: Register escape key to exit color meter mode.

    loupe.startOverlay(context, eyeDropKey);
  }

  void endColorMeter() {
    debugPrint("endColorMeter");
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

//
//
//
//
//
//
//
//
//
//
// eye_dropper_layer.dart
//
//
//
//
//
//
//
//
//
//

final captureKey = GlobalKey();

class EyeDropperModel {
  /// based on PointerEvent.kind
  bool isTouchInterface = false;
  OverlayEntry? loupeOverlayEntry;

  img.Image? snapshot;
  Offset? cursorPosition;

  Color hoverColor = Colors.black;
  List<Color> hoverColors = [];
  Color selectedColor = Colors.black;

  ValueChanged<Color>? onColorSelected;
  ValueChanged<Color>? onColorChanged;
  void Function()? onSecondaryTap;

  EyeDropperModel();
}

class EyeDrop extends InheritedWidget {
  //TODO: This needs to rebuild when the window resizes.

  static EyeDropperModel data = EyeDropperModel();

  EyeDrop({required Widget child, super.key})
      : super(
          child: RepaintBoundary(
            key: captureKey,
            child: Listener(
              onPointerMove: (details) => _onHover(
                details.position,
                details.kind == PointerDeviceKind.touch,
              ),
              onPointerHover: (details) => _onHover(
                details.position,
                details.kind == PointerDeviceKind.touch,
              ),
              onPointerDown: (PointerDownEvent details) {
                if (details.buttons == 2) {
                  data.onSecondaryTap!();
                }
              },
              onPointerUp: (PointerUpEvent details) {
                _onPrimaryTapUp(details.position);
              },
              child: child,
            ),
          ),
        );

  static EyeDrop of(BuildContext context) {
    final eyeDrop = context.dependOnInheritedWidgetOfExactType<EyeDrop>();
    if (eyeDrop == null) {
      throw Exception(
          'No EyeDrop found. You must wrap your application within an EyeDrop widget.');
    }
    return eyeDrop;
  }

  static void _onPrimaryTapUp(Offset position) {
    _onHover(position, data.isTouchInterface);
    if (data.onColorSelected != null) {
      data.onColorSelected!(data.hoverColors.center);
    }
  }

  static void endEyeDrop() {
    if (data.loupeOverlayEntry != null) {
      try {
        data.loupeOverlayEntry!.remove();
        data.loupeOverlayEntry = null;
        data.onColorSelected = null;
        data.onColorChanged = null;
      } catch (err) {
        debugPrint('ERROR !!! _onPointerUp $err');
      }
    }
  }

  static void _onHover(Offset offset, bool isTouchInterface) {
    if (data.loupeOverlayEntry != null) {
      data.loupeOverlayEntry!.markNeedsBuild();
    }

    data.cursorPosition = offset;

    data.isTouchInterface = isTouchInterface;

    if (data.snapshot != null) {
      data.hoverColor = getPixelColor(data.snapshot!, offset);
      data.hoverColors = getPixelColors(data.snapshot!, offset);
    }

    if (data.onColorChanged != null) {
      data.onColorChanged!(data.hoverColors.center);
    }
  }

  void startEyeDropper(
    BuildContext context,
    ValueChanged<Color> onColorSelected,
    ValueChanged<Color>? onColorChanged,
    void Function()? onSecondaryTap,
  ) async {
    await _capturePickableImage();

    if (data.snapshot == null) return;

    data.onColorSelected = onColorSelected;
    data.onColorChanged = onColorChanged;
    data.onSecondaryTap = onSecondaryTap;

    // data.loupeOverlayEntry = OverlayEntry(
    //   builder: (_) => LoupeOverlay(
    //     isTouchInterface: data.isTouchInterface,
    //     colors: data.hoverColors,
    //     cursorPosition: data.cursorPosition,
    //   ),
    // );

    // if (context.mounted) {
    //   Overlay.of(context).insert(data.loupeOverlayEntry!);
    // }
  }

  Future<void> _capturePickableImage() async {
    final renderer =
        captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

    if (renderer == null) return;

    data.snapshot = await repaintBoundaryToImage(renderer);
  }

  @override
  bool updateShouldNotify(EyeDrop oldWidget) {
    return true;
  }
}

//
//
//
//
//
//
//
//
//
//
// eye_dropper_overlay.dart
//
//
//
//
//
//
//
//
//
//

const _cellSize = 10;
const _gridSize = 90.0;

class LoupeOverlay extends StatelessWidget {
  final Offset? cursorPosition;
  final bool isTouchInterface;

  final List<Color> colors;

  const LoupeOverlay({
    required this.colors,
    this.cursorPosition,
    this.isTouchInterface = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return cursorPosition != null
        ? Positioned(
            left: cursorPosition!.dx - (_gridSize / 2),
            top: cursorPosition!.dy -
                (_gridSize / 2) -
                (isTouchInterface ? _gridSize / 2 : 0),
            width: _gridSize,
            height: _gridSize,
            child: _buildZoom(),
          )
        : const SizedBox.shrink();
  }

  Widget _buildZoom() {
    return IgnorePointer(
      ignoring: true,
      child: Container(
        foregroundDecoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              width: 8, color: colors.isEmpty ? Colors.white : colors.center),
        ),
        width: _gridSize,
        height: _gridSize,
        constraints: BoxConstraints.loose(const Size.square(_gridSize)),
        child: ClipOval(
          child: CustomPaint(
            size: const Size.square(_gridSize),
            painter: _PixelGridPainter(colors),
          ),
        ),
      ),
    );
  }
}

/// paint a hovered pixel/colors preview
class _PixelGridPainter extends CustomPainter {
  final List<Color> colors;

  static const gridSize = 9;
  static const eyeRadius = 35.0;

  final blackStroke = Paint()
    ..color = Colors.black
    ..strokeWidth = 10
    ..style = PaintingStyle.stroke;

  _PixelGridPainter(this.colors);

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final gridStroke = Paint()
      ..color = Colors.white.withAlpha(15)
      ..style = PaintingStyle.stroke;

    final blackLine = Paint()
      ..color = Colors.black
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final selectedStroke = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // fill pixels color square
    int i = 0;
    for (final color in colors) {
      final fill = Paint()..color = color;
      final rect = Rect.fromLTWH(
        (i % gridSize).toDouble() * _cellSize,
        ((i ~/ gridSize) % gridSize).toDouble() * _cellSize,
        _cellSize.toDouble(),
        _cellSize.toDouble(),
      );
      canvas.drawRect(rect, fill);
      i++;
    }

    // draw pixels borders after fills
    int colorIndex = 0;
    for (final _ in colors) {
      final rect = Rect.fromLTWH(
        (colorIndex % gridSize).toDouble() * _cellSize,
        ((colorIndex ~/ gridSize) % gridSize).toDouble() * _cellSize,
        _cellSize.toDouble(),
        _cellSize.toDouble(),
      );
      canvas.drawRect(
          rect, colorIndex == colors.length ~/ 2 ? selectedStroke : gridStroke);

      if (colorIndex == colors.length ~/ 2) {
        canvas.drawRect(rect.deflate(1), blackLine);
      }

      colorIndex++;
    }

    // black contrast ring
    canvas.drawCircle(
      const Offset((_gridSize) / 2, (_gridSize) / 2),
      eyeRadius,
      blackStroke,
    );
  }

  @override
  bool shouldRepaint(_PixelGridPainter oldDelegate) {
    return !listEquals(oldDelegate.colors, colors);
  }

  bool listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) {
      return b == null;
    }
    if (b == null || a.length != b.length) {
      return false;
    }
    if (identical(a, b)) {
      return true;
    }
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }
}

//
//
//
//
//
//
//
//
//
//
// utils.dart
//
//
//
//
//
//
//
//
//
//

extension Chroma on String {
  /// converts string to [Color]
  /// fill incomplete values with 0
  /// ex: 'ff00'.toColor() => Color(0xffff0000)
  Color toColor({bool argb = false}) {
    final colorString = '0x${argb ? '' : 'ff'}$this'.padRight(10, '0');
    return Color(int.tryParse(colorString) ?? 0);
  }
}

/// shortcuts to manipulate [Color]
extension Utils on Color {
  HSLColor get hsl => HSLColor.fromColor(this);

  double get hue => hsl.hue;

  double get saturation => hsl.saturation;

  double get lightness => hsl.lightness;

  Color withHue(double value) => hsl.withHue(value).toColor();

  /// ff001232
  String get hexARGB => toARGB32().toRadixString(16).padLeft(8, '0');

  /// 001232ac
  String get hexRGB =>
      toARGB32().toRadixString(16).padLeft(8, '0').replaceRange(0, 2, '');

  Color withSaturation(double value) =>
      HSLColor.fromAHSL(a, hue, value, lightness).toColor();

  Color withLightness(double value) => hsl.withLightness(value).toColor();

  /// generate the gradient of a color with
  /// lightness from 0 to 1 in [stepCount] steps
  List<Color> getShades(int stepCount, {bool skipFirst = true}) =>
      List.generate(
        stepCount,
        (index) {
          return hsl
              .withLightness(1 -
                  ((index + (skipFirst ? 1 : 0)) /
                      (stepCount - (skipFirst ? -1 : 1))))
              .toColor();
        },
      );
}

extension Helper on List<Color> {
  /// return the central item of a color list or black if the list is empty
  Color get center => isEmpty ? Colors.black : this[length ~/ 2];
}

List<Color> getHueGradientColors({double? saturation, int steps = 36}) =>
    List.generate(steps, (value) => value)
        .map<Color>((v) {
          final hsl = HSLColor.fromAHSL(1, v * (360 / steps), 0.67, 0.50);
          final rgb = hsl.toColor();
          return rgb.withValues(alpha: 1);
        })
        .map((c) => saturation != null ? c.withSaturation(saturation) : c)
        .toList();

const samplingGridSize = 9;

List<Color> getPixelColors(
  img.Image image,
  Offset offset, {
  int size = samplingGridSize,
}) =>
    List.generate(
      size * size,
      (index) => getPixelColor(
        image,
        offset + _offsetFromIndex(index, samplingGridSize),
      ),
    );

Color getPixelColor(img.Image image, Offset offset) => (offset.dx >= 0 &&
        offset.dy >= 0 &&
        offset.dx < image.width &&
        offset.dy < image.height)
    ? pixel2Color(image.getPixel(offset.dx.toInt(), offset.dy.toInt()))
    : const Color(0x00000000);

ui.Offset _offsetFromIndex(int index, int numColumns) => Offset(
      (index % numColumns).toDouble(),
      ((index ~/ numColumns) % numColumns).toDouble(),
    );

Color pixel2Color(img.Pixel p) {
  return Color.fromARGB(p.a.toInt(), p.r.toInt(), p.g.toInt(), p.b.toInt());
}

Color abgr2Color(int value) {
  final a = (value >> 24) & 0xFF;
  final b = (value >> 16) & 0xFF;
  final g = (value >> 8) & 0xFF;
  final r = (value >> 0) & 0xFF;

  return Color.fromARGB(a, r, g, b);
}

Future<img.Image?> repaintBoundaryToImage(
  RenderRepaintBoundary renderer,
) async {
  try {
    final rawImage = await renderer.toImage(pixelRatio: 1);
    final byteData =
        await rawImage.toByteData(format: ui.ImageByteFormat.rawStraightRgba);

    if (byteData == null) throw Exception('Null image byteData !');

    final pngBytes = byteData.buffer;

    return img.Image.fromBytes(
      width: rawImage.width,
      height: rawImage.height,
      bytes: pngBytes,
      order: img.ChannelOrder.rgba,
    );
  } catch (err, stackTrace) {
    debugPrint('repaintBoundaryToImage... $err $stackTrace');

    rethrow;
  }
}
