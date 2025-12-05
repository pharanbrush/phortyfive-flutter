import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:flutter/material.dart';
import 'package:pfs2/core/circulator.dart';
import 'package:pfs2/core/image_data.dart';
import 'package:pfs2/core/image_list.dart';
import 'package:pfs2/models/pfs_preferences.dart' as pfs_preferences;
import 'package:pfs2/models/phtimer_model.dart';
import 'package:pfs2/phlutter/model_scope.dart';
import 'package:pfs2/phlutter/simple_notifier.dart';
import 'package:pfs2/phlutter/utils/path_directory_expand.dart';

enum PfsAppControlsMode {
  imageBrowse,
  colorMeter,
  annotation,
  firstAction,
}

class PfsAppModel
    with
        PfsImageListManager,
        PfsModelTimer,
        PfsCountdownCounter,
        PfsInitialUseChoice,
        PfsCirculator {
  static PfsAppModel of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ModelScope<PfsAppModel>>()!
        .model;
  }

  final currentAppControlsMode =
      ValueNotifier<PfsAppControlsMode>(PfsAppControlsMode.imageBrowse);

  bool get isImageBrowseMode =>
      currentAppControlsMode.value == PfsAppControlsMode.imageBrowse;

  bool get allowTimerPlayPause =>
      hasMoreThanOneImage && isInitialUseChoiceChosen.value;
  bool get allowCirculatorControl =>
      hasMoreThanOneImage &&
      isInitialUseChoiceChosen.value &&
      isImageBrowseMode;

  @override
  bool get allowImageSetChange => isImageBrowseMode;

  late final allowedControlsChanged = Listenable.merge([
    imageListChangedNotifier,
    isInitialUseChoiceChosen,
  ]);

  final currentImageChangedNotifier = SimpleNotifier();

  @override
  bool _canStartCountdown() => timerModel.isRunning; // && !isAnnotating;

  ImageData getCurrentImageData() {
    if (!imageList.isPopulated) return ImageData.invalid;

    return imageList.get(circulator.currentOutputIndex);
  }

  void preloadSurroundingImages(BuildContext context) async {
    final current = circulator.currentOutputIndex;

    final surroundingImageData = _getSurroundingImageData(current);

    for (final imageData in surroundingImageData) {
      if (imageData is ImageFileData) {
        final path = imageData.filePath;
        //debugPrint("preloading: $path");
        final fileImage = FileImage(File(path));
        await precacheImage(fileImage, context);
      }
    }
  }

  Iterable<ImageData> _getSurroundingImageData(int index) sync* {
    if (imageList.count == 1) return;
    const indexOffsets = [1, -1];

    for (final offset in indexOffsets) {
      final index = circulator.getSurroundingOutputIndex(offset);
      if (index != null) {
        yield imageList.get(index);
      }
    }
  }

  void tryPauseTimer() {
    if (timerModel.isRunning) {
      tryCancelCountdown();
      timerModel.playPauseToggleTimer();
    }
  }

  void tryTogglePlayPauseTimer() {
    if (!allowTimerPlayPause) return;

    tryCancelCountdown();
    timerModel.playPauseToggleTimer();
  }

  void previousImageNewTimer() {
    if (!allowCirculatorControl) return;

    tryCancelCountdown();
    timerModel.resetTimer();
    _previousImage();
  }

  void nextImageNewTimer() {
    if (!allowCirculatorControl) return;

    tryCancelCountdown();
    timerModel.resetTimer();

    _nextImage();
  }

  void _notifyImageChange() {
    onImageChange?.call();
    currentImageChangedNotifier.notify();
  }

  void _previousImage() {
    if (!allowCirculatorControl) return;

    circulator.movePrevious();
    lastIncrement = -1;
    _notifyImageChange();
  }

  void _nextImage() {
    if (!allowCirculatorControl) return;

    circulator.moveNext();
    lastIncrement = 1;
    _notifyImageChange();
  }

  @override
  void handleTimerElapse() {
    nextImageNewTimer();
    onImageDurationElapse?.call();
    tryStartCountdown();
    _notifyImageChange();
  }

  @override
  void _onImagesLoaded() {
    final loadedCount = imageList.count;
    circulator.startNewOrder(loadedCount);

    if (isInitialUseChoiceChosen.value) {
      reinitializeTimer();
      if (timerModel.isRunning) {
        tryStartCountdown();
      }

      _notifyImageChange();
    } else {
      if (loadedCount == 1) {
        isInitialUseChoiceChosen.value = true;
      }
    }
  }

  void tryStartSession() {
    reinitializeTimer();
    if (isUserChoseToStartTimer) {
      timerModel.setActive(true);
      tryStartCountdown();
    } else {
      timerModel.setActive(false);
    }

    _notifyImageChange();
  }

  void reinitializeTimer() {
    timerModel.tryInitialize();
    timerModel.resetTimer();
  }

  @override
  void _onCountdownCanceled() {
    timerModel.deregisterPauser(this);
    countdownChangedListenable.notify();
  }

  @override
  void _onCountdownStartInternal() {
    timerModel.registerPauser(this);
  }

  @override
  void _onCountdownElapsedInternal() {
    timerModel.deregisterPauser(this);
    timerModel.resetTimer();
  }
}

