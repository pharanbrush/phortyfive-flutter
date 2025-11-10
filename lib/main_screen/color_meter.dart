import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pfs2/libraries/color_meter_cyclop.dart';
import 'package:pfs2/main_screen/main_screen.dart';
import 'package:pfs2/main_screen/panels/modal_panel.dart';

import 'package:pfs2/ui/phanimations.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';
import 'package:pfs2/widgets/phbuttons.dart';
import 'package:vector_math/vector_math.dart' hide Colors;

mixin MainScreenColorMeter on MainScreenPanels {
  void Function()? onColorMeterExit;
  final eyeDropKey = GlobalKey();
  late final colorMeterModel = ColorMeterModel(
    eyeDropKey: eyeDropKey,
  );

  Widget colorMeterModeButton({void Function()? onPressed}) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(Icons.colorize),
      tooltip: "Open color change meter",
    );
  }

  late final ModalPanel colorMeterPanel = ModalPanel(
    onBeforeOpen: () => closeAllPanels(except: colorMeterPanel),
    onClosed: () {
      colorMeterModel.endColorMeter();
      onColorMeterExit?.call();
    },
    useUnderlay: false,
    transitionBuilder: Phanimations.bottomMenuTransition,
    builder: () {
      return ColorMeterBottomBar(
        eyeDropKey: eyeDropKey,
        model: colorMeterModel,
      );
    },
  );
}

class ColorMeterModel {
  ColorMeterModel({required this.eyeDropKey});

  final GlobalKey eyeDropKey;

  ValueChanged<Color> onColorClicked = (_) {
    debugPrint("onColorClicked was not bound");
  };
  ValueChanged<Offset>? onColorPositionClicked;
  ValueChanged<Offset>? onColorPositionHover;
  ValueChanged<Color>? onColorHover;
  void Function()? onSecondaryTap;
  void Function()? onWindowChanged;
  void Function()? onPointerEnter;
  void Function()? onPointerExit;
  bool isColorMetering = false;

  void Function()? onStartColorMeter;
  void Function()? onEndColorMeter;

  void startOverlay(BuildContext context, GlobalKey eyeDropKey) {
    try {
      final eyeDropper = eyeDropKey.currentWidget as EyeDropperLayer?;
      if (eyeDropper != null) {
        eyeDropper.startEyeDropper(
          context,
          onColorSelected: onColorClicked,
          onColorChanged: onColorHover,
          onColorPositionSelected: onColorPositionClicked,
          onColorPositionHover: onColorPositionHover,
          onSecondaryTap: onSecondaryTap,
          onWindowChanged: onWindowChanged,
          onPointerEnter: onPointerEnter,
          onPointerExit: onPointerExit,
        );
      } else {
        debugPrint("eyeDropper not found");
      }
    } catch (err) {
      debugPrint('ERROR !!! showOverlay $err');
    }
  }

  void endOverlay(GlobalKey eyeDropKey) {
    final eyeDropper = eyeDropKey.currentWidget as EyeDropperLayer?;
    if (eyeDropper != null) {
      eyeDropper.stopEyeDropper();
    } else {
      debugPrint("eyedrop was null. Unable to end");
    }
  }

  void startColorMeter(BuildContext context) {
    if (isColorMetering) return;
    isColorMetering = true;
    startOverlay(context, eyeDropKey);
    onStartColorMeter?.call();
  }

  void endColorMeter() {
    if (isColorMetering == false) return;
    isColorMetering = false;
    endOverlay(eyeDropKey);
    onEndColorMeter?.call();
  }
}

class ColorMeterBottomBar extends StatefulWidget {
  const ColorMeterBottomBar({
    super.key,
    required this.eyeDropKey,
    required this.model,
  });

  final GlobalKey eyeDropKey;
  final ColorMeterModel model;

  @override
  State<ColorMeterBottomBar> createState() => _ColorMeterBottomBarState();
}

class _ColorMeterBottomBarState extends State<ColorMeterBottomBar> {
  late final startColor = ValueNotifier(Colors.white);
  late final endColor = ValueNotifier(Colors.white);
  final calculatedColors = CalculatedColors();

  late final startColorPosition = ValueNotifier(Offset(0, 0));
  late final endColorPosition = ValueNotifier(Offset(0, 0));
  late final isStartColorPicked = ValueNotifier(false);
  late final isEndColorPicked = ValueNotifier(false);

  late final isBlendModeBoxesEnabled = ValueNotifier(false);

