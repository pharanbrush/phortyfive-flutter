import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pfs2/models/pfs_model.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';
import 'package:pfs2/ui/phclicker.dart';
import 'package:pfs2/ui/phshortcuts.dart';
import 'package:pfs2/widgets/animation/phanimations.dart';
import 'package:pfs2/widgets/panels/countdown_sheet.dart';
import 'package:pfs2/widgets/panels/filter_menu.dart';
import 'package:pfs2/widgets/panels/first_action_sheet.dart';
import 'package:pfs2/widgets/panels/help_sheet.dart';
import 'package:pfs2/widgets/panels/image_drop_target.dart';
import 'package:pfs2/widgets/image_phviewer.dart';
import 'package:pfs2/widgets/overlay_button.dart';
import 'package:pfs2/widgets/phbuttons.dart';
import 'package:pfs2/widgets/snackbar_phmessage.dart';
import 'package:pfs2/widgets/phtimer_widgets.dart';
import 'package:pfs2/widgets/panels/timer_duration_panel.dart';
import 'package:pfs2/widgets/wrappers/scroll_listener.dart';
import 'package:window_manager/window_manager.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.model});

  final PfsAppModel model;

  static SnackBar snackBar(BuildContext context, {required Widget content}) {
    const double sideMarginNormal = 200;
    const double sideMarginNarrow = 20;
    const marginNormal = EdgeInsets.only(
        bottom: 50, left: sideMarginNormal, right: sideMarginNormal);

    const marginNarrow = EdgeInsets.only(
        bottom: 50, left: sideMarginNarrow, right: sideMarginNarrow);

    const double windowNarrowWidth = 700;
    const Duration duration = Duration(milliseconds: 1500);

    final bool isWindowNarrow =
        MediaQuery.of(context).size.width < windowNarrowWidth;
    final EdgeInsets margin = isWindowNarrow ? marginNarrow : marginNormal;

    return SnackBar(
      dismissDirection: DismissDirection.up,
      behavior: SnackBarBehavior.floating,
      duration: duration,
      margin: margin,
      content: Center(child: content),
    );
  }

  static SnackBar snackBarTextWithBold(BuildContext context, String text,
      {String? boldText, String? lastText}) {
    return snackBar(context,
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

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  final FocusNode mainWindowFocus = FocusNode();
  final Phclicker clicker = Phclicker();

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
    OpenFolderIntent: CallbackAction(
      onInvoke: (intent) => widget.model.openFilePickerForFolder(),
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
      TimerDurationPanel(onDismiss: _doStopEditingCustomTime);
  late ImagePhviewer imagePhviewer = ImagePhviewer(
    onNotify: (iconData, message) {
      _showSnackBar(
          content: SnackbarPhmessage(
        text: message,
        icon: iconData,
      ));
    },
    onStateChange: _handleStateChange,
  );

  bool rightControlsOrientation = true;
  bool isBottomBarMinimized = false;
  bool isAlwaysOnTop = false;
  bool isSoundsEnabled = true;
  bool isTouch = false;
  bool isEditingTime = false;
  bool isShowingCheatSheet = false;
  bool isShowingFiltersMenu = false;

  late final AnimationController _playPauseIconStateAnimator =
      AnimationController(
    duration: const Duration(milliseconds: 200),
    value:
        1, // BUG: the default 0 causes the icon to have the wrong initial state when the timer first plays.
    vsync: this,
  );

  @override
  void initState() {
    _bindModelCallbacks();
    super.initState();
  }

  @override
  void dispose() {
    _playPauseIconStateAnimator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.model.hasFilesLoaded) {
      return Stack(
        children: [
          const FirstActionSheet(),
          _topRightWindowControls(),
          _bottomBar(context),
          _fileDropZone(),
        ],
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

    Widget modalMenu(
        {required bool isOpen, required Widget Function() builder}) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 120),
        child: isOpen ? builder() : null,
      );
    }

    return shortcutsWrapper(Stack(
      children: [
        imagePhviewer.widget(isBottomBarMinimized),
        _fileDropZone(),
        _gestureControls(),
        const CountdownSheet(),
        _topRightWindowControls(),
        _bottomBar(context),
        modalMenu(isOpen: isEditingTime, builder: () => timerDurationWidget),
        modalMenu(
          isOpen: isShowingCheatSheet,
          builder: () =>
              HelpSheet(onDismiss: () => _setCheatSheetActive(false)),
        ),
        modalMenu(
          isOpen: isShowingFiltersMenu,
          builder: () => FilterMenu(
            imagePhviewer: imagePhviewer,
            onDismiss: () => _setFiltersMenuActive(false),
          ),
        ),
        _dockingControls(),
      ],
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
    model.onCountdownUpdate ??= () => _playClickSound();
  }

  void _setFiltersMenuActive(bool active) {
    setState(() {
      isShowingFiltersMenu = active;
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
            text2: ' loaded. ',
            boldText2: '($filesSkipped incompatible $fileSkippedNoun skipped)'),
      );
    }
  }

  void _handleTimerChangeSuccess() {
    _showSnackBarWithBoldText(
      text: 'Timer is set to ',
      boldText: '${widget.model.currentTimerDuration} seconds',
      lastText: ' per image.',
    );
  }

  void _handleOnImageChange() {
    setState(() => imagePhviewer.resetZoomLevel());
  }

  void _handleStateChange() {
    setState(() {});
  }

  void _handleTimerPlayPause() {
    if (widget.model.isTimerRunning) {
      _playPauseIconStateAnimator.forward();
    } else {
      _playPauseIconStateAnimator.reverse();
    }
    _playClickSound();
  }

  void _doStartEditingCustomTime() => _setEditingCustomTimeActive(true);

  void _doStopEditingCustomTime() => _setEditingCustomTimeActive(false);

  void _showSnackBar({required Widget content}) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    scaffoldMessenger.clearSnackBars();
    scaffoldMessenger.showSnackBar(
      MainScreen.snackBar(
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
      MainScreen.snackBarTextWithBold(
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
    AnimatedIcon playPauseIcon = AnimatedIcon(
      icon: AnimatedIcons.play_pause,
      size: 80,
      progress: _playPauseIconStateAnimator,
    );

    return PfsAppModel.scope((_, __, model) {
      Widget nextPreviousOnScrollListener({Widget? child}) {
        return ScrollListener(
          onScrollDown: () => model.nextImageNewTimer(),
          onScrollUp: () => model.previousImageNewTimer(),
          child: child,
        );
      }

      Widget zoomOnScrollListener({Widget? child}) {
        void incrementZoomLevel(int increment) => setState(() {
              imagePhviewer.incrementZoomLevel(increment);
            });

        return ScrollListener(
          onScrollDown: () => incrementZoomLevel(-1),
          onScrollUp: () => incrementZoomLevel(1),
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
              onPressed: onPressed,
              child: child,
            ),
          ),
        );
      }

      return Positioned.fill(
        top: 50,
        bottom: 80,
        left: 10,
        right: 10,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            nextPreviousGestureButton(
                width: 100,
                onPressed: () => model.previousImageNewTimer(),
                child: PfsTheme.beforeGestureIcon),
            Expanded(
                flex: 4,
                child: zoomOnScrollListener(
                  child: imagePhviewer.imageRightClick(
                    clipboardCopyHandler: _clipboardCopyHandler,
                    child: OverlayButton(
                      onPressed: () => model.playPauseToggleTimer(),
                      child: playPauseIcon,
                    ),
                  ),
                )),
            nextPreviousGestureButton(
                width: 140,
                onPressed: () => model.nextImageNewTimer(),
                child: PfsTheme.nextGestureIcon),
          ],
        ),
      );
    });
  }

  void _clipboardCopyHandler({newClipboardText, snackbarMessage}) =>
      _setClipboardText(
          text: newClipboardText, snackbarMessage: snackbarMessage);

  void _setClipboardText(
      {required String text,
      String? snackbarMessage,
      IconData? icon = Icons.copy}) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (snackbarMessage != null) {
      _showSnackBar(
          content: SnackbarPhmessage(
        text: snackbarMessage,
        icon: icon,
      ));
    }
  }

  Widget _fileDropZone() {
    return Positioned.fill(
      left: 20,
      right: 20,
      bottom: 40,
      top: 30,
      child: ImageDropTarget(
        onDragSuccess: _handleFileDropped,
      ),
    );
  }

  void _handleFileDropped() {
    windowManager.focus();
  }

  Widget _topRightWindowControls() {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Phbuttons.topControl(
                  onPressed: () => _doToggleSounds(),
                  icon: isSoundsEnabled ? Icons.volume_up : Icons.volume_off,
                  tooltip:
                      isSoundsEnabled ? 'Mute sounds (M)' : 'Unmute sounds (M)',
                ),
                Phbuttons.topControl(
                  onPressed: () => _doToggleAlwaysOnTop(),
                  icon: isAlwaysOnTop
                      ? Icons.push_pin_rounded
                      : Icons.push_pin_outlined,
                  tooltip: 'Keep Window on Top (Ctrl+T)',
                  isSelected: isAlwaysOnTop,
                ),
                Phbuttons.topControl(
                  onPressed: () => _setCheatSheetActive(true),
                  icon: Icons.help_rounded,
                  tooltip: 'Help... (F1)',
                ),
                //Phbuttons.topControl(() {}, Icons.info_outline_rounded, 'About...'),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            child: Text(
              'For testing only\n0.5.20231006a',
              textAlign: TextAlign.right,
              style: PfsTheme.topRightWatermarkTextStyle,
            ),
          ),
          if (imagePhviewer.currentZoomScale != 1.0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: Text(
                'Zoom ${imagePhviewer.currentZoomScalePercent}%',
                textAlign: TextAlign.right,
                style: PfsTheme.topRightWatermarkTextStyle,
              ),
            )
        ],
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
              ),
      );
    }

    setState(() {
      isSoundsEnabled = !isSoundsEnabled;
      showSoundToggleSnackbar();
    });
  }

  Widget _bottomBar(BuildContext context) {
    if (isBottomBarMinimized) {
      return const Positioned(
        bottom: 1,
        right: 10,
        child: Opacity(
          opacity: PfsTheme.bottomBarButtonOpacity,
          child: Row(children: [
            TimerBar(),
            SizedBox(width: 140),
          ]),
        ),
      );
    }

    List<Widget> bottomBarItems(PfsAppModel model) {
      const double filterIconSize = 20;
      const filterIconOff = Icon(
        Icons.contrast,
        size: filterIconSize,
      );
      const filterIconOn = Icon(
        Icons.contrast,
        size: filterIconSize,
      );

      final filtersButton = IconButton(
        onPressed: () => _setFiltersMenuActive(true),
        style: PfsTheme.bottomBarButtonStyle,
        isSelected: imagePhviewer.isFilterActive,
        tooltip: 'Filters',
        icon: imagePhviewer.isFilterActive ? filterIconOn : filterIconOff,
      );

      final resetZoomButton = IconButton(
        tooltip: 'Reset zoom',
        onPressed: () => setState(() => imagePhviewer.resetZoomLevel()),
        icon: const Icon(
          Icons.youtube_searched_for,
          color: PfsTheme.bottomBarButtonContentColor,
        ),
      );

      if (model.hasFilesLoaded) {
        return [
          if (!imagePhviewer.isZoomLevelDefault) resetZoomButton,
          filtersButton,
          //_bottomButton(() => null, Icons.swap_horiz, 'Flip controls'), // Do this in the settings menu
          const SizedBox(width: 15),
          Phbuttons.timerSettingsButton(
              onPressed: () => _doStartEditingCustomTime()),
          const SizedBox(width: 15),
          Opacity(
            opacity: model.allowTimerPlayPause ? 1 : 0.5,
            child: _timerControls(context),
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
          return Row(
            children: bottomBarItems(model).animate(
              interval: const Duration(milliseconds: 25),
              effects: [Phanimations.bottomBarSlideUpEffect],
            ),
          );
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
        onPressed: () => _doToggleBottomBar(),
      ),
    );
  }

  Widget _timerControls(BuildContext context) {
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
          Phbuttons.playPauseTimer(context, _playPauseIconStateAnimator),
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
    if (!widget.model.isTimerRunning) return;
    clicker.playSound();
  }
}
