import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:macos_secure_bookmarks/macos_secure_bookmarks.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pfs_preferences.dart' as pfs_preferences;

const String _recentFoldersKey = pfs_preferences.recentFoldersKey;
const int folderLimitCount = pfs_preferences.maxRecentFoldersCount;

final _secureBookmarks = SecureBookmarks();
String _lastAccessedFolder = "";

class RecentFolderEntry {
  static const divider = "|";

  static String serialize(String path, String bookmarkToken) =>
      "$path$divider$bookmarkToken";

  static ({String path, String bookmarkToken})? parse(String entry) {
    final parts = entry.split(divider);
    if (parts.length < 2) return null;

    return (path: parts[0], bookmarkToken: parts[1]);
  }

  static String? pathFrom(String entry) => parse(entry)?.path;

  static String itemMatchFor(String path) =>
      "$path${RecentFolderEntry.divider}";
}

Future<List<String>?> getRecentFoldersList() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getStringList(_recentFoldersKey);
}

Future bookmarkFolder(String folderPath) async {
  try {
    debugPrint("[bookmarkFolder] started");
    final folder = Directory(folderPath);
    if (!await folder.exists()) {
      throw Exception("Path $folderPath doesn't exist.");
    }

    final bookmarkToken = await _secureBookmarks.bookmark(folder);

    final prefs = await SharedPreferences.getInstance();
    final recentFoldersList = prefs.getStringList(_recentFoldersKey) ?? [];

    recentFoldersList.removeWhere(
      (item) => item.startsWith(RecentFolderEntry.itemMatchFor(folderPath)),
    );

    // Shorten if list is too long
    if (recentFoldersList.length > pfs_preferences.maxRecentFoldersCount) {
      recentFoldersList.removeAt(0);
    }

    // Combine path and token into a single string for storage (e.g., "path|token")
    final newItem = RecentFolderEntry.serialize(
      folderPath,
      bookmarkToken,
    );

    // Add the item to the end
    recentFoldersList.add(newItem);

    await prefs.setStringList(_recentFoldersKey, recentFoldersList);

    await closeAndReplaceLastAccessedFolder(newFolderPath: folderPath);
  } catch (e) {
    debugPrint("[x] Failed to bookmark folder: $folderPath \n $e");
  }
}

Future<void> accessRecentFolder(
  String recentFolderEntry,
  Future Function(Directory) onReady,
) async {
  debugPrint("[accessRecentFolder] started");

  final entry = RecentFolderEntry.parse(recentFolderEntry);
  if (entry == null) return;

  try {
    // Resolve the token back into a system File/Directory target
    final resolvedDirectory = await _secureBookmarks.resolveBookmark(
      entry.bookmarkToken,
      isDirectory: true,
    );

    // debugPrint("accessRecentFolder: bookmark resolved");

    // CRITICAL: Gain temporary access through the sandbox hole
    await _secureBookmarks.startAccessingSecurityScopedResource(
      resolvedDirectory,
    );

    // debugPrint("accessRecentFolder: security scoped resource access started");
    // debugPrint("accessRecentFolder: now calling onReady");
    await onReady(resolvedDirectory as Directory);

    await closeAndReplaceLastAccessedFolder(
      newFolderPath: resolvedDirectory.path,
    );
  } catch (e) {
    debugPrint("[x] Error accessing secure recent folder: $e");
  }
}

/// Call this function when accessing a new folder.
/// This is to clean up sandbox-mediated file access.
///
/// From Apple docs:
/// If you fail to relinquish your access to file-system resources when you no longer need them, your app leaks kernel resources.
/// If sufficient kernel resources leak, your app loses its ability to add file-system locations to its sandbox, such as with Powerbox or security-scoped bookmarks, until relaunched.
Future<void> closeAndReplaceLastAccessedFolder({
  required String newFolderPath,
}) async {
  Future<void> stopAccessingFolder(String folderPath) async {
    if (folderPath.isEmpty) return;
    await _secureBookmarks.stopAccessingSecurityScopedResource(
      Directory(folderPath),
    );
  }

  debugPrint("replaceAccessLastFolder: old path: $_lastAccessedFolder");
  if (newFolderPath.isEmpty) return;

  final lastAccessedFolder = _lastAccessedFolder;
  if (lastAccessedFolder == newFolderPath) return;
  await stopAccessingFolder(lastAccessedFolder);

  // Now remember a new lastAccessedFolder
  _lastAccessedFolder = newFolderPath;
}
