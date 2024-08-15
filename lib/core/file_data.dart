import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';

class FileData {
  final String filePath;

  const FileData(this.filePath);

  String get fileName => path.basename(filePath);
  String get fileFolder => File(filePath).parent.path;
  String get parentFolderName => path.basename(File(filePath).parent.path);

  static const empty = FileData('');
}

FileData fileDataFromPath(String filePath) {
  if (filePath.isEmpty) return FileData.empty;
  return FileData(filePath);
}

void revealInExplorer(FileData fileData) async {
  if (Platform.isWindows) {
    final windowsFilePath = fileData.filePath.replaceAll('/', '\\');
    await Process.start('explorer', ['/select,', windowsFilePath]);
  } else {
    Uri fileFolder = Uri.file(fileData.fileFolder);
    await launchUrl(fileFolder);
  }
}
