import 'dart:async';
import 'dart:io';

// Matches flutter/foundation.dart
typedef ValueChanged<T> = void Function(T value);

bool pathIsDirectory(String fullPath) {
  if (fullPath.isEmpty) return false;

  final possibleDirectory = Directory(fullPath);
  final exists = possibleDirectory.existsSync();
  return exists;
}

Future<List<String>> getExpandedList(
  List<String?> filePaths, {
  ValueChanged<int>? onFileAdded,
  bool recursive = false,
}) async {
  final expandedFilePaths = List<String>.empty(growable: true);
  Timer? timer;

  try {
    if (onFileAdded != null) {
      timer = Timer.periodic(
        const Duration(milliseconds: 17),
        (timer) {
          onFileAdded.call(expandedFilePaths.length);
        },
      );
    }

    onFileAdded?.call(0);

    for (final filePath in filePaths) {
      if (filePath == null) continue;

      final file = File(filePath);
      if (await file.exists()) {
        expandedFilePaths.add(filePath);
      } else {
        final d = Directory(filePath);
        if (await d.exists()) {
          final directoryFileList = d.list(recursive: recursive);
          await for (final f in directoryFileList) {
            expandedFilePaths.add(f.path);
          }
        }
      }
    }

    onFileAdded?.call(expandedFilePaths.length);
  } finally {
    timer?.cancel();
  }

  return expandedFilePaths;
}
