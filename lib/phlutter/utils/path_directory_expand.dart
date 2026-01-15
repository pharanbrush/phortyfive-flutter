import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:pfs2/phlutter/utils/windows_shortcut_files.dart'
    as windows_shortcuts;

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
  ValueNotifier<bool>? isLoadingExternalStatus,
  bool recursive = false,
  bool resolveShortcuts = false,
}) async {
  final expandedFilePaths = List<String>.empty(growable: true);
  Timer? timer;
  final foldersAdded = <String>{};

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

    Future<void> tryAddIfDirectory(String path, List<String> fileList) async {
      if (foldersAdded.contains(path)) return;

      final d = Directory(path);

      if (await d.exists()) {
        foldersAdded.add(path);
        final directoryFileList = d.list(recursive: recursive);
        await for (final f in directoryFileList) {
          if (isLoadingExternalStatus?.value == false) {
            throw Exception("Canceled from external status.");
          }

          fileList.add(f.path);
        }
      }
    }

    if (!Platform.isWindows) resolveShortcuts = false;

    for (final filePath in filePaths) {
      if (filePath == null) continue;
      if (isLoadingExternalStatus?.value == false) {
        throw Exception("Canceled from external status.");
      }

      if (await File(filePath).exists()) {
        bool wasLink = false;
        if (resolveShortcuts) {
          if (p.extension(filePath) == ".lnk") {
            wasLink = true;
            final resolvedShortcutPath =
                windows_shortcuts.resolveShortcut(filePath);

            if (resolvedShortcutPath != null) {
              if (await File(resolvedShortcutPath).exists()) {
                expandedFilePaths.add(filePath);
              } else if (await Directory(resolvedShortcutPath).exists()) {
                await tryAddIfDirectory(
                  resolvedShortcutPath,
                  expandedFilePaths,
                );
              }
            }
          }
        }

        if (!wasLink) {
          expandedFilePaths.add(filePath);
        }
      } else {
        await tryAddIfDirectory(
          filePath,
          expandedFilePaths,
        );
      }
    }

    onFileAdded?.call(expandedFilePaths.length);
  } finally {
    timer?.cancel();
  }

  return expandedFilePaths;
}
