import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../features/accounts/domain/entities/account.dart';
import '../../features/transactions/domain/entities/transaction.dart';
import '../../features/transactions/domain/entities/recurring_transaction.dart';

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
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Request runtime permission on Android 13+
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();

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
            importance: Importance.max,
            priority: Priority.max,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
            channelShowBadge: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        // alarmClock uses AlarmManager.setAlarmClock which is always exact
        // and doesn't require SCHEDULE_EXACT_ALARM special permission.
        androidScheduleMode: AndroidScheduleMode.alarmClock,
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

  // ── Due-date alerts for recurring transactions ────────────────────────────

  static const _dueDateChannelId   = 'fimakyp_due_dates';
  static const _dueDateChannelName = 'Vencimientos Fimakyp';
  static const _dueDateBaseId      = 3000; // 3000–3099

  /// Schedules a local notification 3 days before each recurring transaction
  /// that is due soon. Replaces all previous due-date notifications.
  static Future<void> scheduleDueDateAlerts(
      List<RecurringTransaction> recurrings) async {
    if (kIsWeb) return;
    await initialize();

    // Cancel old due-date notifications
    for (int i = _dueDateBaseId; i < _dueDateBaseId + 100; i++) {
      await _plugin.cancel(i);
    }

    int notifId = _dueDateBaseId;
    for (final rt in recurrings) {
      if (!rt.isActive) continue;
      final alertTime = rt.nextDueDate.subtract(const Duration(days: 3));
      if (alertTime.isBefore(DateTime.now())) continue;

      final label =
          rt.type == TransactionType.expense ? 'Gasto' : 'Ingreso';
      try {
        await _plugin.zonedSchedule(
          notifId++,
          '⏰ $label próximo a vencer',
          '"${rt.description}" vence el '
          '${rt.nextDueDate.day}/${rt.nextDueDate.month}',
          tz.TZDateTime.from(alertTime, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _dueDateChannelId,
              _dueDateChannelName,
              importance: Importance.max,
              priority: Priority.max,
              icon: '@mipmap/ic_launcher',
              playSound: true,
              enableVibration: true,
              channelShowBadge: true,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {}

      if (notifId >= _dueDateBaseId + 100) break;
    }
  }

  // ── Credit card billing cycle ─────────────────────────────────────────────

  static const _cardChannelId = 'fimakyp_credit_cards';
  static const _cardChannelName = 'Tarjetas de crédito Fimakyp';
  static const _cardBaseId = 3100; // 3100–3199
  static const _cardIdLimit = 100;

  /// How many future cycles we schedule ahead. Local notifications are
  /// one-shot, so booking a few months means the reminders keep arriving even
  /// if the app is not opened for a while; every open re-schedules from today.
  static const _cardCyclesAhead = 3;

  /// Hour of the day the card reminders fire.
  static const _cardAlertHour = 9;

  /// Schedules, for every credit card that has a billing cycle configured:
  ///   * the statement closing day ("hoy corta")
  ///   * 3 days before the due date ("se acerca el pago")
  ///   * the due date itself ("hoy vence")
  /// Replaces all previously scheduled card reminders.
  static Future<void> scheduleCreditCardAlerts(List<Account> accounts) async {
    if (kIsWeb) return;
    await initialize();

    for (int i = _cardBaseId; i < _cardBaseId + _cardIdLimit; i++) {
      await _plugin.cancel(i);
    }

    final cards = accounts
        .where((a) => !a.isArchived && a.hasBillingCycle)
        .toList();
    if (cards.isEmpty) return;

    final now = DateTime.now();
    var notifId = _cardBaseId;
    const maxId = _cardBaseId + _cardIdLimit;

    for (final card in cards) {
      // Walk the next few cycles by asking for the occurrence that follows the
      // previous one, which keeps short months (Feb) correctly clamped.
      var statementCursor = now;
      var paymentCursor = now;

      for (int cycle = 0; cycle < _cardCyclesAhead; cycle++) {
        final statement = card.nextStatementDate(from: statementCursor);
        final payment = card.nextPaymentDate(from: paymentCursor);
        if (statement == null || payment == null) break;

        final alerts = <_CardAlert>[
          _CardAlert(
            when: statement,
            title: '💳 Corte de ${card.name}',
            body: 'Hoy cierra tu facturación. Lo que compres desde mañana '
                'entra a la siguiente factura.',
          ),
          _CardAlert(
            when: payment.subtract(const Duration(days: 3)),
            title: '⏰ Pago de ${card.name} en 3 días',
            body: 'Vence el ${payment.day}/${payment.month}. Prepara el pago '
                'para no generar intereses.',
          ),
          _CardAlert(
            when: payment,
            title: '🔔 Hoy vence ${card.name}',
            body: 'Último día para pagar tu tarjeta sin intereses de mora.',
          ),
        ];

        for (final alert in alerts) {
          if (notifId >= maxId) return;
          final fireAt = DateTime(
            alert.when.year,
            alert.when.month,
            alert.when.day,
            _cardAlertHour,
          );
          if (!fireAt.isAfter(now)) continue; // already past today
          await _scheduleOneShot(
            notifId++,
            alert.title,
            alert.body,
            fireAt,
            _cardChannelId,
            _cardChannelName,
          );
        }

        // Next cycle starts the day after the one we just scheduled.
        statementCursor = statement.add(const Duration(days: 1));
        paymentCursor = payment.add(const Duration(days: 1));
      }
    }
  }

  static Future<void> _scheduleOneShot(
    int id,
    String title,
    String body,
    DateTime when,
    String channelId,
    String channelName,
  ) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(when, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            importance: Importance.max,
            priority: Priority.max,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
            channelShowBadge: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // Never crash if notification scheduling fails
    }
  }
}

class _CardAlert {
  final DateTime when;
  final String title;
  final String body;

  const _CardAlert({
    required this.when,
    required this.title,
    required this.body,
  });
}
