import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:pfs2/core/file_list.dart';
import 'package:pfs2/models/pfs_model.dart';
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
  final Color accentColor = Colors.blueAccent;

  final FocusNode timerSettingFocusNode =
      FocusNode(debugLabel: 'Timer settings');

  final clicker = AudioPlayer();
  final _clickSound = AssetSource('sounds/clacktrimmed.wav');

  bool rightOrientation = true;
  bool isBottomBarMinimized = false;
  bool isAlwaysOnTop = false;
  bool isSoundsEnabled = true;
  bool isTouch = false;

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
              _bottomBar(context),
              _fileDropZone(),
            ],
          ),
        );
      }

      return Container(
        color: backgroundColor,
        child: Stack(
          children: [
            _imageViewer(),

            _fileDropZone(),
            _gestureControls(),
            _topRightWindowControls(),
            _bottomBar(context),
            _dockingControls(),
          ],
        ),
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
              width: 140,
              child: OverlayButton(
                onPressed: () => model.previousImageNewTimer(),
                child: beforeIcon,
              ),
            ),
            Expanded(
                flex: 4,
                child: OverlayButton(
                  onPressed: () => model.setTimerActive(!model.isTimerRunning),
                  child: playPauseIcon,
                )),
            SizedBox(
              width: 180,
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

  Widget _firstActionSheet() {
    const double iconSize = 100;
    final Color boxColor = Colors.grey.shade100;
    final Color borderColor = Colors.grey.shade200;
    const Color contentColor = Colors.black38;
    const TextStyle textStyle = TextStyle(
      color: contentColor,
    );
    const Icon icon = Icon(Icons.image, size: iconSize, color: contentColor);
    const Icon downIcon =
        Icon(Icons.arrow_downward_rounded, color: contentColor);

    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        margin: const EdgeInsets.fromLTRB(0, 0, 20, 40),
        child: SizedBox(
          width: 300,
          height: 200,
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
                  children: [
                    icon,
                    Text(
                      'Get started by loading images.',
                      style: textStyle,
                    ),
                    Text(
                      'You can also drag & drop images into the window.',
                      style: textStyle,
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
                isSoundsEnabled ? 'Mute sounds' : 'Unmute sounds.'),
            Phbuttons.topControl(
                () => _toggleAlwaysOnTop(),
                isAlwaysOnTop
                    ? Icons.push_pin_rounded
                    : Icons.push_pin_outlined,
                'Keep Window on Top'),
            Phbuttons.topControl(() {}, Icons.help_rounded, 'Help...'),
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

  Widget _bottomBar(BuildContext context) {
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
          _timerStatButton(),
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
          const SizedBox(width: 10),
        ];
      }
    }

    return Positioned(
      bottom: 2,
      right: 10,
      child: Phbuttons.appModelWidget(
        (context, child, model) {
          return Row(children: bottomBarItems(model));
        },
      ),
    );
  }

  Widget _dockingControls() {
    return Positioned(
      bottom: 3,
      right: 3,
      child: Phbuttons.collapseBottomBarButton(
          isMinimized: isBottomBarMinimized,
          onPressed: () {
            setState(() {
              isBottomBarMinimized = !isBottomBarMinimized;
            });
          }),
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
      final fileCount = model.fileList.getCount();
      const double iconSize = 18;
      const Icon icon = Icon(Icons.image, size: iconSize);
      final String tooltip =
          '${model.fileList.getCount()} images loaded.\nClick to open a different image set...';

      imageStats() {
        return Tooltip(
          message: tooltip,
          child: TextButton(
            onPressed: () => model.openImagesWithFilePicker(),
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

  Widget _timerStatButton() {
    return Phbuttons.appModelWidget(
      (context, child, model) {
        const double timerMenuWidth = 130;
        const double textSize = 14;
        const double menuItemHeight = 40;
        final currentTimerSeconds = model.timer.duration.inSeconds;
        const double iconSize = 18;

        menuItem(
          String label, {
          double menuWidth = timerMenuWidth,
          Function()? onPressed,
          //Icon? icon,
        }) {
          return MenuItemButton(
            style: MenuItemButton.styleFrom(
              minimumSize: Size(menuWidth, menuItemHeight),
              alignment: Alignment.centerLeft,
            ),
            onPressed: onPressed,
//          leadingIcon: icon,
            child: SizedBox(
              width: menuWidth,
              child: Text(
                label,
                style: const TextStyle(fontSize: textSize),
              ),
            ),
          );
        }

        presetItem(String label, {required int seconds}) {
          return menuItem(label,
              onPressed: () => model.setTimerSeconds(seconds));
        }

        return Opacity(
          opacity: 0.4,
          child: Row(
            children: [
              MenuAnchor(
                menuChildren: [
                  menuItem('Timer duration'),
                  const Divider(),
                  presetItem("15 seconds", seconds: 15),
                  presetItem("30 seconds", seconds: 30),
                  presetItem("45 seconds", seconds: 45),
                  presetItem("60 seconds", seconds: 60),
                  presetItem("90 seconds", seconds: 90),
                  presetItem("2 minutes", seconds: 2 * 60),
                  presetItem("3 minutes", seconds: 3 * 60),
                  const Divider(),
                  menuItem('Custom...'),
                ],
                builder: (context, controller, child) {
                  return Tooltip(
                    message:
                        '${model.timer.duration.inSeconds} seconds per image. Click to edit timer.',
                    child: TextButton(
                        onPressed: () {
                          if (controller.isOpen) {
                            controller.close();
                          } else {
                            controller.open();
                          }
                        },
                        child: textThenIcon('${currentTimerSeconds}s',
                            const Icon(Icons.timer_outlined, size: iconSize))),
                  );
                },
              ),
            ],
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
            onPressed: () => model.openImagesWithFilePicker(),
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
        isMinimized ? 'Expand controls' : 'Minimize controls';
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
