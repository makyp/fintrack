import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// Where the receipt image comes from.
enum ReceiptImageSource { camera, gallery }

/// Outcome of asking the OS for camera or photo access.
enum CaptureAccess {
  granted,

  /// Refused this time; asking again is allowed.
  denied,

  /// Refused for good — only the system settings screen can undo it.
  blocked,
}

/// Reads the text of a receipt photo using ML Kit's **on-device** recognizer.
///
/// Runs entirely offline: the image never leaves the phone and there is no
/// per-scan cost. The first run may take a moment while Play Services fetches
/// the Latin-script model.
class ReceiptOcrService {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  /// Asks the OS for the access this [source] needs, before opening any
  /// picker — so the user sees a permission prompt instead of a screen that
  /// silently does nothing.
  ///
  /// On Android `Permission.photos` resolves to nothing below API 33 (the
  /// system photo picker needs no grant there) and to `READ_MEDIA_IMAGES`
  /// from 33 up. On iOS it maps to the photo library.
  Future<CaptureAccess> requestAccess(ReceiptImageSource source) async {
    if (kIsWeb) return CaptureAccess.granted;

    final permission = source == ReceiptImageSource.camera
        ? Permission.camera
        : Permission.photos;

    try {
      final status = await permission.request();
      if (status.isGranted || status.isLimited) return CaptureAccess.granted;
      if (status.isPermanentlyDenied || status.isRestricted) {
        return CaptureAccess.blocked;
      }
      return CaptureAccess.denied;
    } catch (_) {
      // A platform without this permission concept: let the picker try.
      return CaptureAccess.granted;
    }
  }

  /// Opens the OS settings so the user can undo a permanent denial.
  Future<void> openSettings() => openAppSettings();

  /// Lets the user take or pick a photo. Returns null when they cancel.
  Future<XFile?> pickImage(ReceiptImageSource source) {
    return _picker.pickImage(
      source: source == ReceiptImageSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      // Receipts are small print — downscaling too aggressively costs
      // accuracy, so keep the image large and only trim the JPEG quality.
      maxWidth: 2000,
      imageQuality: 90,
    );
  }

  /// Runs OCR over [image] and returns the raw recognized text.
  Future<String> recognize(XFile image) async {
    final input = InputImage.fromFilePath(image.path);
    final result = await _recognizer.processImage(input);
    return result.text;
  }

  /// Releases the native recognizer. Must be called when the flow ends.
  Future<void> dispose() => _recognizer.close();
}
