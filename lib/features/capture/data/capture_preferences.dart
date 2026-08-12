import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the language the user picked for voice dictation.
///
/// Stored per install (not per user): it describes the device's recognizer,
/// not the account.
class CapturePreferences {
  const CapturePreferences._();

  static const _localeKey = 'capture_speech_locale';

  static Future<String?> speechLocaleId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localeKey);
  }

  static Future<void> setSpeechLocaleId(String localeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, localeId);
  }
}
