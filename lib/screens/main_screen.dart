import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pfs2/models/pfs_model.dart';
import 'package:pfs2/models/phtimer_model.dart';
import 'package:pfs2/ui/pfs_localization.dart';
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
  final PfsWindowState windowState = PfsWindowState();

  late Map<Type, Action<Intent>> shortcutActions = {
    PreviousImageIntent: CallbackAction(
      onInvoke: (_) => widget.model.previousImageNewTimer(),
    ),
    NextImageIntent: CallbackAction(
      onInvoke: (_) => widget.model.nextImageNewTimer(),
    ),
    PlayPauseIntent: CallbackAction(
      onInvoke: (_) => widget.model.tryTogglePlayPauseTimer(),
    ),
    OpenTimerMenuIntent: CallbackAction(
      onInvoke: (_) => _doStartEditingCustomTime(),
    ),
    RestartTimerIntent: CallbackAction(
      onInvoke: (_) => widget.model.timerModel.restartTimer(),
    ),
    HelpIntent: CallbackAction(
      onInvoke: (_) => _doToggleCheatSheet(),
    ),
    BottomBarToggleIntent: CallbackAction(
      onInvoke: (_) => _doToggleBottomBar(),
    ),
    OpenFilesIntent: CallbackAction(
      onInvoke: (_) => widget.model.openFilePickerForImages(),
    ),
    OpenFolderIntent: CallbackAction(
      onInvoke: (_) => widget.model.openFilePickerForFolder(),
    ),
    AlwaysOnTopIntent: CallbackAction(
      onInvoke: (_) => _doToggleAlwaysOnTop(),
    ),
    ToggleSoundIntent: CallbackAction(
      onInvoke: (_) => _doToggleSounds(),
    ),
    ReturnHomeIntent: CallbackAction(
      onInvoke: (_) => _tryReturnHome(),
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
  late final AnimationController _playPauseIconStateAnimator =
      AnimationController(
    duration: Phanimations.defaultDuration,
    value:
        1, // WORKAROUND: the default 0 causes the icon to have the wrong initial state when the timer first plays.
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
          _fileDropZone,
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
        duration: Phanimations.fastDuration,
        child: isOpen ? builder() : null,
      );
    }

    return shortcutsWrapper(
      Stack(
        children: [
          imagePhviewer.widget(windowState.isBottomBarMinimized),
          _fileDropZone,
          _gestureControls(),
          const CountdownSheet(),
          _topRightWindowControls(),
          _bottomBar(context),
          modalMenu(
            isOpen: windowState.isEditingTime,
            builder: () => TimerDurationPanel(
              onDismiss: () => _doStopEditingCustomTime(),
            ),
          ),
          modalMenu(
            isOpen: windowState.isShowingCheatSheet,
            builder: () => Theme(
              data: ThemeData.dark(useMaterial3: true),
              child: HelpSheet(onDismiss: () => _setCheatSheetActive(false)),
            ),
          ),
          modalMenu(
            isOpen: windowState.isShowingFiltersMenu,
            builder: () => FilterMenu(
              imagePhviewer: imagePhviewer,
              onDismiss: () => _setFiltersMenuActive(false),
            ),
          ),
          _dockingControls(),
        ],
      ),
    );
  }

  void _bindModelCallbacks() {
    final model = widget.model;
    model.onFilesChanged ??= () => setState(() {
          /* make the window repaint after loading the first image set */
        });
    model.onFilesLoadedSuccess ??= _handleFilesLoadedSuccess;
    model.onImageChange ??= _handleOnImageChange;
    model.onCountdownUpdate ??= () => _playClickSound();
    model.onImageDurationElapse ??= () => _playClickSound();

    final timerModel = model.timerModel;
    timerModel.onPlayPause ??= () => _handleTimerPlayPause();
    timerModel.onReset ??= () => _playClickSound();
    timerModel.onDurationChangeSuccess ??= () => _handleTimerChangeSuccess();
  }

  void _setFiltersMenuActive(bool active) {
    setState(() {
      windowState.isShowingFiltersMenu = active;
    });
  }

  void _cancelAllModals() {
    if (windowState.isShowingCheatSheet) {
      _setCheatSheetActive(false);
    }

    if (windowState.isEditingTime) {
      _doStopEditingCustomTime();
    }
  }

  void _tryReturnHome() {
    _cancelAllModals();
  }

  void _handleFilesLoadedSuccess(int filesLoaded, int filesSkipped) {
    final imageNoun = PfsLocalization.imageNoun(filesLoaded);

    if (filesSkipped == 0) {
      _showSnackBarWithBoldText(
        text: '',
        boldText: '$filesLoaded $imageNoun',
        lastText: ' loaded.',
      );
    } else {
      final fileSkippedNoun = PfsLocalization.fileNoun(filesSkipped);

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
      boldText: '${widget.model.timerModel.currentDurationSeconds} seconds',
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
    if (widget.model.timerModel.isRunning) {
      _playPauseIconStateAnimator.forward();
    } else {
      _playPauseIconStateAnimator.reverse();
    }
    _playClickSound(playWhilePaused: true);
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
      windowState.isEditingTime = active;
      if (!active) {
        mainWindowFocus.requestFocus();
      }
      //timerDurationWidget.setActive(active, widget.model.timerModel.currentDurationSeconds);
    });
  }

  void _doToggleCheatSheet() {
    _setCheatSheetActive(!windowState.isShowingCheatSheet);
  }

  void _setCheatSheetActive(bool active) {
    if (active) _cancelAllModals();

    setState(() {
      windowState.isShowingCheatSheet = active;
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
                      onPressed: () => model.tryTogglePlayPauseTimer(),
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

  void _setClipboardText({
    required String text,
    String? snackbarMessage,
    IconData? icon = Icons.copy,
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (snackbarMessage != null) {
      _showSnackBar(
          content: SnackbarPhmessage(
        text: snackbarMessage,
        icon: icon,
      ));
    }
  }

  late final Widget _fileDropZone = Positioned.fill(
    left: 20,
    right: 20,
    bottom: 40,
    top: 30,
    child: ImageDropTarget(onDragSuccess: _handleFileDropped),
  );

  void _handleFileDropped() {
    windowManager.focus();
  }

  Widget _topRightWindowControls() {
    final soundShortcut =
        PfsLocalization.tooltipShortcut(Phshortcuts.toggleSounds);
    const Color watermarkColor = Color(0x55555555);
    const topRightWatermarkTextStyle =
        TextStyle(color: watermarkColor, fontSize: 12);

    return Positioned(
      right: 4,
      top: 2,
      child: Wrap(
        direction: Axis.vertical,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          Wrap(
            spacing: 3,
            direction: Axis.horizontal,
            alignment: WrapAlignment.end,
            children: [
              Phbuttons.topControl(
                onPressed: () => _doToggleSounds(),
                icon: windowState.isSoundsEnabled
                    ? Icons.volume_up
                    : Icons.volume_off,
                tooltip: windowState.isSoundsEnabled
                    ? 'Mute sounds ($soundShortcut)'
                    : 'Unmute sounds ($soundShortcut)',
              ),
              Phbuttons.topControl(
                onPressed: () => _doToggleAlwaysOnTop(),
                icon: windowState.isAlwaysOnTop
                    ? Icons.push_pin_rounded
                    : Icons.push_pin_outlined,
                tooltip: PfsLocalization.buttonTooltip(
                  commandName: PfsLocalization.alwaysOnTop,
                  shortcut: Phshortcuts.alwaysOnTop,
                ),
                isSelected: windowState.isAlwaysOnTop,
              ),
              Phbuttons.topControl(
                onPressed: () => _setCheatSheetActive(true),
                icon: Icons.help_rounded,
                tooltip: PfsLocalization.buttonTooltip(
                  commandName: PfsLocalization.help,
                  shortcut: Phshortcuts.help,
                ),
              ),
              //Phbuttons.topControl(() {}, Icons.info_outline_rounded, 'About...'),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 14),
            child: DefaultTextStyle(
              textAlign: TextAlign.right,
              style: topRightWatermarkTextStyle,
              child: Wrap(
                direction: Axis.vertical,
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 5,
                children: [
                  const Text('For testing only\n${PfsLocalization.version}'),
                  if (imagePhviewer.currentZoomScale != 1.0)
                    Text('Zoom ${imagePhviewer.currentZoomScalePercent}%'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _doToggleAlwaysOnTop() {
    showAlwaysOnTopToggleSnackbar() {
      _showSnackBar(
          content: windowState.isAlwaysOnTop
              ? const SnackbarPhmessage(
                  text: '"${PfsLocalization.alwaysOnTop}" enabled',
                  icon: Icons.push_pin,
                )
              : const SnackbarPhmessage(
                  text: '"${PfsLocalization.alwaysOnTop}" disabled',
                  icon: Icons.push_pin_outlined,
                ));
    }

    setState(() {
      windowState.isAlwaysOnTop = !windowState.isAlwaysOnTop;
      windowManager.setAlwaysOnTop(windowState.isAlwaysOnTop);
      showAlwaysOnTopToggleSnackbar();
    });
  }

  void _doToggleSounds() {
    showSoundToggleSnackbar() {
      _showSnackBar(
        content: windowState.isSoundsEnabled
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
      windowState.isSoundsEnabled = !windowState.isSoundsEnabled;
      showSoundToggleSnackbar();
    });
  }

  static const Key timerBarKey = Key('timerBar');

  Widget _bottomBar(BuildContext context) {
    const Widget minimizedBottomBar = Positioned(
      bottom: 1,
      right: 10,
      child: Row(children: [
        TimerBar(key: timerBarKey),
        SizedBox(width: 140),
      ]),
    );

    if (windowState.isBottomBarMinimized) {
      return minimizedBottomBar;
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
        isSelected: imagePhviewer.isFilterActive,
        tooltip: 'Filters',
        icon: imagePhviewer.isFilterActive ? filterIconOn : filterIconOff,
      );

      final resetZoomButton = IconButton(
        tooltip: 'Reset zoom',
        onPressed: () => setState(() => imagePhviewer.resetZoomLevel()),
        icon: const Icon(Icons.youtube_searched_for),
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
            child: _timerControls,
          ),
          const SizedBox(width: 20),
          const ImageSetButton(),
          const SizedBox(width: 10),
        ];
      } else {
        return [
          Phbuttons.openFiles(),
          const SizedBox(width: 15, height: 43),
        ];
      }
    }

    final normalBottomBar = Positioned(
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

    return normalBottomBar;
  }

  void _doToggleBottomBar() {
    setState(() {
      windowState.isBottomBarMinimized = !windowState.isBottomBarMinimized;
    });
  }

  Widget _dockingControls() {
    return Positioned(
      bottom: 3,
      right: 3,
      child: CollapseBottomBarButton(
        isMinimized: windowState.isBottomBarMinimized,
        onPressed: () => _doToggleBottomBar(),
      ),
    );
  }

  late final Widget _timerControls = Column(
    children: [
      const TimerBar(key: timerBarKey),
      Row(
        children: [
          PhtimerModel.scope(
            (_, __, model) => BottomBarTimerControl(
              onPressed: () => model.restartTimer(),
              icon: Icons.refresh,
              tooltip: PfsLocalization.buttonTooltip(
                commandName: 'Restart timer',
                shortcut: Phshortcuts.restartTimer,
              ),
            ),
          ),
          PfsAppModel.scope(
            (_, __, model) => BottomBarTimerControl(
              onPressed: () => model.previousImageNewTimer(),
              icon: Icons.skip_previous,
              tooltip: PfsLocalization.buttonTooltip(
                commandName: 'Previous Image',
                shortcut: Phshortcuts.previous2,
              ),
            ),
          ),
          PlayPauseTimerButton(iconProgress: _playPauseIconStateAnimator),
          PfsAppModel.scope(
            (_, __, model) => BottomBarTimerControl(
              onPressed: () => model.nextImageNewTimer(),
              icon: Icons.skip_next,
              tooltip: PfsLocalization.buttonTooltip(
                commandName: 'Next Image',
                shortcut: Phshortcuts.next2,
              ),
            ),
          ),
        ],
      )
    ],
  );

  void _playClickSound({bool playWhilePaused = false}) {
    if (!windowState.isSoundsEnabled) return;
    if (!widget.model.timerModel.isRunning && !playWhilePaused) return;
    clicker.playSound();
  }
}

class PfsWindowState with ChangeNotifier {
  bool rightControlsOrientation = true;
  bool isBottomBarMinimized = false;
  bool isAlwaysOnTop = false;
  bool isSoundsEnabled = true;
  bool isTouch = false;
  bool isEditingTime = false;
  bool isShowingCheatSheet = false;
  bool isShowingFiltersMenu = false;
}
