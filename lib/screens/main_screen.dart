import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pfs2/core/file_list.dart';
import 'package:pfs2/models/pfs_model.dart';
import 'package:pfs2/ui/phshortcuts.dart';
import 'package:pfs2/widgets/overlay_button.dart';
import 'package:pfs2/widgets/timer_bar.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:window_manager/window_manager.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final FocusNode timerSettingFocusNode =
      FocusNode(debugLabel: 'Timer settings');
  final FocusNode mainWindowFocus = FocusNode();

  final clicker = AudioPlayer();
  final _clickSound = AssetSource('sounds/clacktrimmed.wav');

  final TextEditingController timerTextEditorController =
      TextEditingController(text: '');
  final Map<Type, Action<Intent>> shortcutActions = {};

  bool rightOrientation = true;
  bool isBottomBarMinimized = false;
  bool isAlwaysOnTop = false;
  bool isSoundsEnabled = true;
  bool isTouch = false;
  bool isEditingTime = false;
  bool isShowingCheatSheet = false;

  @override
  void initState() {
    timerSettingFocusNode.onKey = (node, event) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _stopEditingCustomTime();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    };

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = Theme.of(context).colorScheme.background;

    return Phbuttons.appModelWidget((context, child, model) {
      if (model.onTimerElapse == null) {
        model.onTimerElapse = () => _playClickSound();
        model.onTimerPlayPause = () => _playClickSound();
        model.onTimerReset = () => _playClickSound();
      }

      if (!model.hasFilesLoaded) {
        return Container(
          color: backgroundColor,
          child: Stack(
            children: [
              _firstActionSheet(),
              _topRightWindowControls(),
              _bottomBar(),
              _fileDropZone(),
            ],
          ),
        );
      }

      return _shortcutsWrapper(Container(
        color: backgroundColor,
        child: Stack(
          children: [
            _imageViewer(),
            _fileDropZone(),
            _gestureControls(),
            _topRightWindowControls(),
            _bottomBar(),
            if (isEditingTime) _setTimerDurationWidget(),
            if (isShowingCheatSheet) _cheatSheetSheet(),
            _dockingControls(),
          ],
        ),
      ));
    });
  }

  Widget _shortcutsWrapper(Widget childWidget) {
    return Phbuttons.appModelWidget((context, child, model) {
      if (shortcutActions.isEmpty) {
        shortcutActions.addAll({
          PreviousImageIntent: CallbackAction(
            onInvoke: (intent) => model.previousImageNewTimer(),
          ),
          NextImageIntent: CallbackAction(
            onInvoke: (intent) => model.nextImageNewTimer(),
          ),
          PlayPauseIntent: CallbackAction(
            onInvoke: (intent) => model.playPauseToggleTimer(),
          ),
          OpenTimerMenuIntent: CallbackAction(
            onInvoke: (intent) => _startEditingCustomTime(),
          ),
          RestartTimerIntent: CallbackAction(
            onInvoke: (intent) => model.timerRestartAndNotifyListeners(),
          ),
          HelpIntent: CallbackAction(
            onInvoke: (intent) => isShowingCheatSheet = !isShowingCheatSheet,
          ),
          BottomBarToggleIntent: CallbackAction(
            onInvoke: (intent) => _toggleBottomBar(),
          ),
          OpenFilesIntent: CallbackAction(
            onInvoke: (intent) => model.openFilePickerForImages(),
          ),
          AlwaysOnTopIntent: CallbackAction(
            onInvoke: (intent) => _toggleAlwaysOnTop(),
          ),
          ToggleSoundIntent: CallbackAction(
            onInvoke: (intent) => _toggleSounds(),
          ),
        });
      }

      return Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
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
        },
        child: Actions(
          actions: shortcutActions,
          child: Focus(
            focusNode: mainWindowFocus,
            autofocus: true,
            child: childWidget,
          ),
        ),
      );
    });
  }

  void _updateTextControllerText() {
    var model = ScopedModel.of<PfsAppModel>(context, rebuildOnChange: true);
    timerTextEditorController.text = model.currentTimerDuration.toString();
  }

  void _startEditingCustomTime() => _setEditingCustomTimeActive(true);

  void _stopEditingCustomTime() => _setEditingCustomTimeActive(false);

  void _setEditingCustomTimeActive(bool active) {
    _updateTextControllerText();
    setState(() {
      isEditingTime = active;

      if (active) {
        timerSettingFocusNode.requestFocus();
        var textValue = timerTextEditorController.text;
        timerTextEditorController.selection =
            TextSelection(baseOffset: 0, extentOffset: textValue.length);
      } else {
        mainWindowFocus.requestFocus();
      }
    });
  }

  Widget _modalUnderlay(Function()? onTapOnUnderlay) {
    return Positioned.fill(
      child: GestureDetector(
        onTapDown: (details) => onTapOnUnderlay!(),
        child:
            Container(decoration: const BoxDecoration(color: Colors.white60)),
      ),
    );
  }

  Widget _setTimerDurationWidget() {
    const double diameter = 350;
    const double radius = diameter * 0.5;
    const double containerPadding = 100;
    const double bottomOffset = 90 - (containerPadding * 0.5);
    const double rightMargin = 230 - (containerPadding * 0.5);

    const Color backgroundColor = Color(0xAA81B6E0);
    const Color textColor = Colors.white;
    const Color outlineColor = Color(0xFF0F6892);

    return Phbuttons.appModelWidget((context, child, model) {
      Widget preset(String text, int seconds, double left, double top) {
        if (seconds == model.currentTimerDuration) {
          return Positioned(
            left: left,
            top: top,
            child: FilledButton(
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(10)),
              onPressed: () {
                model.setTimerSeconds(seconds);
                _stopEditingCustomTime();
              },
              child: Text(text),
            ),
          );
        }

        return Positioned(
          left: left,
          top: top,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(10)),
            onPressed: () {
              model.setTimerSeconds(seconds);
              _stopEditingCustomTime();
            },
            child: Text(text),
          ),
        );
      }

      return Stack(
        children: [
          _modalUnderlay(() => _stopEditingCustomTime()),
          Positioned(
            right: rightMargin,
            bottom: (-radius) + bottomOffset,
            child: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: diameter + containerPadding,
                height: diameter + containerPadding,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    GestureDetector(
                      onTapDown: (details) {
                        _stopEditingCustomTime();
                      },
                      child: Container(
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: backgroundColor),
                        child: SizedBox(
                          width: diameter,
                          height: diameter,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'Timer duration',
                                  style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                              ),
                              SizedBox(
                                  width: 100,
                                  child: TextField(
                                    controller: timerTextEditorController,
                                    focusNode: timerSettingFocusNode,
                                    autocorrect: false,
                                    maxLength: 4,
                                    textAlign: TextAlign.center,
                                    textAlignVertical: TextAlignVertical.center,
                                    style: const TextStyle(fontSize: 32),
                                    autofocus: true,
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 5),
                                      border: OutlineInputBorder(),
                                      focusColor: outlineColor,
                                      filled: true,
                                      fillColor: Colors.white,
                                      counterText: '',
                                      counterStyle: TextStyle(fontSize: 1),
                                    ),
                                    onSubmitted: (value) {
                                      model.trySetTimerSecondsInput(value);
                                      _stopEditingCustomTime();
                                    },
                                  )),
                              const SizedBox(height: 3),
                              const Text(
                                'seconds',
                                style: TextStyle(color: textColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: diameter,
                      width: diameter,
                      child: Stack(
                        children: [
                          preset('15s', 15, 5, 80),
                          preset('30s', 30, 50, 30),
                          preset('45s', 45, 115, 0),
                          preset('60s', 60, 195, 5),
                          preset('90s', 90, 255, 35),
                          preset('2m', 2 * 60, 290, 80),
                          preset('3m', 3 * 60, 293, 130),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _gestureControls() {
    const Icon beforeIcon = Icon(
      Icons.navigate_before,
      size: 100,
    );
    const Icon nextIcon = Icon(
      Icons.navigate_next,
      size: 100,
    );

    const Icon playIcon = Icon(Icons.play_arrow, size: 80);
    const Icon pauseIcon = Icon(Icons.pause, size: 80);

    return Phbuttons.appModelWidget((context, child, model) {
      Icon playPauseIcon = model.isTimerRunning ? pauseIcon : playIcon;

      return Positioned.fill(
        top: 30,
        bottom: 50,
        left: 10,
        right: 10,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 100,
              child: OverlayButton(
                onPressed: () => model.previousImageNewTimer(),
                child: beforeIcon,
              ),
            ),
            Expanded(
                flex: 4,
                child: GestureDetector(
                  onSecondaryTapDown: (details) {
                    print('right-clicked');
                  },
                  child: OverlayButton(
                    onPressed: () =>
                        model.setTimerActive(!model.isTimerRunning),
                    child: playPauseIcon,
                  ),
                )),
            SizedBox(
              width: 140,
              child: OverlayButton(
                onPressed: () => model.nextImageNewTimer(),
                child: nextIcon,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _fileDropZone() {
    return Phbuttons.appModelWidget((context, child, model) {
      return Positioned.fill(
        left: 10,
        right: 10,
        bottom: 40,
        top: 10,
        child: DropTarget(
          onDragDone: (details) {
            if (details.files.isEmpty) return;
            List<String> filePaths = [];
            for (var file in details.files) {
              var filePath = file.path;
              if (FileList.fileIsImage(filePath)) {
                filePaths.add(filePath);
              }
            }
            if (filePaths.isEmpty) return;

            model.loadImages(filePaths);

            if (model.hasFilesLoaded) {
              windowManager.focus();
            }
          },
          child: Container(
            color: Colors.transparent,
            child: const Center(
              child: Material(
                child: Text(
                  '',
                  style: TextStyle(fontSize: 40),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  void _setCheatSheetActive(bool active) {
    setState(() {
      isShowingCheatSheet = active;
    });
  }

  Widget _cheatSheetSheet() {
    const Color textColor = Color(0xFFEEEEEE);
    const Color sheetColor = Color(0xEE000000);
    const double sheetHeight = 500;

    const Icon headingIcon = Icon(
      Icons.keyboard,
      color: textColor,
      size: 40,
    );

    const TextStyle headingStyle = TextStyle(
      color: textColor,
      fontWeight: FontWeight.bold,
      fontSize: 30,
    );

    Widget keySymbol(String key) {
      const double height = 32;
      const double minWidth = 32;
      const double verticalPadding = 3;
      const double horizontalPadding = 8;
      const double borderRadius = 5;
      const Color keyColor = Color(0xFF272727);

      return Container(
        constraints: const BoxConstraints(minWidth: minWidth, minHeight: height),
        padding: const EdgeInsets.symmetric(
          vertical: verticalPadding,
          horizontal: horizontalPadding,
        ),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
          color: keyColor,
        ),
        child: Text(key),
      );
    }

    Widget shortcutItem(String text, String key, {String? key2}) {
      const double textWidth = 160;
      const double keysWidth = 100;
      const double padding = 3;

      return Padding(
        padding: const EdgeInsets.all(padding),
        child: Row(
          children: [
            SizedBox(
              width: textWidth,
              child: Text(text),
            ),
            SizedBox(
              width: keysWidth,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  keySymbol(key),
                  if (key2 != null) const Text(' + '),
                  if (key2 != null) keySymbol(key2),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        _modalUnderlay(() => _setCheatSheetActive(false)),
        Center(
          child: Material(
            color: Colors.transparent,
            textStyle: const TextStyle(color: textColor, inherit: true),
            child: Container(
              height: sheetHeight,
              //width: double.infinity,
              decoration: const BoxDecoration(
                  color: sheetColor,
                  borderRadius: BorderRadius.all(Radius.circular(20))),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 100,
                    child: Column(
                      children: [
                        headingIcon,
                        Text('Keyboard Shortcuts', style: headingStyle)
                      ],
                    ),
                  ),
                  SizedBox(
                    //decoration: Debugui.boxDecoration,
                    width: 720,
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  shortcutItem('Open images...', 'Ctrl',
                                      key2: 'O'),
                                  const Text(''),
                                  shortcutItem('Next image', 'J'),
                                  shortcutItem('Previous image', 'K'),
                                  const Text(''),
                                  shortcutItem('Play/Pause', 'P'),
                                  shortcutItem('Restart timer', 'R'),
                                  shortcutItem('Change timer duration', 'F2'),
                                ]),
                          ),
                        ),
                        Expanded(
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                shortcutItem('Toggle "Always on top"', 'Ctrl',
                                    key2: 'T'),
                                shortcutItem('Show/hide bottom bar', 'H'),
                                shortcutItem('Open help sheet', 'F1'),
                                shortcutItem('Mute/unmute sounds', 'M'),
                              ]),
                        )
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: SizedBox(
                        width: 600,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Icon(
                                Icons.file_open_outlined,
                                color: textColor,
                                size: 30,
                              ),
                            ),
                            Text(
                                'You can also load new images using drag and drop.'),
                            Padding(
                              padding: EdgeInsets.all(20.0),
                              child: SizedBox(
                                width: 30,
                                height: 30,
                              ),
                            )
                          ],
                        )),
                  )
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _firstActionSheet() {
    const double iconSize = 100;
    final Color boxColor = Colors.grey.shade100;
    final Color borderColor = Colors.grey.shade200;
    const Color contentColor = Colors.black38;
    const TextStyle textStyleMain = TextStyle(
      color: contentColor,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );
    const TextStyle textStyleSecondary = TextStyle(
      color: contentColor,
    );

    const Icon icon = Icon(Icons.image, size: iconSize, color: contentColor);
    const Icon downIcon =
        Icon(Icons.keyboard_double_arrow_down_rounded, color: contentColor);

    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        margin: const EdgeInsets.fromLTRB(0, 0, 25, 45),
        child: SizedBox(
          width: 350,
          height: 250,
          child: Material(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                border: Border.all(color: borderColor),
                color: boxColor,
              ),
              child: Stack(children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 25,
                    ),
                    icon,
                    Text(
                      'Get started by loading images!',
                      style: textStyleMain,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'You can also drag & drop images into the window.',
                      style: textStyleSecondary,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                    child: downIcon,
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topRightWindowControls() {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Opacity(
        opacity: 0.8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Phbuttons.topControl(
                () => _toggleSounds(),
                isSoundsEnabled ? Icons.volume_up : Icons.volume_off,
                isSoundsEnabled ? 'Mute sounds (M)' : 'Unmute sounds (M)'),
            Phbuttons.topControl(
                () => _toggleAlwaysOnTop(),
                isAlwaysOnTop
                    ? Icons.push_pin_rounded
                    : Icons.push_pin_outlined,
                'Keep Window on Top (Ctrl+T)'),
            Phbuttons.topControl(() => _setCheatSheetActive(true),
                Icons.help_rounded, 'Help... (F1)'),
            Phbuttons.topControl(() {}, Icons.info_outline_rounded, 'About...'),
          ],
        ),
      ),
    );
  }

  void _toggleAlwaysOnTop() {
    setState(() {
      isAlwaysOnTop = !isAlwaysOnTop;
      windowManager.setAlwaysOnTop(isAlwaysOnTop);
    });
  }

  void _toggleSounds() {
    setState(() {
      isSoundsEnabled = !isSoundsEnabled;
    });
  }

  Widget _imageViewer() {
    final double bottomPadding = isBottomBarMinimized ? 5 : 45;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Phbuttons.appModelWidget((_, __, model) {
        const defaultImage = 'C:/Projects/pfs2/assets/83131sf5043558883378.png';

        final FileData imageFileData = model.hasFilesLoaded
            ? model.getCurrentImageData()
            : FileList.fileDataFromPath(defaultImage);

        final File imageFile = File(imageFileData.filePath);

        final style = TextStyle(
          color: Colors.grey.shade500,
          fontSize: 11,
        );
        var topText = Text(imageFileData.fileName, style: style);
        const opacity = 0.3;

        return Stack(
          children: [
            Center(
              child: Image.file(
                imageFile,
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Material(
                color: Colors.transparent,
                child: Opacity(opacity: opacity, child: topText),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _bottomBar() {
    if (isBottomBarMinimized) {
      return Phbuttons.appModelWidget((context, child, model) {
        return Positioned(
          bottom: 1,
          right: 10,
          child: Opacity(
            opacity: 1,
            child: Phbuttons.appModelWidget(
              (context, child, model) {
                return const Opacity(
                  opacity: 0.5,
                  child: Row(children: [
                    TimerBar(),
                    SizedBox(
                      width: 140,
                    )
                  ]),
                );
              },
            ),
          ),
        );
      });
    }

    List<Widget> bottomBarItems(PfsAppModel model) {
      if (model.hasFilesLoaded) {
        return [
          //_bottomButton(() => null, Icons.swap_horiz, 'Flip controls'), // Do this in the settings menu
          const SizedBox(width: 15),
          _timerButton(),
          const SizedBox(width: 15),
          Phbuttons.appModelWidget((context, child, model) {
            double opacity = model.allowTimerPlayPause ? 0.4 : 0.2;
            return Opacity(
              opacity: opacity,
              child: _timerControls(),
            );
          }),
          const SizedBox(width: 20),
          _imageSetButton(),
          const SizedBox(width: 10),
        ];
      } else {
        return [
          Phbuttons.openFiles(),
          const SizedBox(width: 15, height: 43),
        ];
      }
    }

    return Positioned(
      bottom: 1,
      right: 10,
      child: Phbuttons.appModelWidget(
        (context, child, model) {
          return Row(children: bottomBarItems(model));
        },
      ),
    );
  }

  void _toggleBottomBar() {
    setState(() {
      isBottomBarMinimized = !isBottomBarMinimized;
    });
  }

  Widget _dockingControls() {
    return Positioned(
      bottom: 3,
      right: 3,
      child: Phbuttons.collapseBottomBarButton(
          isMinimized: isBottomBarMinimized,
          onPressed: () => _toggleBottomBar()),
    );
  }

  Widget _timerControls() {
    return Column(children: [
      const TimerBar(),
      Row(
        children: [
          Phbuttons.appModelWidget(
            (_, __, model) => Phbuttons.timerControl(
              () => model.timerRestartAndNotifyListeners(),
              Icons.refresh,
              'Restart Timer (R)',
            ),
          ),
          Phbuttons.appModelWidget(
            (_, __, model) => Phbuttons.timerControl(
              () => model.previousImageNewTimer(),
              Icons.skip_previous,
              'Previous Image (K)',
            ),
          ),
          Phbuttons.playPauseTimer(),
          Phbuttons.appModelWidget(
            (_, __, model) => Phbuttons.timerControl(
              () => model.nextImageNewTimer(),
              Icons.skip_next,
              'Next Image (J)',
            ),
          ),
        ],
      )
    ]);
  }

  Widget textThenIcon(String text, Icon icon, {double spacing = 3}) {
    return Row(
      children: [
        Text(text),
        SizedBox(width: spacing),
        icon,
      ],
    );
  }

  Widget _imageSetButton() {
    return Phbuttons.appModelWidget((context, child, model) {
      const double iconSize = 18;
      const Icon icon = Icon(Icons.image, size: iconSize);

      final fileCount = model.fileList.getCount();
      final String tooltip =
          '$fileCount images loaded.\nClick to open a different image set... (Ctrl+O)';

      imageStats() {
        return Tooltip(
          message: tooltip,
          child: TextButton(
            onPressed: () => model.openFilePickerForImages(),
            child: SizedBox(
              width: 80,
              child: Align(
                alignment: Alignment.center,
                child: Row(
                  children: [
                    const Spacer(),
                    textThenIcon(fileCount.toString(), icon),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      return Opacity(
        opacity: 0.4,
        child: imageStats(),
      );
    });
  }

  Widget _timerButton() {
    return Phbuttons.appModelWidget(
      (context, child, model) {
        final currentTimerSeconds = model.timer.duration.inSeconds;
        const double iconSize = 18;
        const opacity = 0.4;

        return Opacity(
          opacity: opacity,
          child: Tooltip(
            message:
                '${model.timer.duration.inSeconds} seconds per image.\nClick to edit timer. (F2)',
            child: TextButton(
                onPressed: () => _startEditingCustomTime(),
                child: textThenIcon('${currentTimerSeconds}s',
                    const Icon(Icons.timer_outlined, size: iconSize))),
          ),
        );
      },
    );
  }

  void _playClickSound() {
    if (!isSoundsEnabled) return;
    clicker.play(_clickSound);
  }
}

class Phbuttons {
  static const Color accentColor = Colors.blueAccent;
  static const Color topBarButtonColor = Colors.black12;

  static Widget topControl(
      Function()? onPressed, IconData icon, String? tooltip) {
    const double buttonSpacing = 5;
    const double iconSize = 20;
    const size = Size(25, 25);
    final style = TextButton.styleFrom(
      minimumSize: size,
      maximumSize: size,
      padding: const EdgeInsets.all(0),
    );

    return Container(
      margin: const EdgeInsets.only(right: buttonSpacing),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: iconSize),
        color: topBarButtonColor,
        tooltip: tooltip,
        style: style,
      ),
    );
  }

  static Widget timerControl(
      Function()? onPressed, IconData icon, String? tooltip) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      tooltip: tooltip,
      focusColor: const Color(0xFFFFE4C0),
    );
  }

  static Widget bottomButton(
      Function()? onPressed, IconData icon, String? tooltip) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      tooltip: tooltip,
      focusColor: const Color(0xFFFFE4C0),
    );
  }

  static Widget playPauseTimer() {
    return Phbuttons.appModelWidget((_, __, model) {
      const toolTipText = 'Pause/Resume Timer (P)';
      const playIcon = Icon(Icons.play_arrow);
      const pauseIcon = Icon(Icons.pause);

      final icon = model.isTimerRunning ? pauseIcon : playIcon;

      bool allowTimerControl = model.allowTimerPlayPause;
      Color buttonColor =
          allowTimerControl ? accentColor : Colors.grey.shade500;

      var style = FilledButton.styleFrom(backgroundColor: buttonColor);

      return Tooltip(
        message: toolTipText,
        child: FilledButton(
          style: style,
          onPressed: () => model.setTimerActive(!model.isTimerRunning),
          child: SizedBox(
            width: 50,
            child: icon,
          ),
        ),
      );
    });
  }

  static Widget openFiles() {
    const toolTipText = 'Open images... (Ctrl+O)';
    const color = Colors.white;

    var style = FilledButton.styleFrom(backgroundColor: accentColor);

    return appModelWidget(
      (_, __, model) {
        return Tooltip(
          message: toolTipText,
          child: FilledButton(
            style: style,
            onPressed: () => model.openFilePickerForImages(),
            child: const SizedBox(
              width: 40,
              child: Icon(Icons.folder_open, color: color),
            ),
          ),
        );
      },
    );
  }

  static ScopedModelDescendant<PfsAppModel> appModelWidget(
          ScopedModelDescendantBuilder<PfsAppModel> builder) =>
      ScopedModelDescendant<PfsAppModel>(builder: builder);

  static Widget collapseBottomBarButton(
      {required bool isMinimized, Function()? onPressed}) {
    const buttonSize = Size(25, 25);
    const collapseIcon = Icons.expand_more_rounded;
    const expandIcon = Icons.expand_less_rounded;

    final IconData buttonIcon = isMinimized ? expandIcon : collapseIcon;
    final String tooltip =
        isMinimized ? 'Expand controls (H)' : 'Minimize controls (H)';
    const iconColor = Colors.black38;

    const double iconSize = 20;

    final style = TextButton.styleFrom(
      minimumSize: buttonSize,
      maximumSize: buttonSize,
      padding: const EdgeInsets.all(0),
    );

    return Tooltip(
      message: tooltip,
      child: TextButton(
        style: style,
        onPressed: onPressed,
        child: Icon(
          buttonIcon,
          size: iconSize,
          color: iconColor,
        ),
      ),
    );
  }
}
