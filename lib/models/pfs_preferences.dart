import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

const _themeKey = "theme";
const _timerDurationKey = "timer_duration";
const _soundKey = "sounds";
const recentFoldersKey = "recent_folders";

const int defaultTimerDuration = 45;

const maxRecentFoldersCount = 8;
const String includeSubfoldersSuffix = " ?s";

final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

final soundPreference = BoolPreference(_soundKey);
final themePreference = StringPreference(_themeKey);
final timerDurationPreference = IntPreference(
  _timerDurationKey,
  sanitize: (duration) {
    bool isValidDuration(int? duration) {
      return (duration != null && duration > 0 && duration < 9999);
    }

    if (!isValidDuration(duration)) {
      return defaultTimerDuration;
    }

    return duration;
  },
);

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

class Preference {
  Preference(this.preferenceKey);
  final String preferenceKey;
}

class BoolPreference extends Preference {
  BoolPreference(super.preferenceKey);

  Future<bool> getValue({required bool defaultValue}) async {
    final SharedPreferences prefs = await _prefs;

    // Separate nullable variable so it can be checked and logged.
    final bool? loadedBool = prefs.getBool(preferenceKey);
    return loadedBool ?? defaultValue;
  }

  Future<void> setValue(bool value) async {
    final SharedPreferences prefs = await _prefs;
    prefs.setBool(
      preferenceKey,
      value,
    );
  }
}

class Vector2IntPreference extends Preference {
  Vector2IntPreference(super.preferenceKey);
  static const xSuffix = "_x";
  static const ySuffix = "_y";

  Future<(int x, int y)> getValue({
    required (int x, int y) defaultValue,
  }) async {
    final x = await _getInt(
        key: preferenceKey + xSuffix, defaultValue: defaultValue.$1);
    final y = await _getInt(
        key: preferenceKey + ySuffix, defaultValue: defaultValue.$2);

    return (x, y);
  }

  Future<void> setValue((int x, int y) value) async {
    final setX = _setInt(
      value: value.$1,
      key: preferenceKey + xSuffix,
    );

    final setY = _setInt(
      value: value.$2,
      key: preferenceKey + ySuffix,
    );

    await Future.wait([setX, setY]);
  }
}

class IntPreference extends Preference {
  IntPreference(
    super.preferenceKey, {
    this.sanitize,
  });

  int Function(int)? sanitize;

  Future<int> getValue({required int defaultValue}) async {
    final loadedInt = await _getInt(
      key: preferenceKey,
      defaultValue: defaultValue,
    );

    final sanitizeFunction = sanitize;
    return sanitizeFunction == null
        ? loadedInt
        : sanitizeFunction.call(loadedInt);
  }

  Future<void> setValue(int value) {
    final sanitizeFunction = sanitize;
    final sanitizedValue =
        sanitizeFunction == null ? value : sanitizeFunction.call(value);

    return _setInt(
      value: sanitizedValue,
      key: preferenceKey,
    );
  }
}

class StringPreference extends Preference {
  StringPreference(super.preferenceKey);

  Future<String> getValue({required String defaultValue}) {
    return getString(
      key: preferenceKey,
      defaultValue: defaultValue,
    );
  }

  Future<void> setValue(String value) {
    return setString(
      value: value,
      key: preferenceKey,
    );
  }
}
