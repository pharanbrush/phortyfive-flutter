import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Phshortcuts {
  static const previous = SingleActivator(LogicalKeyboardKey.arrowLeft);
  static const next = SingleActivator(LogicalKeyboardKey.arrowRight);

  static const previous2 = SingleActivator(LogicalKeyboardKey.keyK);
  static const next2 = SingleActivator(LogicalKeyboardKey.keyJ);

  static const previous3 = SingleActivator(LogicalKeyboardKey.keyA);
  static const next3 = SingleActivator(LogicalKeyboardKey.keyD);

  static const previous4 = SingleActivator(LogicalKeyboardKey.period);
  static const next4 = SingleActivator(LogicalKeyboardKey.comma);

  static const playPause = SingleActivator(LogicalKeyboardKey.keyP);
  static const restartTimer = SingleActivator(LogicalKeyboardKey.keyR);
  static const openTimerMenu = SingleActivator(LogicalKeyboardKey.f2);

  static const openFiles =
      SingleActivator(LogicalKeyboardKey.keyO, control: true);
  static const alwaysOnTop =
      SingleActivator(LogicalKeyboardKey.keyT, control: true);

  static const toggleSounds = SingleActivator(LogicalKeyboardKey.keyM);
  static const toggleBottomBar = SingleActivator(LogicalKeyboardKey.keyH);
  static const help = SingleActivator(LogicalKeyboardKey.f1);

  static const returnHome = SingleActivator(LogicalKeyboardKey.escape);

  static const intentMap = <ShortcutActivator, Intent>{
    Phshortcuts.openFiles: OpenFilesIntent(),
    Phshortcuts.previous: PreviousImageIntent(),
    Phshortcuts.next: NextImageIntent(),
    Phshortcuts.previous2: PreviousImageIntent(),
    Phshortcuts.next2: NextImageIntent(),
    Phshortcuts.previous3: PreviousImageIntent(),
    Phshortcuts.next3: NextImageIntent(),
    Phshortcuts.previous4: PreviousImageIntent(),
    Phshortcuts.next4: NextImageIntent(),
    Phshortcuts.playPause: PlayPauseIntent(),
    Phshortcuts.openTimerMenu: OpenTimerMenuIntent(),
    Phshortcuts.restartTimer: RestartTimerIntent(),
    Phshortcuts.help: HelpIntent(),
    Phshortcuts.toggleBottomBar: BottomBarToggleIntent(),
    Phshortcuts.alwaysOnTop: AlwaysOnTopIntent(),
    Phshortcuts.toggleSounds: ToggleSoundIntent(),
    Phshortcuts.returnHome: ReturnHomeIntent(),
  };
}

class ReturnHomeIntent extends Intent {
  const ReturnHomeIntent();
}

class ToggleSoundIntent extends Intent {
  const ToggleSoundIntent();
}

class NextImageIntent extends Intent {
  const NextImageIntent();
}

class PreviousImageIntent extends Intent {
  const PreviousImageIntent();
}

class PlayPauseIntent extends Intent {
  const PlayPauseIntent();
}

class RestartTimerIntent extends Intent {
  const RestartTimerIntent();
}

class OpenFilesIntent extends Intent {
  const OpenFilesIntent();
}

class HelpIntent extends Intent {
  const HelpIntent();
}

class OpenTimerMenuIntent extends Intent {
  const OpenTimerMenuIntent();
}

class BottomBarToggleIntent extends Intent {
  const BottomBarToggleIntent();
}

class AlwaysOnTopIntent extends Intent {
  const AlwaysOnTopIntent();
}
