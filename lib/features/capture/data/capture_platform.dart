import 'package:flutter/foundation.dart';

/// Which capture routes the current platform can actually offer.
///
/// Voice runs on Android, iOS and web (the browser's Web Speech API), so it is
/// offered everywhere and the sheet falls back gracefully if the device has no
/// recognizer. On-device OCR is Android/iOS only — ML Kit has no web build.
class CapturePlatform {
  const CapturePlatform._();

  static bool get supportsVoice => true;

  static bool get supportsReceiptOcr {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }
}
