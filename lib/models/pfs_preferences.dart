import 'dart:io';

import 'package:pfs2/ui/themes/pfs_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

const themeKey = "theme";
const timerDurationKey = "timer_duration";
const soundKey = "sounds";
const recentFoldersKey = "recent_folders";

const int defaultTimerDuration = 45;

const maxRecentFoldersCount = 8;
const String includeSubfoldersSuffix = " ?s";

final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

// RECENT FOLDERS
Future<List<String>?> _getRecentFolderEntryList() async {
  final prefs = await _prefs;
  return prefs.getStringList(recentFoldersKey);
}

Future<Iterable<({String folderPath, bool includeSubfolders})>?>
    getRecentFolders() async {
  final recentFolderEntries = await _getRecentFolderEntryList();
  if (recentFolderEntries == null) return null;

  return recentFolderEntries.map((e) => decodeRecentFolderEntry(e));
}

Future<void> pushRecentFolder({
  required String folderPath,
  required bool includeSubfolders,
}) async {
  final folder = Directory(folderPath);
  if (await folder.exists()) {
    // Load old list from preferences.
    final folderList =
        await _getRecentFolderEntryList().onError((_, __) => <String>[]) ??
            <String>[];

    // Remove an existing item that matches the item added.
    folderList.removeWhere(
      (element) {
        final e = decodeRecentFolderEntry(element);
        return (e.folderPath == folderPath &&
            e.includeSubfolders == includeSubfolders);
      },
    );

    // Shorten if list is too long
    if (folderList.length > maxRecentFoldersCount) {
      folderList.removeAt(0);
    }

    // Add the item to the end
    folderList.add(encodeRecentFolderEntry(folderPath, includeSubfolders));

    // Push the list to preferences.
    final prefs = await _prefs;
    await prefs.setStringList(recentFoldersKey, folderList);
  }
}

Future<void> trimRecentFolders() async {
  final folderEntryList = await _getRecentFolderEntryList();
  if (folderEntryList == null) return;

  final entriesToRemove = <String>[];
  for (final folderEntry in folderEntryList) {
    final decodedEntry = decodeRecentFolderEntry(folderEntry);
    final folder = Directory(decodedEntry.folderPath);
    if (!(await folder.exists())) {
      entriesToRemove.add(folderEntry);
    }
  }

  for (final entryToRemove in entriesToRemove) {
    folderEntryList.remove(entryToRemove);
  }

  if (folderEntryList.length > maxRecentFoldersCount) {
    folderEntryList.removeRange(
      maxRecentFoldersCount,
      folderEntryList.length - 1,
    );
  }
}

Future<bool> clearRecentFolders() async {
  final prefs = await _prefs;
  final exists = prefs.containsKey(recentFoldersKey);
  if (!exists) return false;
  return await prefs.remove(recentFoldersKey);
}

String encodeRecentFolderEntry(String folderPath, bool includeSubfolders) {
  return "$folderPath${(includeSubfolders ? includeSubfoldersSuffix : "")}";
}

({String folderPath, bool includeSubfolders}) decodeRecentFolderEntry(
    String folderEntryString) {
  if (folderEntryString.endsWith(includeSubfoldersSuffix)) {
    return (
      folderPath: folderEntryString.substring(
        0,
        folderEntryString.length - includeSubfoldersSuffix.length,
      ),
      includeSubfolders: true
    );
  } else {
    return (folderPath: folderEntryString, includeSubfolders: false);
  }
}

// DURATION
bool isValidDuration(int? duration) {
  return (duration != null && duration > 0 && duration < 9999);
}

Future<int> getTimerDuration() async {
  final int loadedDuration = await _getInt(
    key: timerDurationKey,
    defaultValue: defaultTimerDuration,
  );
  final int cleanDuration = sanitizeDuration(loadedDuration);

  return cleanDuration;
}

int sanitizeDuration(int? duration) {
  if (duration == null || !isValidDuration(duration)) {
    return defaultTimerDuration;
  }

  return duration;
}

Future<void> setDuration(int durationToSave) async {
  if (!isValidDuration(durationToSave)) return;
  _setInt(
    value: durationToSave,
    key: timerDurationKey,
  );
}

// THEME
Future<String> getTheme() async {
  return await getString(
    key: themeKey,
    defaultValue: PfsTheme.defaultTheme,
  );
}

Future<void> setTheme(String themeToSave) async {
  await setString(
    value: themeToSave,
    key: themeKey,
  );
}

// SOUNDS
Future<bool> getSoundsEnabled() async {
  return await _getBool(
    key: soundKey,
    defaultValue: true,
  );
}

Future<void> setSoundsEnabled(bool soundsEnabled) async {
  _setBool(
    value: soundsEnabled,
    key: soundKey,
  );
}

// GENERAL
Future<String> getString({
  required String key,
  required String defaultValue,
}) async {
  final SharedPreferences prefs = await _prefs;

  // Separate nullable variable so it can be checked and logged.
  final String? loadedString = prefs.getString(key);
  return loadedString ?? defaultValue;
}

Future<void> setString({
  required String value,
  required String key,
}) async {
  final SharedPreferences prefs = await _prefs;
  prefs.setString(
    key,
    value,
  );
}

Future<int> _getInt({
  required String key,
  required int defaultValue,
}) async {
  final SharedPreferences prefs = await _prefs;

  // Separate nullable variable so it can be checked and logged.
  final int? loadedInt = prefs.getInt(key);
  return loadedInt ?? defaultValue;
}

Future<void> _setInt({
  required int value,
  required String key,
}) async {
  final SharedPreferences prefs = await _prefs;
  prefs.setInt(
    key,
    value,
  );
}

Future<bool> _getBool({
  required String key,
  required bool defaultValue,
}) async {
  final SharedPreferences prefs = await _prefs;

  // Separate nullable variable so it can be checked and logged.
  final bool? loadedBool = prefs.getBool(key);
  return loadedBool ?? defaultValue;
}

Future<void> _setBool({
  required bool value,
  required String key,
}) async {
  final SharedPreferences prefs = await _prefs;
  prefs.setBool(
    key,
    value,
  );
}
