import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pfs2/core/image_memory_data.dart';
import 'package:pfs2/core/image_data.dart' as image_data;
import 'package:pfs2/core/image_data.dart';
import 'package:pfs2/core/image_list.dart';
import 'package:pfs2/libraries/color_meter_cyclop.dart';
import 'package:pfs2/main_screen/color_meter.dart';
import 'package:pfs2/main_screen/image_phviewer.dart';
import 'package:pfs2/main_screen/main_screen_sound.dart';
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
import 'package:pfs2/phlutter/escape_route.dart';
import 'package:pfs2/phlutter/value_notifier_extensions.dart';
import 'package:pfs2/ui/pfs_localization.dart';
import 'package:pfs2/ui/phanimations.dart';
import 'package:pfs2/ui/phshortcuts.dart';
import 'package:pfs2/ui/phtoasts.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';
import 'package:pfs2/phlutter/utils/image_from_file.dart';
import 'package:pfs2/phlutter/utils/path_directory_expand.dart';
import 'package:pfs2/phlutter/utils/phclipboard.dart' as phclipboard;
import 'package:pfs2/models/preferences.dart';
import 'package:pfs2/widgets/clipboard_handlers.dart';
import 'package:pfs2/widgets/hover_container.dart';
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
        MainScreenModels,
        MainScreenWindow,
        MainScreenPanels,
        MainScreenColorMeter,
        MainScreenSound,
        MainScreenToaster,
        MainScreenImageViewedCounter,
        MainScreenClipboardFunctions {
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
  ImageData getCurrentImageFileData() => widget.model.getCurrentImageData();

  @override
  String getCurrentImagePath() {
    final currentImageData = getCurrentImageFileData();
    if (currentImageData is ImageFileData) {
      return currentImageData.filePath;
    }

    return "";
  }

  final Map<Type, Action<Intent>> shortcutActions = {};
  late List<(Type, Object? Function(Intent))> shortcutIntentActions = [
    (PreviousImageIntent, (_) => widget.model.previousImageNewTimer()),
    (NextImageIntent, (_) => widget.model.nextImageNewTimer()),
    (PlayPauseIntent, (_) => widget.model.tryTogglePlayPauseTimer()),
    (RestartTimerIntent, (_) => widget.model.timerModel.resetTimer()),
    (OpenFilesIntent, (_) => widget.model.openFilePickerForImages()),
    (OpenFolderIntent, (_) => widget.model.openFilePickerForFolder()),
    (CopyFileIntent, (_) => copyCurrentImageToClipboard()),
    (OpenTimerMenuIntent, (_) => timerDurationMenu.open()),
    (HelpIntent, (_) => helpMenu.open()),
    (BottomBarToggleIntent, (_) => windowState.isBottomBarMinimized.toggle()),
    (AlwaysOnTopIntent, (_) => windowState.isAlwaysOnTop.toggle()),
    (ToggleSoundIntent, (_) => windowState.isSoundsEnabled.toggle()),
    (EscapeIntent, (_) => _tryEscape()),
    (RevealInExplorerIntent, (_) => revealCurrentImageInExplorer()),
    (OpenPreferencesIntent, (_) => settingsMenu.open()),
    (ZoomInIntent, (_) => imagePhviewer.incrementZoomLevel(1)),
    (FlipHorizontalIntent, (_) => imagePhviewer.flipHorizontal()),
    (ZoomOutIntent, (_) => imagePhviewer.incrementZoomLevel(-1)),
    (ZoomResetIntent, (_) => imagePhviewer.resetTransform()),
    (PasteIntent, (_) => tryPaste()),
  ];

  final Map<Type, Action<Intent>> firstScreenShortcutActions = {};
  late List<(Type, Object? Function(Intent))> firstScreenShortcutIntentActions =
      [(PasteIntent, (_) => tryPaste())];

  @override
  void initState() {
    _bindModelCallbacks();
    _loadSettings();
    super.initState();

    _checkAndLoadLaunchArgPath();

    EscapeNavigator.of(context)?.push(
      EscapeRoute(
        name: "home",
        onEscape: () {
          setAppMode(PfsAppControlsMode.imageBrowse);
          closeAllPanels();
        },
        willPopOnEscape: false,
      ),
    );
  }

  @override
  void dispose() {
    _playPauseIconStateAnimator.dispose();
    _handleDisposeCallbacks();
    super.dispose();
  }

  @override
  void onAppModeChange() {
    //setState(() {});
  }

  void tryPaste() async {
    if (currentAppControlsMode.value != PfsAppControlsMode.imageBrowse) return;
    for (final panel in modalPanels) {
      if (panel.isOpen) return;
    }

    phclipboard.getImageBytesFromClipboard(
      (imageBytes) {
        final imageDataFromPaste = ImageMemoryData(bytes: imageBytes);
        widget.model.loadImage(imageDataFromPaste);
      },
    );
  }

  Widget overlayGestureControls(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: currentAppControlsMode,
        builder: (_, currentAppControlsModeValue, ___) {
          if (currentAppControlsModeValue == PfsAppControlsMode.colorMeter) {
            return SizedBox.shrink();
          }

          return ImageBrowseGestureControls(
            model: widget.model,
            playPauseIconProgress: _playPauseIconStateAnimator,
            imagePhviewer: imagePhviewer,
            revealInExplorerHandler: revealCurrentImageInExplorer,
            colorMeterMenuItemHandler: _handleOpenColorMeterMenuItem,
          );
        });
  }

  Widget bottomControlBar(BuildContext context) {
    final Size windowSize = MediaQuery.of(context).size;

    return ValueListenableBuilder(
      valueListenable: windowState.isBottomBarMinimized,
      builder: (_, __, ___) {
        return _bottomControls(windowWidth: windowSize.width);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loadingSheetLayer = ValueListenableBuilder(
      valueListenable: widget.model.isLoadingImages,
      builder: (_, isLoading, __) {
        return Visibility(
          visible: isLoading,
          child: LoadingSheet(
            loadedFileCountListenable: widget.model.currentlyLoadingImages,
          ),
        );
      },
    );

    if (!widget.model.hasImagesLoaded) {
      final firstActionApp = Stack(
        children: [
          const FirstActionSheet(),
          CornerWindowControls(
            windowState: windowState,
            zoomPanner: imagePhviewer,
            helpMenu: helpMenu,
            settingsMenu: settingsMenu,
          ),
          ValueListenableBuilder(
            valueListenable: windowState.isBottomBarMinimized,
            builder: (context, __, ___) => _bottomControls(),
          ),
          _fileDropZone(),
          ...modalPanelWidgets,
          loadingSheetLayer,
        ],
      );

      if (firstScreenShortcutActions.isEmpty) {
        for (final (intentType, callback) in firstScreenShortcutIntentActions) {
          firstScreenShortcutActions[intentType] =
              CallbackAction(onInvoke: callback);
        }
      }

      final wrappedFirstActionApp = Shortcuts(
        shortcuts: Phshortcuts.intentMap,
        child: Actions(
          actions: firstScreenShortcutActions,
          child: Focus(
            focusNode: mainWindowFocus,
            autofocus: true,
            child: firstActionApp,
          ),
        ),
      );

      return wrappedFirstActionApp;
    } else if (!widget.model.isWelcomeDone.value &&
        widget.model.hasImagesLoaded) {
      final welcomeChooseModeApp = Stack(
        children: [
          const WelcomeChooseModeSheet(),
          CornerWindowControls(
            windowState: windowState,
            zoomPanner: imagePhviewer,
            helpMenu: helpMenu,
            settingsMenu: settingsMenu,
          ),
          ...modalPanelWidgets,
          loadingSheetLayer,
        ],
      );

      return welcomeChooseModeApp;
    }

    Widget shortcutsWrapper({required Widget child}) {
      if (shortcutActions.isEmpty) {
        for (final (intentType, callback) in shortcutIntentActions) {
          shortcutActions[intentType] = CallbackAction(onInvoke: callback);
        }
      }

      final Widget wrappedWidget = Shortcuts(
        shortcuts: Phshortcuts.intentMap,
        child: Actions(
          actions: shortcutActions,
          child: Focus(
            focusNode: mainWindowFocus,
            autofocus: true,
            child: child,
          ),
        ),
      );

      return wrappedWidget;
    }

    Widget inheritedWidgetsWrapper({required Widget child}) {
      return ClipboardHandlers(
        copyText: _setClipboardText,
        copyCurrentImage: copyCurrentImageToClipboard,
        child: child,
      );
    }

    final appWindowContent = inheritedWidgetsWrapper(
      child: shortcutsWrapper(
        child: Stack(
          children: [
            Overlay.wrap(
              child: EyeDropperLayer(
                key: eyeDropKey,
                child: imagePhviewer.widget(windowState.isBottomBarMinimized),
              ),
            ),
            _fileDropZone(),
            overlayGestureControls(context),
            CountdownSheet(),
            CornerWindowControls(
              windowState: windowState,
              zoomPanner: imagePhviewer,
              helpMenu: helpMenu,
              settingsMenu: settingsMenu,
            ),
            bottomControlBar(context),
            ValueListenableBuilder(
              valueListenable: currentAppControlsMode,
              builder: (_, currentAppControlsModeValue, __) {
                if (currentAppControlsModeValue ==
                    PfsAppControlsMode.imageBrowse) {
                  return WindowDockingControls(
                    isBottomBarMinimized: windowState.isBottomBarMinimized,
                  );
                }

                return SizedBox.shrink();
              },
            ),
            colorMeterPanel.widget(),
            ...modalPanelWidgets,
            loadingSheetLayer,
          ],
        ),
      ),
    );

    return appWindowContent;
  }

  void _loadSettings() async {
    windowState.isSoundsEnabled.value = await Preferences.getSoundsEnabled();
  }

  void _checkAndLoadLaunchArgPath() {
    if (Platform.executableArguments.isEmpty) return;
    final possiblePath = Platform.executableArguments[0];
    if (possiblePath.isEmpty) return;

    if (Directory(possiblePath).existsSync()) {
      widget.model.loadFolder(possiblePath, recursive: true);
    }
  }

  void _bindModelCallbacks() {
    final model = widget.model;
    model.onImagesChanged ??= () => _handleStateChange();
    model.onImagesLoadedSuccess ??= _handleFilesLoadedSuccess;
    model.onImageChange ??= _handleOnImageChange;
    model.onCountdownUpdate ??= () => playClickSound();
    model.onImageDurationElapse ??= () => playClickSound();
    model.onFilePickerStateChange ??= () => _handleFilePickerOpenClose();
    model.onWelcomeComplete ??= () => _handleWelcomeComplete();

    final timerModel = model.timerModel;
    timerModel.onPlayPause ??= () => _handleTimerPlayPause();
    timerModel.onReset ??= () => playClickSound();
    timerModel.onDurationChangeSuccess ??= () => _handleTimerChangeSuccess();

    windowState.isSoundsEnabled.addListener(() => _handleSoundChanged());
    windowState.isAlwaysOnTop.addListener(() => _handleAlwaysOnTopChanged());

    currentAppControlsMode.addListener(() => _handleAppControlsChanged());

    onColorMeterExit = () {
      setAppMode(PfsAppControlsMode.imageBrowse);
    };
  }

  void _handleDisposeCallbacks() {
    windowState.isSoundsEnabled.removeListener(() => _handleSoundChanged());
    windowState.isAlwaysOnTop.removeListener(() => _handleAlwaysOnTopChanged());
  }

  void _handleWelcomeComplete() {
    _handleTimerPlayPause();
  }

  void _tryEscape() {
    EscapeNavigator.of(context)?.tryEscape();
  }

  void _handleOpenColorMeterMenuItem() {
    if (currentAppControlsMode.value != PfsAppControlsMode.imageBrowse) return;
    setAppMode(PfsAppControlsMode.colorMeter);
  }

  void _handleFilesLoadedSuccess(int filesLoaded, int filesSkipped) {
    final imageNoun = PfsLocalization.imageNoun(filesLoaded);

    if (filesSkipped == 0) {
      if (filesLoaded == 1) {
        Phtoasts.showWidget(
          context,
          child: Text("${imageNoun.capitalizeFirst()} loaded."),
        );
      } else {
        Phtoasts.showWidget(
          context,
          child: PfsLocalization.textWithMultiBold(
            text1: '',
            boldText1: '$filesLoaded $imageNoun',
            text2: ' loaded.',
          ),
        );
      }
    } else {
      final fileSkippedNoun = PfsLocalization.fileNoun(filesSkipped);

      Phtoasts.showWidget(
        context,
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
    Phtoasts.showWidget(context, child: toastContent);
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
    final isTimerRunning = widget.model.timerModel.isRunning;
    animateTimerIconTo(isTimerRunning);
  }

  void _handleTimerPlayPause() {
    void showTimerToast() {
      final isRunning = widget.model.timerModel.isRunning;
      final message = PfsLocalization.timerSwitched(isRunning);
      final icon = isRunning ? Icons.play_arrow : Icons.pause;

      showToast(
        message: message,
        icon: icon,
      );
    }

    updateTimerPlayPauseIcon();
    showTimerToast();
    playClickSound(playWhilePaused: true);
  }

  void _handleAlwaysOnTopChanged() {
    void showAlwaysOnTopToast() {
      final bool wasEnabled = windowState.isAlwaysOnTop.value;
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
    void showSoundToggleToast() {
      final bool wasEnabled = windowState.isSoundsEnabled.value;
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
        colorMeterPanel.open();
      } else {
        debugPrint(
            "image widget not found. canceled opening color meter panel");
        setAppMode(PfsAppControlsMode.imageBrowse);
      }
    } else {
      colorMeterPanel.close();
      colorMeterModel.endColorMeter();
    }
  }

  void revealCurrentImageInExplorer() {
    final currentImageData = getCurrentImageFileData();
    if (currentImageData is ImageFileData) {
      image_data.revealImageFileDataInExplorer(currentImageData);
    }
  }

  Widget _fileDropZone() {
    return ValueListenableBuilder(
      valueListenable: currentAppControlsMode,
      builder: (context, currentAppControlModeValue, __) {
        if (currentAppControlModeValue != PfsAppControlsMode.imageBrowse) {
          return const SizedBox.shrink();
        }

        final model = PfsAppModel.of(context);

        const double horizontalMargin = 20;
        const double bottomMargin = 40;
        const double topMargin = 30;

        return Positioned.fill(
          left: horizontalMargin,
          right: horizontalMargin,
          bottom: bottomMargin,
          top: topMargin,
          child: ImageDropTarget(
            dragImagesHandler: (details) {
              if (details.files.isEmpty) return;
              final List<String> filePaths = [];
              for (final file in details.files) {
                final filePath = file.path;
                if (ImageList.fileIsImage(filePath)) {
                  filePaths.add(filePath);
                } else if (pathIsDirectory(filePath)) {
                  filePaths.add(filePath);
                }
              }
              if (filePaths.isEmpty) return;

              model.loadImageFiles(filePaths, recursive: true).then(
                (_) {
                  if (model.hasImagesLoaded) {
                    _onFileDropped();
                  }
                },
              );
            },
          ),
        );
      },
    );
  }

  void _onFileDropped() {
    windowManager.focus();
  }

  Widget _bottomControls({double? windowWidth}) {
    final bool isNarrowWindow = windowWidth != null && windowWidth < 500.00;

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

    List<Widget> imageBrowseBottomBarItems({
      double spacing = 15,
    }) {
      const double rightMargin = 20;
      final SizedBox spacingBox = SizedBox(width: spacing);

      if (widget.model.hasImagesLoaded) {
        return [
          colorMeterModeButton(onPressed: () {
            setAppMode(PfsAppControlsMode.colorMeter);
          }),
          ResetZoomButton(zoomPanner: imagePhviewer),
          FiltersButton(imageFilters: imagePhviewer, filtersMenu: filtersMenu),
          spacingBox,
          Phbuttons.timerSettingsButton(
            onPressed: () => timerDurationMenu.open(),
            timerModel: widget.model.timerModel,
          ),
          spacingBox,
          TimerControls(playPauseIconController: _playPauseIconStateAnimator),
          SizedBox(width: spacing + 3),
          ValueListenableBuilder(
              valueListenable: imagesViewedCounter,
              builder: (context, value, child) {
                return ImageSetButton(
                  model: widget.model,
                  narrowButton: isNarrowWindow,
                  extraTooltip: getScoreText(),
                );
              }),
          const SizedBox(width: rightMargin),
        ];
      } else {
        return [
          Phbuttons.openFiles(
            width: isNarrowWindow ? 20 : 40,
            model: widget.model,
          ),
          const SizedBox(width: 15, height: 43),
        ];
      }
    }

    const double narrowSpacing = 4;
    const double wideSpacing = 12;
    const double minimizeButtonRightSpace = 10;

    Widget imageBrowseBottomBar() {
      return Positioned(
        bottom: 0,
        right: minimizeButtonRightSpace,
        child: TweenAnimationBuilder<double>(
          duration: Phanimations.defaultDuration,
          tween: Tween<double>(
            begin: narrowSpacing,
            end: isNarrowWindow ? narrowSpacing : wideSpacing,
          ),
          builder: (_, spacing, __) {
            final theme = Theme.of(context);
            final containerBorderRadius =
                theme.extension<PfsAppTheme>()?.borderRadius ??
                    BorderRadius.circular(25);

            return HoverContainer(
              hoverBackgroundColor: theme.scaffoldBackgroundColor,
              borderRadius: containerBorderRadius,
              child: Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: ListenableBuilder(
                  listenable: widget.model.imageListChangedNotifier,
                  builder: (context, child) {
                    return Row(
                      children: imageBrowseBottomBarItems(
                        spacing: spacing,
                      ).animate(
                        interval: const Duration(milliseconds: 25),
                        effects: const [Phanimations.bottomBarSlideUpEffect],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      );
    }

    return ValueListenableBuilder(
      valueListenable: currentAppControlsMode,
      builder: (_, currentAppControlsModeValue, __) {
        if (currentAppControlsModeValue == PfsAppControlsMode.colorMeter) {
          return SizedBox.shrink();
        }

        return imageBrowseBottomBar();
      },
    );
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

mixin MainScreenImageViewedCounter {
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

mixin MainScreenToaster on State<MainScreen> {
  void showToast({
    required String message,
    IconData? icon,
    Alignment alignment = Alignment.bottomCenter,
  }) {
    Phtoasts.show(
      context,
      message: message,
      icon: icon,
      alignment: Phtoasts.topControlsAlign,
    );
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
    final bool isPickingFiles = widget.model.isPickerOpen;
    final bool isAlwaysOnTopUserIntent = windowState.isAlwaysOnTop.value;

    final bool currentAlwaysOnTop = isAlwaysOnTopUserIntent && !isPickingFiles;
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
      widget.model.tryPauseTimer();
    }

    currentAppControlsMode.value = newMode;
    onAppModeChange();
  }

  void onAppModeChange();

  late ImagePhviewer imagePhviewer = ImagePhviewer(
    appControlsMode: currentAppControlsMode,
  );
}

mixin MainScreenClipboardFunctions on MainScreenToaster {
  ImageData getCurrentImageFileData();

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

    if (currentImageData is ImageFileData) {
      final filePath = currentImageData.filePath;
      try {
        final imageData = await getUiImageFromFile(filePath);
        await phclipboard.copyImageFileToClipboardAsPngAndFileUri(
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
    } else if (currentImageData is ImageMemoryData) {
      try {
        await phclipboard.copyImageBytesToClipboardAsPng(
            imageBytes: currentImageData.bytes!);
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
  }
}

mixin MainScreenPanels on MainScreenModels, MainScreenWindow {
  ValueNotifier<bool> getSoundEnabledNotifier();
  ValueNotifier<String> getThemeNotifier();

  late final ModalPanel filtersMenu = ModalPanel(
    onBeforeOpen: () {
      closeAllPanels(except: filtersMenu);
      registerEscape("filters panel");
    },
    isUnderlayTransparent: true,
    builder: () => FilterPanel(imagePhviewer: imagePhviewer),
    transitionBuilder: Phanimations.bottomMenuTransition,
  );

  late final ModalPanel helpMenu = ModalPanel(
    onBeforeOpen: () {
      closeAllPanels(except: helpMenu);
      registerEscape("help menu");
    },
    builder: () {
      return Theme(
        data: ThemeData.dark(useMaterial3: true),
        child: const HelpSheet(),
      );
    },
  );

  late final ModalPanel settingsMenu = ModalPanel(
    onBeforeOpen: () {
      closeAllPanels(except: settingsMenu);
      registerEscape("settings menu");
    },
    builder: () {
      return SettingsPanel(
        themeNotifier: getThemeNotifier(),
        soundEnabledNotifier: getSoundEnabledNotifier(),
        aboutMenu: aboutMenu,
      );
    },
    transitionBuilder: Phanimations.rightMenuTransition,
  );

  late final ModalPanel timerDurationMenu = ModalPanel(
    onBeforeOpen: () {
      closeAllPanels(except: timerDurationMenu);
      registerEscape("timer durations menu");
    },
    onOpened: () {
      timerDurationEditor.setActive(timerDurationMenu.isOpen,
          widget.model.timerModel.currentDurationSeconds);
    },
    onClosed: () {
      refocusMainWindow();
      timerDurationEditor.setActive(timerDurationMenu.isOpen,
          widget.model.timerModel.currentDurationSeconds);
    },
    builder: () => timerDurationEditor.widget(),
    transitionBuilder: Phanimations.bottomMenuTransition,
  );

  late final ModalPanel aboutMenu = ModalPanel(
    onBeforeOpen: () {
      closeAllPanels(except: aboutMenu);
      registerEscape("about menu");
    },
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
    for (final panel in modalPanels) {
      yield panel.widget();
    }
  }

  void registerEscape(String panelName) {
    final escapeNavigator = EscapeNavigator.of(context);
    escapeNavigator?.push(
      EscapeRoute(
        name: panelName,
        onEscape: () {
          closeAllPanels();
        },
        willPopOnEscape: true,
      ),
    );
  }

  void closeAllPanels({ModalPanel? except}) {
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
    required this.imageFilters,
    required this.filtersMenu,
  });

  final ImageFilters imageFilters;
  final ModalPanel filtersMenu;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: imageFilters.filtersChangeListenable,
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

        final String tooltip = imageFilters.isFilterActive
            ? 'Filters (${imageFilters.activeFilterCount})'
            : 'Filters';

        return GestureDetector(
          onTertiaryTapDown: (details) {
            if (imageFilters.isFilterActive) {
              imageFilters.resetAllFilters();
            }
          },
          child: IconButton(
            onPressed: () => filtersMenu.open(),
            isSelected: imageFilters.isFilterActive,
            tooltip: tooltip,
            icon: imageFilters.isFilterActive ? filterIconOn : filterIconOff,
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
  static const double cornerMargin = 3;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: cornerMargin,
      right: cornerMargin,
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
    required this.colorMeterMenuItemHandler,
    required this.model,
  });

  final PfsAppModel model;
  final Animation<double> playPauseIconProgress;
  final ImagePhviewer imagePhviewer;
  final VoidCallback revealInExplorerHandler;
  final VoidCallback colorMeterMenuItemHandler;

  @override
  Widget build(BuildContext context) {
    final AnimatedIcon playPauseIcon = AnimatedIcon(
      icon: AnimatedIcons.play_pause,
      size: 80,
      progress: playPauseIconProgress,
    );

    return ListenableBuilder(
      listenable: model.allowedControlsChanged,
      builder: (_, __) {
        const double beforeButtonWidth = 100;
        const double afterButtonWidth = 140;

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
            return model.allowTimerPlayPause
                ? OverlayButton(
                    onPressed: () => model.tryTogglePlayPauseTimer(),
                    child: playPauseIcon,
                  )
                : TextButton(onPressed: null, child: Text(""));
          }

          return ImagePhviewerZoomOnScrollListener(
            zoomPanner: imagePhviewer,
            child: ImageRightClick(
              revealInExplorerHandler: revealInExplorerHandler,
              resetZoomLevelHandler: () => imagePhviewer.resetTransform(),
              colorChangeModeHandler: colorMeterMenuItemHandler,
              child: ValueListenableBuilder(
                valueListenable: imagePhviewer.zoomLevelListenable,
                builder: (_, __, ___) {
                  return ImagePhviewerPanListener(
                    zoomPanner: imagePhviewer,
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
                model.allowCirculatorControl
                    ? nextPreviousGestureButton(
                        width: beforeButtonWidth,
                        onPressed: () => model.nextImageNewTimer(),
                        child: PfsTheme.beforeGestureIcon,
                      )
                    : SizedBox(width: beforeButtonWidth),
                Expanded(
                  flex: 4,
                  child: middleGestureButton(),
                ),
                model.allowCirculatorControl
                    ? nextPreviousGestureButton(
                        width: afterButtonWidth,
                        onPressed: () => model.nextImageNewTimer(),
                        child: PfsTheme.nextGestureIcon,
                      )
                    : SizedBox(width: afterButtonWidth),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PfsWindowState {
  bool rightControlsOrientation = true;
  bool isTouch = false;

  final isBottomBarMinimized = ValueNotifier(false);
  final isAlwaysOnTop = ValueNotifier(false);
  final isSoundsEnabled = ValueNotifier(true);
}
