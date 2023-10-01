import 'dart:io';

//import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

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

  FileData get(int index) {
    final count = getCount();
    if (count <= 0) return FileData.empty();
    if (index >= count) index = 0;
    return files[index];
  }

  void load(List<String?> filePaths) {
    files.clear();
    append(filePaths);
  }

  int append(List<String?> filePaths) {
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

  static FileData fileDataFromPath(String filePath) {
    if (filePath.isEmpty) return FileData('', '');
    return FileData(getFileName(filePath), filePath);
  }
}

class FileData {
  String fileName;
  String filePath;

  FileData(this.fileName, this.filePath);

  static empty() => FileData('', '');
}
