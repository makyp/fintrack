import 'package:speech_to_text/speech_to_text.dart';

import 'capture_preferences.dart';

/// Why a dictation session could not start.
enum SpeechFailure { unavailable, permissionDenied, error }

/// Thin wrapper over `speech_to_text`.
///
/// Recognition is handled by the OS (Android/iOS) or the browser, so there is
/// no API key and no per-request cost. The service owns the plugin lifecycle
/// so the widget only deals with transcript callbacks.
class SpeechCaptureService {
  final SpeechToText _speech = SpeechToText();

  bool _initialized = false;
  SpeechFailure? _lastFailure;
  List<LocaleName>? _locales;

  bool get isListening => _speech.isListening;
  SpeechFailure? get lastFailure => _lastFailure;

  /// Prepares the recognizer. Returns false when the device has none or the
  /// microphone permission was denied — [lastFailure] says which.
  Future<bool> initialize({void Function()? onDone}) async {
    if (_initialized) return true;
    try {
      _initialized = await _speech.initialize(
        onStatus: (status) {
          // 'done' and 'notListening' both mean the mic released.
          if (status == 'done' || status == 'notListening') onDone?.call();
        },
        onError: (error) {
          _lastFailure = error.permanent
              ? SpeechFailure.permissionDenied
              : SpeechFailure.error;
        },
        debugLogging: false,
      );
      if (!_initialized) {
        _lastFailure ??= SpeechFailure.unavailable;
      }
    } catch (_) {
      _initialized = false;
      _lastFailure = SpeechFailure.unavailable;
    }
    return _initialized;
  }

  // ── Locales ──────────────────────────────────────────────────────────────

  /// Every language this device can transcribe, Spanish variants first.
  ///
  /// Only meaningful after [initialize]. The list comes from the OS, so it is
  /// the honest answer to "why can't it understand me" — if Spanish is not in
  /// here, the user has to install it from the system settings.
  Future<List<LocaleName>> availableLocales() async {
    if (!_initialized) return const [];
    if (_locales != null) return _locales!;
    try {
      final locales = await _speech.locales();
      locales.sort((a, b) {
        final aSpanish = _isSpanish(a.localeId);
        final bSpanish = _isSpanish(b.localeId);
        if (aSpanish != bSpanish) return aSpanish ? -1 : 1;
        return a.name.compareTo(b.name);
      });
      _locales = locales;
      return locales;
    } catch (_) {
      return const [];
    }
  }

  /// The locale dictation will actually use: the one the user chose, else the
  /// best Spanish match, else the system default.
  Future<LocaleName?> activeLocale() async {
    final locales = await availableLocales();
    if (locales.isEmpty) return null;

    final saved = await CapturePreferences.speechLocaleId();
    if (saved != null) {
      for (final locale in locales) {
        if (locale.localeId == saved) return locale;
      }
    }

    // Prefer Colombian Spanish, then any Spanish.
    LocaleName? anySpanish;
    for (final locale in locales) {
      final id = _normalizeId(locale.localeId);
      if (id == 'es-co') return locale;
      anySpanish ??= _isSpanish(locale.localeId) ? locale : null;
    }
    if (anySpanish != null) return anySpanish;

    try {
      final system = await _speech.systemLocale();
      if (system != null) return system;
    } catch (_) {
      // Fall through to the first available locale.
    }
    return locales.first;
  }

  Future<void> setPreferredLocale(String localeId) =>
      CapturePreferences.setSpeechLocaleId(localeId);

  /// True when the device offers no Spanish recognizer at all — the user has
  /// to install it before dictation in Spanish can work.
  Future<bool> hasSpanish() async {
    final locales = await availableLocales();
    return locales.any((l) => _isSpanish(l.localeId));
  }

  static bool _isSpanish(String localeId) =>
      _normalizeId(localeId).startsWith('es');

  static String _normalizeId(String localeId) =>
      localeId.replaceAll('_', '-').toLowerCase();

  /// The plugin reports locale ids as `es_CO`, but Android's
  /// `RecognizerIntent.EXTRA_LANGUAGE` and the Web Speech API both expect a
  /// BCP-47 tag (`es-CO`). Passing the underscore form through makes Android
  /// silently ignore it and transcribe in the system language instead — which
  /// is why dictation came out in English. iOS accepts either form.
  static String toLanguageTag(String localeId) => localeId.replaceAll('_', '-');

  // ── Listening ────────────────────────────────────────────────────────────

  /// Starts listening, reporting partial transcripts as the user speaks.
  ///
  /// [onResult] receives the text so far and whether the recognizer considers
  /// it final. Stops on its own after ~4s of silence.
  Future<void> start({
    required void Function(String transcript, bool isFinal) onResult,
    void Function(double level)? onSoundLevel,
  }) async {
    if (!_initialized) return;
    _lastFailure = null;

    final locale = await activeLocale();
    final languageTag =
        locale == null ? null : toLanguageTag(locale.localeId);

    // Long enough for a full sentence, short enough to not hang open.
    const listenFor = Duration(seconds: 30);
    const pauseFor = Duration(seconds: 4);

    // In speech_to_text 6.x the Dart-side timers and locale come from these
    // top-level arguments; `listenOptions` is only forwarded to the native
    // recognizer. Passing both keeps the two sides in agreement.
    await _speech.listen(
      onResult: (result) =>
          onResult(result.recognizedWords, result.finalResult),
      onSoundLevelChange: onSoundLevel,
      localeId: languageTag,
      listenFor: listenFor,
      pauseFor: pauseFor,
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
        localeId: languageTag,
        listenFor: listenFor,
        pauseFor: pauseFor,
      ),
    );
  }

  Future<void> stop() async {
    if (_speech.isListening) await _speech.stop();
  }

  Future<void> cancel() async {
    if (_speech.isListening) await _speech.cancel();
  }
}