mixin PfsInitialUseChoice {
  final isInitialUseChoiceChosen = ValueNotifier(false);
  bool isUserChoseToStartTimer = false;

  void Function()? onInitialUseChoiceComplete;
}

mixin PfsCirculator {
  final Circulator circulator = Circulator();

  int lastIncrement = 1;
  int get currentImageIndex => circulator.currentOutputIndex;
}

mixin PfsModelTimer {
  late final PhtimerModel timerModel = PhtimerModel(
    onElapse: handleTimerElapse,
  );

  void handleTimerElapse();

  void Function()? onImageDurationElapse;
}

mixin PfsCountdownCounter {
  bool _isCountdownEnabled = true;
  bool get isCountdownEnabled => _isCountdownEnabled;
  static const int countdownStart = 3;
  int countdownLeft = 0;
  bool countdownCancelled = false;
  bool get isCountingDown => countdownLeft > 0;
  void Function()? onCountdownStart;
  void Function()? onCountdownElapsed;
  void Function()? onCountdownUpdate;

  final countdownChangedListenable = SimpleNotifier();

  void _onCountdownActiveStateChanged() => countdownChangedListenable.notify();
  void _onCountdownCountChanged() => countdownChangedListenable.notify();
  void _onCountdownCanceled();
  void _onCountdownStartInternal();
  void _onCountdownElapsedInternal();
  bool _canStartCountdown();

  void setCountdownActive(bool active) {
    _isCountdownEnabled = active;
    _onCountdownActiveStateChanged();
  }

  /// Countdown doesn't start if timer is not enabled.
  void tryStartCountdown() {
    if (_isCountdownEnabled && _canStartCountdown()) {
      _countdownRoutine();
    } else {
      _countdownElapse();
    }
  }

  void tryCancelCountdown() {
    if (countdownLeft > 0) {
      countdownCancelled = true;
      _onCountdownCanceled();
    }
    countdownLeft = 0;
  }

  void _countdownRoutine() async {
    countdownLeft = countdownStart;
    _onCountdownStartInternal();
    onCountdownStart?.call();

    for (int i = 30; i > 0; i++) {
      await Future.delayed(const Duration(seconds: 1));

      if (countdownCancelled) {
        countdownCancelled = false;
        _onCountdownCanceled();
        return;
      }

      countdownLeft--;
      onCountdownUpdate?.call();
      _onCountdownCountChanged();
      if (countdownLeft <= 0) break;
    }

    _onCountdownElapsedInternal();
    _countdownElapse();
  }

  void _countdownElapse() {
    onCountdownElapsed?.call();
  }
}

