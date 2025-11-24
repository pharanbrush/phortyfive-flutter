import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pfs2/core/image_memory_data.dart';
import 'package:pfs2/core/image_data.dart';

class ImageList {
  static const List<String> allowedExtensions = [
    'jpg',
    'webp',
    'png',
    'jpeg',
    'jfif',
    'gif'
  ];

  final items = List<ImageData>.empty(growable: true);

  int getCount() => items.length;
  bool isPopulated() => items.isNotEmpty;
  ImageData getFirst() => get(0);
  ImageData getLast() => get(items.length - 1);

  ({int first, int last})? getIndexRange() {
    if (items.isEmpty) return null;

    return (first: 0, last: items.length - 1);
  }

  ImageData get(int index) {
    final count = getCount();
    if (count <= 0) return ImageData.invalid;
    if (index >= count) index = 0;
    return items[index];
  }

  Future loadFiles(List<String?> filePaths) async {
    items.clear();
    await appendFiles(filePaths);
  }

  Future<int> appendFiles(List<String?> filePaths) async {
    int filesAppendedCount = 0;
    for (final filePath in filePaths) {
      if (filePath == null) continue;
      if (!fileIsImage(filePath)) continue;

      items.add(imageDataFromPath(filePath));
      filesAppendedCount++;
    }

    return filesAppendedCount;
  }

  Future loadImages(List<ImageData?> images) async {
    items.clear();
    appendImages(images);
  }

  Future loadImage(ImageData? image) async {
    if (image == null) return;

    items.clear();
    items.add(image);
  }

  Future<int> appendImages(List<ImageData?> images) async {
    int imagesAppendedCount = 0;
    for (final image in images) {
      if (image is ImageFileData) {
        if (image.filePath.isEmpty) continue;
        items.add(image);
        imagesAppendedCount++;
      } else if (image is ImageMemoryData) {
        items.add(image);
        imagesAppendedCount++;
      }
    }

    return imagesAppendedCount;
  }

  static bool fileIsImage(String filePath) {
    if (filePath.isEmpty) return false;

    final fileExtension = getFileExtension(filePath);
    final isImage = ImageList.allowedExtensions.contains(fileExtension);
    return isImage;
  }
}

String getFileName(String filePath) {
  return File(filePath).uri.pathSegments.last;
}

String getFileExtension(String filePath) {
  return p.extension(filePath).split('.').last;
}
