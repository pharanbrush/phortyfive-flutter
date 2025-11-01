import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pfs2/core/file_data.dart' as file_data;
import 'package:pfs2/core/file_data.dart';
import 'package:pfs2/core/file_list.dart';
import 'package:pfs2/main_screen/color_meter.dart';
import 'package:pfs2/main_screen/image_phviewer.dart';
import 'package:pfs2/main_screen/panels/corner_window_controls.dart';
import 'package:pfs2/main_screen/panels/filter_panel.dart';
import 'package:pfs2/main_screen/panels/modal_panel.dart';
import 'package:pfs2/main_screen/panels/settings_panel.dart';
import 'package:pfs2/main_screen/panels/timer_duration_panel.dart';
import 'package:pfs2/main_screen/sheets/about_sheet.dart';
import 'package:pfs2/main_screen/sheets/countdown_sheet.dart';
import 'package:pfs2/main_screen/sheets/first_action_sheet.dart';
import 'package:pfs2/main_screen/sheets/help_sheet.dart';
import 'package:pfs2/main_screen/sheets/loading_sheet.dart';
import 'package:pfs2/main_screen/sheets/welcome_choose_mode_sheet.dart';
import 'package:pfs2/models/pfs_model.dart';
import 'package:pfs2/phlutter/value_notifier_extensions.dart';
import 'package:pfs2/ui/pfs_localization.dart';
import 'package:pfs2/ui/phanimations.dart';
import 'package:pfs2/ui/phclicker.dart';
import 'package:pfs2/ui/phshortcuts.dart';
import 'package:pfs2/ui/phtoasts.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';
import 'package:pfs2/phlutter/utils/image_data.dart';
import 'package:pfs2/phlutter/utils/path_directory_expand.dart';
import 'package:pfs2/phlutter/utils/phclipboard.dart';
import 'package:pfs2/models/preferences.dart';
import 'package:pfs2/widgets/image_drop_target.dart';
import 'package:pfs2/widgets/overlay_button.dart';
import 'package:pfs2/widgets/phbuttons.dart';
import 'package:pfs2/widgets/phtimer_widgets.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:async';

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
        PlayPauseAnimatedIcon,
        MainScreenColorMeter,
        MainScreenBuildContext,
        MainScreenModels,
        MainScreenWindow,
        MainScreenPanels,
        MainScreenSound,
        MainScreenToaster,
        MainScreenScore,
        MainScreenClipboardFunctions {
  @override
  ValueNotifier<bool> getSoundEnabledNotifier() =>
      widget.windowState.isSoundsEnabled;

  @override
  ValueNotifier<String> getThemeNotifier() => widget.theme;

  @override
  bool get isSoundsEnabled => windowState.isSoundsEnabled.value;

  @override
  bool get isTimerRunning => model.timerModel.isRunning;

  @override
  FileData getCurrentImageFileData() => model.getCurrentImageFileData();

  @override
  String getCurrentImagePath() => getCurrentImageFileData().filePath;

  final Map<Type, Action<Intent>> shortcutActions = {};
  late List<(Type, Object? Function(Intent))> shortcutIntentActions = [
    (PreviousImageIntent, (_) => model.previousImageNewTimer()),
    (NextImageIntent, (_) => model.nextImageNewTimer()),
    (PlayPauseIntent, (_) => model.tryTogglePlayPauseTimer()),
    (RestartTimerIntent, (_) => model.timerModel.restartTimer()),
    (OpenFilesIntent, (_) => model.openFilePickerForImages()),
    (OpenFolderIntent, (_) => model.openFilePickerForFolder()),
    (CopyFileIntent, (_) => copyCurrentImageToClipboard()),
    (OpenTimerMenuIntent, (_) => timerDurationMenu.open()),
    (HelpIntent, (_) => helpMenu.open()),
    (BottomBarToggleIntent, (_) => windowState.isBottomBarMinimized.toggle()),
    (AlwaysOnTopIntent, (_) => windowState.isAlwaysOnTop.toggle()),
    (ToggleSoundIntent, (_) => windowState.isSoundsEnabled.toggle()),
    (ReturnHomeIntent, (_) => _tryReturnHome()),
    (RevealInExplorerIntent, (_) => revealCurrentImageInExplorer()),
    (OpenPreferencesIntent, (_) => settingsMenu.open()),
    (ZoomInIntent, (_) => imagePhviewer.incrementZoomLevel(1)),
    (FlipHorizontalIntent, (_) => imagePhviewer.flipHorizontal()),
    (ZoomOutIntent, (_) => imagePhviewer.incrementZoomLevel(-1)),
    (ZoomResetIntent, (_) => imagePhviewer.resetTransform()),
  ];

  @override
  void initState() {
    _bindModelCallbacks();
    _loadSettings();
    super.initState();

    _checkAndLoadLaunchArgPath();
  }

  @override
  void dispose() {
    _playPauseIconStateAnimator.dispose();
    _handleDisposeCallbacks();
    super.dispose();
  }

  @override
  void onAppModeChange() {
    setState(() {});
  }

  Widget overlayGestureControls(BuildContext context) {
    if (currentAppControlsMode.value == PfsAppControlsMode.colorMeter) {
      return SizedBox.shrink();
    }

    return ImageBrowseGestureControls(
      playPauseIconProgress: _playPauseIconStateAnimator,
      imagePhviewer: imagePhviewer,
      revealInExplorerHandler: revealCurrentImageInExplorer,
      clipboardCopyImageFileHandler: copyCurrentImageToClipboard,
      clipboardCopyTextHandler: _clipboardCopyTextHandler,
    );
  }

  Widget bottomControlBar(BuildContext context) {
    final Size windowSize = MediaQuery.of(context).size;

    return ValueListenableBuilder(
      valueListenable: windowState.isBottomBarMinimized,
      builder: (_, __, ___) {
        return _bottomControls(
          context,
          windowWidth: windowSize.width,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    updateCurrentBuildContext(context: context);

    final loadingSheetLayer = ValueListenableBuilder(
      valueListenable: model.isLoadingImages,
      builder: (_, isLoading, __) {
        return Visibility(
          visible: isLoading,
          child: LoadingSheet(
            loadedFileCountListenable: model.currentlyLoadingImages,
          ),
        );
      },
    );

    if (!model.hasFilesLoaded) {
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
            builder: (context, __, ___) => _bottomControls(context),
          ),
          _fileDropZone(model),
          ...modalPanelWidgets,
          loadingSheetLayer,
        ],
      );

      return firstActionApp;
    } else if (!model.isWelcomeDone && model.hasFilesLoaded) {
      final welcomeChooseModeApp = Stack(
        children: [
          WelcomeChooseModeSheet(model: model),
          // CornerWindowControls(
          //   windowState: windowState,
          //   imagePhviewer: imagePhviewer,
          //   helpMenu: helpMenu,
          //   settingsMenu: settingsMenu,
          // ),
          // ValueListenableBuilder(
          //   valueListenable: windowState.isBottomBarMinimized,
          //   builder: (context, __, ___) => _bottomBar(context),
          // ),
          ...modalPanelWidgets,
          loadingSheetLayer,
        ],
      );

      return welcomeChooseModeApp;
    }

    Widget shortcutsWrapper(Widget childWidget) {
      if (shortcutActions.isEmpty) {
        for (var (intentType, callback) in shortcutIntentActions) {
          shortcutActions[intentType] = CallbackAction(onInvoke: callback);
        }
      }

      Widget wrappedWidget = Shortcuts(
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

      return wrappedWidget;
    }

    final appWindowContent = shortcutsWrapper(
      Stack(
        children: [
          EyeDrop(
            key: eyeDropKey,
            child: imagePhviewer.widget(windowState.isBottomBarMinimized),
          ),
          _fileDropZone(model),
          overlayGestureControls(context),
          const CountdownSheet(),
          CornerWindowControls(
            windowState: windowState,
            imagePhviewer: imagePhviewer,
            helpMenu: helpMenu,
            settingsMenu: settingsMenu,
          ),
          _bottomBarUnderlay(context),
          bottomControlBar(context),
          WindowDockingControls(
            isBottomBarMinimized: windowState.isBottomBarMinimized,
          ),
          ...modalPanelWidgets,
          loadingSheetLayer,
        ],
      ),
    );

    return appWindowContent;
  }

  Widget _bottomBarUnderlay(BuildContext context) {
    const double underlayOpacity = 0.95;
    const double barHeight = 100;

    final theme = Theme.of(context);
    final backgroundColor =
        theme.colorScheme.surface.withValues(alpha: underlayOpacity);

    final barColor = backgroundColor; // Color.fromARGB(220, 0, 0, 0);
    final boxDecoration = BoxDecoration(color: barColor);

    return ValueListenableBuilder(
      valueListenable: currentAppControlsMode,
      builder: (context, value, child) {
        if (currentAppControlsMode.value == PfsAppControlsMode.imageBrowse) {
          return SizedBox.shrink();
        }

        return Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SizedBox(
            height: barHeight,
            child: Container(decoration: boxDecoration),
          ),
        );
      },
    );
  }

  void _loadSettings() async {
    windowState.isSoundsEnabled.value = await Preferences.getSoundsEnabled();
  }

  void _checkAndLoadLaunchArgPath() {
    if (Platform.executableArguments.isEmpty) return;
    final possiblePath = Platform.executableArguments[0];
    if (possiblePath.isEmpty) return;

    if (Directory(possiblePath).existsSync()) {
      model.loadFolder(possiblePath, recursive: true);
    }
  }

  void _bindModelCallbacks() {
    final model = this.model;
    model.onFilesChanged ??= () => _handleStateChange();
    model.onFilesLoadedSuccess ??= _handleFilesLoadedSuccess;
    model.onImageChange ??= _handleOnImageChange;
    model.onCountdownUpdate ??= () => _playClickSound();
    model.onImageDurationElapse ??= () => _playClickSound();
    model.onFilePickerStateChange ??= () => _handleFilePickerOpenClose();
    model.onWelcomeComplete ??= () => _handleWelcomeComplete();

    final timerModel = model.timerModel;
    timerModel.onPlayPause ??= () => _handleTimerPlayPause();
    timerModel.onReset ??= () => _playClickSound();
    timerModel.onDurationChangeSuccess ??= () => _handleTimerChangeSuccess();

    windowState.isSoundsEnabled.addListener(() => _handleSoundChanged());
    windowState.isAlwaysOnTop.addListener(() => _handleAlwaysOnTopChanged());

    currentAppControlsMode.addListener(() => _handleAppControlsChanged());

    onColorMeterSecondaryTap = () {
      setState(() {
        setAppMode(PfsAppControlsMode.imageBrowse);
        Phtoasts.showWidget(
          currentContext,
          child: Text("Color meter closed."),
        );
      });
    };
  }

  void _handleDisposeCallbacks() {
    windowState.isSoundsEnabled.removeListener(() => _handleSoundChanged());
    windowState.isAlwaysOnTop.removeListener(() => _handleAlwaysOnTopChanged());
  }

  void _handleWelcomeComplete() {
    _handleTimerPlayPause();
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
      boldText1: '${model.timerModel.currentDurationSeconds} seconds',
      text2: ' per image.',
    );
    Phtoasts.showWidget(currentContext, child: toastContent);
  }

  void _handleOnImageChange() {
    waitThenAddImageToScore();
    setState(() => imagePhviewer.resetTransform());
  }

  void _handleStateChange() {
    setState(() {});
  }

  void _handleFilePickerOpenClose() {
    _updateAlwaysOnTop();
  }

  void updateTimerPlayPauseIcon() {
    final isTimerRunning = model.timerModel.isRunning;
    animateTimerIconTo(isTimerRunning);
  }

  void _handleTimerPlayPause() {
    showTimerToast() {
      bool isRunning = model.timerModel.isRunning;
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

  void _handleAppControlsChanged() {
    if (currentAppControlsMode.value == PfsAppControlsMode.colorMeter) {
      final imageWidgetContext = ImagePhviewer.imageWidgetKey.currentContext;
      if (imageWidgetContext != null) {
        startColorMeter(imageWidgetContext);
      } else {
        setAppMode(PfsAppControlsMode.imageBrowse);
      }
    } else {
      endColorMeter();
    }
  }

  void revealCurrentImageInExplorer() {
    final currentImageData = getCurrentImageFileData();
    file_data.revealInExplorer(currentImageData);
  }

  Widget _fileDropZone(PfsAppModel model) {
    if (currentAppControlsMode.value != PfsAppControlsMode.imageBrowse) {
      return const SizedBox.shrink();
    }

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

          model.loadImages(filePaths, recursive: true);

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

  Widget _bottomControls(
    BuildContext context, {
    double? windowWidth,
  }) {
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
          colorMeterModeButton(onPressed: () {
            setAppMode(PfsAppControlsMode.colorMeter);
          }),
          ResetZoomButton(imageZoomPanner: imagePhviewer),
          FiltersButton(imagePhviewer: imagePhviewer, filtersMenu: filtersMenu),
          spacingBox,
          Phbuttons.timerSettingsButton(
              onPressed: () => timerDurationMenu.open()),
          spacingBox,
          TimerControls(playPauseIconController: _playPauseIconStateAnimator),
          SizedBox(width: spacing + 3),
          ValueListenableBuilder(
              valueListenable: imagesViewedCounter,
              builder: (context, value, child) {
                return ImageSetButton(
                  narrowButton: isNarrowWindow,
                  extraTooltip: getScoreText(),
                );
              }),
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
    const double minimizeButtonRightSpace = 10;

    if (currentAppControlsMode.value == PfsAppControlsMode.colorMeter) {
      return colorMeterBottomBar(
        onCloseButtonPressed: () => setAppMode(PfsAppControlsMode.imageBrowse),
      );
    }

    Widget normalBottomBar() {
      return Positioned(
        bottom: 0,
        right: minimizeButtonRightSpace,
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
                    effects: const [Phanimations.bottomBarSlideUpEffect],
                  ),
                );
              },
            );
          },
        ),
      );
    }

    return normalBottomBar();
  }
}

