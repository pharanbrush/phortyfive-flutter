import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';

final buttonColorsOnLight = WindowButtonColors(
  mouseOver: Colors.grey.withAlpha(0x55),
  mouseDown: Colors.grey.withAlpha(0xCC),
  iconNormal: Colors.black,
  iconMouseOver: const Color(0xFF1C1B17),
  iconMouseDown: const Color(0xFF1C1B17),
);

final buttonColorsOnDark = WindowButtonColors(
  mouseOver: Colors.grey.withAlpha(0x55),
  mouseDown: Colors.grey.withAlpha(0xCC),
  iconNormal: Colors.white70,
  iconMouseOver: Colors.white70,
  iconMouseDown: Colors.white70,
);

final closeButtonColorsOnLight = WindowButtonColors(
  mouseOver: const Color(0xFFF23F42),
  mouseDown: const Color(0xFFF16F7A),
  iconNormal: const Color(0xFF1C1B17),
  iconMouseOver: Colors.white,
);

final closeButtonColorsOnDark = WindowButtonColors(
  mouseOver: const Color(0xFFF23F42),
  mouseDown: const Color(0xFFF16F7A),
  iconNormal: Colors.white70,
  iconMouseOver: Colors.white,
);
