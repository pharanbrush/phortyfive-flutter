import 'dart:async';

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

  bool isPickingFiles = false;

  bool get hasFilesLoaded => fileList.isPopulated();
  bool get isTimerRunning => timer.isActive;
  int get currentTimerDuration => timer.duration.inSeconds;

  bool get allowTimerPlayPause => hasFilesLoaded;
  bool get allowCirculatorControl => hasFilesLoaded;

  void Function()? onTimerElapse;
  void Function()? onTimerReset;
  void Function()? onTimerPlayPause;
  void Function()? onTimerChangeSuccess;
  
  void Function()? onFilesChanged;
  
  void Function(int loadedCount, int skippedCount)? onFilesLoadedSuccess;

  Timer? ticker;

  double get progressPercent => timer.percentElapsed;

  FileData getCurrentImageData() {
    return fileList.get(circulator.getCurrentIndex());
  }

  void handleTimerElapsed() {
    nextImageNewTimer();
    onTimerElapse?.call();    
    notifyListeners();
  }

  void _handleTick() {
    if (timer.isActive) {
      timer.handleTick();
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

  void _previousImage() {
    if (!allowCirculatorControl) return;

    circulator.movePrevious();
    notifyListeners();
  }

  void previousImageNewTimer() {
    if (!allowCirculatorControl) return;

    timerRestartAndNotifyListeners();
    _previousImage();
  }

  void nextImageNewTimer() {
    if (!allowCirculatorControl) return;

    timerRestartAndNotifyListeners();
    _nextImage();
  }

  void _nextImage() {
    if (!allowCirculatorControl) return;

    circulator.moveNext();
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
    if (isPickingFiles) return;

    isPickingFiles = true;
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: FileList.allowedExtensions,
    );
    isPickingFiles = false;

    if (result == null) return;

    loadImages(result.paths);
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
