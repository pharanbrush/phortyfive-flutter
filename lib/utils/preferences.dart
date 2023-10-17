import 'package:pfs2/ui/themes/pfs_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  static const String themeKey = 'theme';
  static const String timerDurationKey = 'timer_duration';

  static const int defaultTimerDuration = 45;

  static final Future<SharedPreferences> _prefs =
      SharedPreferences.getInstance();

  // DURATION
  static bool isValidDuration(int? duration) {
    return (duration != null && duration > 0 && duration < 9999);
  }

  static Future<int> getTimerDuration() async {
    final int loadedDuration = await getInt(
      key: Preferences.timerDurationKey,
      defaultValue: Preferences.defaultTimerDuration,
    );
    final int cleanDuration = sanitizeDuration(loadedDuration);

    return cleanDuration;
  }

  static int sanitizeDuration(int? duration) {
    if (duration == null || !isValidDuration(duration)) {
      return defaultTimerDuration;
    }

    return duration;
  }

  static Future<void> setDuration(int durationToSave) async {
    if (!isValidDuration(durationToSave)) return;
    Preferences.setInt(
      value: durationToSave,
      key: timerDurationKey,
    );
  }

  // THEME
  static Future<String> getTheme() async {
    return await Preferences.getString(
      key: Preferences.themeKey,
      defaultValue: PfsTheme.defaultTheme,
    );
  }

  static Future<void> setTheme(String themeToSave) async {
    await Preferences.setString(
      value: themeToSave,
      key: Preferences.themeKey,
    );
  }

  // GENERAL
  static Future<String> getString({
    required String key,
    required String defaultValue,
  }) async {
    final SharedPreferences prefs = await _prefs;

    // Separate nullable variable so it can be checked and logged.
    final String? loadedString = prefs.getString(key);
    return loadedString ?? defaultValue;
  }

  static Future<void> setString({
    required String value,
    required String key,
  }) async {
    final SharedPreferences prefs = await _prefs;
    prefs.setString(
      key,
      value,
    );
  }

  static Future<int> getInt({
    required String key,
    required int defaultValue,
  }) async {
    final SharedPreferences prefs = await _prefs;

    // Separate nullable variable so it can be checked and logged.
    final int? loadedInt = prefs.getInt(key);
    return loadedInt ?? defaultValue;
  }

  static Future<void> setInt({
    required int value,
    required String key,
  }) async {
    final SharedPreferences prefs = await _prefs;
    prefs.setInt(
      key,
      value,
    );
  }
}
