import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pfs2/core/file_data.dart' as file_data;
import 'package:pfs2/core/file_data.dart';
import 'package:pfs2/core/file_list.dart';
import 'package:pfs2/models/pfs_model.dart';
import 'package:pfs2/main_screen/sheets/about_sheet.dart';
import 'package:pfs2/main_screen/sheets/countdown_sheet.dart';
import 'package:pfs2/main_screen/filter_panel.dart';
import 'package:pfs2/main_screen/sheets/first_action_sheet.dart';
import 'package:pfs2/main_screen/settings_panel.dart';
import 'package:pfs2/ui/pfs_localization.dart';
import 'package:pfs2/ui/phtoasts.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';
import 'package:pfs2/ui/phclicker.dart';
import 'package:pfs2/ui/phshortcuts.dart';
import 'package:pfs2/utils/image_data.dart';
import 'package:pfs2/utils/path_directory_expand.dart';
import 'package:pfs2/utils/phclipboard.dart';
import 'package:pfs2/utils/preferences.dart';
import 'package:pfs2/ui/phanimations.dart';
import 'package:pfs2/phlutter/value_notifier_extensions.dart';
import 'package:pfs2/widgets/modal_panel.dart';
import 'package:pfs2/main_screen/sheets/help_sheet.dart';
import 'package:pfs2/widgets/image_drop_target.dart';
import 'package:pfs2/main_screen/image_phviewer.dart';
import 'package:pfs2/widgets/overlay_button.dart';
import 'package:pfs2/main_screen/corner_window_controls.dart';
import 'package:pfs2/widgets/phbuttons.dart';
import 'package:pfs2/widgets/phtimer_widgets.dart';
import 'package:pfs2/main_screen/timer_duration_panel.dart';
import 'package:window_manager/window_manager.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
    required this.model,
    required this.theme,
    required this.windowState,
  });

  final PfsAppModel model;
  final ValueNotifier<String> theme;
  final PfsWindowState windowState;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with
        TickerProviderStateMixin,
        MainScreenModels,
        MainScreenPanels,
        MainScreenSound,
        MainScreenToaster,
        MainScreenClipboardFunctions {
  final FocusNode mainWindowFocus = FocusNode();
  PfsWindowState get windowState => widget.windowState;

  BuildContext? currentContext;

  @override
  PfsAppModel getModel() => widget.model;

  @override
  void refocusMainWindow() {
    mainWindowFocus.requestFocus();
  }

  @override
  ValueNotifier<bool> getSoundEnabledNotifier() =>
      widget.windowState.isSoundsEnabled;

  @override
  ValueNotifier<String> getThemeNotifier() => widget.theme;

  @override
  bool get isSoundsEnabled => windowState.isSoundsEnabled.value;

  @override
  bool get isTimerRunning => widget.model.timerModel.isRunning;

  @override
  FileData getCurrentImageFileData() => widget.model.getCurrentImageFileData();

  final Map<Type, Action<Intent>> shortcutActions = {};
  late List<(Type, Object? Function(Intent))> shortcutIntentActions = [
    (PreviousImageIntent, (_) => widget.model.previousImageNewTimer()),
    (NextImageIntent, (_) => widget.model.nextImageNewTimer()),
    (PlayPauseIntent, (_) => widget.model.tryTogglePlayPauseTimer()),
    (RestartTimerIntent, (_) => widget.model.timerModel.restartTimer()),
    (OpenFilesIntent, (_) => widget.model.openFilePickerForImages()),
    (OpenFolderIntent, (_) => widget.model.openFilePickerForFolder()),
    (OpenTimerMenuIntent, (_) => timerDurationMenu.open()),
    (HelpIntent, (_) => helpMenu.open()),
    (BottomBarToggleIntent, (_) => windowState.isBottomBarMinimized.toggle()),
    (AlwaysOnTopIntent, (_) => windowState.isAlwaysOnTop.toggle()),
    (ToggleSoundIntent, (_) => windowState.isSoundsEnabled.toggle()),
    (ReturnHomeIntent, (_) => _tryReturnHome()),
    (RevealInExplorerIntent, (_) => revealCurrentImageInExplorer()),
    (OpenPreferencesIntent, (_) => settingsMenu.open()),
  ];

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

    final Size windowSize = MediaQuery.of(context).size;

    if (!widget.model.hasFilesLoaded) {
      final firstActionApp = Stack(
        children: [
          const FirstActionSheet(),
          CornerWindowControls(
            windowState: windowState,
            imagePhviewer: imagePhviewer,
            helpMenu: helpMenu,
            settingsMenu: settingsMenu,
          ),
          ValueListenableBuilder(
            valueListenable: windowState.isBottomBarMinimized,
            builder: (context, __, ___) {
              return _bottomBar(context);
            },
          ),
          _fileDropZone(widget.model),
          ...modalPanelWidgets,
        ],
      );

      return firstActionApp;
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
          imagePhviewer.widget(windowState.isBottomBarMinimized),
          _fileDropZone(widget.model),
          PhgestureControls(
            playPauseIconProgress: _playPauseIconStateAnimator,
            imagePhviewer: imagePhviewer,
            revealInExplorerHandler: revealCurrentImageInExplorer,
            clipboardCopyImageHandler: copyCurrentImagePixelsToClipboard,
            clipboardCopyTextHandler: _clipboardCopyTextHandler,
          ),
          const CountdownSheet(),
          CornerWindowControls(
            windowState: windowState,
            imagePhviewer: imagePhviewer,
            helpMenu: helpMenu,
            settingsMenu: settingsMenu,
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
          WindowDockingControls(
            isBottomBarMinimized: windowState.isBottomBarMinimized,
          ),
          ...modalPanelWidgets,
        ],
      ),
    );

    return appWindowContent;
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
  }

  void _handleDisposeCallbacks() {
    windowState.isSoundsEnabled.removeListener(() => _handleSoundChanged());
    windowState.isAlwaysOnTop.removeListener(() => _handleAlwaysOnTopChanged());
  }

  void _tryReturnHome() {
    _closeAllPanels();
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
    setState(() => imagePhviewer.resetTransform());
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
    void updateTimerPlayPauseIcon() {
      if (widget.model.timerModel.isRunning) {
        _playPauseIconStateAnimator.forward();
      } else {
        _playPauseIconStateAnimator.reverse();
      }
    }

    showTimerToast() {
      bool isRunning = widget.model.timerModel.isRunning;
      final message = PfsLocalization.timerSwitched(isRunning);
      final icon = isRunning ? Icons.play_arrow : Icons.pause;

      showToast(
        message: message,
        icon: icon,
      );
    }

    updateTimerPlayPauseIcon();
    showTimerToast();
    _playClickSound(playWhilePaused: true);
  }

  void _handleAlwaysOnTopChanged() {
    showAlwaysOnTopToast() {
      bool wasEnabled = windowState.isAlwaysOnTop.value;
      final message = PfsLocalization.alwaysOnTopSwitched(wasEnabled);

      final icon = wasEnabled
          ? Icons.picture_in_picture
          : Icons.picture_in_picture_outlined;

      showToast(
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

      showToast(
        message: message,
        icon: icon,
        alignment: Phtoasts.topControlsAlign,
      );
    }

    showSoundToggleToast();
    Preferences.setSoundsEnabled(windowState.isSoundsEnabled.value);
  }

  @override
  void showToast({
    required String message,
    IconData? icon,
    Alignment alignment = Alignment.bottomCenter,
  }) {
    if (currentContext == null) return;

    Phtoasts.show(
      currentContext,
      message: message,
      icon: icon,
      alignment: Phtoasts.topControlsAlign,
    );
  }

  void revealCurrentImageInExplorer() {
    final currentImageData = getCurrentImageFileData();
    file_data.revealInExplorer(currentImageData);
  }

  Widget _fileDropZone(PfsAppModel model) {
    return Positioned.fill(
      left: 20,
      right: 20,
      bottom: 40,
      top: 30,
      child: ImageDropTarget(
        dragImagesHandler: (details) {
          if (details.files.isEmpty) return;
          List<String> filePaths = [];
          for (var file in details.files) {
            var filePath = file.path;
            if (FileList.fileIsImage(filePath)) {
              filePaths.add(filePath);
            } else if (pathIsDirectory(filePath)) {
              filePaths.add(filePath);
            }
          }
          if (filePaths.isEmpty) return;

          model.loadImages(filePaths);

          if (model.hasFilesLoaded) {
            _onFileDropped();
          }
        },
      ),
    );
  }

  void _onFileDropped() {
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
      final SizedBox spacingBox = SizedBox(width: spacing);

      if (model.hasFilesLoaded) {
        return [
          ResetZoomButton(imageZoomPanner: imagePhviewer),
          FiltersButton(imagePhviewer: imagePhviewer, filtersMenu: filtersMenu),
          spacingBox,
          Phbuttons.timerSettingsButton(
              onPressed: () => timerDurationMenu.open()),
          spacingBox,
          TimerControls(playPauseIconController: _playPauseIconStateAnimator),
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
}

mixin MainScreenToaster {
  void showToast({
    required String message,
    IconData? icon,
    Alignment alignment = Alignment.bottomCenter,
  });
}

mixin MainScreenSound {
  final Phclicker clicker = Phclicker();

  bool get isSoundsEnabled;
  bool get isTimerRunning;

  void _playClickSound({bool playWhilePaused = false}) {
    if (!isSoundsEnabled) return;
    if (!isTimerRunning && !playWhilePaused) return;
    clicker.playSound();
  }
}

mixin MainScreenModels {
  late TimerDurationEditor timerDurationEditor = TimerDurationEditor();
  late ImagePhviewer imagePhviewer = ImagePhviewer();
}

mixin MainScreenClipboardFunctions on MainScreenToaster {
  FileData getCurrentImageFileData();

  void _setClipboardText({
    required String text,
    String? toastMessage,
    IconData? icon = Icons.copy,
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (toastMessage != null) {
      showToast(
        message: toastMessage,
        icon: icon,
        alignment: Phtoasts.topControlsAlign,
      );
    }
  }

  void copyCurrentImagePixelsToClipboard() async {
    final currentImageData = getCurrentImageFileData();
    final filePath = currentImageData.filePath;
    try {
      final imageData = await getImageDataFromFile(filePath);
      copyImageToClipboardAsPng(imageData, currentImageData.fileName);
      showToast(
        message: "Image copied to clipboard",
        icon: Icons.copy,
        alignment: Alignment.center,
      );
    } catch (e) {
      showToast(
        message: "Image copy failed",
        icon: Icons.error,
      );
    }
  }

  void _clipboardCopyTextHandler({newClipboardText, toastMessage}) =>
      _setClipboardText(text: newClipboardText, toastMessage: toastMessage);
}

mixin MainScreenPanels on MainScreenModels {
  PfsAppModel getModel();
  void refocusMainWindow();

  ValueNotifier<bool> getSoundEnabledNotifier();
  ValueNotifier<String> getThemeNotifier();

  late final ModalPanel filtersMenu = ModalPanel(
    onBeforeOpen: () => _closeAllPanels(except: filtersMenu),
    isUnderlayTransparent: true,
    builder: () => FilterPanel(imagePhviewer: imagePhviewer),
    transitionBuilder: Phanimations.bottomMenuTransition,
  );

  late final ModalPanel helpMenu = ModalPanel(
    onBeforeOpen: () => _closeAllPanels(except: helpMenu),
    builder: () {
      return Theme(
        data: ThemeData.dark(useMaterial3: true),
        child: const HelpSheet(),
      );
    },
  );

  late final ModalPanel settingsMenu = ModalPanel(
    onBeforeOpen: () => _closeAllPanels(except: settingsMenu),
    builder: () {
      return SettingsPanel(
        appModel: getModel(),
        themeNotifier: getThemeNotifier(),
        soundEnabledNotifier: getSoundEnabledNotifier(),
        aboutMenu: aboutMenu,
      );
    },
    transitionBuilder: Phanimations.rightMenuTransition,
  );

  late final ModalPanel timerDurationMenu = ModalPanel(
    onBeforeOpen: () => _closeAllPanels(except: timerDurationMenu),
    onOpened: () {
      timerDurationEditor.setActive(timerDurationMenu.isOpen,
          getModel().timerModel.currentDurationSeconds);
    },
    onClosed: () {
      refocusMainWindow();
      timerDurationEditor.setActive(timerDurationMenu.isOpen,
          getModel().timerModel.currentDurationSeconds);
    },
    builder: () => timerDurationEditor.widget(),
    transitionBuilder: Phanimations.bottomMenuTransition,
  );

  late final ModalPanel aboutMenu = ModalPanel(
    onBeforeOpen: () => _closeAllPanels(except: aboutMenu),
    builder: () => const AboutSheet(),
  );

  late final modalPanels = [
    filtersMenu,
    helpMenu,
    settingsMenu,
    timerDurationMenu,
    aboutMenu,
  ];

  Iterable<Widget> get modalPanelWidgets sync* {
    for (var panel in modalPanels) {
      yield panel.widget();
    }
  }

  void _closeAllPanels({ModalPanel? except}) {
    void tryDismiss(ModalPanel toDismiss) {
      if (except != null || toDismiss != except) {
        toDismiss.close();
      }
    }

    for (final panel in modalPanels) {
      tryDismiss(panel);
    }
  }
}

class FiltersButton extends StatelessWidget {
  const FiltersButton({
    super.key,
    required this.imagePhviewer,
    required this.filtersMenu,
  });

  final ImagePhviewer imagePhviewer;
  final ModalPanel filtersMenu;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: imagePhviewer.filtersChangeListenable,
      builder: (_, __, ___) {
        const double filterIconSize = 20;
        const filterIconOff = Icon(
          Icons.contrast,
          size: filterIconSize,
        );
        const filterIconOn = Icon(
          Icons.contrast,
          size: filterIconSize,
        );

        String tooltip = imagePhviewer.isFilterActive
            ? 'Filters (${imagePhviewer.activeFilterCount})'
            : 'Filters';

        return GestureDetector(
          onTertiaryTapDown: (details) {
            if (imagePhviewer.isFilterActive) {
              imagePhviewer.resetAllFilters();
            }
          },
          child: IconButton(
            onPressed: () => filtersMenu.open(),
            isSelected: imagePhviewer.isFilterActive,
            tooltip: tooltip,
            icon: imagePhviewer.isFilterActive ? filterIconOn : filterIconOff,
          ),
        );
      },
    );
  }
}

class WindowDockingControls extends StatelessWidget {
  const WindowDockingControls({
    super.key,
    required this.isBottomBarMinimized,
  });

  final ValueNotifier<bool> isBottomBarMinimized;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 3,
      right: 3,
      child: ValueListenableBuilder(
        valueListenable: isBottomBarMinimized,
        builder: (_, __, ___) {
          return CollapseBottomBarButton(
            isMinimized: isBottomBarMinimized.value,
            onPressed: () => isBottomBarMinimized.toggle(),
          );
        },
      ),
    );
  }
}

