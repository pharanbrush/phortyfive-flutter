import 'dart:io';

class FileList {
  final files = List<FileData>.empty(growable: true);

  int getCount() => files.length;
  bool isPopulated() => getCount() > 0;
  String getFirst() => get(0);

  String get(int index) {
    final count = getCount();
    if (count <= 0) return '';
    if (index >= count) index = 0;
    return files[index].filePath;
  }

  void load(List<String?> filePaths) {
    files.clear();
    append(filePaths);
  }

  int append(List<String?> filePaths) {
    int filesAppendedCount = 0;
    for (var filePath in filePaths) {
      if (filePath == null) continue;
      files.add(FileData(
        getFileName(filePath),
        filePath,
      ));
      filesAppendedCount++;
    }
    return filesAppendedCount;
  }

  String getFileName(String filePath) {
    return File(filePath).uri.pathSegments.last;
  }
}

class FileData {
  String fileName;
  String filePath;

  FileData(this.fileName, this.filePath);
}
