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
    final folder = Directory(folderPath);
    if (!await folder.exists()) return;

    final secureBookmarks = SecureBookmarks();
    final bookmarkToken = await secureBookmarks.bookmark(
      folder,
    );

    final prefs = await SharedPreferences.getInstance();
    List<String> currentBookmarks =
        prefs.getStringList(_recentFoldersKey) ?? [];

    // Remove if it already exists to prevent duplicates, then insert at the top
    currentBookmarks.removeWhere((item) => item.contains(folderPath));

    // Combine path and token into a single string for storage (e.g., "path|token")
    currentBookmarks.insert(0, "$folderPath$_divider$bookmarkToken");

    // Limit recent folders to 10
    if (currentBookmarks.length > folderLimitCount) {
      currentBookmarks = currentBookmarks.sublist(0, folderLimitCount);
    }

    await prefs.setStringList(_recentFoldersKey, currentBookmarks);
  } catch (e) {
    debugPrint("[x] Failed to bookmark folder: $folderPath");
  }
}

({String bookmarkToken, String path})? parseEntry(String recentEntry) {
  final parts = recentEntry.split(_divider);
  if (parts.length < 2) return null;

  final folderPath = parts[0];
  final bookmarkToken = parts[1];
  return (path: folderPath, bookmarkToken: bookmarkToken);
}

String? getPathFromEntry(String recentEntry) => parseEntry(recentEntry)?.path;

Future<void> accessRecentFolder(
  String storedItem,
  Function(Directory) onReady,
) async {
  final entry = parseEntry(storedItem);
  if (entry == null) return;

  final secureBookmarks = SecureBookmarks();

  try {
    // Resolve the token back into a system File/Directory target
    final resolvedDirectory = await secureBookmarks.resolveBookmark(
      entry.bookmarkToken,
      isDirectory: true,
    );

    // CRITICAL: Gain temporary access through the sandbox hole
    await secureBookmarks.startAccessingSecurityScopedResource(
      resolvedDirectory,
    );

    await onReady(resolvedDirectory as Directory);
  } catch (e) {
    debugPrint("[x] Error accessing secure recent folder: $e");
  } finally {
    // CRITICAL: Always release the system lock when done to avoid memory leaks
    await secureBookmarks.stopAccessingSecurityScopedResource(File(entry.path));
  }
}

Future<List<String>?> getRecentFoldersList() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getStringList(_recentFoldersKey);
}
