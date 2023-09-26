import 'dart:io';

class FileList {
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
      files.add(fileDataFromPath(filePath));
      filesAppendedCount++;
    }
    return filesAppendedCount;
  }

  static String getFileName(String filePath) {
    return File(filePath).uri.pathSegments.last;
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
