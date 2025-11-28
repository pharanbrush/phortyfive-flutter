import 'dart:io';

import 'package:flutter/material.dart';

extension CapitalizeExtension on String {
  String capitalizeFirst() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

extension ShortenExtension on String {
  String shortenWithEllipsis(int maxLength) {
    if (length <= maxLength) {
      return this;
    }
    return "${substring(0, maxLength)}...";
  }
}

String shortenFolderPath(String folderPath) {
  final separator = Platform.pathSeparator;
  final split = folderPath.split(separator);
  final splitLength = split.length;
  if (splitLength <= 4) {
    return folderPath;
  }

  final candidateFolderPath =
      "${split.first}$separator...$separator${split[splitLength - 2]}$separator${split.last}";
  if (candidateFolderPath.length > 50) {
    return "${split.first}$separator...$separator${split.last}";
  }

  return candidateFolderPath;
}

class PfsLocalization {
  static const appTitle = "Phorty-Five Seconds";
  static const bool isDesktop = true;
  static const String version = '0.9.20251125c';

  static const String alwaysOnTop = "Keep window on top";
  static const String shortcutHelp = "Shortcut help...";
  static const String revealInExplorer = "Reveal file in Explorer";
  static const String copyFilePath = "Copy file path";
  static const String copyImageToClipboard = "Copy Image";
  static const String copyFileName = "Copy filename";

  static const String timerPlaying = "Timer running";
  static const String timerPaused = "Timer paused";

  static const String openColorChangeMeter = "Open color change meter";
  static const String colorChangeMeter = "Color change meter";
  static const String clickForColorComponents =
      'Click to toggle color components.';

  static const String clickImageToPickStartingColor =
      "Click on the image to pick the starting color.";
  static const String rightClickToExitColorMeter =
      "Right-click to exit color change meter.";

  static const String normal = "normal";
  static const String multiply = "multiply";
  static const String screen = "screen";
  static const String colorDodge = "color dodge";
  static const String add = "add";
  static const String linearBurn = "linear burn";

  static const String startColorLabel = "start";
  static const String endColorLabel = "end";

  static const String timer = 'Timer';

  static String timerSwitched(bool enabled) =>
      enabled ? '$timer running' : '$timer paused';

  static String alwaysOnTopSwitched(bool enabled) =>
      enabled ? '"$alwaysOnTop" enabled' : '"$alwaysOnTop" disabled';

  static String soundsSwitched(bool enabled) =>
      enabled ? "Sounds enabled" : "Sounds muted";

  static const String press = isDesktop ? "click" : "tap";

  static String get pressCapital => press.capitalizeFirst();

  static const String secondaryPressCapital =
      isDesktop ? "Right-click" : "Long-press";

  static String imageNoun(int count) {
    return count == 1 ? "image" : "images";
  }

  static String fileNoun(int count) {
    return count == 1 ? "file" : "files";
  }

  static String tooltipShortcut(SingleActivator shortcut) {
    final keyString = shortcut.trigger.keyLabel;
    return "${shortcut.control ? "Ctrl+" : ""}${shortcut.shift ? "Shift+" : ""}$keyString";
  }

  static String buttonTooltip({
    required String commandName,
    required SingleActivator shortcut,
  }) {
    return "$commandName (${tooltipShortcut(shortcut)})";
  }

  static Text textWithMultiBold(
      {required String text1,
      String? boldText1,
      String? text2,
      String? boldText2,
      String? text3}) {
    return Text.rich(
      TextSpan(
        text: text1,
        children: [
          TextSpan(
              text: boldText1,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: text2),
        ],
      ),
    );
  }
}
