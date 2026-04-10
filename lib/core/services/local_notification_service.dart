import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Manages on-device scheduled reminder notifications.
/// All ops are no-ops on web.
class LocalNotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _channelId = 'fimakyp_reminders';
  static const _channelName = 'Recordatorios Fimakyp';
  static const _baseId = 2000; // Use 2000–2099 to avoid collisions

  static Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  /// Parses the stored reminder string (comma-separated "HH:mm" values)
  /// and schedules one daily notification per entry.
  static Future<void> scheduleFromString(String? stored) async {
    if (kIsWeb || stored == null || stored.isEmpty) {
      await cancelAll();
      return;
    }
    final times = stored
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    await scheduleReminders(times);
  }

  /// Schedules daily notifications for each time in the list.
  /// Replaces any previously scheduled reminders.
  static Future<void> scheduleReminders(List<String> times) async {
    if (kIsWeb) return;
    await initialize();
    await cancelAll();

    for (int i = 0; i < times.length && i < 20; i++) {
      final parts = times[i].split(':');
      if (parts.length != 2) continue;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;
      await _scheduleDaily(_baseId + i, hour, minute);
    }
  }

  static Future<void> _scheduleDaily(int id, int hour, int minute) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      var next = tz.TZDateTime(
          tz.local, now.year, now.month, now.day, hour, minute);
      if (!next.isAfter(now)) {
        next = next.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        id,
        '💰 Fimakyp',
        '¿Ya registraste tus gastos de hoy? Solo toma 3 minutos.',
        next,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // Never crash if notification scheduling fails
    }
  }

  static Future<void> cancelAll() async {
    if (kIsWeb) return;
    await initialize();
    for (int i = _baseId; i < _baseId + 20; i++) {
      await _plugin.cancel(i);
    }
  }
}
