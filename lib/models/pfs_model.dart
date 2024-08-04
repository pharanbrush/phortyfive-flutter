import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:pfs2/core/circulator.dart';
import 'package:pfs2/core/file_list.dart';
import 'package:pfs2/models/phtimer_model.dart';
import 'package:scoped_model/scoped_model.dart';

class PfsAppModel extends Model {
  static ScopedModelDescendant<PfsAppModel> scope(
          ScopedModelDescendantBuilder<PfsAppModel> builder) =>
      ScopedModelDescendant<PfsAppModel>(builder: builder);

  bool get allowTimerPlayPause => hasFilesLoaded;

  final Circulator circulator = Circulator();
  final FileList fileList = FileList();
  final PhtimerModel timerModel = PhtimerModel();

  bool isPickerOpen = false;

  int lastIncrement = 1;
  bool get hasFilesLoaded => fileList.isPopulated();
  String lastFolder = '';
  int get currentImageIndex => circulator.currentIndex;
  bool get allowCirculatorControl => hasFilesLoaded;
  void Function()? onImageChange;
  void Function()? onFilesChanged;

  bool _isCountdownEnabled = true;
  bool get isCountdownEnabled => _isCountdownEnabled;
  static const int countdownStart = 3;
  int countdownLeft = 0;
  bool countdownCancelled = false;
  bool get isCountingDown => countdownLeft > 0;
  void Function()? onCountdownStart;
  void Function()? onCountdownElapsed;
  void Function()? onCountdownUpdate;
  void Function()? onImageDurationElapse;

  void Function(int loadedCount, int skippedCount)? onFilesLoadedSuccess;
  void Function()? onFilePickerStateChange;

  FileData getCurrentImageFileData() {
    return fileList.get(circulator.currentIndex);
  }

  void tryTogglePlayPauseTimer() {
    if (!allowTimerPlayPause) return;

    tryCancelCountdown();
    timerModel.playPauseToggleTimer();
  }

  void tryStartCountdown() {
    if (_isCountdownEnabled && timerModel.isRunning) {
      _countdownRoutine();
    } else {
      _countdownElapse();
    }
  }

  void tryCancelCountdown() {
    if (countdownLeft > 0) {
      countdownCancelled = true;
      notifyListeners();
    }
    countdownLeft = 0;
  }

  void setCountdownActive(bool active) {
    _isCountdownEnabled = active;
    notifyListeners();
  }

  void _countdownRoutine() async {
    countdownLeft = countdownStart;
    timerModel.registerPauser(this);
    onCountdownStart?.call();

    for (int i = 30; i > 0; i++) {
      await Future.delayed(const Duration(seconds: 1));

      if (countdownCancelled) {
        timerModel.deregisterPauser(this);
        countdownCancelled = false;
        return;
      }

      countdownLeft--;
      onCountdownUpdate?.call();
      notifyListeners();
      if (countdownLeft <= 0) break;
    }

    timerModel.deregisterPauser(this);
    timerModel.restartTimer();
    _countdownElapse();
  }

  void _countdownElapse() {
    onCountdownElapsed?.call();
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

  void openFilePickerForFolder() async {
    if (isPickerOpen) return;

    _setStateFilePickerOpen(true);
    var folder = await getDirectoryPath();
    _setStateFilePickerOpen(false);

    if (folder == null || folder.isEmpty) return;

    loadFolder(folder);
  }

  void loadFolder(String folderPath) async {
    if (folderPath.isEmpty) return;

    final directory = Directory(folderPath);

    try {
      final directoryContents = directory.list();
      final List<String?> filePaths = [];
      await for (final FileSystemEntity entry in directoryContents) {
        if (entry is File) {
          filePaths.add(entry.path);
        }
      }
      loadImages(filePaths);
    } catch (e) {
      isPickerOpen = false;
      onFilePickerStateChange?.call();
    }
  }

  void loadImages(List<String?> filePaths) async {
    if (filePaths.isEmpty) return;

    await fileList.load(filePaths);

    final loadedCount = fileList.getCount();
    final lastFile = fileList.getLast();
    final potentialFolderPath = lastFile.fileFolder;
    if (potentialFolderPath.trim().isNotEmpty) {
      lastFolder = potentialFolderPath.split(Platform.pathSeparator).last;
    } else {
      lastFolder = '';
    }

    circulator.startNewOrder(loadedCount);
    onFilesChanged?.call();
    onFilesLoadedSuccess?.call(loadedCount, loadedCount - filePaths.length);

    timerModel.tryInitialize();
    timerModel.onElapse ??= () => _handleTimerElapsed();

    tryStartCountdown();
    timerModel.restartTimer();
    notifyListeners();
  }

  void _handleTimerElapsed() {
    nextImageNewTimer();
    onImageDurationElapse?.call;
    tryStartCountdown();
    notifyListeners();
  }

  void _setStateFilePickerOpen(bool active) {
    isPickerOpen = active;
    onFilePickerStateChange?.call();
  }
}
