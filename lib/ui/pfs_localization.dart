import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PfsLocalization {
  static const bool isDesktop = true;
  static const String version = '0.9.20250710a';

  static const String alwaysOnTop = 'Keep window on top';
  static const String help = 'Help...';
  static const String revealInExplorer = 'Reveal file in Explorer';
  static const String copyFilePath = 'Copy file path';
  static const String copyImageToClipboard = 'Copy Image';

  static const String timerPlaying = 'Timer running';
  static const String timerPaused = 'Timer paused';

  static const String timer = 'Timer';

  static String timerSwitched(bool enabled) =>
      enabled ? '$timer running' : '$timer paused';

  static String alwaysOnTopSwitched(bool enabled) =>
      enabled ? '"$alwaysOnTop" enabled' : '"$alwaysOnTop" disabled';

  static String soundsSwitched(bool enabled) =>
      enabled ? 'Sounds enabled' : 'Sounds disabled';

  static const String press = isDesktop ? 'click' : 'tap';

  static String get pressCapital => capitalizeFirst(press);

  static const String secondaryPressCapital =
      isDesktop ? 'Right-click' : 'Long-press';

  static String imageNoun(int count) {
    return count == 1 ? 'image' : 'images';
  }

  static String fileNoun(int count) {
    return count == 1 ? 'file' : 'files';
  }

  static String capitalizeFirst(String s) {
    return GetUtils.capitalizeFirst(s)!;
  }

  static String tooltipShortcut(SingleActivator shortcut) {
    var keyString = shortcut.trigger.keyLabel;
    return '${shortcut.control ? 'Ctrl+' : ''}${shortcut.shift ? 'Shift+' : ''}$keyString';
  }

  static String buttonTooltip({
    required String commandName,
    required SingleActivator shortcut,
  }) {
    return '$commandName (${tooltipShortcut(shortcut)})';
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
