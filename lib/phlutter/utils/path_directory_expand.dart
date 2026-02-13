import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
// import 'package:pfs2/main_screen/macos/macos_alias_files.dart'
//     as macos_alias_files;
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
  List<String>? ignoredSuffixes,
}) async {
  final outputFilePathList = <String>[];
  Timer? timer;

  Future<FileSystemEntity?> tryResolveShortcut(
    String possibleShortcutFile,
  ) async {
    if (!resolveShortcuts) return null;

    const windowsShortcutExtension = ".lnk";
    // const macosAliasDefaultSuffix = "alias";

    final String? resolvedShortcutPath;
    if (Platform.isWindows &&
        p.extension(possibleShortcutFile) == windowsShortcutExtension) {
      resolvedShortcutPath =
          windows_shortcuts.resolveShortcut(possibleShortcutFile);
      // } else if (Platform.isMacOS &&
      //     possibleShortcutFile.endsWith(macosAliasDefaultSuffix)) {
      //   resolvedShortcutPath =
      //       await macos_alias_files.resolveAlias(possibleShortcutFile);
    } else {
      resolvedShortcutPath = null;
    }

    if (resolvedShortcutPath == null) return null;

    switch (await FileSystemEntity.type(resolvedShortcutPath)) {
      case FileSystemEntityType.directory:
        final resolvedDirectory = Directory(resolvedShortcutPath);
        if (await resolvedDirectory.exists()) {
          debugPrint(
              "Found shortcut and resolved. Adding to stack: $resolvedShortcutPath");
          return resolvedDirectory;
        }
        break;

      case FileSystemEntityType.file:
        final resolvedFile = File(resolvedShortcutPath);
        if (await resolvedFile.exists()) {
          return resolvedFile;
        }
        break;

      default:
        break;
    }

    return null;
  }

  try {
    if (onFileAdded != null) {
      timer = Timer.periodic(
        const Duration(milliseconds: 17),
        (timer) {
          onFileAdded.call(outputFilePathList.length);
        },
      );
    }

    onFileAdded?.call(0);

    final alreadyProcessedDirectories = <String>{};
    final directoryTraversalStack = <Directory>[];

    for (final path in filePaths) {
      if (path == null) continue;

      final directory = Directory(path);
      if (await directory.exists()) {
        debugPrint("Adding $path to initial traversal");
        directoryTraversalStack.add(directory);
        continue;
      }

      final file = File(path);
      if (await file.exists()) {
        final possibleResolvedShortcut = await tryResolveShortcut(path);
        if (possibleResolvedShortcut == null) {
          debugPrint("Adding $path to initial file list");
          outputFilePathList.add(path);
        } else if (possibleResolvedShortcut is Directory) {
          debugPrint("Adding $path to initial traversal");
          directoryTraversalStack.add(possibleResolvedShortcut);
        } else if (possibleResolvedShortcut is File) {
          outputFilePathList.add(possibleResolvedShortcut.path);
        }
      }
    }

    while (directoryTraversalStack.isNotEmpty) {
      final currentDirectory = directoryTraversalStack.removeLast();
      final currentDirectoryPath = currentDirectory.path;

      if (alreadyProcessedDirectories.contains(currentDirectoryPath)) {
        //debugPrint("Avoiding duplicate load: $currentDirectoryPath");
        continue;
      }
      alreadyProcessedDirectories.add(currentDirectoryPath);

      bool ignoreFolder = false;
      if (ignoredSuffixes != null) {
        for (final suffix in ignoredSuffixes) {
          if (currentDirectoryPath.endsWith(suffix)) {
            debugPrint(
                "Ignoring '$currentDirectoryPath' because of suffix: $suffix");
            ignoreFolder = true;
            break;
          }
        }
      }
      if (ignoreFolder == true) continue;

      await for (final entity in currentDirectory.list()) {
        if (entity is Directory) {
          if (recursive) {
            // debugPrint("Adding found directory to traversal stack: ${entity.path}");
            directoryTraversalStack.add(entity);
          }
        } else if (entity is File) {
          final filePath = entity.path;

          if (isLoadingExternalStatus?.value == false) {
            throw Exception("Canceled from external status.");
          }

          final possibleResolvedShortcut = await tryResolveShortcut(filePath);
          if (possibleResolvedShortcut == null) {
            outputFilePathList.add(filePath);
          } else if (possibleResolvedShortcut is Directory) {
            directoryTraversalStack.add(possibleResolvedShortcut);
          } else if (possibleResolvedShortcut is File) {
            outputFilePathList.add(possibleResolvedShortcut.path);
          }
        }
      }
    }

    onFileAdded?.call(outputFilePathList.length);
  } finally {
    timer?.cancel();
  }

  return outputFilePathList;
}