  final keyRng = math.Random();
  late final lastPickKey = ValueNotifier("defaultKey");

  final overlays = ColorMeterOverlays();

  bool initOverlaysQueued = false;

  void initColorPickPositionOverlays() {
    debugPrint("_initColorPickPositionOverlays");
    overlays.tryInitialize(
      widget.eyeDropKey.currentContext,
      startPosition: startColorPosition,
      endPosition: endColorPosition,
      startColor: startColor,
      endColor: endColor,
      isStartColorSelected: isStartColorPicked,
    );
    
    initOverlaysQueued = false;
  }

  @override
  void initState() {
    final model = widget.model;
    model.onColorHover = onColorHover;
    model.onColorClicked = onColorSelected;
    model.onColorPositionClicked = onColorPositionClicked;
    model.onColorPositionHover = onColorPositionHover;
    model.onWindowChanged = _onWindowChanged;
    model.onPointerEnter = onPointerEnter;
    model.onPointerExit = onPointerExit;
    model.onSecondaryTap = () => handleEscape();

    model.onEndColorMeter = () {
      _resetState();
      overlays.removeOverlays();
    };

    model.startColorMeter(context);
    initOverlaysQueued = true;
    super.initState();
  }

  void onPointerExit() {
    overlays.setPointerOverlayActive(false, widget.eyeDropKey.currentContext);
  }

  void onPointerEnter() {
    overlays.setPointerOverlayActive(true, widget.eyeDropKey.currentContext);
  }

  void onColorSelected(Color newColor) {
    startColor.value = newColor;
    isStartColorPicked.value = true;

    lastPickKey.value = "pick${keyRng.nextInt(1000).toString()}";
  }

  void onColorPositionClicked(Offset offset) {
    startColorPosition.value = offset;
  }

  void onColorHover(Color value) {
    if (initOverlaysQueued) initColorPickPositionOverlays();

    endColor.value = value;
    calculatedColors.updateColors(startColor.value, endColor.value);
  }

  void onColorPositionHover(Offset offset) {
    endColorPosition.value = offset;
  }

