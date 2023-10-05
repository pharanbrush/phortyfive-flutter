import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pfs2/core/file_list.dart';
import 'package:pfs2/models/pfs_model.dart';
import 'package:pfs2/ui/phshortcuts.dart';
import 'package:pfs2/widgets/help_sheet.dart';
import 'package:pfs2/widgets/image_drop_target.dart';
import 'package:pfs2/widgets/modal_underlay.dart';
import 'package:pfs2/widgets/overlay_button.dart';
import 'package:pfs2/widgets/snackbar_phmessage.dart';
import 'package:pfs2/widgets/timer_bar.dart';
import 'package:pfs2/widgets/timer_duration_panel.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:window_manager/window_manager.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.model});

  final PfsAppModel model;

  static SnackBar topSnackBar(BuildContext context, {required Widget content}) {
    const double sideMarginNormal = 200;
    const double sideMarginNarrow = 20;
    const marginNormal = EdgeInsets.only(
        bottom: 50, left: sideMarginNormal, right: sideMarginNormal);

    const marginNarrow = EdgeInsets.only(
        bottom: 50, left: sideMarginNarrow, right: sideMarginNarrow);

    const double windowNarrowWidth = 700;
    const Duration duration = Duration(milliseconds: 1500);
    const Color toastColor = Color(0xFF91AECC);

    final bool isWindowNarrow =
        MediaQuery.of(context).size.width < windowNarrowWidth;
    final EdgeInsets margin = isWindowNarrow ? marginNarrow : marginNormal;

    return SnackBar(
      dismissDirection: DismissDirection.up,
      behavior: SnackBarBehavior.floating,
      duration: duration,
      backgroundColor: toastColor,
      margin: margin,
      content: Center(child: content),
    );
  }

  static SnackBar topSnackBarTextWithBold(BuildContext context, String text,
      {String? boldText, String? lastText}) {
    return topSnackBar(context,
        content: Text.rich(
          TextSpan(
            text: text,
            children: [
              TextSpan(
                  text: boldText,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: lastText),
            ],
          ),
        ));
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

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final FocusNode mainWindowFocus = FocusNode();

  final clicker = AudioPlayer();
  final _clickSound = AssetSource('sounds/clack.wav');
  final Map<Type, Action<Intent>> shortcutActions = {};

  TimerDurationPanel? timerDurationWidget;

  bool rightControlsOrientation = true;
  bool isBottomBarMinimized = false;
  bool isAlwaysOnTop = false;
  bool isSoundsEnabled = true;
  bool isTouch = false;
  bool isEditingTime = false;
  bool isShowingCheatSheet = false;
  bool isShowingFiltersMenu = false;

  bool get isEffectActive => (imageGrayscale || imageBlurLevel > 0);
  bool imageGrayscale = false;
  double imageBlurLevel = 0;

  @override
  void initState() {
    timerDurationWidget =
        TimerDurationPanel(onCloseIntent: _doStopEditingCustomTime);

    final model = widget.model;
    model.onTimerElapse ??= () => _playClickSound();
    model.onTimerPlayPause ??= () => _handleTimerPlayPause();
    model.onTimerReset ??= () => _playClickSound();
    model.onFilesChanged ??= () => setState(() {});
    model.onTimerChangeSuccess ??= () => _handleTimerChangeSuccess();
    model.onFilesLoadedSuccess ??= _handleFilesLoadedSuccess;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = Theme.of(context).colorScheme.background;

    if (!widget.model.hasFilesLoaded) {
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
          if (isEditingTime) timerDurationWidget!,
          if (isShowingCheatSheet)
            HelpSheet(onTapUnderlay: () => _setCheatSheetActive(false)),
          if (isShowingFiltersMenu) _filterMenu(),
          _dockingControls(),
        ],
      ),
    ));
  }

  Widget _blurSlider() {
    return Row(
      children: [
        const Text('Blur'),
        Slider(
          min: 0,
          max: 12,
          divisions: 12,
          label: imageBlurLevel.toInt().toString(),
          onChanged: (value) {
            setState(() {
              imageBlurLevel = value;
            });
          },
          value: imageBlurLevel,
        ),
      ],
    );
  }

  Widget _grayscaleCheckbox() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              imageGrayscale = !imageGrayscale;
            });
          },
          child: const Text('Grayscale'),
        ),
        const SizedBox(width: 10),
        Checkbox(
          value: imageGrayscale,
          onChanged: (value) {
            setState(() {
              imageGrayscale = value ?? false;
            });
          },
          semanticLabel: 'Grayscale checkbox',
        ),
      ],
    );
  }

  Widget _filterMenu() {
    const decoration = BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(10)),
        boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 2)]);
    const padding = EdgeInsets.symmetric(horizontal: 30, vertical: 15);

    return Stack(
      children: [
        ModalUnderlay(
          isTransparent: true,
          onTapDown: () => setState(() => isShowingFiltersMenu = false),
        ),
        Positioned(
          bottom: 10,
          right: 280,
          child: SizedBox(
            child: Container(
              decoration: decoration,
              child: Padding(
                padding: padding,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.invert_colors, color: Color(0xFFE4E4E4), size: 14),
                          SizedBox(width: 7),
                          Text(
                            'Filters',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          
                          
                        ],
                      ),
                      const SizedBox(height: 15),
                      _grayscaleCheckbox(),
                      _blurSlider(),
                    ]),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _shortcutsWrapper(Widget childWidget) {
    return Phbuttons.appModelWidget((_, __, model) {
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
            onInvoke: (intent) => _doStartEditingCustomTime(),
          ),
          RestartTimerIntent: CallbackAction(
            onInvoke: (intent) => model.timerRestartAndNotifyListeners(),
          ),
          HelpIntent: CallbackAction(
            onInvoke: (intent) => _doToggleCheatSheet(),
          ),
          BottomBarToggleIntent: CallbackAction(
            onInvoke: (intent) => _doToggleBottomBar(),
          ),
          OpenFilesIntent: CallbackAction(
            onInvoke: (intent) => model.openFilePickerForImages(),
          ),
          AlwaysOnTopIntent: CallbackAction(
            onInvoke: (intent) => _doToggleAlwaysOnTop(),
          ),
          ToggleSoundIntent: CallbackAction(
            onInvoke: (intent) => _doToggleSounds(),
          ),
          ReturnHomeIntent: CallbackAction(
            onInvoke: (intent) => _tryReturnHome(),
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
          Phshortcuts.returnHome: ReturnHomeIntent(),
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

  void _cancelAllModals() {
    if (isShowingCheatSheet) {
      _setCheatSheetActive(false);
    }

    if (isEditingTime) {
      _doStopEditingCustomTime();
    }
  }

  void _tryReturnHome() {
    _cancelAllModals();
  }

  void _handleFilesLoadedSuccess(int filesLoaded, int filesSkipped) {
    final imageNoun = filesLoaded == 1 ? 'image' : 'images';

    if (filesSkipped == 0) {
      _showSnackBarWithBoldText(
        text: '',
        boldText: '$filesLoaded $imageNoun',
        lastText: ' loaded.',
      );
    } else {
      final fileSkippedNoun = filesSkipped == 1 ? 'file' : 'files';

      _showSnackBar(
        content: MainScreen.textWithMultiBold(
            text1: '',
            boldText1: '$filesLoaded $imageNoun',
            text2: 'loaded.',
            boldText2: '($filesSkipped incompatible $fileSkippedNoun skipped)'),
      );
    }
  }

  void _handleTimerChangeSuccess() {
    _showSnackBarWithBoldText(
      text: 'Timer is set to ',
      boldText: '${widget.model.currentTimerDuration} seconds',
      lastText: '.',
    );
  }

  void _handleTimerPlayPause() {
    _playClickSound();
  }

  void _doStartEditingCustomTime() => _setEditingCustomTimeActive(true);

  void _doStopEditingCustomTime() => _setEditingCustomTimeActive(false);

  void _showSnackBar({required Widget content}) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    scaffoldMessenger.clearSnackBars();
    scaffoldMessenger.showSnackBar(
      MainScreen.topSnackBar(
        context,
        content: content,
      ),
    );
  }

  void _showSnackBarWithBoldText(
      {required String text, String? boldText, String? lastText}) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    scaffoldMessenger.clearSnackBars();
    scaffoldMessenger.showSnackBar(
      MainScreen.topSnackBarTextWithBold(
        context,
        text,
        boldText: boldText,
        lastText: lastText,
      ),
    );
  }

  void _setEditingCustomTimeActive(bool active) {
    if (active) {
      _cancelAllModals();
      ScaffoldMessenger.of(context).clearSnackBars();
    }

    setState(() {
      isEditingTime = active;
      if (!active) {
        mainWindowFocus.requestFocus();
      }
      timerDurationWidget!.setActive(active, widget.model.currentTimerDuration);
    });
  }

  void _doToggleCheatSheet() {
    _setCheatSheetActive(!isShowingCheatSheet);
  }

  void _setCheatSheetActive(bool active) {
    if (active) _cancelAllModals();

    setState(() {
      isShowingCheatSheet = active;
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

    return Phbuttons.appModelWidget((_, __, model) {
      Icon playPauseIcon = model.isTimerRunning ? pauseIcon : playIcon;

      Widget nextPreviousOnScrollListener({Widget? child}) {
        return Listener(
          onPointerSignal: (pointerEvent) {
            if (pointerEvent is PointerScrollEvent) {
              PointerScrollEvent scroll = pointerEvent;
              final dy = scroll.scrollDelta.dy;
              final bool isScrollDown = dy > 0;
              final bool isScrollUp = dy < 0;
              if (isScrollDown) {
                model.nextImageNewTimer();
              } else if (isScrollUp) {
                model.previousImageNewTimer();
              }
            }
          },
          child: child,
        );
      }

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
              child: nextPreviousOnScrollListener(
                child: OverlayButton(
                  onPressed: () => model.previousImageNewTimer(),
                  child: beforeIcon,
                ),
              ),
            ),
            Expanded(
                flex: 4,
                child: GestureDetector(
                  // onSecondaryTapDown: (details) {
                  //   print('right-clicked');
                  // },
                  child: OverlayButton(
                    onPressed: () =>
                        model.setTimerActive(!model.isTimerRunning),
                    child: playPauseIcon,
                  ),
                )),
            SizedBox(
              width: 140,
              child: nextPreviousOnScrollListener(
                child: OverlayButton(
                  onPressed: () => model.nextImageNewTimer(),
                  child: nextIcon,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _fileDropZone() {
    return Positioned.fill(
      left: 10,
      right: 10,
      bottom: 40,
      top: 10,
      child: ImageDropTarget(
        onDragSuccess: () => windowManager.focus(),
      ),
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
                () => _doToggleSounds(),
                isSoundsEnabled ? Icons.volume_up : Icons.volume_off,
                isSoundsEnabled ? 'Mute sounds (M)' : 'Unmute sounds (M)'),
            Phbuttons.topControl(
                () => _doToggleAlwaysOnTop(),
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

  void _doToggleAlwaysOnTop() {
    showAlwaysOnTopToggleSnackbar() {
      _showSnackBar(
          content: isAlwaysOnTop
              ? const SnackbarPhmessage(
                  text: '"Always on top" enabled',
                  icon: Icons.push_pin,
                )
              : const SnackbarPhmessage(
                  text: '"Always on top" disabled',
                  icon: Icons.push_pin_outlined,
                ));
    }

    setState(() {
      isAlwaysOnTop = !isAlwaysOnTop;
      windowManager.setAlwaysOnTop(isAlwaysOnTop);
      showAlwaysOnTopToggleSnackbar();
    });
  }

  void _doToggleSounds() {
    showSoundToggleSnackbar() {
      _showSnackBar(
          content: isSoundsEnabled
              ? const SnackbarPhmessage(
                  text: 'Sounds enabled',
                  icon: Icons.volume_up,
                )
              : const SnackbarPhmessage(
                  text: 'Sounds muted',
                  icon: Icons.volume_off,
                ));
    }

    setState(() {
      isSoundsEnabled = !isSoundsEnabled;
      showSoundToggleSnackbar();
    });
  }

  Widget _imageViewer() {
    const Widget matrixGrayscale = BackdropFilter(
      filter: ColorFilter.matrix(<double>[
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0,
        0,
        0,
        1,
        0
      ]),
      child: SizedBox.expand(),
    );

    final double bottomPadding = isBottomBarMinimized ? 5 : 45;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Phbuttons.appModelWidget((_, __, model) {
        const defaultImage = '';

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
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
                imageFile,
              ),
            ),
            if (imageBlurLevel > 0)
              BackdropFilter(
                filter: ImageFilter.blur(
                    sigmaX: pow(1.3, imageBlurLevel).toDouble(), sigmaY: pow(1.3, imageBlurLevel).toDouble()),
                child: const SizedBox.expand(),
              ),
            if (imageGrayscale) matrixGrayscale,
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
      return const Positioned(
        bottom: 1,
        right: 10,
        child: Opacity(
          opacity: 0.5,
          child: Row(children: [
            TimerBar(),
            SizedBox(
              width: 140,
            )
          ]),
        ),
      );
    }

    List<Widget> bottomBarItems(PfsAppModel model) {
      final filtersButton = Opacity(
        opacity: 0.4,
        child: IconButton(
          onPressed: () {
            setState(() => isShowingFiltersMenu = true);
          },
          tooltip: 'Filters',
          icon: Icon(Icons.contrast,
              color: isEffectActive ? Colors.orange : Colors.grey,
              size: 20,),
        ),
      );

      if (model.hasFilesLoaded) {
        return [
          filtersButton,
          //_bottomButton(() => null, Icons.swap_horiz, 'Flip controls'), // Do this in the settings menu
          const SizedBox(width: 15),
          _timerButton(),
          const SizedBox(width: 15),
          Opacity(
            opacity: model.allowTimerPlayPause ? 0.4 : 0.2,
            child: _timerControls(),
          ),
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
        (_, __, model) {
          return Row(children: bottomBarItems(model));
        },
      ),
    );
  }

  void _doToggleBottomBar() {
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
          onPressed: () => _doToggleBottomBar()),
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
    return Phbuttons.appModelWidget((_, __, model) {
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
      (_, __, model) {
        final currentTimerSeconds = model.timer.duration.inSeconds;
        const double iconSize = 18;
        const opacity = 0.4;

        return Opacity(
          opacity: opacity,
          child: Tooltip(
            message:
                '${model.timer.duration.inSeconds} seconds per image.\nClick to edit timer. (F2)',
            child: TextButton(
                onPressed: () => _doStartEditingCustomTime(),
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
      const playButtonTooltip = 'Timer paused. Press to resume (P)';
      const pauseButtonTooltip = 'Timer running. Press to pause (P)';
      const playIcon = Icon(Icons.play_arrow);
      const pauseIcon = Icon(Icons.pause);
      const Color pausedColor = Color.fromARGB(255, 255, 196, 0);
      const Color playingColor = accentColor;

      bool allowTimerControl = model.allowTimerPlayPause;
      Color buttonColor = allowTimerControl
          ? (model.isTimerRunning ? playingColor : pausedColor)
          : Colors.grey.shade500;

      final icon = model.isTimerRunning ? pauseIcon : playIcon;
      final style = FilledButton.styleFrom(backgroundColor: buttonColor);
      final tooltipText =
          model.isTimerRunning ? pauseButtonTooltip : playButtonTooltip;

      return Tooltip(
        message: tooltipText,
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
