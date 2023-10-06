import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pfs2/models/pfs_model.dart';
import 'package:pfs2/ui/phshortcuts.dart';
import 'package:pfs2/widgets/help_sheet.dart';
import 'package:pfs2/widgets/image_drop_target.dart';
import 'package:pfs2/widgets/image_phviewer.dart';
import 'package:pfs2/widgets/modal_underlay.dart';
import 'package:pfs2/widgets/overlay_button.dart';
import 'package:pfs2/widgets/phbuttons.dart';
import 'package:pfs2/widgets/snackbar_phmessage.dart';
import 'package:pfs2/widgets/timer_bar.dart';
import 'package:pfs2/widgets/timer_duration_panel.dart';
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
  late Map<Type, Action<Intent>> shortcutActions = {
    PreviousImageIntent: CallbackAction(
      onInvoke: (intent) => widget.model.previousImageNewTimer(),
    ),
    NextImageIntent: CallbackAction(
      onInvoke: (intent) => widget.model.nextImageNewTimer(),
    ),
    PlayPauseIntent: CallbackAction(
      onInvoke: (intent) => widget.model.playPauseToggleTimer(),
    ),
    OpenTimerMenuIntent: CallbackAction(
      onInvoke: (intent) => _doStartEditingCustomTime(),
    ),
    RestartTimerIntent: CallbackAction(
      onInvoke: (intent) => widget.model.timerRestartAndNotifyListeners(),
    ),
    HelpIntent: CallbackAction(
      onInvoke: (intent) => _doToggleCheatSheet(),
    ),
    BottomBarToggleIntent: CallbackAction(
      onInvoke: (intent) => _doToggleBottomBar(),
    ),
    OpenFilesIntent: CallbackAction(
      onInvoke: (intent) => widget.model.openFilePickerForImages(),
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
  };

  late TimerDurationPanel timerDurationWidget =
      TimerDurationPanel(onCloseIntent: _doStopEditingCustomTime);
  final ImagePhviewer imagePhviewer = ImagePhviewer();

  bool rightControlsOrientation = true;
  bool isBottomBarMinimized = false;
  bool isAlwaysOnTop = false;
  bool isSoundsEnabled = true;
  bool isTouch = false;
  bool isEditingTime = false;
  bool isShowingCheatSheet = false;
  bool isShowingFiltersMenu = false;

  @override
  void initState() {
    _bindModelCallbacks();
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

    Widget shortcutsWrapper(Widget childWidget) {
      return Shortcuts(
        shortcuts: Phshortcuts.intentMap,
        child: Actions(
          actions: shortcutActions,
          child: Focus(
            focusNode: mainWindowFocus,
            autofocus: true,
            child: childWidget,
          ),
        ),
      );
    }

    return shortcutsWrapper(Container(
      color: backgroundColor,
      child: Stack(
        children: [
          imagePhviewer.widget(isBottomBarMinimized),
          _fileDropZone(),
          _gestureControls(),
          _topRightWindowControls(),
          _bottomBar(),
          if (isEditingTime) timerDurationWidget,
          if (isShowingCheatSheet)
            HelpSheet(onTapUnderlay: () => _setCheatSheetActive(false)),
          if (isShowingFiltersMenu) _filterMenu(),
          _dockingControls(),
        ],
      ),
    ));
  }

  void _bindModelCallbacks() {
    final model = widget.model;
    model.onTimerElapse ??= () => _playClickSound();
    model.onTimerPlayPause ??= () => _handleTimerPlayPause();
    model.onTimerReset ??= () => _playClickSound();
    model.onFilesChanged ??= () => setState(() {
          /* make the window repaint after loading the first image set */
        });
    model.onTimerChangeSuccess ??= () => _handleTimerChangeSuccess();
    model.onFilesLoadedSuccess ??= _handleFilesLoadedSuccess;
    model.onImageChange ??= _handleOnImageChange;
  }

  Widget _blurSlider() {
    return Row(
      children: [
        const Text('Blur'),
        Slider(
          min: 0,
          max: 12,
          divisions: 12,
          label: imagePhviewer.blurLevel.toInt().toString(),
          onChanged: (value) {
            setState(() {
              imagePhviewer.blurLevel = value;
            });
          },
          value: imagePhviewer.blurLevel,
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
              imagePhviewer.toggleGrayscale();
            });
          },
          child: const Text('Grayscale'),
        ),
        const SizedBox(width: 10),
        Checkbox(
          value: imagePhviewer.isUsingGrayscale,
          onChanged: (value) {
            setState(() {
              imagePhviewer.isUsingGrayscale = value ?? false;
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
                          Icon(Icons.invert_colors,
                              color: Color(0xFFE4E4E4), size: 14),
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

  void _handleOnImageChange() {
    setState(() => imagePhviewer.resetZoomLevel());
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
      timerDurationWidget.setActive(active, widget.model.currentTimerDuration);
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
    const Icon beforeIcon = Icon(Icons.navigate_before, size: 100);
    const Icon nextIcon = Icon(Icons.navigate_next, size: 100);

    const Icon playIcon = Icon(Icons.play_arrow, size: 80);
    const Icon pauseIcon = Icon(Icons.pause, size: 80);

    return PfsAppModel.scope((_, __, model) {
      Icon playPauseIcon = model.isTimerRunning ? pauseIcon : playIcon;

      Widget scrollListener({
        Function()? onScrollUp,
        Function()? onScrollDown,
        Widget? child,
      }) {
        return Listener(
          onPointerSignal: (pointerEvent) {
            if (pointerEvent is PointerScrollEvent) {
              PointerScrollEvent scroll = pointerEvent;
              final dy = scroll.scrollDelta.dy;
              final bool isScrollDown = dy > 0;
              final bool isScrollUp = dy < 0;
              if (isScrollDown) {
                onScrollDown?.call();
              } else if (isScrollUp) {
                onScrollUp?.call();
              }
            }
          },
          child: child,
        );
      }

      Widget nextPreviousOnScrollListener({Widget? child}) {
        return scrollListener(
          onScrollDown: () => model.nextImageNewTimer(),
          onScrollUp: () => model.previousImageNewTimer(),
          child: child,
        );
      }

      Widget zoomOnScrollListener({Widget? child}) {
        void incrementZoomLevel(int increment) =>
            setState(() => imagePhviewer.incrementZoomLevel(increment));

        return scrollListener(
          onScrollDown: () => incrementZoomLevel(1),
          onScrollUp: () => incrementZoomLevel(-1),
          child: child,
        );
      }

      Widget nextPreviousGestureButton(
          {required double width,
          required Function()? onPressed,
          required Widget child}) {
        return SizedBox(
          width: 100,
          child: nextPreviousOnScrollListener(
            child: OverlayButton(
              onPressed: () => model.previousImageNewTimer(),
              child: beforeIcon,
            ),
          ),
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
            nextPreviousGestureButton(
                width: 100,
                onPressed: () => model.previousImageNewTimer(),
                child: beforeIcon),
            Expanded(
                flex: 4,
                child: zoomOnScrollListener(
                  child: GestureDetector(
                    // onSecondaryTapDown: (details) {
                    //   print('right-clicked');
                    // },
                    child: OverlayButton(
                      onPressed: () =>
                          model.setTimerActive(!model.isTimerRunning),
                      child: playPauseIcon,
                    ),
                  ),
                )),
            nextPreviousGestureButton(
                width: 140,
                onPressed: () => model.nextImageNewTimer(),
                child: nextIcon),
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
          icon: Icon(
            Icons.contrast,
            color: imagePhviewer.isEffectActive ? Colors.orange : Colors.grey,
            size: 20,
          ),
        ),
      );

      if (model.hasFilesLoaded) {
        return [
          filtersButton,
          //_bottomButton(() => null, Icons.swap_horiz, 'Flip controls'), // Do this in the settings menu
          const SizedBox(width: 15),
          Phbuttons.timerButton(onPressed: () => _doStartEditingCustomTime()),
          const SizedBox(width: 15),
          Opacity(
            opacity: model.allowTimerPlayPause ? 0.4 : 0.2,
            child: _timerControls(),
          ),
          const SizedBox(width: 20),
          Phbuttons.imageSetButton(),
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
      child: PfsAppModel.scope(
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
          PfsAppModel.scope(
            (_, __, model) => Phbuttons.timerControl(
              () => model.timerRestartAndNotifyListeners(),
              Icons.refresh,
              'Restart Timer (R)',
            ),
          ),
          PfsAppModel.scope(
            (_, __, model) => Phbuttons.timerControl(
              () => model.previousImageNewTimer(),
              Icons.skip_previous,
              'Previous Image (K)',
            ),
          ),
          Phbuttons.playPauseTimer(),
          PfsAppModel.scope(
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

  void _playClickSound() {
    if (!isSoundsEnabled) return;
    clicker.play(_clickSound);
  }
}
