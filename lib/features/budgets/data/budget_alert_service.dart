import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/local_notification_service.dart';
import '../../reports/data/datasources/reports_datasource.dart';
import '../domain/budget_calculator.dart';
import '../domain/entities/budget.dart';
import 'datasources/budget_datasource.dart';

/// Fires a notification the moment a category crosses 80% or 100% of its cap.
///
/// Crossings are events, not schedules, so this runs after a movement is saved
/// (and once on launch). The highest threshold already announced is remembered
/// per category *and month*, so the user is told once — not on every purchase
/// after the cap is blown — and the counter resets when the month rolls over.
@lazySingleton
class BudgetAlertService {
  final BudgetDataSource _budgets;
  final ReportsDataSource _reports;

  BudgetAlertService(this._budgets, this._reports);

  static const _prefix = 'budget_alert';

  static String _key(String categoryId, DateTime month) =>
      '$_prefix.${month.year}-${month.month}.$categoryId';

  /// Checks every cap and notifies about the ones that just crossed a
  /// threshold. Safe to call often; it stays quiet when nothing changed.
  Future<void> check(String userId) async {
    try {
      final now = DateTime.now();
      final budgets = await _budgets.getBudgets(userId);
      if (budgets.isEmpty) return;

      final report = await _reports.loadReport(userId, now.year, now.month);
      final summary = BudgetCalculator.summarize(
        budgets: budgets,
        spendingByCategory: report.expensesByCategory,
      );

      final prefs = await SharedPreferences.getInstance();
      for (final status in summary.statuses) {
        final reached = _thresholdOf(status);
        final key = _key(status.category.id, now);
        final announced = prefs.getInt(key) ?? 0;

        if (reached <= announced) continue;
        await prefs.setInt(key, reached);
        await _notify(status, reached);
      }
    } catch (_) {
      // An alert is a nicety — never let it break saving a movement.
    }
  }

  /// 100 when over the cap, 80 when close, 0 when there is nothing to say.
  static int _thresholdOf(BudgetStatus status) {
    if (status.isOver) return 100;
    if (status.isNearLimit) return 80;
    return 0;
  }

  Future<void> _notify(BudgetStatus status, int threshold) {
    if (threshold >= 100) {
      return LocalNotificationService.showBudgetAlert(
        categoryId: status.category.id,
        title: '🚨 Te pasaste del tope de ${status.category.label}',
        body: 'Llevas ${_money(status.spent)} de ${_money(status.limit)} — '
            '${_money(status.overspent)} por encima.',
      );
    }
    return LocalNotificationService.showBudgetAlert(
      categoryId: status.category.id,
      title: '⚠️ Vas en el ${(status.progress * 100).round()}% '
          'de ${status.category.label}',
      body: 'Te quedan ${_money(status.available)} de tu tope de '
          '${_money(status.limit)} para lo que resta del mes.',
    );
  }

  static String _money(double amount) {
    final rounded = amount.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < rounded.length; i++) {
      if (i > 0 && (rounded.length - i) % 3 == 0) buf.write('.');
      buf.write(rounded[i]);
    }
    return '\$$buf';
  }
}