  Iterable<Widget> colorMeterHSLItems() {
    return [
      ValueListenableBuilder(
        valueListenable: endColor,
        builder: (_, __, ___) {
          return ValueListenableBuilder(
            valueListenable: startColor,
            builder: (context, __, ___) {
              final start = startColor.value.hsl;
              final end = endColor.value.hsl;

              var hueDifference = end.hue - start.hue;
              if (hueDifference < -180) {
                hueDifference += 180;
              } else if (hueDifference > 180) {
                hueDifference -= 180;
              }
              hueDifference *= 100.0 / 180.0;

              final ss = start.saturation;
              final es = end.saturation;

              final saturationPercent = (es / ss);
              final saturationDifference = (es - ss) * 100;

              final sDifferenceText =
                  "${saturationDifference > 0 ? "+" : ""}${saturationDifference.toStringAsFixed(0)}";

              final isSaturationInvalid =
                  (saturationPercent.isInfinite || saturationPercent.isNaN);

              final lightnessPercent = (end.lightness / start.lightness) * 100;
              final lPercentText =
                  (lightnessPercent.isInfinite || lightnessPercent.isNaN)
                      ? "-"
                      : lightnessPercent.toStringAsFixed(0);

              final hueDiffText = isSaturationInvalid || end.saturation == 0
                  ? "-"
                  : (hueDifference > 0 ? "+" : "") +
                      hueDifference.toStringAsFixed(1);

              final theme = Theme.of(context);
              final baseSize = theme.textTheme.bodyMedium?.fontSize ?? 12;
              final lightnessPercentTextStyle = TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: baseSize * 1.4,
              );

              final percentTextStyle =
                  theme.textTheme.labelMedium?.copyWith(color: textGray);

              final percentLabel = Text("%", style: percentTextStyle);

              return Container(
                // decoration: BoxDecoration(
                //   borderRadius: BorderRadius.all(Radius.circular(3)),
                //   color: Colors.black.withValues(alpha: 0.25),
                // ),
                child: SizedBox(
                  width: 360,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Hue
                        HslChangeIcon(
                          value: hueDifference,
                          cutoff: 0,
                          increase: Icons.redo,
                          decrease: Icons.undo,
                          extraRightPadding: 3,
                        ),
                        Tooltip(
                          message:
                              "Hue movement.\n100% means the exact opposite color.\nPositive is clockwise in a color wheel where\nRed, Yellow, Green, Cyan, Blue, Violet is clockwise.",
                          child: Text("hue  ", style: numberLabel),
                        ),
                        SizedBox(
                            width: 65,
                            child: Row(
                              children: [
                                Text(hueDiffText.padLeft(5)),
                                percentLabel
                              ],
                            )),
                        // Saturation
                        HslChangeIcon(
                          value: saturationPercent,
                          cutoff: 100,
                          decrease: Icons.arrow_back,
                          increase: Icons.arrow_forward,
                        ),
                        Tooltip(
                            message:
                                "Delta saturation.\nThe difference in saturation between color A and color B.",
                            child: Text("sat ", style: numberLabel)),
                        SizedBox(
                            width: 58,
                            child: Row(
                              children: [
                                Text(sDifferenceText),
                                percentLabel,
                              ],
                            )),

                        // Lightness
                        HslChangeIcon(
                          value: lightnessPercent,
                          cutoff: 100,
                          decrease: Icons.arrow_downward,
                          increase: Icons.arrow_upward,
                        ),
                        Tooltip(
                            message:
                                "Relative lightness percent.\nThe amount of lightness color B has in proportion to color A",
                            child: Text("lightness × ", style: numberLabel)),
                        Container(
                          //decoration: BoxDecoration(color: Colors.red),
                          child: SizedBox(
                            width: 64,
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    right: 1.55,
                                    bottom: 1,
                                  ),
                                  child: Text(
                                    lPercentText,
                                    style: lightnessPercentTextStyle,
                                  ),
                                ),
                                percentLabel,
                              ],
                            ),
                          ),
                        ),
                      ].animate(
                        effects: [
                          Phanimations.slideRightEffect,
                          Phanimations.fadeInEffect
                        ],
                        delay: Duration(milliseconds: 30),
                        interval: Duration(milliseconds: 20),
                      ),
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

  // TODO: Use theme styles
  static const double smallTextSize = 10.5;
  static const double numberLabelSize = 13;
  static const double grayTone = 0.62;
  static const Color textGray = Color.from(
    alpha: 1,
    red: grayTone,
    green: grayTone,
    blue: grayTone,
  );

  static const smallGrayText = TextStyle(
    fontSize: smallTextSize,
    color: textGray,
  );
  static const blendModeText = TextStyle(
    fontSize: smallTextSize,
    color: textGray,
  );
  static const numberLabel = TextStyle(
    fontSize: numberLabelSize,
    color: textGray,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final panelMaterial = PfsAppTheme.boxPanelFrom(theme);

    const double barHeight = 120;

    final mainStack = Stack(
      children: [
        Column(
          spacing: 4,
          children: [
            //
            // Title bar
            //
            Container(
              // color: Colors.red.withValues(alpha: 0.5),
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Text(
                  "COLOR CHANGE METER",
                  style: TextStyle(
                    letterSpacing: 1.5,
                    color: Colors.grey.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            Row(
              children: [
                // Leftmost block
                Container(
                  //color: Colors.green,
                  child: Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _startColorBoxWidget(),
                          Text("start", style: blendModeText),
                        ],
                      ),
                      ValueListenableBuilder(
                          valueListenable: isStartColorPicked,
                          builder: (context, value, child) {
                            if (value == false) {
                              return SizedBox(width: 28, height: 39);
                            }

                            return Padding(
                              padding: EdgeInsetsGeometry.only(bottom: 15),
                              child: _rightArrow,
                            ).animate(
                              effects: [
                                Phanimations.slideRightEffect,
                                Phanimations.fadeInEffect
                              ],
                            );
                          }),
                      SizedBox(width: 10),
                    ],
                  ),
                ),
                //
                // Main middle block
                //
                ValueListenableBuilder(
                    valueListenable: isStartColorPicked,
                    builder: (context, value, _) {
                      if (isStartColorPicked.value == false) {
                        return SizedBox(
                          width: 360,
                          height: 78,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Padding(
                                  padding: EdgeInsets.only(
                                      left: 10, right: 10, top: 0, bottom: 15),
                                  child: Icon(Icons.colorize),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  spacing: 3,
                                  children: [
                                    Text(
                                      "Click on the image to pick the starting color.",
                                    ),
                                    Text(
                                      "Right-click to exit color change meter.",
                                      style: smallGrayText,
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
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
                                    color:
                                        Colors.white.withValues(alpha: 0.15)),

                                //
                                // Bottom row
                                //
                                Row(
                                  children: [
                                    SizedBox(
                                        width: 100, child: _normalColorBox()),
                                    SizedBox(width: 25),
                                    SizedBox(
                                      width: 225,
                                      child: ValueListenableBuilder(
                                        valueListenable:
                                            isBlendModeBoxesEnabled,
                                        builder: (context, isBlendModesVisible,
                                            ___) {
                                          if (!isBlendModesVisible) {
                                            return SizedBox(
                                              height: 33,
                                              child: TextButton(
                                                onPressed: () {
                                                  isBlendModeBoxesEnabled
                                                      .value = true;
                                                },
                                                child: Row(
                                                  children: const [
                                                    Spacer(),
                                                    Padding(
                                                      padding: EdgeInsets.only(
                                                          top: 2),
                                                      child: Icon(
                                                        Icons.visibility,
                                                        size: 15,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 6,
                                                    ),
                                                    Padding(
                                                      padding: EdgeInsets.only(
                                                          bottom: 1),
                                                      child:
                                                          Text("Blend modes"),
                                                    ),
                                                    Spacer(),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }

                                          return SizedBox(
                                            //width: 245,
                                            height: 33,
                                            child: TextButton(
                                              onPressed: () {
                                                isBlendModeBoxesEnabled.value =
                                                    false;
                                              },
                                              style: ButtonStyle(
                                                padding: WidgetStatePropertyAll(
                                                  const EdgeInsets.symmetric(
                                                    vertical: 0,
                                                    horizontal: 2,
                                                  ),
                                                ),
                                              ),
                                              child: _blendModeBoxes(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                )
                              ].animate(
                                effects: [
                                  Phanimations.slideRightWideEffect,
                                  Phanimations.fadeInEffect
                                ],
                                delay: Duration(milliseconds: 50),
                                interval: Duration(milliseconds: 60),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 3,
                          )
                        ],
                      );
                    }),
                //
                // Rightmost block
                //
                Container(
                  width: 80,
                  //color: Colors.lightBlueAccent,
                  child: ValueListenableBuilder(
                      valueListenable: isStartColorPicked,
                      builder: (context, value, child) {
                        if (value == false) {
                          return SizedBox.shrink();
                        }

                        return Row(
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
                          ].animate(
                            effects: [
                              Phanimations.slideRightEffect,
                              Phanimations.fadeInEffect
                            ],
                            delay: Duration(milliseconds: 220),
                            interval: Duration(milliseconds: 80),
                          ),
                        );
                      }),
                ),
                SizedBox(width: 20),
              ],
            ),
          ],
        ),
        //
        // Close button layer
        Positioned(
          top: 0,
          right: 4,
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: PanelCloseButton(
              onPressed: () {
                widget.model.endColorMeter();
                ModalDismissContext.of(context)?.onDismiss?.call();
              },
            ),
          ),
        ),
      ],
    );

    return Stack(
      children: [
        Positioned(
          bottom: -8,
          right: 5,
          child: panelMaterial(
            child: Container(
              padding: EdgeInsets.only(left: 30),
              height: barHeight,
              child: mainStack,
            ),
          ),
        ),
      ],
    );
  }

  Row _normalColorBox() {
    return Row(
      children: [
        Text("normal ", style: blendModeText),
        SizedBox(
          width: 35,
          child: ValueListenableBuilder(
            valueListenable: calculatedColors.alphaBlendColorPercent,
            builder: (_, value, ___) {
              if (value.isInfinite || value.isNaN || value == 0) {
                return Text(" - ");
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 1.3),
                child: Text(
                  "${(100.0 / value).floor()}%",
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 12),
                ),
              );
            },
          ),
        ),
        valueListeningColorBox(calculatedColors.terminalAlphaBlendColor),
      ],
    );
  }

  Widget _blendModeBoxes() {
    const double boxSpacing = 12;

    return ValueListenableBuilder(
      valueListenable: calculatedColors.startEndColorDifference,
      builder: (_, difference, __) {
        if (difference == ColorDifference.allDarkerOrEqual) {
          return Row(
            children: [
              _labeledListeningColorBox(
                  label: "multiply",
                  colorListenable: calculatedColors.multiplyColor),
              SizedBox(width: 1),
              ValueListenableBuilder(
                  valueListenable: calculatedColors.multiplyMinimumAlpha,
                  builder: (_, __, ___) {
                    final multiplyPercentText =
                        (calculatedColors.multiplyMinimumAlpha.value * 100)
                            .toStringAsFixed(0);

                    return _conditionalLabeledListeningColorBox(
                      label: "$multiplyPercentText%",
                      textSpace: 0,
                      colorListenable: calculatedColors.multiplyWithAlphaColor,
                      conditionListenable:
                          calculatedColors.canMultiplyWithAlpha,
                    );
                  }),
              SizedBox(width: boxSpacing),
              _labeledListeningColorBox(
                  label: "linear burn",
                  colorListenable: calculatedColors.linearBurnColor),
            ],
          );
        } else if (difference == ColorDifference.allLighterOrEqual) {
          return Row(
            spacing: boxSpacing,
            children: [
              _labeledListeningColorBox(
                  label: "screen",
                  colorListenable: calculatedColors.screenColor),
              _colorDodgeBox(),
              _labeledListeningColorBox(
                  label: "add", colorListenable: calculatedColors.addColor),
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
      valueListenable: calculatedColors.canColorDodge,
      builder: (_, __, ___) {
        return _labeledColorBox(
          label: "color dodge",
          strikethrough: !calculatedColors.canColorDodge.value,
          boxWidget: valueListeningColorBox(calculatedColors.dodgeColor),
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
    double? textSpace,
    required Widget boxWidget,
  }) {
    return Row(
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 0.5, right: textSpace ?? 2),
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
    double? textSpace,
    required String label,
    required ValueListenable<Color> colorListenable,
  }) {
    return _labeledColorBox(
      label: label,
      textSpace: textSpace,
      boxWidget: valueListeningColorBox(colorListenable),
    );
  }

  Widget _conditionalLabeledListeningColorBox({
    double? textSpace,
    required String label,
    required ValueListenable<Color> colorListenable,
    required ValueListenable<bool> conditionListenable,
  }) {
    return ValueListenableBuilder(
      valueListenable: conditionListenable,
      builder: (_, isConditionTrue, __) {
        if (isConditionTrue) {
          return _labeledListeningColorBox(
            label: label,
            textSpace: textSpace,
            colorListenable: colorListenable,
          );
        } else {
          return SizedBox.shrink();
        }
      },
    );
  }

  static const double bigColorBoxSize = 40;
  static const double colorBoxSize = 18;

  Widget _endColorBoxWidget() {
    return valueListeningColorBox(
      endColor,
      size: bigColorBoxSize,
      shape: BoxShape.circle,
    );
  }

  Widget _startColorBoxWidget() {
    return ValueListenableBuilder(
        valueListenable: isStartColorPicked,
        builder: (context, _, __) {
          if (isStartColorPicked.value == false) {
            return valueListeningColorBox(
              endColor,
              size: bigColorBoxSize,
              shape: BoxShape.circle,
            );
          }

          return ValueListenableBuilder(
            valueListenable: lastPickKey,
            builder: (_, __, ___) {
              return Animate(
                key: Key(lastPickKey.value),
                effects: const [Phanimations.startColorPulseEffect],
                child: valueListeningColorBox(
                  startColor,
                  size: bigColorBoxSize,
                  shape: BoxShape.circle,
                ),
              );
            },
          );
        });
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
    BoxShape shape = BoxShape.rectangle,
  }) {
    return ValueListenableBuilder(
      valueListenable: listenableColor,
      builder: (_, colorValue, __) {
        final isClipped =
            colorValue == Colors.white || colorValue == Colors.black;

        return _colorBox(
          colorValue,
          size: size,
          shape: shape,
          borderWidth: isClipped ? 3 : 1,
        );
      },
    );
  }

  Widget _colorBox(
    Color color, {
    double size = colorBoxSize,
    Color borderColor = Colors.white,
    BoxShape shape = BoxShape.rectangle,
    double borderWidth = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Material(
        elevation: 1,
        shape: shape == BoxShape.circle
            ? CircleBorder()
            : RoundedRectangleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
              shape: shape,
              color: color,
              border: Border.all(
                color: borderColor,
                width: borderWidth,
              )),
        ),
      ),
    );
  }

  void handleEscape() {
    if (isStartColorPicked.value == true) {
      _resetState();
      overlays.removeOverlays();

      initColorPickPositionOverlays();
      return;
    }

    widget.model.endColorMeter();
    ModalDismissContext.of(context)?.onDismiss?.call();
  }

  void _resetState() {
    isStartColorPicked.value = false;
    isEndColorPicked.value = false;
    startColor.value = Colors.transparent;
    endColor.value = Colors.transparent;
  }

  void _onWindowChanged() {
    overlays.removeOverlays();
  }
}

class HslChangeIcon extends StatelessWidget {
  const HslChangeIcon(
      {super.key,
      required this.value,
      required this.cutoff,
      required this.decrease,
      required this.increase,
      this.extraRightPadding = 0});

  final double value;
  final double cutoff;
  final IconData decrease;
  final IconData increase;
  final double extraRightPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 3, right: 1 + extraRightPadding),
      child: value == cutoff
          ? SizedBox(width: 14)
          : Icon(
              value > cutoff ? increase : decrease,
              size: 14,
              color: Color.from(alpha: 0.45, red: 0.5, green: 0.5, blue: 0.5),
            ),
    );
  }
}

enum ColorDifference {
  allLighterOrEqual,
  allDarkerOrEqual,
  same,
  mixed,
  invalid,
}

class CalculatedColors {
  late final startEndColorDifference = ValueNotifier(ColorDifference.mixed);

  late final multiplyColor = ValueNotifier(Colors.white);
  late final dodgeColor = ValueNotifier(Colors.black);
  late final linearBurnColor = ValueNotifier(Colors.white);
  late final multiplyWithAlphaColor = ValueNotifier(Colors.white);
  late final multiplyMinimumAlpha = ValueNotifier(0.0);

  late final canColorDodge = ValueNotifier(false);
  late final canMultiplyWithAlpha = ValueNotifier(false);

  late final addColor = ValueNotifier(Colors.black);
  late final screenColor = ValueNotifier(Colors.black);

  late final terminalAlphaBlendColor = ValueNotifier(Colors.white);
  late final alphaBlendColorPercent = ValueNotifier(0.0);

  void updateColors(Color start, Color end) {
    _updateColorDifference(start, end);
    _updateTerminalColor(start, end);
    _updateBlendModeColors(start, end);
  }

  void _updateColorDifference(Color start, Color end) {
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

  void _updateBlendModeColors(Color start, Color end) {
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

        double findAlphaWithMultiply(
            double start, double end, double multiply) {
          if (start == end) return 0;
          if (start <= 0) return double.negativeInfinity;
          if (multiply == 1) return double.infinity;

          // Find the alpha required to reach this.
          return (end - start) / (start * (multiply - 1.0));
        }

        final azmr = findAlphaWithMultiply(r1, r2, 0);
        final azmg = findAlphaWithMultiply(g1, g2, 0);
        final azmb = findAlphaWithMultiply(b1, b2, 0);
        double maxIfAlphaValid(double previous, double candidate) {
          if (candidate.isFinite && candidate > 0 && candidate < 1) {
            return math.max(previous, candidate);
          } else {
            return previous;
          }
        }

        double minimumValidAlpha = 0;
        minimumValidAlpha = maxIfAlphaValid(minimumValidAlpha, azmr);
        minimumValidAlpha = maxIfAlphaValid(minimumValidAlpha, azmg);
        minimumValidAlpha = maxIfAlphaValid(minimumValidAlpha, azmb);

        double inverseMultiplyWithAlpha(
          double start,
          double end,
          double alpha,
        ) {
          if (start == 0) return 0;
          if (alpha == 0) return start;

          return (end - ((1 - alpha) * start)) / (alpha * start);
        }

        if (minimumValidAlpha < 1) {
          final opacity = minimumValidAlpha;
          final double mhr = inverseMultiplyWithAlpha(r1, r2, opacity);
          final double mhg = inverseMultiplyWithAlpha(g1, g2, opacity);
          final double mhb = inverseMultiplyWithAlpha(b1, b2, opacity);

          canMultiplyWithAlpha.value = true;
          multiplyMinimumAlpha.value = opacity;
          multiplyWithAlphaColor.value = Color.from(
            alpha: 1,
            red: mhr,
            green: mhg,
            blue: mhb,
          );
        } else {
          canMultiplyWithAlpha.value = false;
        }

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

      default:
        multiplyColor.value = Colors.transparent;
        return;
    }
  }

  void _updateTerminalColor(Color start, Color end) {
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

    final tr = r1 + svr;
    final tg = g1 + svg;
    final tb = b1 + svb;

    final outputColor = Color.from(alpha: 1.0, red: tr, green: tg, blue: tb);

    terminalAlphaBlendColor.value = outputColor;
    alphaBlendColorPercent.value = vectorScaleToEdge;
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
}

class ColorMeterOverlays {
  OverlayEntry? startColorLocation;
  OverlayEntry? endColorLocation;
  OverlayEntry? arrow;
  late final startEndArrowColor = ValueNotifier(Colors.red);

  void tryInitialize(
    BuildContext? context, {
    required ValueListenable<Offset> startPosition,
    required ValueListenable<Offset> endPosition,
    required ValueListenable<Color> startColor,
    required ValueListenable<Color> endColor,
    required ValueListenable<bool> isStartColorSelected,
  }) {
    if (context == null) return;
    if (context.mounted == false) return;

    final overlayOfContext = Overlay.of(context);
    if (overlayOfContext.mounted == false) return;

    if (startColorLocation == null) {
      startColorLocation = OverlayEntry(
        builder: (context) {
          return ColorSampleLocationOverlay(
            position: startPosition,
            color: startColor,
            isVisible: isStartColorSelected,
          );
        },
      );

      if (endColorLocation == null) {
        endColorLocation = OverlayEntry(
          builder: (context) {
            return ColorSampleLocationOverlay(
              position: endPosition,
              color: endColor,
            );
          },
        );

        arrow = OverlayEntry(
          builder: (context) {
            return StartEndArrowOverlay(
              startPosition: startPosition,
              endPosition: endPosition,
              color: startEndArrowColor,
              isVisible: isStartColorSelected,
            );
          },
        );

        overlayOfContext.insert(endColorLocation!);
        overlayOfContext.insert(arrow!);
      }

      overlayOfContext.insert(startColorLocation!);
    }
  }

  void setPointerOverlayActive(bool active, BuildContext? context) {
    if (context == null) return;
    if (context.mounted == false) return;

    if (active) {
      final overlayOfContext = Overlay.of(context);
      if (overlayOfContext.mounted == false) return;

      if (endColorLocation != null && endColorLocation!.mounted == false) {
        overlayOfContext.insert(endColorLocation!);
      }

      if (arrow != null && arrow!.mounted == false) {
        overlayOfContext.insert(arrow!);
      }
    } else {
      if (endColorLocation != null && endColorLocation!.mounted) {
        endColorLocation!.remove();
      }

      if (arrow != null && arrow!.mounted) {
        arrow!.remove();
      }
    }
  }

  void removeOverlays() {
    startColorLocation?.remove();
    startColorLocation = null;

    if (endColorLocation != null) {
      if (endColorLocation!.mounted) {
        endColorLocation?.remove();
      }
      endColorLocation = null;
    }

    if (arrow != null) {
      if (arrow!.mounted) {
        arrow?.remove();
      }

      arrow = null;
    }
  }
}

class ColorSampleLocationOverlay extends StatelessWidget {
  const ColorSampleLocationOverlay({
    super.key,
    required this.position,
    required this.color,
    this.isVisible,
    this.radius = 7,
  });

  final ValueListenable<Offset> position;
  final ValueListenable<Color> color;
  final ValueListenable<bool>? isVisible;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final widget = ValueListenableBuilder(
      valueListenable: color,
      builder: (_, __, ___) {
        return ValueListenableBuilder(
          valueListenable: position,
          builder: (_, __, ___) {
            return Positioned(
              left: position.value.dx,
              top: position.value.dy,
              child: CustomPaint(
                foregroundPainter: ColorSampleLocationMarkerPainter(
                  color: color.value,
                  radius: radius,
                ),
                size: Size(radius * 2, radius * 2),
              ),
            );
          },
        );
      },
    );

    if (isVisible != null) {
      return ValueListenableBuilder(
        valueListenable: isVisible!,
        builder: (context, value, child) {
          return value ? widget : SizedBox.shrink();
        },
      );
    }

    return widget;
  }
}

class ColorSampleLocationMarkerPainter extends CustomPainter {
  ColorSampleLocationMarkerPainter({
    super.repaint,
    required this.color,
    this.radius = 7,
  });

  final Color color;
  final double radius;

  static const double strokeWidth = 1;

  static final darkStroke = Paint()
    ..color = Colors.black
    ..strokeWidth = strokeWidth
    ..style = PaintingStyle.stroke;

  static final lightStroke = Paint()
    ..color = Colors.white
    ..strokeWidth = strokeWidth
    ..style = PaintingStyle.stroke;

  static final redStroke = Paint()
    ..color = Colors.red
    ..strokeWidth = strokeWidth
    ..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final isClipped = color == Colors.white || color == Colors.black;
    final isDark = color.lightness < 0.5;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final stroke = isClipped
        ? redStroke
        : isDark
            ? lightStroke
            : darkStroke;

    canvas.drawCircle(Offset.zero, radius, fill);
    canvas.drawCircle(Offset.zero, radius, stroke);
  }

  @override
  bool shouldRepaint(ColorSampleLocationMarkerPainter oldPainter) {
    return oldPainter.color != color;
  }
}

class StartEndArrowOverlay extends StatelessWidget {
  final ValueListenable<Offset> startPosition;
  final ValueListenable<Offset> endPosition;
  final ValueListenable<Color> color;
  final ValueListenable<bool>? isVisible;

  const StartEndArrowOverlay({
    super.key,
    required this.startPosition,
    required this.endPosition,
    required this.color,
    this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    //const double canvasPadding = 15;
    final start = startPosition.value;
    final end = endPosition.value;

    final minX = math.min(start.dx, end.dx);
    final minY = math.min(start.dy, end.dy);
    final min = Offset(minX, minY);

    final width = (start.dx - end.dx).abs();
    final height = (start.dy - end.dy).abs();

    final widget = ValueListenableBuilder(
      valueListenable: startPosition,
      builder: (_, __, ___) {
        return ValueListenableBuilder(
          valueListenable: endPosition,
          builder: (_, __, ___) {
            return Positioned(
              left: minX,
              top: minY,
              child: CustomPaint(
                foregroundPainter: StartEndArrowPainter(
                  color: color.value,
                  startPosition: startPosition.value - min,
                  endPosition: endPosition.value - min,
                ),
                size: Size(width, height),
              ),
            );
          },
        );
      },
    );

    if (isVisible != null) {
      return ValueListenableBuilder(
        valueListenable: isVisible!,
        builder: (context, value, child) => value ? widget : SizedBox.shrink(),
      );
    }

    return widget;
  }
}

class StartEndArrowPainter extends CustomPainter {
  final Color color;
  final Offset startPosition;
  final Offset endPosition;
  static const double radius = 20;
  static const double minimumDistance = 15;
  static const double arrowHeadSize = 15;

  StartEndArrowPainter({
    super.repaint,
    required this.color,
    required this.startPosition,
    required this.endPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final arrowStroke = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final arrowFill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final vo = (endPosition - startPosition);
    final vector = Vector2(vo.dx, vo.dy);
    final direction = vector.normalized();

    final length = vector.length;
    if (length < minimumDistance) return;

    final start = Vector2(startPosition.dx, startPosition.dy);
    final end = Vector2(endPosition.dx, endPosition.dy);

    final radiusOffset = direction.scaled(radius * 0.5);

    final drawnStart = start + radiusOffset;
    final drawnEnd = end - radiusOffset;

    final lineTipShorten = direction * arrowHeadSize * 0.5;
    final lineTip = drawnEnd - lineTipShorten;

    // Draw arrow shaft
    canvas.drawLine(
      Offset(drawnStart.x, drawnStart.y),
      Offset(lineTip.x, lineTip.y),
      arrowStroke,
    );

    final drawnLength = length - (radius * 0.9);
    final headSize =
        arrowHeadSize > drawnLength ? drawnLength + 2 : arrowHeadSize;
    if (headSize < 2) return;

    const triangleAngle = math.pi / 6;
    final lineAngle = math.atan2(vector.y, vector.x);

    final a2 = drawnEnd -
        Vector2(
          headSize * math.cos(lineAngle - triangleAngle),
          headSize * math.sin(lineAngle - triangleAngle),
        );

    final a3 = drawnEnd -
        Vector2(
          headSize * math.cos(lineAngle + triangleAngle),
          headSize * math.sin(lineAngle + triangleAngle),
        );

    final arrowHead = Path()
      ..moveTo(drawnEnd.x, drawnEnd.y)
      ..lineTo(a2.x, a2.y)
      ..lineTo(a3.x, a3.y)
      ..close();

    // Draw filled arrowhead
    canvas.drawPath(arrowHead, arrowFill);
  }

  @override
  bool shouldRepaint(StartEndArrowPainter oldPainter) {
    return oldPainter.color != color ||
        oldPainter.startPosition != startPosition ||
        oldPainter.endPosition != endPosition;
  }
}
