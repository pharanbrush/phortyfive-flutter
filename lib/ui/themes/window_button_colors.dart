import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';

final buttonColorsOnLight = WindowButtonColors(
  mouseOver: Colors.grey.withAlpha(0x55),
  mouseDown: Colors.grey.withAlpha(0xCC),
  iconNormal: Colors.black,
  iconMouseOver: Colors.black,
  iconMouseDown: Colors.black,
);

final buttonColorsOnDark = WindowButtonColors(
  mouseOver: Colors.grey.withAlpha(0x55),
  mouseDown: Colors.grey.withAlpha(0xCC),
  iconNormal: Colors.white70,
  iconMouseOver: Colors.white70,
  iconMouseDown: Colors.white70,
);

final closeButtonColorsOnLight = WindowButtonColors(
  mouseOver: const Color(0xFFD32F2F),
  mouseDown: const Color(0xFFB71C1C),
  iconNormal: Colors.black,
  iconMouseOver: Colors.white,
);

final closeButtonColorsOnDark = WindowButtonColors(
  mouseOver: const Color(0xFFD32F2F),
  mouseDown: const Color(0xFFB71C1C),
  iconNormal: Colors.white70,
  iconMouseOver: Colors.white,
);
