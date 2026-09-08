import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;
import 'package:win32/win32.dart';
import 'dart:ffi';

const windowsShortcutExtension = ".lnk";

bool fileIsShortcut(String possibleShortcutFilePath) {
  return Platform.isWindows &&
      p.extension(possibleShortcutFilePath) == windowsShortcutExtension;
}

// Edited version of recommendation from https://github.com/halildurmus/win32/discussions/965
String? resolveShortcut(String shortcutPath) {
  if (!Platform.isWindows) return null;

  String? path;
  final lpPath = wsalloc(MAX_PATH + 1);

  // String? description;
  // final lpDescription = wsalloc(MAX_PATH + 1);

  try {
    final shellLink = ShellLink.createInstance();
    final persistFile = IPersistFile.from(shellLink);
    final shortcutPathNative = shortcutPath.toNativeUtf16();

    if (persistFile.load(shortcutPathNative, 0) == 0) {
      const pathFormat = 0x0;

      if (shellLink.getPath(lpPath, MAX_PATH + 1, nullptr, pathFormat) == 0) {
        path = lpPath.toDartString();
        //debugPrint("read: $path");
      }

      // if (shellLink.getDescription(lpDescription, MAX_PATH + 1) == 0) {
      //   description = lpDescription.toDartString();
      //   debugPrint("loaded $description");
      // }
    }
  } finally {
    free(lpPath);
    // free(lpDescription);
  }

  return path;
}
