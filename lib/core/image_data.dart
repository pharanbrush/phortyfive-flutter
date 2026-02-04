import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:pfs2/phlutter/utils/windows_shortcut_files.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

abstract class ImageData {
  const ImageData();

  static const ImageData invalid = InvalidImageData();
}

class InvalidImageData extends ImageData {
  const InvalidImageData();
}

class ImageFileData extends ImageData {
  final String filePath;

  const ImageFileData(this.filePath);

  String get fileName => path.basename(filePath);
  String get fileFolder => File(filePath).parent.path;
  String get parentFolderName => path.basename(File(filePath).parent.path);

  static const empty = ImageFileData('');
}

const linksFilename = "links.txt";
const linksShortcut = "$linksFilename - Shortcut.lnk";

Future<Iterable<String>?> tryGetUrls(ImageData imageData) async {
  if (imageData is ImageFileData) {
    final parentFolder = imageData.fileFolder;
    final urlsFilePath = "$parentFolder${Platform.pathSeparator}$linksFilename";
    File urlsFile = File(urlsFilePath);
    bool fileExists = await urlsFile.exists();

    if (!fileExists) {
      final urlShortcutPath =
          "$parentFolder${Platform.pathSeparator}$linksShortcut";
      urlsFile = File(urlShortcutPath);
      if (await urlsFile.exists()) {
        final resolvedUrlPath = resolveShortcut(urlShortcutPath);
        if (resolvedUrlPath != null &&
            resolvedUrlPath.endsWith(linksFilename)) {
          urlsFile = File(resolvedUrlPath);
          fileExists = await urlsFile.exists();
        }
      }
    }

    if (!fileExists) throw FileSystemException("File not found");

    final outputLines = <String>[];
    final lines = await urlsFile.readAsLines();
    for (final line in lines) {
      if (line.isEmpty) continue;
      final canLaunch = await url_launcher.canLaunchUrl(Uri.parse(line));
      if (canLaunch) {
        outputLines.add(line);
      }
    }

    if (outputLines.isNotEmpty) return outputLines;

    throw Exception("File exists but did not contain valid URLs.");
  }

  throw UnsupportedError("Image is not a file from a folder.");
}

ImageData imageDataFromPath(String filePath) {
  if (filePath.isEmpty) return ImageFileData.empty;
  return ImageFileData(filePath);
}

void revealImageFileDataInExplorer(ImageFileData fileData) {
  revealPathInExplorer(fileData.filePath);
}

void revealPathInExplorer(String? filePath) async {
  if (filePath == null) return;

  if (Platform.isWindows) {
    final windowsFilePath = filePath.replaceAll('/', '\\');
    await Process.start('explorer', ['/select,', windowsFilePath]);
  } else {
    final fileFolder = Uri.file(File(filePath).parent.path);
    await url_launcher.launchUrl(fileFolder);
  }
}