class PhgestureControls extends StatelessWidget {
  const PhgestureControls({
    super.key,
    required this.playPauseIconProgress,
    required this.imagePhviewer,
    required this.revealInExplorerHandler,
    required this.clipboardCopyTextHandler,
    required this.clipboardCopyImageHandler,
  });

  final Animation<double> playPauseIconProgress;
  final ImagePhviewer imagePhviewer;
  final VoidCallback revealInExplorerHandler;
  final ClipboardCopyTextHandler clipboardCopyTextHandler;
  final VoidCallback clipboardCopyImageHandler;

  @override
  Widget build(BuildContext context) {
    AnimatedIcon playPauseIcon = AnimatedIcon(
      icon: AnimatedIcons.play_pause,
      size: 80,
      progress: playPauseIconProgress,
    );

    return PfsAppModel.scope((_, __, model) {
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

      Widget middleGestureButton() {
        Widget playPauseButton() {
          return OverlayButton(
            onPressed: () => model.tryTogglePlayPauseTimer(),
            child: playPauseIcon,
          );
        }

        return ImagePhviewerZoomOnScrollListener(
          imagePhviewer: imagePhviewer,
          child: ImageRightClick(
            revealInExplorerHandler: revealInExplorerHandler,
            resetZoomLevelHandler: () => imagePhviewer.resetTransform(),
            clipboardCopyHandler: clipboardCopyTextHandler,
            copyImageHandler: clipboardCopyImageHandler,
            child: ValueListenableBuilder(
              valueListenable: imagePhviewer.zoomLevelListenable,
              builder: (_, __, ___) {
                return ImagePhviewerPanListener(
                  imagePhviewer: imagePhviewer,
                  child: playPauseButton(),
                );
              },
            ),
          ),
        );
      }

      return Positioned.fill(
        top: Phbuttons.windowTitleBarHeight + 50,
        bottom: 80,
        left: 10,
        right: 10,
        child: Opacity(
          opacity: 0.4,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              nextPreviousGestureButton(
                width: 100,
                onPressed: () => model.previousImageNewTimer(),
                child: PfsTheme.beforeGestureIcon,
              ),
              Expanded(
                flex: 4,
                child: middleGestureButton(),
              ),
              nextPreviousGestureButton(
                width: 140,
                onPressed: () => model.nextImageNewTimer(),
                child: PfsTheme.nextGestureIcon,
              ),
            ],
          ),
        ),
      );
    });
  }
}

class PfsWindowState {
  bool rightControlsOrientation = true;
  bool isTouch = false;

  final isBottomBarMinimized = ValueNotifier(false);
  final isAlwaysOnTop = ValueNotifier(false);
  final isSoundsEnabled = ValueNotifier(true);
}
