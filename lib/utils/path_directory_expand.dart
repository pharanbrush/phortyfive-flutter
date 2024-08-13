import 'dart:io';

bool pathIsDirectory(String fullPath) {
  if (fullPath.isEmpty) return false;

  final possibleDirectory = Directory(fullPath);
  final exists = possibleDirectory.existsSync();
  return exists;
}

Future<List<String>> getExpandedList(List<String?> filePaths) async {
  final expandedFilePaths = List<String>.empty(growable: true);
  for (final filePath in filePaths) {
    if (filePath == null) continue;

    final file = File(filePath);
    if (await file.exists()) {
      expandedFilePaths.add(filePath);
    } else {
      final d = Directory(filePath);
      if (await d.exists()) {
        final directoryFileList = d.list(recursive: false);
        await for (final f in directoryFileList) {
          expandedFilePaths.add(f.path);
        }
      }
    }
  }

  return expandedFilePaths;
}
