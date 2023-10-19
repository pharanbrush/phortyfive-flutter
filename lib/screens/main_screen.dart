import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pfs2/models/pfs_model.dart';
import 'package:pfs2/ui/pfs_localization.dart';
import 'package:pfs2/ui/phtoasts.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';
import 'package:pfs2/ui/phclicker.dart';
import 'package:pfs2/ui/phshortcuts.dart';
import 'package:pfs2/utils/preferences.dart';
import 'package:pfs2/widgets/animation/phanimations.dart';
import 'package:pfs2/widgets/panels/countdown_sheet.dart';
import 'package:pfs2/widgets/panels/filter_menu.dart';
import 'package:pfs2/widgets/panels/first_action_sheet.dart';
import 'package:pfs2/widgets/panels/help_sheet.dart';
import 'package:pfs2/widgets/panels/image_drop_target.dart';
import 'package:pfs2/widgets/image_phviewer.dart';
import 'package:pfs2/widgets/overlay_button.dart';
import 'package:pfs2/widgets/panels/corner_window_controls.dart';
import 'package:pfs2/widgets/panels/settings_panel.dart';
import 'package:pfs2/widgets/phbuttons.dart';
import 'package:pfs2/widgets/phtimer_widgets.dart';
import 'package:pfs2/widgets/panels/timer_duration_panel.dart';
import 'package:pfs2/widgets/wrappers/scroll_listener.dart';
import 'package:window_manager/window_manager.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.model, required this.theme});

  final PfsAppModel model;
  final ValueNotifier<String> theme;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  final FocusNode mainWindowFocus = FocusNode();
  final Phclicker clicker = Phclicker();
  final PfsWindowState windowState = PfsWindowState();

  late final ModalMenu filtersMenu = ModalMenu(
    builder: (closeMenu) {
      return FilterMenu(imagePhviewer: imagePhviewer, onDismiss: closeMenu);
    },
  );

  late final ModalMenu helpMenu = ModalMenu(
    onOpen: () => _handleHelpMenuChanged(),
    builder: (closeMenu) {
      return Theme(
        data: ThemeData.dark(useMaterial3: true),
        child: HelpSheet(onDismiss: closeMenu),
      );
    },
  );

  BuildContext? currentContext;

  final Map<Type, Action<Intent>> shortcutActions = {};
  late List<(Type, Object? Function(Intent))> shortcutIntentActions = [
    (PreviousImageIntent, (_) => widget.model.previousImageNewTimer()),
    (NextImageIntent, (_) => widget.model.nextImageNewTimer()),
    (PlayPauseIntent, (_) => widget.model.tryTogglePlayPauseTimer()),
    (RestartTimerIntent, (_) => widget.model.timerModel.restartTimer()),
    (OpenFilesIntent, (_) => widget.model.openFilePickerForImages()),
    (OpenFolderIntent, (_) => widget.model.openFilePickerForFolder()),
    (
      OpenTimerMenuIntent,
      (_) => windowState.isShowingTimerDurationMenu.set(true)
    ),
    (HelpIntent, (_) => helpMenu.open()),
    (BottomBarToggleIntent, (_) => windowState.isBottomBarMinimized.toggle()),
    (AlwaysOnTopIntent, (_) => windowState.isAlwaysOnTop.toggle()),
    (ToggleSoundIntent, (_) => windowState.isSoundsEnabled.toggle()),
    (ReturnHomeIntent, (_) => _tryReturnHome())
  ];

  //WORKAROUND: widget with persistent state that can be commanded directly by the main window.
  late TimerDurationPanel timerDurationWidget = TimerDurationPanel(
      onDismiss: () => windowState.isShowingTimerDurationMenu.set(false));
  late ImagePhviewer imagePhviewer = ImagePhviewer(
    onNotify: (message, icon) {
      showImagePhviewerToast(message: message, icon: icon);
    },
  );

  late final AnimationController _playPauseIconStateAnimator =
      AnimationController(
    duration: Phanimations.defaultDuration,
    // WORKAROUND: the default value: 0 causes the icon to have the wrong initial state when the timer first plays.
    value: 1,
    vsync: this,
  );

  @override
  void initState() {
    _bindModelCallbacks();
    _loadSettings();
    super.initState();
  }

  @override
  void dispose() {
    _playPauseIconStateAnimator.dispose();
    _handleDisposeCallbacks();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    currentContext = context;

    final theme = Theme.of(context);
    final borderSide = theme.extension<PfsAppTheme>()?.appWindowBorderSide;

    final Size windowSize = MediaQuery.of(context).size;

    Widget modalMenu({
      required bool isOpen,
      required Widget Function() builder,
    }) {
      return AnimatedSwitcher(
        duration: Phanimations.fastDuration,
        child: isOpen ? builder() : null,
      );
    }

    Widget settingsPanel() {
      return modalMenu(
        isOpen: windowState.isShowingSettingsMenu.boolValue,
        builder: () => SettingsPanel(
          windowState: windowState,
          appModel: widget.model,
          themeNotifier: widget.theme,
          onDismiss: () => windowState.isShowingSettingsMenu.set(false),
        ),
      );
    }

    Widget windowBorderWrapper({required Widget child}) {
      return Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(borderSide?.width ?? 0),
            child: child,
          ),
          if (borderSide != null)
            Material(
              type: MaterialType.transparency,
              shape: Border.fromBorderSide(borderSide),
              child: const SizedBox.expand(),
            )
        ],
      );

      // if (borderSide == null) {
      //   return child;
      // } else {
      //   final appWindowPadding = borderSide.width;

      //   return Stack(
      //     children: [
      //       Padding(
      //         padding: EdgeInsets.all(appWindowPadding),
      //         child: child,
      //       ),
      //       if (borderSide != null) Material(
      //         type: MaterialType.transparency,
      //         shape: Border.fromBorderSide(borderSide),
      //         child: const SizedBox.expand(),
      //       )
      //     ],
      //   );
    }

    if (!widget.model.hasFilesLoaded) {
      final firstActionApp = Stack(
        children: [
          const FirstActionSheet(),
          CornerWindowControls(
            windowState: windowState,
            imagePhviewer: imagePhviewer,
            helpMenu: helpMenu,
          ),
          ValueListenableBuilder(
            valueListenable: windowState.isBottomBarMinimized,
            builder: (context, __, ___) {
              return _bottomBar(context);
            },
          ),
          _fileDropZone,
          settingsPanel(),
        ],
      );

      return windowBorderWrapper(child: firstActionApp);
    }

    Widget shortcutsWrapper(Widget childWidget) {
      if (shortcutActions.isEmpty) {
        for (var (intentType, callback) in shortcutIntentActions) {
          shortcutActions[intentType] = CallbackAction(onInvoke: callback);
        }
      }

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

    final appWindowContent = shortcutsWrapper(
      Stack(
        children: [
          ValueListenableBuilder(
            valueListenable: windowState.isBottomBarMinimized,
            builder: (_, isBottomBarMinimized, __) {
              return imagePhviewer.widget(isBottomBarMinimized);
            },
          ),
          _fileDropZone,
          _gestureControls(),
          const CountdownSheet(),
          CornerWindowControls(
            windowState: windowState,
            imagePhviewer: imagePhviewer,
            helpMenu: helpMenu,
          ),
          ValueListenableBuilder(
            valueListenable: windowState.isBottomBarMinimized,
            builder: (_, __, ___) {
              return _bottomBar(
                context,
                windowWidth: windowSize.width,
              );
            },
          ),
          modalMenu(
            isOpen: windowState.isShowingTimerDurationMenu.boolValue,
            builder: () => timerDurationWidget,
          ),
          helpMenu.widget(context),
          filtersMenu.widget(context),
          settingsPanel(),
          _dockingControls(),
        ],
      ),
    );

    return windowBorderWrapper(child: appWindowContent);
  }

  void _loadSettings() async {
    windowState.isSoundsEnabled.value = await Preferences.getSoundsEnabled();
  }

  void _bindModelCallbacks() {
    final model = widget.model;
    model.onFilesChanged ??= () => _handleStateChange();
    model.onFilesLoadedSuccess ??= _handleFilesLoadedSuccess;
    model.onImageChange ??= _handleOnImageChange;
    model.onCountdownUpdate ??= () => _playClickSound();
    model.onImageDurationElapse ??= () => _playClickSound();
    model.onFilePickerStateChange ??= () => _handleFilePickerOpenClose();

    final timerModel = model.timerModel;
    timerModel.onPlayPause ??= () => _handleTimerPlayPause();
    timerModel.onReset ??= () => _playClickSound();
    timerModel.onDurationChangeSuccess ??= () => _handleTimerChangeSuccess();

    windowState.isSoundsEnabled.addListener(() => _handleSoundChanged());
    windowState.isAlwaysOnTop.addListener(() => _handleAlwaysOnTopChanged());

    windowState.isShowingTimerDurationMenu
        .setListener(() => _handleEditingTimeChanged());

    windowState.isShowingSettingsMenu
        .setListener(() => _handleSettingsMenuChanged());
  }

  void _handleDisposeCallbacks() {
    windowState.isSoundsEnabled.removeListener(() => _handleSoundChanged());
    windowState.isAlwaysOnTop.removeListener(() => _handleAlwaysOnTopChanged());
  }

  void _tryReturnHome() {
    _cancelAllModals();
  }

  void _handleFilesLoadedSuccess(int filesLoaded, int filesSkipped) {
    final imageNoun = PfsLocalization.imageNoun(filesLoaded);

    if (filesSkipped == 0) {
      Phtoasts.showWidget(
        currentContext,
        child: PfsLocalization.textWithMultiBold(
          text1: '',
          boldText1: '$filesLoaded $imageNoun',
          text2: ' loaded.',
        ),
      );
    } else {
      final fileSkippedNoun = PfsLocalization.fileNoun(filesSkipped);

      Phtoasts.showWidget(
        currentContext,
        child: PfsLocalization.textWithMultiBold(
            text1: '',
            boldText1: '$filesLoaded $imageNoun',
            text2: ' loaded. ',
            boldText2: '($filesSkipped incompatible $fileSkippedNoun skipped)'),
      );
    }
  }

  void _handleTimerChangeSuccess() {
    final toastContent = PfsLocalization.textWithMultiBold(
      text1: 'Timer is set to ',
      boldText1: '${widget.model.timerModel.currentDurationSeconds} seconds',
      text2: ' per image.',
    );
    Phtoasts.showWidget(currentContext, child: toastContent);
  }

  void _handleOnImageChange() {
    setState(() => imagePhviewer.resetZoomLevel());
  }

  void showImagePhviewerToast({required String message, IconData? icon}) {
    if (currentContext == null) return;
    Phtoasts.show(
      currentContext,
      message: message,
      icon: icon,
      alignment: Phtoasts.topControlsAlign,
    );
  }

  void _handleStateChange() {
    setState(() {});
  }

  void _handleFilePickerOpenClose() {
    _updateAlwaysOnTop();
  }

  void _updateAlwaysOnTop() {
    bool isPickingFiles = widget.model.isPickerOpen;
    bool isAlwaysOnTopUserIntent = windowState.isAlwaysOnTop.value;

    bool currentAlwaysOnTop = isAlwaysOnTopUserIntent && !isPickingFiles;
    windowManager.setAlwaysOnTop(currentAlwaysOnTop);
  }

  void _handleTimerPlayPause() {
    if (widget.model.timerModel.isRunning) {
      _playPauseIconStateAnimator.forward();
    } else {
      _playPauseIconStateAnimator.reverse();
    }

    showTimerToast() {
      if (currentContext == null) return;
      BuildContext context = currentContext!;

      bool isRunning = widget.model.timerModel.isRunning;
      final message = PfsLocalization.timerSwitched(isRunning);
      final icon = isRunning ? Icons.play_arrow : Icons.pause;

      Phtoasts.show(
        context,
        message: message,
        icon: icon,
      );
    }

    showTimerToast();
    _playClickSound(playWhilePaused: true);
  }

  void _cancelAllModals({ListenableBool? except}) {
    void tryDismiss(ListenableBool toDismiss) {
      if (except == null || toDismiss != except) {
        toDismiss.set(false);
      }
    }

    tryDismiss(windowState.isShowingTimerDurationMenu);
  }

  void _cancelAllMenus({ModalMenu? except}) {
    void tryDismiss(ModalMenu toDismiss) {
      if (except != null || toDismiss != except) {
        toDismiss.dismiss();
      }
    }

    tryDismiss(helpMenu);
    tryDismiss(filtersMenu);
  }

  void _handleEditingTimeChanged() {
    bool active = windowState.isShowingTimerDurationMenu.boolValue;
    if (active) {
      _cancelAllModals(except: windowState.isShowingTimerDurationMenu);
      _cancelAllMenus();
    }
    if (!active) {
      mainWindowFocus.requestFocus();
    }

    timerDurationWidget.setActive(
        active, widget.model.timerModel.currentDurationSeconds);

    setState(() {});
  }

  void _handleHelpMenuChanged() {
    _cancelAllMenus(except: helpMenu);
  }

  void _handleAlwaysOnTopChanged() {
    showAlwaysOnTopToast() {
      if (currentContext == null) return;
      BuildContext context = currentContext!;

      bool wasEnabled = windowState.isAlwaysOnTop.value;
      final message = PfsLocalization.alwaysOnTopSwitched(wasEnabled);

      final icon = wasEnabled
          ? Icons.picture_in_picture
          : Icons.picture_in_picture_outlined;

      Phtoasts.show(
        context,
        message: message,
        icon: icon,
        alignment: Phtoasts.topControlsAlign,
      );
    }

    _updateAlwaysOnTop();
    showAlwaysOnTopToast();
  }

  void _handleSoundChanged() {
    showSoundToggleToast() {
      bool wasEnabled = windowState.isSoundsEnabled.value;
      final message = PfsLocalization.soundsSwitched(wasEnabled);
      final icon = wasEnabled ? Icons.volume_up : Icons.volume_off;

      Phtoasts.show(
        context,
        message: message,
        icon: icon,
        alignment: Phtoasts.topControlsAlign,
      );
    }

    showSoundToggleToast();
    Preferences.setSoundsEnabled(windowState.isSoundsEnabled.value);
  }

  void _handleSettingsMenuChanged() {
    _cancelAllModals(except: windowState.isShowingSettingsMenu);
    setState(() {});
  }

  Widget _gestureControls() {
    AnimatedIcon playPauseIcon = AnimatedIcon(
      icon: AnimatedIcons.play_pause,
      size: 80,
      progress: _playPauseIconStateAnimator,
    );

    return PfsAppModel.scope((_, __, model) {
      Widget zoomOnScrollListener({Widget? child}) {
        return ScrollListener(
          onScrollDown: () => imagePhviewer.incrementZoomLevel(-1),
          onScrollUp: () => imagePhviewer.incrementZoomLevel(1),
          child: child,
        );
      }

      Widget nextPreviousGestureButton(
          {required double width,
          required Function()? onPressed,
          required Widget child}) {
        return SizedBox(
          width: 100,
          child: Phbuttons.nextPreviousOnScrollListener(
            model: model,
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

  void _clipboardCopyHandler({newClipboardText, toastMessage}) =>
      _setClipboardText(text: newClipboardText, toastMessage: toastMessage);

  void _setClipboardText({
    required String text,
    String? toastMessage,
    IconData? icon = Icons.copy,
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (toastMessage != null) {
      Phtoasts.show(
        currentContext,
        message: toastMessage,
        icon: icon,
        alignment: Phtoasts.topControlsAlign,
      );
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

  Widget _bottomBar(BuildContext context, {double? windowWidth}) {
    bool isNarrowWindow = windowWidth != null && windowWidth < 500.00;

    const Widget minimizedBottomBar = Positioned(
      bottom: 1,
      right: 10,
      child: Row(children: [
        TimerBar(key: TimerBar.mainScreenKey),
        SizedBox(width: 140),
      ]),
    );

    if (windowState.isBottomBarMinimized.value) {
      return minimizedBottomBar;
    }

    List<Widget> bottomBarItems(PfsAppModel model, {double spacing = 15}) {
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
        onPressed: () => filtersMenu.open(),
        isSelected: imagePhviewer.isFilterActive,
        tooltip: 'Filters',
        icon: imagePhviewer.isFilterActive ? filterIconOn : filterIconOff,
      );

      final resetZoomButton = ValueListenableBuilder(
        valueListenable: imagePhviewer.zoomLevelListenable,
        builder: (_, __, ___) {
          return Visibility(
            visible: !imagePhviewer.isZoomLevelDefault,
            child: IconButton(
              tooltip: 'Reset zoom',
              onPressed: () => imagePhviewer.resetZoomLevel(),
              icon: const Icon(Icons.youtube_searched_for),
            ),
          );
        },
      );

      final SizedBox spacingBox = SizedBox(width: spacing);

      if (model.hasFilesLoaded) {
        return [
          resetZoomButton,
          filtersButton,
          //_bottomButton(() => null, Icons.swap_horiz, 'Flip controls'), // Do this in the settings menu
          spacingBox,
          Phbuttons.timerSettingsButton(
              onPressed: () =>
                  windowState.isShowingTimerDurationMenu.set(true)),
          spacingBox,
          Opacity(
            opacity: model.allowTimerPlayPause ? 1 : 0.5,
            child: TimerControls(
                playPauseIconController: _playPauseIconStateAnimator),
          ),
          SizedBox(width: spacing + 3),
          ImageSetButton(narrowButton: isNarrowWindow),
          const SizedBox(width: 20),
        ];
      } else {
        return [
          Phbuttons.openFiles(width: isNarrowWindow ? 20 : 40),
          const SizedBox(width: 15, height: 43),
        ];
      }
    }

    const double narrowSpacing = 4;
    const double wideSpacing = 12;

    final normalBottomBar = Positioned(
      bottom: 0,
      right: 10,
      child: PfsAppModel.scope(
        (_, __, model) {
          return TweenAnimationBuilder<double>(
            duration: Phanimations.defaultDuration,
            tween: Tween<double>(
              begin: narrowSpacing,
              end: isNarrowWindow ? narrowSpacing : wideSpacing,
            ),
            builder: (_, spacing, __) {
              return Row(
                children: bottomBarItems(
                  model,
                  spacing: spacing,
                ).animate(
                  interval: const Duration(milliseconds: 25),
                  effects: [Phanimations.bottomBarSlideUpEffect],
                ),
              );
            },
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
      child: ValueListenableBuilder(
        valueListenable: windowState.isBottomBarMinimized,
        builder: (_, __, ___) {
          return CollapseBottomBarButton(
            isMinimized: windowState.isBottomBarMinimized.value,
            onPressed: () => windowState.isBottomBarMinimized.toggle(),
          );
        },
      ),
    );
  }

  void _playClickSound({bool playWhilePaused = false}) {
    if (!windowState.isSoundsEnabled.value) return;
    if (!widget.model.timerModel.isRunning && !playWhilePaused) return;
    clicker.playSound();
  }
}

class PfsWindowState {
  bool rightControlsOrientation = true;
  bool isTouch = false;

  final isBottomBarMinimized = ValueNotifier(false);
  final isAlwaysOnTop = ValueNotifier(false);
  final isSoundsEnabled = ValueNotifier(true);

  final isShowingTimerDurationMenu = ListenableBool(false);
  final isShowingSettingsMenu = ListenableBool(false);
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

extension BoolNotifierToggle on ValueNotifier<bool> {
  void toggle() {
    value = !value;
  }
}

class ModalMenu {
  ModalMenu({
    required this.builder,
    this.transitionBuilder = AnimatedSwitcher.defaultTransitionBuilder,
    this.onOpen,
  });

  final Widget Function(Widget, Animation<double>) transitionBuilder;

  final Widget Function(Function() closeMenu) builder;
  final Function()? onOpen;

  final ValueNotifier<bool> _isOpen = ValueNotifier(false);

  ValueListenable<bool> get openStateListenable => _isOpen;

  void open() {
    _isOpen.value = true;
    onOpen?.call();
  }

  void dismiss() {
    _isOpen.value = false;
  }

  Widget widget(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _isOpen,
      builder: (_, value, __) {
        return AnimatedSwitcher(
          transitionBuilder: transitionBuilder,
          duration: Phanimations.fastDuration,
          child: value ? builder(dismiss) : null,
        );
      },
    );
  }
}
