import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/bank_notification_parser.dart';

/// Bridge to the Android notification listener.
///
/// The native service writes what it catches into the same SharedPreferences
/// file this plugin reads, so there is no stream to keep alive: the app just
/// picks up the queue when it opens. Everything stays on the device.
class BankNotificationService {
  const BankNotificationService._();

  static const _channel = MethodChannel('fimakyp/notification_access');

  static const _queueKey = 'bank_notifications_queue';
  static const _enabledKey = 'bank_notifications_enabled';
  static const _mutedKey = 'bank_notifications_muted';

  /// Only Android exposes a notification listener at all. iOS has no
  /// equivalent — Apple does not let an app read other apps' notifications.
  static bool get isSupported => !kIsWeb && Platform.isAndroid;

  /// Whether the user granted the system-level notification access.
  static Future<bool> hasAccess() async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('isEnabled') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Opens the system screen where the access is granted. There is no runtime
  /// dialog for this permission.
  static Future<void> openSettings() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('openSettings');
    } on PlatformException {
      // Some manufacturers hide the screen; nothing else we can do here.
    }
  }

  /// The app's own switch, separate from the system permission: the user can
  /// leave the access granted and still turn the feature off.
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs.getBool(_enabledKey) ?? false;
  }

  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
    if (!value) await prefs.setString(_queueKey, '[]');
  }

  /// What the listener has caught since the last time it was cleared, newest
  /// first.
  static Future<List<BankNotification>> pending() async {
    if (!isSupported) return const [];
    final prefs = await SharedPreferences.getInstance();
    // The queue was written by another process' view of the file, so the
    // in-memory cache this plugin keeps has to be refreshed first.
    await prefs.reload();
    final raw = prefs.getString(_queueKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(BankNotification.fromJson)
          .toList();
    } catch (_) {
      // A corrupt queue is not worth blocking the screen over.
      return const [];
    }
  }

  /// Drops [notifications] from the queue — after the user booked or
  /// dismissed them.
  static Future<void> remove(Iterable<BankNotification> notifications) async {
    final prints = notifications.map((n) => n.fingerprint).toSet();
    if (prints.isEmpty) return;
    final remaining = (await pending())
        .where((n) => !prints.contains(n.fingerprint))
        .map((n) => {
              'package': n.packageName,
              'title': n.title,
              'text': n.text,
              'postedAt': n.postedAt.millisecondsSinceEpoch,
            })
        .toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_queueKey, jsonEncode(remaining));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_queueKey, '[]');
  }

  /// Apps whose notifications are ignored from now on. Read by the native
  /// service on every notification, so muting takes effect immediately.
  static Future<Set<String>> mutedPackages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final raw = prefs.getString(_mutedKey) ?? '';
    return raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toSet();
  }

  static Future<void> mute(String packageName) async {
    final muted = await mutedPackages()..add(packageName);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mutedKey, muted.join(','));
    await remove((await pending()).where((n) => n.packageName == packageName));
  }

  static Future<void> unmuteAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mutedKey, '');
  }
}
