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

import 'dart:ui';

import 'package:cyclop/cyclop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;

class ColorLoupe {
  final ValueChanged<Color> onColorClicked;
  final ValueChanged<Color> onColorHover;

  ColorLoupe({
    required this.onColorClicked,
    required this.onColorHover,
  });

  Color color = Colors.white;

  void showOverlay(BuildContext context) {
    try {
      EyeDrop.of(context).capture(
        context,
        _handleOnColorClicked,
        _handleOnColorHover,
      );
    } catch (err) {
      debugPrint('ERROR !!! showOverlay $err');
    }
  }

  void endOverlay() {
    EyeDrop.endEyeDrop();
  }

  void _handleOnColorHover(Color value) {
    onColorHover(value);
  }

  void _handleOnColorClicked(Color value) {
    color = value;
    onColorClicked(value);
  }
}

final captureKey = GlobalKey();

class EyeDropperModel {
  /// based on PointerEvent.kind
  bool touchable = false;

  OverlayEntry? eyeOverlayEntry;

  img.Image? snapshot;

  Offset? cursorPosition;

  Color hoverColor = Colors.black;

  List<Color> hoverColors = [];

  Color selectedColor = Colors.black;

  ValueChanged<Color>? onColorSelected;

  ValueChanged<Color>? onColorChanged;

  EyeDropperModel();
}

class EyeDrop extends InheritedWidget {
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
              onPointerUp: (details) => _onPointerUp(details.position),
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

  static void _onPointerUp(Offset position) {
    _onHover(position, data.touchable);
    if (data.onColorSelected != null) {
      data.onColorSelected!(data.hoverColors.center);
    }

    //endEyeDrop();
  }

  static void endEyeDrop() {
    if (data.eyeOverlayEntry != null) {
      try {
        data.eyeOverlayEntry!.remove();
        data.eyeOverlayEntry = null;
        data.onColorSelected = null;
        data.onColorChanged = null;
      } catch (err) {
        debugPrint('ERROR !!! _onPointerUp $err');
      }
    }
  }

  static void _onHover(Offset offset, bool touchable) {
    if (data.eyeOverlayEntry != null) data.eyeOverlayEntry!.markNeedsBuild();

    data.cursorPosition = offset;

    data.touchable = touchable;

    if (data.snapshot != null) {
      data.hoverColor = getPixelColor(data.snapshot!, offset);
      data.hoverColors = getPixelColors(data.snapshot!, offset);
    }

    if (data.onColorChanged != null) {
      data.onColorChanged!(data.hoverColors.center);
    }
  }

  void capture(
    BuildContext context,
    ValueChanged<Color> onColorSelected,
    ValueChanged<Color>? onColorChanged,
  ) async {
    final renderer =
        captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

    if (renderer == null) return;

    data.onColorSelected = onColorSelected;
    data.onColorChanged = onColorChanged;

    data.snapshot = await repaintBoundaryToImage(renderer);

    if (data.snapshot == null) return;

    data.eyeOverlayEntry = OverlayEntry(
      builder: (_) => EyeDropOverlay(
        touchable: data.touchable,
        colors: data.hoverColors,
        cursorPosition: data.cursorPosition,
      ),
    );

    if (context.mounted) {
      Overlay.of(context).insert(data.eyeOverlayEntry!);
    }
  }

  @override
  bool updateShouldNotify(EyeDrop oldWidget) {
    return true;
  }
}