mixin PlayPauseAnimatedIcon on TickerProvider {
  late final AnimationController _playPauseIconStateAnimator =
      AnimationController(
    duration: Phanimations.defaultDuration,
    // WORKAROUND: the default value: 0 causes the icon to have the wrong initial state when the timer first plays.
    value: 1,
    vsync: this,
  );

  void animateTimerIconTo(bool isTimerRunning) {
    if (isTimerRunning) {
      _playPauseIconStateAnimator.forward();
    } else {
      _playPauseIconStateAnimator.reverse();
    }
  }
}

mixin MainScreenBuildContext {
  BuildContext? currentContext;

  void updateCurrentBuildContext({required BuildContext context}) {
    currentContext = context;
  }
}

mixin MainScreenScore {
  final imagesViewedCounter = ValueNotifier<int>(0);

  final _viewedImages = <String>{};
  Timer? _imageQualifiedTimer;

  String getCurrentImagePath();

  static const secondsViewedForImageToScoreCount = 10;

  String getScoreText() {
    return "Images observed: ${imagesViewedCounter.value}";
  }

  void waitThenAddImageToScore() {
    _imageQualifiedTimer?.cancel();

    _imageQualifiedTimer = Timer(
      const Duration(seconds: secondsViewedForImageToScoreCount),
      () {
        _viewedImages.add(getCurrentImagePath());
        imagesViewedCounter.value = _viewedImages.length;
      },
    );
  }

  void cancelLastCount() {
    _imageQualifiedTimer?.cancel();
  }

  void resetScore() {
    _viewedImages.clear();
    imagesViewedCounter.value = 0;
  }
}

