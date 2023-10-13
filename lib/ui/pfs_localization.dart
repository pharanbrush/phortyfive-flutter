import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PfsLocalization {
  static const bool isDesktop = true;
  static const String version = '0.5.20231012a';

  static const String alwaysOnTop = 'Keep window on top';
  static const String help = 'Help...';
  static const String revealInExplorer = 'Show in Explorer';

  static const String press = isDesktop ? 'click' : 'tap';

  static String get pressCapital => capitalizeFirst(press);
  
  static const String secondaryPressCapital = isDesktop ? 'Right-click' : 'Long-press';

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
}
