import 'package:path/path.dart' as p;

extension ShortenExtension on String {
  String shortenWithEllipsis(int maxLength) {
    if (length <= maxLength) {
      return this;
    }
    return "${substring(0, maxLength)}...";
  }
}

String shortenFolderPath(String folderPath) {
  final separator = p.separator;
  final split = folderPath.split(separator);
  final splitLength = split.length;
  if (splitLength <= 4) {
    return folderPath;
  }

  final candidateFolderPath =
      "${split.first}$separator...$separator${split[splitLength - 2]}$separator${split.last}";
  if (candidateFolderPath.length > 50) {
    return "${split.first}$separator...$separator${split.last}";
  }

  return candidateFolderPath;
}

String shortenFilePath(String folderPath) {
  final separator = p.separator;
  final split = folderPath.split(separator);
  final splitLength = split.length;
  if (splitLength <= 4) {
    return folderPath;
  }

  final candidateFolderPath =
      "${split.first}$separator...$separator${split[splitLength - 2]}$separator${split.last}";
  if (candidateFolderPath.length > 50) {
    return "${split.first}$separator...$separator${split.last}";
  }

  return candidateFolderPath;
}
