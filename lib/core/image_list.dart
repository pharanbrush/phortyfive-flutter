import 'dart:io';
import 'dart:math' as math;

import 'package:path/path.dart' as p;
import 'package:pfs2/core/image_memory_data.dart';
import 'package:pfs2/core/image_data.dart';

enum ImageLoadResult {
  success,
  empty,
}

class ImageList {
  static const List<String> allowedExtensions = [
    "jpg",
    "webp",
    "png",
    "jpeg",
    "jfif",
    "gif",
    "avif",
  ];

  final items = <ImageData>[];

  int get count => items.length;
  bool get isPopulated => items.isNotEmpty;
  ImageData get first => items.first;
  ImageData get last => items.last;

  ({int first, int last})? getIndexRange() {
    if (items.isEmpty) return null;

    return (first: 0, last: items.length - 1);
  }

  ImageData get(int index) {
    final count = this.count;
    if (count <= 0) return ImageData.invalid;
    if (index >= count) index = 0;
    return items[index];
  }

  Future<ImageLoadResult> loadFiles(List<String?> filePaths) async {
    final newItems = <ImageData>[];
    await appendFiles(filePaths, imageDataList: newItems);
    if (newItems.isEmpty) {
      return ImageLoadResult.empty;
    }

    items.clear();
    items.addAll(newItems);
    return ImageLoadResult.success;
  }

  Future<int> appendFiles(
    List<String?> filePaths, {
    required List<ImageData> imageDataList,
  }) async {
    int imagesAppendedCount = 0;
    for (final filePath in filePaths) {
      if (filePath == null) continue;
      if (!fileIsImage(filePath)) {
        //debugPrint("$filePath skipped");
        continue;
      }
      imagesAppendedCount++;
      imageDataList.add(imageDataFromPath(filePath));
    }

    return imagesAppendedCount;
  }

  Future<ImageLoadResult> loadImages(List<ImageData?> images) async {
    final newItems = <ImageData>[];
    await appendImages(images, imageDataList: newItems);
    if (newItems.isEmpty) {
      return ImageLoadResult.empty;
    }

    items.clear();
    items.addAll(newItems);
    return ImageLoadResult.success;
  }

  Future loadImage(ImageData? image) async {
    if (image == null) return;

    items.clear();
    items.add(image);
  }

  Future<int> appendImages(
    List<ImageData?> images, {
    required List<ImageData> imageDataList,
  }) async {
    int imagesAppendedCount = 0;
    for (final image in images) {
      if (image is ImageFileData) {
        if (image.filePath.isEmpty) continue;
        imageDataList.add(image);
        imagesAppendedCount++;
      } else if (image is ImageMemoryData) {
        imageDataList.add(image);
        imagesAppendedCount++;
      }
    }

    return imagesAppendedCount;
  }

  static bool fileIsImage(String filePath) {
    if (filePath.isEmpty) return false;

    final fileExtension = p.extension(filePath).replaceFirst(".", "");
    final isImage = ImageList.allowedExtensions.contains(fileExtension);
    return isImage;
  }
}

Future<String?> getRandomFolderFrom(String parentFolderPath) async {
  final parentDirectory = Directory(parentFolderPath);
  if (!await parentDirectory.exists()) return null;

  // Build the directory list to randomly pick from.
  final directoryList = <Directory>[];
  final listStream = parentDirectory.list();
  await for (final entity in listStream) {
    if (entity is Directory) {
      directoryList.add(entity);
    }
  }

  // Attempt to find a random non-empty folder. Return the first one.
  const maxAttempts = 6;
  final random = math.Random();
  for (int i = 0; i < maxAttempts; i++) {
    final index = random.nextInt(directoryList.length);
    final directoryCandidate = directoryList[index];
    await for (final possibleFile in directoryCandidate.list()) {
      if (possibleFile is File && ImageList.fileIsImage(possibleFile.path)) {
        return directoryCandidate.path;
      }
    }
  }

  return null;
}
