import 'package:flutter/foundation.dart';
import 'package:macos_window_utils/macos/ns_window_delegate.dart';
import 'package:macos_window_utils/window_manipulator.dart';

final windowEventDelegate = _PfsMacWindowDelegate();
final isWindowFullscreen = ValueNotifier(false);

Future bindWindowDelegate () async {
  await WindowManipulator.initialize(enableWindowDelegate: true);
  WindowManipulator.addNSWindowDelegate(windowEventDelegate);
}

Future<void> tryExitFullScreen () async {
  if (isWindowFullscreen.value == false) return;
  return await WindowManipulator.exitFullscreen();
}

class _PfsMacWindowDelegate extends NSWindowDelegate {
  @override
  void windowDidEnterFullScreen() {
    isWindowFullscreen.value = true;
    super.windowDidEnterFullScreen();
  }

  @override
  void windowDidExitFullScreen() {
    isWindowFullscreen.value = false;
    super.windowDidExitFullScreen();
  }
}