mixin PfsImageListManager {
  final ImageList imageList = ImageList();

  String lastFolder = '';
  bool isPickerOpen = false;
  bool get hasImagesLoaded => imageList.isPopulated;
  bool get hasMoreThanOneImage => imageList.count > 1;

  final imageListChangedNotifier = SimpleNotifier();

  bool get allowImageSetChange;

  void Function(int loadedCount, int skippedCount)? onImagesLoadedSuccess;
  void Function()? onFilePickerStateChange;
  void Function()? onImageChange;
  void Function()? onImagesChanged;

  final isLoadingImages = ValueNotifier(false);
  final currentlyLoadingImages = ValueNotifier<int>(0);

  void _onImagesLoaded();

  void _setStateFilePickerOpen(bool active) {
    isPickerOpen = active;
    onFilePickerStateChange?.call();
  }

  void openFilePickerForImages() async {
    if (!allowImageSetChange) return;
    if (isPickerOpen) return;

    _setStateFilePickerOpen(true);
    final files = await file_selector.openFiles(
      acceptedTypeGroups: [
        const file_selector.XTypeGroup(
          label: "images",
          extensions: ImageList.allowedExtensions,
        )
      ],
    );
    _setStateFilePickerOpen(false);

    if (files.isEmpty) return;

    final pathList = files.map((file) => file.path).toList();
    loadImageFiles(pathList);
  }

  void openFilePickerForFolder({bool includeSubfolders = false}) async {
    if (!allowImageSetChange) return;
    if (isPickerOpen) return;

    _setStateFilePickerOpen(true);
    final folder = await file_selector.getDirectoryPath();
    _setStateFilePickerOpen(false);

    if (folder == null || folder.isEmpty) return;

    loadFolder(folder, recursive: includeSubfolders);
  }

  void openFilePickerForRandomFolderInFolder({
    bool includeSubfolders = false,
  }) async {
    if (!allowImageSetChange) return;
    if (isPickerOpen) return;

    _setStateFilePickerOpen(true);
    final parentFolderPath = await file_selector.getDirectoryPath();
    _setStateFilePickerOpen(false);

    if (parentFolderPath == null || parentFolderPath.isEmpty) return;

    final folderPath = await getRandomFolderFrom(parentFolderPath);

    if (folderPath == null || folderPath.isEmpty) return;

    loadFolder(
      folderPath,
      recursive: includeSubfolders,
      addToRecentFolders: false,
    );
  }

  void loadFolder(
    String folderPath, {
    bool recursive = false,
    bool addToRecentFolders = true,
  }) async {
    if (!allowImageSetChange) return;
    if (folderPath.isEmpty) return;

    final directory = Directory(folderPath);

    try {
      final directoryContents = directory.list(recursive: recursive);
      final filePaths = <String?>[];
      await for (final FileSystemEntity entry in directoryContents) {
        if (entry is File) {
          filePaths.add(entry.path);
        }
      }
      await loadImageFiles(filePaths);
      lastFolder = directory.path.split(Platform.pathSeparator).last;
    } catch (e) {
      isPickerOpen = false;
      onFilePickerStateChange?.call();
    }

    if (addToRecentFolders) {
      await pfs_preferences.pushRecentFolder(
        folderPath: folderPath,
        includeSubfolders: recursive,
      );
    }
  }

  Future loadImageFiles(
    List<String?> filePaths, {
    bool recursive = false,
  }) async {
    if (filePaths.isEmpty) return;

    _startLoadingImages();

    final expandedFilePaths = await getExpandedList(
      filePaths,
      onFileAdded: (fileCount) => currentlyLoadingImages.value = fileCount,
      recursive: recursive,
    );

    await imageList.loadFiles(expandedFilePaths);

    final lastFile = imageList.last;
    if (lastFile is ImageFileData) {
      final potentialFolderPath = lastFile.fileFolder;
      if (potentialFolderPath.trim().isNotEmpty) {
        lastFolder = potentialFolderPath.split(Platform.pathSeparator).last;
      } else {
        lastFolder = "[mixed]";
      }
    } else {
      lastFolder = "";
    }

    _endLoadingImages(expandedFilePaths.length);
  }

  Future loadImage(ImageData? image) async {
    if (image == null) return;
    _startLoadingImages();
    await imageList.loadImage(image);
    _endLoadingImages(1);
  }

  Future loadImages(List<ImageData?> images) async {
    if (images.isEmpty) return;
    _startLoadingImages();
    await imageList.loadImages(images);
    _endLoadingImages(images.length);
  }

  void _startLoadingImages() {
    isLoadingImages.value = true;
  }

  void _endLoadingImages(int sourceCount) {
    final loadedCount = imageList.count;
    onImagesChanged?.call();

    onImagesLoadedSuccess?.call(loadedCount, loadedCount - sourceCount);
    isLoadingImages.value = false;
    imageListChangedNotifier.notify();

    _onImagesLoaded();
  }
}
