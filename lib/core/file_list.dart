import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pfs2/core/file_data.dart';

class FileList {
  static const List<String> allowedExtensions = [
    'jpg',
    'webp',
    'png',
    'jpeg',
    'jfif',
    'gif'
  ];

  final files = List<FileData>.empty(growable: true);

  int getCount() => files.length;
  bool isPopulated() => getCount() > 0;
  FileData getFirst() => get(0);
  FileData getLast() => get(files.length - 1);

  FileData get(int index) {
    final count = getCount();
    if (count <= 0) return FileData.empty;
    if (index >= count) index = 0;
    return files[index];
  }

  Future load(List<String?> filePaths) async {
    files.clear();
    await append(filePaths);
  }

  Future<int> append(List<String?> filePaths) async {
    int filesAppendedCount = 0;
    for (var filePath in filePaths) {
      if (filePath == null) continue;
      if (!fileIsImage(filePath)) continue;

      files.add(fileDataFromPath(filePath));
      filesAppendedCount++;
    }

    return filesAppendedCount;
  }

  static bool fileIsImage(String filePath) {
    if (filePath.isEmpty) return false;

    final fileExtension = getFileExtension(filePath);
    final isImage = FileList.allowedExtensions.contains(fileExtension);
    return isImage;
  }

  static String getFileName(String filePath) {
    return File(filePath).uri.pathSegments.last;
  }

  static String getFileExtension(String filePath) {
    return p.extension(filePath).split('.').last;
  }
}
