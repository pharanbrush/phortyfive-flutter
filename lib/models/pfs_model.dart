import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:pfs2/core/circulator.dart';
import 'package:pfs2/core/file_data.dart';
import 'package:pfs2/core/file_list.dart';
import 'package:pfs2/models/phtimer_model.dart';
import 'package:pfs2/utils/path_directory_expand.dart';
import 'package:scoped_model/scoped_model.dart';

class PfsAppModel extends Model
    with
        PfsImageFileManager,
        PfsModelTimer,
        PfsCountdownCounter,
        PfsWelcomer,
        PfsCirculator,
        PfsAnnotator {
  static ScopedModelDescendant<PfsAppModel> scope(
          ScopedModelDescendantBuilder<PfsAppModel> builder) =>
      ScopedModelDescendant<PfsAppModel>(builder: builder);

  bool get allowTimerPlayPause => hasFilesLoaded && isWelcomeDone && !isAnnotating;
  bool get allowCirculatorControl => hasFilesLoaded && isWelcomeDone && !isAnnotating;
  bool get isAnnotating => isAnnotatingMode.value;

  @override
  bool _canStartCountdown() => timerModel.isRunning && !isAnnotating;

  FileData getCurrentImageFileData() {
    return fileList.get(circulator.currentIndex);
  }

  void tryTogglePlayPauseTimer() {
    if (!allowTimerPlayPause) return;

    tryCancelCountdown();
    timerModel.playPauseToggleTimer();
  }

  void previousImageNewTimer() {
    if (!allowCirculatorControl) return;

    tryCancelCountdown();
    timerModel.restartTimer();
    onImageChange?.call();
    _previousImage();
  }

  void nextImageNewTimer() {
    if (!allowCirculatorControl) return;

    tryCancelCountdown();
    timerModel.restartTimer();
    onImageChange?.call();
    _nextImage();
  }

  void _previousImage() {
    if (!allowCirculatorControl) return;

    circulator.movePrevious();
    lastIncrement = -1;
    notifyListeners();
  }

  void _nextImage() {
    if (!allowCirculatorControl) return;

    circulator.moveNext();
    lastIncrement = 1;
    notifyListeners();
  }

  void _handleTimerElapsed() {
    nextImageNewTimer();
    onImageDurationElapse?.call();
    tryStartCountdown();
    notifyListeners();
  }

  @override
  void _onImagesLoaded() {
    final loadedCount = fileList.getCount();
    circulator.startNewOrder(loadedCount);

    if (isWelcomeDone) {
      reinitializeTimer();
      if (timerModel.isRunning) {
        tryStartCountdown();
      }

      onImageChange?.call();
      notifyListeners();
    }
  }

  void tryStartSession() {
    reinitializeTimer();
    if (isUserChoseToStartTimer) {
      tryStartCountdown();
    } else {
      timerModel.setActive(false);
    }

    onImageChange?.call();
    notifyListeners();
  }  

  void reinitializeTimer() {
    timerModel.tryInitialize();
    timerModel.onElapse ??= () => _handleTimerElapsed();
    timerModel.restartTimer();
  }

  @override
  void _onCountdownCanceled() {
    timerModel.deregisterPauser(this);
    notifyListeners();
  }

  @override
  void _onCountdownStartInternal() {
    timerModel.registerPauser(this);
  }

  @override
  void _onCountdownElapsedInternal() {
    timerModel.deregisterPauser(this);
    timerModel.restartTimer();
  }
}

mixin PfsWelcomer {
  bool isWelcomeDone = false;
  bool isUserChoseToStartTimer = false;

  void Function()? onWelcomeComplete;
}

mixin PfsAnnotator {
  final isAnnotatingMode = ValueNotifier(false);

  void toggleAnnotationMode() {
    isAnnotatingMode.value = !isAnnotatingMode.value;
  }
}

mixin PfsCirculator {
  final Circulator circulator = Circulator();

  int lastIncrement = 1;
  int get currentImageIndex => circulator.currentIndex;
}

