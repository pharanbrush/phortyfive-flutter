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
import 'package:pfs2/widgets/panels/corner_window_controls.dart';
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
    RestartTimerIntent: CallbackAction(
      onInvoke: (_) => widget.model.timerModel.restartTimer(),
    ),
    OpenFilesIntent: CallbackAction(
      onInvoke: (_) => widget.model.openFilePickerForImages(),
    ),
    OpenFolderIntent: CallbackAction(
      onInvoke: (_) => widget.model.openFilePickerForFolder(),
    ),
    OpenTimerMenuIntent: CallbackAction(
      onInvoke: (_) => windowState.isEditingTime.set(true),
    ),
    HelpIntent: CallbackAction(
      onInvoke: (_) => windowState.isShowingCheatSheet.set(true),
    ),
    BottomBarToggleIntent: CallbackAction(
      onInvoke: (_) => windowState.isBottomBarMinimized.toggle(),
    ),
    AlwaysOnTopIntent: CallbackAction(
      onInvoke: (_) => windowState.isAlwaysOnTop.toggle(),
    ),
    ToggleSoundIntent: CallbackAction(
      onInvoke: (_) => windowState.isSoundsEnabled.toggle(),
    ),
    ReturnHomeIntent: CallbackAction(
      onInvoke: (_) => _tryReturnHome(),
    ),
  };

  late TimerDurationPanel timerDurationWidget =
      TimerDurationPanel(onDismiss: () => windowState.isEditingTime.set(false));
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
          CornerWindowControls(
            windowState: windowState,
            imagePhviewer: imagePhviewer,
          ),
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
          imagePhviewer.widget(windowState.isBottomBarMinimized.boolValue),
          _fileDropZone,
          _gestureControls(),
          const CountdownSheet(),
          CornerWindowControls(
            windowState: windowState,
            imagePhviewer: imagePhviewer,
          ),
          _bottomBar(context),
          modalMenu(
            isOpen: windowState.isEditingTime.boolValue,
            builder: () => timerDurationWidget,
          ),
          modalMenu(
            isOpen: windowState.isShowingCheatSheet.boolValue,
            builder: () => Theme(
              data: ThemeData.dark(useMaterial3: true),
              child: HelpSheet(
                onDismiss: () => windowState.isShowingCheatSheet.set(false),
              ),
            ),
          ),
          modalMenu(
            isOpen: windowState.isShowingFiltersMenu.boolValue,
            builder: () => FilterMenu(
              imagePhviewer: imagePhviewer,
              onDismiss: () => windowState.isShowingFiltersMenu.set(false),
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

    windowState.isAlwaysOnTop.setListener(() => _handleAlwaysOnTopChanged());
    windowState.isSoundsEnabled.setListener(() => _handleSoundChanged());
    windowState.isShowingCheatSheet
        .setListener(() => _handleCheatSheetChanged());
    windowState.isEditingTime.setListener(() => _handleEditingTimeChanged());
    windowState.isBottomBarMinimized
        .setListener(() => _handleBottomBarChanged());
    windowState.isShowingFiltersMenu
        .setListener(() => _handleFilterMenuChanged());
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

  void _handleFilterMenuChanged() {
    setState(() {});
  }

  void _handleBottomBarChanged() {
    setState(() {});
  }

  void _cancelAllModals({ListenableBool? except}) {
    void tryDismiss(ListenableBool toDismiss) {
      if (except == null || toDismiss != except) {
        toDismiss.set(false);
      }
    }

    tryDismiss(windowState.isShowingCheatSheet);
    tryDismiss(windowState.isEditingTime);
    tryDismiss(windowState.isShowingFiltersMenu);
  }

  void _handleEditingTimeChanged() {
    bool active = windowState.isEditingTime.boolValue;
    if (active) {
      _cancelAllModals(except: windowState.isEditingTime);
      ScaffoldMessenger.of(context).clearSnackBars();
    }
    if (!active) {
      mainWindowFocus.requestFocus();
    }

    timerDurationWidget.setActive(
        active, widget.model.timerModel.currentDurationSeconds);

    setState(() {});
  }

  void _handleCheatSheetChanged() {
    _cancelAllModals(except: windowState.isShowingCheatSheet);
    setState(() {});
  }

  void _handleAlwaysOnTopChanged() {
    showAlwaysOnTopToggleSnackbar() {
      _showSnackBar(
          content: windowState.isAlwaysOnTop.boolValue
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
      windowManager.setAlwaysOnTop(windowState.isAlwaysOnTop.boolValue);
      showAlwaysOnTopToggleSnackbar();
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

  void _handleSoundChanged() {
    showSoundToggleSnackbar() {
      _showSnackBar(
        content: windowState.isSoundsEnabled.boolValue
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
      //windowState.isSoundsEnabled = !windowState.isSoundsEnabled;
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

    if (windowState.isBottomBarMinimized.boolValue) {
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
        onPressed: () => windowState.isShowingFiltersMenu.set(true),
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
              onPressed: () => windowState.isEditingTime.set(true)),
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

  Widget _dockingControls() {
    return Positioned(
      bottom: 3,
      right: 3,
      child: CollapseBottomBarButton(
        isMinimized: windowState.isBottomBarMinimized.boolValue,
        onPressed: () => windowState.isBottomBarMinimized.toggle(),
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
    if (!windowState.isSoundsEnabled.boolValue) return;
    if (!widget.model.timerModel.isRunning && !playWhilePaused) return;
    clicker.playSound();
  }
}

class PfsWindowState {
  bool rightControlsOrientation = true;
  bool isTouch = false;

  final isBottomBarMinimized = ListenableBool(false);
  final isAlwaysOnTop = ListenableBool(false);
  final isSoundsEnabled = ListenableBool(true);
  final isEditingTime = ListenableBool(false);
  final isShowingCheatSheet = ListenableBool(false);
  final isShowingFiltersMenu = ListenableBool(false);
}

class ListenableBool {
  ListenableBool(bool initialValue) {
    _boolValue = initialValue;
  }

  bool _boolValue = false;
  bool get boolValue => _boolValue;
  Function()? _onChange;

  void setListener(Function() onChange) {
    _onChange = onChange;
  }

  void set(bool newValue) {
    if (_boolValue == newValue) return;
    _boolValue = newValue;
    _onChange?.call();
  }

  void toggle() {
    set(!_boolValue);
  }
}
