import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
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
  int get currentImageIndex => circulator.getCurrentIndex();
  bool get allowCirculatorControl => hasFilesLoaded;
  void Function()? onImageChange;
  void Function()? onFilesChanged;

  bool _isCountdownEnabled = true;
  bool get isCountdownEnabled => _isCountdownEnabled;
  static const int countdownStart = 3;
  int countdownLeft = 0;
  bool get isCountingDown => countdownLeft > 0;
  void Function()? onCountdownStart;
  void Function()? onCountdownElapsed;
  void Function()? onCountdownUpdate;
  void Function()? onImageDurationElapse;

  void Function(int loadedCount, int skippedCount)? onFilesLoadedSuccess;

  FileData getCurrentImageData() {
    return fileList.get(circulator.getCurrentIndex());
  }

  void tryTogglePlayPauseTimer() {
    if (!allowTimerPlayPause) return;

    timerModel.playPauseToggleTimer();
  }

  void tryStartCountdown() {
    if (_isCountdownEnabled && timerModel.isRunning) {
      _countdownRoutine();
    } else {
      _countdownElapse();
    }
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

    timerModel.restartTimer();
    onImageChange?.call();
    _previousImage();
  }

  void nextImageNewTimer() {
    if (!allowCirculatorControl) return;

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

    isPickerOpen = true;
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Open images...',
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: FileList.allowedExtensions,
    );
    isPickerOpen = false;

    if (result == null) return;

    loadImages(result.paths);
  }

  void openFilePickerForFolder() async {
    if (isPickerOpen) return;

    isPickerOpen = true;
    var result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Open image folder...',
    );
    isPickerOpen = false;

    if (result == null) return;

    loadFolder(result);
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
    }
  }

  void loadImages(List<String?> filePaths) async {
    if (filePaths.isEmpty) return;

    await fileList.load(filePaths);

    final loadedCount = fileList.getCount();
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
}
