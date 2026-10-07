import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:macos_secure_bookmarks/macos_secure_bookmarks.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pfs_preferences.dart' as pfs_preferences;

const String _recentFoldersKey = pfs_preferences.recentFoldersKey;
const int folderLimitCount = 10;
const _divider = "|";

Future bookmarkFolder(String folderPath) async {
  try {
    debugPrint("[bookmarkFolder] started");
    final folder = Directory(folderPath);
    if (!await folder.exists()) return;

    final secureBookmarks = SecureBookmarks();
    final bookmarkToken = await secureBookmarks.bookmark(folder);

    final prefs = await SharedPreferences.getInstance();
    final recentFoldersList = prefs.getStringList(_recentFoldersKey) ?? [];

    recentFoldersList.removeWhere(
      (item) => item.startsWith("$folderPath$_divider"),
    );

    // Shorten if list is too long
    if (recentFoldersList.length > pfs_preferences.maxRecentFoldersCount) {
      recentFoldersList.removeAt(0);
    }

    // Combine path and token into a single string for storage (e.g., "path|token")
    final newItem = "$folderPath$_divider$bookmarkToken";
    // Add the item to the end
    recentFoldersList.add(newItem);

    await prefs.setStringList(_recentFoldersKey, recentFoldersList);

    await replaceAccessLastFolder(folderPath);
  } catch (e) {
    debugPrint("[x] Failed to bookmark folder: $folderPath \n $e");
  }
}

({String path, String bookmarkToken})? parseEntry(String recentEntry) {
  final parts = recentEntry.split(_divider);
  if (parts.length < 2) return null;

  return (path: parts[0], bookmarkToken: parts[1]);
}

String? getPathFromEntry(String recentEntry) => parseEntry(recentEntry)?.path;

String _lastAccessedFolder = "";

Future<void> stopAccessingFolder(String folderPath) async {
  if (folderPath.isEmpty) return;
  // debugPrint("stopping access of previousFolder");
  final secureBookmarks = SecureBookmarks();
  await secureBookmarks.stopAccessingSecurityScopedResource(
    Directory(folderPath),
  );
}

Future<void> replaceAccessLastFolder(String newFolderPath) async {
  // Is this necessary? What type of leak does this really cause?
  // debugPrint("replaceAccessLastFolder: old path: $_lastAccessedFolder");
  if (_lastAccessedFolder == newFolderPath) return;
  await stopAccessingFolder(_lastAccessedFolder);
  _lastAccessedFolder = newFolderPath;
  // debugPrint("replaceAccessLastFolder: new path: $newFolderPath");
}

Future<void> accessRecentFolder(
  String storedItem,
  Future Function(Directory) onReady,
) async {
  debugPrint("[accessRecentFolder] started");

  final entry = parseEntry(storedItem);
  if (entry == null) return;

  final secureBookmarks = SecureBookmarks();

  try {
    // Resolve the token back into a system File/Directory target
    final resolvedDirectory = await secureBookmarks.resolveBookmark(
      entry.bookmarkToken,
      isDirectory: true,
    );

    // debugPrint("accessRecentFolder: bookmark resolved");

    // CRITICAL: Gain temporary access through the sandbox hole
    await secureBookmarks.startAccessingSecurityScopedResource(
      resolvedDirectory,
    );

    // debugPrint("accessRecentFolder: security scoped resource access started");
    // debugPrint("accessRecentFolder: now calling onReady");
    await onReady(resolvedDirectory as Directory);

    await replaceAccessLastFolder(resolvedDirectory.path);
  } catch (e) {
    debugPrint("[x] Error accessing secure recent folder: $e");
  }
}

Future<List<String>?> getRecentFoldersList() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getStringList(_recentFoldersKey);
}
