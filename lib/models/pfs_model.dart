import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:pfs2/core/circulator.dart';
import 'package:pfs2/core/file_list.dart';
import 'package:pfs2/core/phtimer.dart';
import 'package:scoped_model/scoped_model.dart';

class PfsAppModel extends Model {
  static const bool startTimerOnFirst = true;

  final Circulator circulator = Circulator();
  final FileList fileList = FileList();
  final Phtimer timer = Phtimer();  

  bool isPickerOpen = false;
  bool _isCountdownEnabled = true;
  
  bool get isCountdownEnabled => _isCountdownEnabled;

  int lastIncrement = 1;

  bool get hasFilesLoaded => fileList.isPopulated();
  bool get isTimerRunning => timer.isActive;
  int get currentTimerDuration => timer.duration.inSeconds;

  bool get allowTimerPlayPause => hasFilesLoaded;
  bool get allowCirculatorControl => hasFilesLoaded;

  static const int countdownStart = 3;
  int countdownLeft = 0;

  bool get isCountingDown => countdownLeft > 0;

  int get currentImageIndex => circulator.getCurrentIndex();

  void Function()? onTimerElapse;
  void Function()? onTimerReset;
  void Function()? onTimerPlayPause;
  void Function()? onTimerChangeSuccess;

  void Function()? onImageChange;

  void Function()? onFilesChanged;
  void Function()? onCountdownStart;
  void Function()? onCountdownElapsed;
  void Function()? onCountdownUpdate;

  void Function(int loadedCount, int skippedCount)? onFilesLoadedSuccess;

  Timer? ticker;

  double get progressPercent => timer.percentElapsed;

  static ScopedModelDescendant<PfsAppModel> scope(
          ScopedModelDescendantBuilder<PfsAppModel> builder) =>
      ScopedModelDescendant<PfsAppModel>(builder: builder);

  FileData getCurrentImageData() {
    return fileList.get(circulator.getCurrentIndex());
  }

  void startCountdown() {
    if (_isCountdownEnabled) {
      _countdownRoutine();
    } else {
      _countdownElapse();
    }
  }
  
  void setCountdownActive(bool active) {
    _isCountdownEnabled = active;
  }

  void _countdownRoutine() async {
    countdownLeft = countdownStart;
    onCountdownStart?.call();

    for (int i = 30; i > 0; i++) {
      await Future.delayed(const Duration(seconds: 1));
      countdownLeft--;
      onCountdownUpdate?.call();
      notifyListeners();
      if (countdownLeft <= 0) break;
    }
    
    timer.restart();
    _countdownElapse();
  }

  void _countdownElapse() {
    onCountdownElapsed?.call();
  }

  void handleTimerElapsed() {
    nextImageNewTimer();
    onTimerElapse?.call();
    startCountdown();
    notifyListeners();
  }

  void _handleTick() {
    if (timer.isActive) {
      if (!isCountingDown) {
        timer.handleTick();
      }

      notifyListeners();
    }
  }

  void playPauseToggleTimer() {
    setTimerActive(!timer.isActive);
  }

  void setTimerActive(bool active) {
    if (!allowTimerPlayPause) return;

    timer.setActive(active);
    onTimerPlayPause?.call();
    notifyListeners();
  }

  void timerRestartAndNotifyListeners() {
    timer.restart();
    onTimerReset?.call();
    notifyListeners();
  }

  void previousImageNewTimer() {
    if (!allowCirculatorControl) return;

    timerRestartAndNotifyListeners();
    onImageChange?.call();
    _previousImage();
  }

  void nextImageNewTimer() {
    if (!allowCirculatorControl) return;

    timerRestartAndNotifyListeners();
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

  void trySetTimerSecondsInput(String secondsString) {
    int? seconds = int.tryParse(secondsString);
    if (seconds != null) {
      setTimerSeconds(seconds);
    }
  }

  void setTimerSeconds(int seconds) {
    timer.setDuration(Duration(seconds: seconds));
    onTimerChangeSuccess?.call();
    timerRestartAndNotifyListeners();
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

  void loadImages(List<String?> filePaths) {
    if (filePaths.isEmpty) return;

    fileList.load(filePaths);

    final int loadedCount = fileList.getCount();
    circulator.startNewOrder(loadedCount);

    onFilesChanged?.call();
    onFilesLoadedSuccess?.call(loadedCount, loadedCount - filePaths.length);
    _tryInitializeTimer();
    timerRestartAndNotifyListeners();
  }

  void _tryInitializeTimer() {
    ticker ??= Timer.periodic(Phtimer.tickInterval, (timer) => _handleTick());

    if (timer.onElapse == null) {
      timer.onElapse = () => handleTimerElapsed();
      if (startTimerOnFirst) {
        timer.setActive(true);
      }
    }
  }
}
