import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';

abstract class ImageData {
  const ImageData();

  static const ImageData invalid = InvalidImageData();
}

class InvalidImageData extends ImageData {
  const InvalidImageData();
}

class ImageFileData extends ImageData {
  final String filePath;

  const ImageFileData(this.filePath);

  String get fileName => path.basename(filePath);
  String get fileFolder => File(filePath).parent.path;
  String get parentFolderName => path.basename(File(filePath).parent.path);

  static const empty = ImageFileData('');
}

ImageData imageDataFromPath(String filePath) {
  if (filePath.isEmpty) return ImageFileData.empty;
  return ImageFileData(filePath);
}

void revealImageFileDataInExplorer(ImageFileData fileData) {
  revealPathInExplorer(fileData.filePath);
}

void revealPathInExplorer(String? filePath) async {
  if (filePath == null) return;

  if (Platform.isWindows) {
    final windowsFilePath = filePath.replaceAll('/', '\\');
    await Process.start('explorer', ['/select,', windowsFilePath]);
  } else {
    final fileFolder = Uri.file(File(filePath).parent.path);
    await launchUrl(fileFolder);
  }
}
