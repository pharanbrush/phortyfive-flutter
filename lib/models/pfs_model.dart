import 'package:file_picker/file_picker.dart';
//import 'package:flutter/foundation.dart';
import 'package:pfs2/core/circulator.dart';
import 'package:pfs2/core/file_list.dart';
import 'package:scoped_model/scoped_model.dart';

class PfsAppModel extends Model {
  final Circulator circulator = Circulator();
  final FileList fileList = FileList();

  bool get hasFilesLoaded => fileList.isPopulated();
  bool get isTimerRunning => false;

  List<String> allowedExtensions = [
    'jpg',
    'webp',
    'png',
    'jpeg',
    'jfif',
    'gif'
  ];

  double _progressPercent = 0.10;
  double get progressPercent => _progressPercent;

  FileData getCurrentImageData() {
    return fileList.get(circulator.getCurrentIndex());
  }

  void restart() {
    _progressPercent = 0;
    notifyListeners();
  }

  // void increment(double addedPercent) {
  //   _progressPercent += addedPercent;
  //   _progressPercent = clampDouble(_progressPercent, 0, 1);

  //   notifyListeners();
  // }

  void previousImage() {
    // reset timer
    circulator.movePrevious();
    notifyListeners();
  }

  void nextImage() {
    // reset timer
    circulator.moveNext();
    notifyListeners();
  }

  void openFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );

    if (result == null) return;

    fileList.load(result.paths);
    circulator.startNewOrder(fileList.getCount());
    notifyListeners();
  }
}