mixin PfsModelTimer {
  final PhtimerModel timerModel = PhtimerModel();

  void Function()? onImageDurationElapse;
}

mixin PfsCountdownCounter on Model {
  bool _isCountdownEnabled = true;
  bool get isCountdownEnabled => _isCountdownEnabled;
  static const int countdownStart = 3;
  int countdownLeft = 0;
  bool countdownCancelled = false;
  bool get isCountingDown => countdownLeft > 0;
  void Function()? onCountdownStart;
  void Function()? onCountdownElapsed;
  void Function()? onCountdownUpdate;

  void _onCountdownActiveStateChanged() => notifyListeners();
  void _onCountdownCountChanged() => notifyListeners();
  void _onCountdownCanceled();
  void _onCountdownStartInternal();
  void _onCountdownElapsedInternal();
  bool _canStartCountdown();

  void setCountdownActive(bool active) {
    _isCountdownEnabled = active;
    _onCountdownActiveStateChanged();
  }

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

mixin PfsImageFileManager {
  final FileList fileList = FileList();

  String lastFolder = '';
  bool isPickerOpen = false;
  bool get hasFilesLoaded => fileList.isPopulated();

  void Function(int loadedCount, int skippedCount)? onFilesLoadedSuccess;
  void Function()? onFilePickerStateChange;
  void Function()? onImageChange;
  void Function()? onFilesChanged;

  final isLoadingImages = ValueNotifier(false);
  final currentlyLoadingImages = ValueNotifier<int>(0);

  void _onImagesLoaded();

  void _setStateFilePickerOpen(bool active) {
    isPickerOpen = active;
    onFilePickerStateChange?.call();
  }

  void openFilePickerForImages() async {
    if (isPickerOpen) return;

    _setStateFilePickerOpen(true);
    final files = await openFiles(
      acceptedTypeGroups: [
        const XTypeGroup(
          label: 'images',
          extensions: FileList.allowedExtensions,
        )
      ],
    );
    _setStateFilePickerOpen(false);

    if (files.isEmpty) return;

    final pathList = files.map((file) => file.path).toList();
    loadImages(pathList);
  }

  void openFilePickerForFolder({bool includeSubfolders = false}) async {
    if (isPickerOpen) return;

    _setStateFilePickerOpen(true);
    var folder = await getDirectoryPath();
    _setStateFilePickerOpen(false);

    if (folder == null || folder.isEmpty) return;

    loadFolder(folder, recursive: includeSubfolders);
  }

  void loadFolder(String folderPath, {bool recursive = false}) async {
    if (folderPath.isEmpty) return;

    final directory = Directory(folderPath);

    try {
      final directoryContents = directory.list(recursive: recursive);
      final List<String?> filePaths = [];
      await for (final FileSystemEntity entry in directoryContents) {
        if (entry is File) {
          filePaths.add(entry.path);
        }
      }
      await loadImages(filePaths);
      lastFolder = directory.path.split(Platform.pathSeparator).last;
    } catch (e) {
      isPickerOpen = false;
      onFilePickerStateChange?.call();
    }
  }

  Future loadImages(
    List<String?> filePaths, {
    bool recursive = false,
  }) async {
    if (filePaths.isEmpty) return;

    isLoadingImages.value = true;
    final expandedFilePaths = await getExpandedList(
      filePaths,
      onFileAdded: (fileCount) => currentlyLoadingImages.value = fileCount,
      recursive: recursive,
    );

    await fileList.load(expandedFilePaths);

    final loadedCount = fileList.getCount();
    final lastFile = fileList.getLast();
    final potentialFolderPath = lastFile.fileFolder;
    if (potentialFolderPath.trim().isNotEmpty) {
      lastFolder = potentialFolderPath.split(Platform.pathSeparator).last;
    } else {
      lastFolder = '[mixed]';
    }
    onFilesChanged?.call();
    onFilesLoadedSuccess?.call(loadedCount, loadedCount - filePaths.length);
    isLoadingImages.value = false;

    _onImagesLoaded();
  }
}
