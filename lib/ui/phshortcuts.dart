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

  static const previous5 = SingleActivator(LogicalKeyboardKey.navigatePrevious);
  static const next5 = SingleActivator(LogicalKeyboardKey.navigateNext);

  static const playPause = SingleActivator(LogicalKeyboardKey.keyP);
  static const restartTimer = SingleActivator(LogicalKeyboardKey.keyR);
  static const openTimerMenu = SingleActivator(LogicalKeyboardKey.f2);

  static const zoomIn = SingleActivator(LogicalKeyboardKey.equal);
  static const zoomOut = SingleActivator(LogicalKeyboardKey.minus);
  static const zoomReset = SingleActivator(LogicalKeyboardKey.digit0);

  static const toggleAnnotation = SingleActivator(LogicalKeyboardKey.keyN);
  static const clearAnnotations = SingleActivator(LogicalKeyboardKey.backspace);
  static const cycleAnnotationColors = SingleActivator(LogicalKeyboardKey.keyC);

  static const undo = SingleActivator(LogicalKeyboardKey.keyZ, control: true);

  static const flipHorizontal = SingleActivator(LogicalKeyboardKey.keyH);
  static const zoomInNumpad = SingleActivator(LogicalKeyboardKey.numpadAdd);
  static const zoomOutNumpad =
      SingleActivator(LogicalKeyboardKey.numpadSubtract);
  static const zoomResetNav = SingleActivator(LogicalKeyboardKey.insert);

  static const zoomInArrow = SingleActivator(LogicalKeyboardKey.arrowUp);
  static const zoomOutArrow = SingleActivator(LogicalKeyboardKey.arrowDown);

  static const openFiles =
      SingleActivator(LogicalKeyboardKey.keyO, control: true);
  static const openFolder =
      SingleActivator(LogicalKeyboardKey.keyO, control: true, shift: true);
  static const alwaysOnTop =
      SingleActivator(LogicalKeyboardKey.keyT, control: true);

  static const revealInExplorer =
      SingleActivator(LogicalKeyboardKey.enter, shift: true);

  static const preferences =
      SingleActivator(LogicalKeyboardKey.comma, control: true);

  static const toggleSounds = SingleActivator(LogicalKeyboardKey.keyM);
  static const toggleBottomBar = SingleActivator(LogicalKeyboardKey.keyH, control: true);
  static const help = SingleActivator(LogicalKeyboardKey.f1);

  static const returnHome = SingleActivator(LogicalKeyboardKey.escape);

  static const intentMap = <ShortcutActivator, Intent>{
    Phshortcuts.openFiles: OpenFilesIntent(),
    Phshortcuts.openFolder: OpenFolderIntent(),
    Phshortcuts.previous: PreviousImageIntent(),
    Phshortcuts.next: NextImageIntent(),
    Phshortcuts.previous2: PreviousImageIntent(),
    Phshortcuts.next2: NextImageIntent(),
    Phshortcuts.previous3: PreviousImageIntent(),
    Phshortcuts.next3: NextImageIntent(),
    Phshortcuts.previous4: PreviousImageIntent(),
    Phshortcuts.next4: NextImageIntent(),
    Phshortcuts.previous5: PreviousImageIntent(),
    Phshortcuts.next5: NextImageIntent(),
    Phshortcuts.playPause: PlayPauseIntent(),
    Phshortcuts.openTimerMenu: OpenTimerMenuIntent(),
    Phshortcuts.restartTimer: RestartTimerIntent(),
    Phshortcuts.help: HelpIntent(),
    Phshortcuts.toggleBottomBar: BottomBarToggleIntent(),
    Phshortcuts.alwaysOnTop: AlwaysOnTopIntent(),
    Phshortcuts.toggleSounds: ToggleSoundIntent(),
    Phshortcuts.returnHome: ReturnHomeIntent(),
    Phshortcuts.revealInExplorer: RevealInExplorerIntent(),
    Phshortcuts.preferences: OpenPreferencesIntent(),
    Phshortcuts.flipHorizontal: FlipHorizontalIntent(),
    Phshortcuts.zoomIn: ZoomInIntent(),
    Phshortcuts.zoomInNumpad: ZoomInIntent(),
    Phshortcuts.zoomOut: ZoomOutIntent(),
    Phshortcuts.zoomOutNumpad: ZoomOutIntent(),
    Phshortcuts.zoomInArrow: ZoomInIntent(),
    Phshortcuts.zoomOutArrow: ZoomOutIntent(),
    Phshortcuts.zoomReset: ZoomResetIntent(),
    Phshortcuts.zoomResetNav: ZoomResetIntent(),
    Phshortcuts.undo: UndoIntent(),
    Phshortcuts.toggleAnnotation: AnnotationToggleIntent(),
    Phshortcuts.clearAnnotations: AnnotationClearIntent(),
    Phshortcuts.cycleAnnotationColors: AnnotationCycleColorsIntent(),
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

class OpenFolderIntent extends Intent {
  const OpenFolderIntent();
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

class RevealInExplorerIntent extends Intent {
  const RevealInExplorerIntent();
}

class OpenPreferencesIntent extends Intent {
  const OpenPreferencesIntent();
}

class ZoomInIntent extends Intent {
  const ZoomInIntent();
}

class ZoomOutIntent extends Intent {
  const ZoomOutIntent();
}

class ZoomResetIntent extends Intent {
  const ZoomResetIntent();
}

class AnnotationToggleIntent extends Intent {
  const AnnotationToggleIntent();
}

class AnnotationClearIntent extends Intent {
  const AnnotationClearIntent();
}

class AnnotationCycleColorsIntent extends Intent {
  const AnnotationCycleColorsIntent();
}

class UndoIntent extends Intent {
  const UndoIntent();
}

class FlipHorizontalIntent extends Intent {
  const FlipHorizontalIntent();
}
