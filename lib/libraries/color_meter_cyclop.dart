// Heavily modified code from Cyclop by RX Labz

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

import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;

final captureKey = GlobalKey();

class EyeDropperModel {
  /// based on PointerEvent.kind
  bool isTouchInterface = false;
  bool isEnabled = false;

  img.Image? snapshot;
  Offset? cursorPosition;
  int lastButtonDown = -1;

  Color hoverColor = Colors.black;
  List<Color> hoverColors = [];

  ValueChanged<Color>? onColorSelected;
  ValueChanged<Color>? onColorChanged;
  ValueChanged<Offset>? onColorPositionSelected;
  ValueChanged<Offset>? onColorPositionHover;
  void Function()? onPointerExit;
  void Function()? onPointerEnter;
  void Function()? onWindowChanged;
  void Function()? onSecondaryTap;
}

class LoupeModel {
  OverlayEntry? overlayEntry;
  OverlayState? overlayOfContext;

  void setContext(BuildContext context) {
    if (context.mounted == false) return;
    overlayOfContext = Overlay.of(context);
  }

  void update() {
    if (overlayEntry == null) return;
    overlayEntry!.markNeedsBuild();
  }

  void setActive(
    bool active, {
    required bool isTouchInterface,
    required Offset? cursorPosition,
    required List<Color> hoverColors,
  }) {
    switch (active) {
      case true:
        if (overlayEntry != null) return;
        if (overlayOfContext == null) return;

        overlayEntry = OverlayEntry(
          builder: (_) => LoupeView(
            isTouchInterface: isTouchInterface,
            colors: hoverColors,
            cursorPosition: cursorPosition,
          ),
        );

        overlayOfContext?.insert(overlayEntry!);
      case false:
        if (overlayEntry == null) return;

        try {
          final loupeOverlayEntry = overlayEntry;
          overlayEntry = null;
          loupeOverlayEntry!.remove();
        } catch (err) {
          debugPrint('ERROR !!! setActive $err');
        }
    }
  }
}

/// Originally EyeDrop
class EyeDropperLayer extends StatelessWidget with WidgetsBindingObserver {
  EyeDropperLayer({required this.child, super.key});

  static EyeDropperModel model = EyeDropperModel();
  static LoupeModel loupeModel = LoupeModel();
  final Widget child;

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    model.onWindowChanged?.call();

    const safeUpdateDelayDuration = Duration(milliseconds: 100);
    Future.delayed(
      safeUpdateDelayDuration,
      () => updateCapturedRegion(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: captureKey,
      child: MouseRegion(
        onExit: (event) {
          model.onPointerExit?.call();
        },
        onEnter: (event) {
          model.onPointerEnter?.call();
        },
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
            if (!model.isEnabled) return;

            model.lastButtonDown = details.buttons;
            if (details.buttons == kSecondaryButton) {
              model.onSecondaryTap?.call();
            }
          },
          onPointerUp: (PointerUpEvent details) {
            if (model.lastButtonDown == kPrimaryButton) {
              _onPrimaryTapUp(details.position);
            }

            model.lastButtonDown = -1;
          },
          child: child,
        ),
      ),
    );
  }

  void _onPrimaryTapUp(Offset position) {
    if (!model.isEnabled) return;

    _onHover(position, model.isTouchInterface);
    final onColorSelected = model.onColorSelected;
    //onColorSelected?.call(model.hoverColors.center);
    onColorSelected?.call(model.hoverColor);

    final updatePosition = model.onColorPositionSelected;
    updatePosition?.call(position);
  }

  void _onHover(Offset offset, bool isTouchInterface) {
    if (!model.isEnabled) return;

    loupeModel.update();

    model.cursorPosition = offset;

    model.isTouchInterface = isTouchInterface;

    if (model.snapshot != null) {
      model.hoverColor = getPixelColor(model.snapshot!, offset);
      _updateHoverColors(offset);
    }

    final onColorChanged = model.onColorChanged;
    onColorChanged?.call(model.hoverColor);

    final onColorPositionHover = model.onColorPositionHover;
    onColorPositionHover?.call(offset);
  }

  void _updateHoverColors(Offset offset) {
    if (model.snapshot == null) return;

    model.hoverColors = getPixelColors(model.snapshot!, offset);
  }

  void startEyeDropper(
    BuildContext context, {
    required ValueChanged<Color> onColorSelected,
    ValueChanged<Color>? onColorChanged,
    ValueChanged<Offset>? onColorPositionSelected,
    ValueChanged<Offset>? onColorPositionHover,
    void Function()? onWindowChanged,
    void Function()? onPointerExit,
    void Function()? onPointerEnter,
    void Function()? onSecondaryTap,
  }) async {
    loupeModel.setContext(context);

    await updateCapturedRegion();

    model.isEnabled = true;
    if (model.snapshot == null) return;

    model.onPointerExit = onPointerExit;
    model.onPointerEnter = onPointerEnter;

    model.onWindowChanged = onWindowChanged;
    model.onColorSelected = onColorSelected;
    model.onColorChanged = onColorChanged;
    model.onSecondaryTap = onSecondaryTap;
    model.onColorPositionSelected = onColorPositionSelected;
    model.onColorPositionHover = onColorPositionHover;

    WidgetsBinding.instance.addObserver(this);
  }

  void stopEyeDropper() {
    model.isEnabled = false;
    WidgetsBinding.instance.removeObserver(this);

    model.onColorSelected = null;
    model.onColorChanged = null;
    model.onSecondaryTap = null;
    model.onColorPositionSelected = null;
    model.onColorPositionHover = null;
    model.onWindowChanged = null;

    setLoupeActive(false);
  }

  void setLoupeActive(bool active) {
    if (!model.isEnabled) return;

    loupeModel.setActive(
      active,
      isTouchInterface: model.isTouchInterface,
      cursorPosition: model.cursorPosition,
      hoverColors: model.hoverColors,
    );
  }

  Future<void> updateCapturedRegion() async {
    final renderer =
        captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

    if (renderer == null) return;

    model.snapshot = await repaintBoundaryToImage(renderer);
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

class LoupeView extends StatelessWidget {
  final Offset? cursorPosition;
  final bool isTouchInterface;

  final List<Color> colors;

  const LoupeView({
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
