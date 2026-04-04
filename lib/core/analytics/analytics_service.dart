import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class AnalyticsService {
  static final _analytics = FirebaseAnalytics.instance;
  static final _crashlytics = FirebaseCrashlytics.instance;

  // ── User ─────────────────────────────────────────────────────────────────

  static Future<void> setUser(String uid) async {
    await _analytics.setUserId(id: uid);
    await _crashlytics.setUserIdentifier(uid);
  }

  static Future<void> clearUser() async {
    await _analytics.setUserId(id: null);
    await _crashlytics.setUserIdentifier('');
  }

  // ── Auth events ───────────────────────────────────────────────────────────

  static Future<void> logLogin(String method) =>
      _analytics.logLogin(loginMethod: method);

  static Future<void> logSignUp(String method) =>
      _analytics.logSignUp(signUpMethod: method);

  // ── Transaction events ────────────────────────────────────────────────────

  static Future<void> logTransactionCreated(String type, double amount, String currency) =>
      _analytics.logEvent(
        name: 'transaction_created',
        parameters: {'type': type, 'amount': amount, 'currency': currency},
      );

  // ── Goal events ───────────────────────────────────────────────────────────

  static Future<void> logGoalCreated() =>
      _analytics.logEvent(name: 'goal_created');

  static Future<void> logGoalCompleted() =>
      _analytics.logEvent(name: 'goal_completed');

  // ── Reports events ────────────────────────────────────────────────────────

  static Future<void> logReportViewed(String mode) =>
      _analytics.logEvent(
        name: 'report_viewed',
        parameters: {'mode': mode},
      );

  // ── Household events ──────────────────────────────────────────────────────

  static Future<void> logHouseholdCreated() =>
      _analytics.logEvent(name: 'household_created');

  static Future<void> logHouseholdJoined() =>
      _analytics.logEvent(name: 'household_joined');

  // ── Error reporting ───────────────────────────────────────────────────────

  static Future<void> recordError(dynamic exception, StackTrace? stack, {bool fatal = false}) =>
      _crashlytics.recordError(exception, stack, fatal: fatal);
}
