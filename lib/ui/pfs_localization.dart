import 'package:flutter/material.dart';

class PfsLocalization {
  static const String version = '0.5.20231012a';
  
  static const String alwaysOnTop = 'Keep window on top';
  static const String help = 'Help...';

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
