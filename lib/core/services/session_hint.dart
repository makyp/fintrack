import 'package:shared_preferences/shared_preferences.dart';

/// Remembers, on the device itself, that this install had a signed-in user.
///
/// FirebaseAuth already persists the session natively; this flag is only a
/// *hint* about what we should expect on the next cold start. It lets
/// `AuthBloc` tell two very different situations apart while Firebase is still
/// hydrating:
///
///   * never signed in on this device  → a null user is the truth, show login
///     immediately (no splash delay).
///   * signed in before                → a null user is almost certainly the
///     Android cold-start null that arrives before the persisted session is
///     restored, so wait longer before giving up and showing login.
///
/// It is never used as a substitute for a real session: without a FirebaseAuth
/// user we always end up unauthenticated, the flag only changes how long we
/// are willing to wait.
class SessionHint {
  const SessionHint._();

  static const _key = 'had_session';

  /// Cached in memory so the hot path never awaits disk twice.
  static bool? _cached;

  static Future<bool> hadSession() async {
    final cached = _cached;
    if (cached != null) return cached;
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getBool(_key) ?? false;
      _cached = value;
      return value;
    } catch (_) {
      // Storage unavailable — fall back to the conservative "no hint".
      return false;
    }
  }

  static Future<void> set(bool value) async {
    if (_cached == value) return;
    _cached = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, value);
    } catch (_) {
      // Losing the hint only costs a shorter grace window next launch.
    }
  }

  /// Test seam: drops the in-memory cache so each test starts clean.
  static void resetCacheForTest() => _cached = null;
}