mixin MainScreenToaster on MainScreenBuildContext {
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

mixin MainScreenWindow on State<MainScreen>, MainScreenModels {
  final FocusNode mainWindowFocus = FocusNode();
  late TimerDurationEditor timerDurationEditor = TimerDurationEditor();
  PfsWindowState get windowState => widget.windowState;

  void refocusMainWindow() {
    mainWindowFocus.requestFocus();
  }

  void _updateAlwaysOnTop() {
    bool isPickingFiles = model.isPickerOpen;
    bool isAlwaysOnTopUserIntent = windowState.isAlwaysOnTop.value;

    bool currentAlwaysOnTop = isAlwaysOnTopUserIntent && !isPickingFiles;
    windowManager.setAlwaysOnTop(currentAlwaysOnTop);
  }
}

enum PfsAppControlsMode {
  imageBrowse,
  colorMeter,
  annotation,
  firstAction,
  welcomeChoice
}

mixin MainScreenModels on State<MainScreen> {
  final currentAppControlsMode =
      ValueNotifier<PfsAppControlsMode>(PfsAppControlsMode.imageBrowse);

  void setAppMode(PfsAppControlsMode newMode) {
    final oldValue = currentAppControlsMode.value;

    if (oldValue == PfsAppControlsMode.imageBrowse) {
      model.tryPauseTimer();
    }

    currentAppControlsMode.value = newMode;
    onAppModeChange();
  }

  void onAppModeChange();

  late ImagePhviewer imagePhviewer = ImagePhviewer(
    appControlsMode: currentAppControlsMode,
  );

  PfsAppModel get model => widget.model;
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

  void copyCurrentImageToClipboard() async {
    final currentImageData = getCurrentImageFileData();
    final filePath = currentImageData.filePath;
    try {
      final imageData = await getImageDataFromFile(filePath);
      await copyImageFileToClipboardAsPngAndFileUri(
        image: imageData,
        filePath: currentImageData.filePath,
        suggestedName: currentImageData.fileName,
      );
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

mixin MainScreenPanels on MainScreenModels, MainScreenWindow {
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
        appModel: model,
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
      timerDurationEditor.setActive(
          timerDurationMenu.isOpen, model.timerModel.currentDurationSeconds);
    },
    onClosed: () {
      refocusMainWindow();
      timerDurationEditor.setActive(
          timerDurationMenu.isOpen, model.timerModel.currentDurationSeconds);
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

class ImageBrowseGestureControls extends StatelessWidget {
  const ImageBrowseGestureControls({
    super.key,
    required this.playPauseIconProgress,
    required this.imagePhviewer,
    required this.revealInExplorerHandler,
    required this.clipboardCopyTextHandler,
    required this.clipboardCopyImageFileHandler,
  });

  final Animation<double> playPauseIconProgress;
  final ImagePhviewer imagePhviewer;
  final VoidCallback revealInExplorerHandler;
  final ClipboardCopyTextHandler clipboardCopyTextHandler;
  final VoidCallback clipboardCopyImageFileHandler;

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
            copyImageFileHandler: clipboardCopyImageFileHandler,
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
