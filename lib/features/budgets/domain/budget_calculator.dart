import '../../categories/domain/category_registry.dart';
import '../../reports/domain/models/report_data.dart';
import 'entities/budget.dart';

/// Turns the caps plus the month's spending into [BudgetStatus]es.
///
/// Pure and synchronous: both inputs are already loaded elsewhere (the caps by
/// the budgets cubit, the spending by the reports datasource), so this adds no
/// queries of its own.
class BudgetCalculator {
  const BudgetCalculator._();

  /// [spendingByCategory] is [ReportData.expensesByCategory] — a category that
  /// has a cap but no spending yet still gets a status, with `spent` at 0.
  static BudgetSummary summarize({
    required List<Budget> budgets,
    required List<CategoryData> spendingByCategory,
  }) {
    final spentById = <String, double>{};
    for (final entry in spendingByCategory) {
      spentById[entry.category.id] =
          (spentById[entry.category.id] ?? 0) + entry.amount;
    }

    final statuses = budgets
        .where((b) => b.amount > 0)
        .map((b) => BudgetStatus(
              category: CategoryRegistry.byId(b.categoryId),
              limit: b.amount,
              spent: spentById[b.categoryId] ?? 0,
            ))
        .toList()
      // Most urgent first: the closest to (or furthest past) its cap.
      ..sort((a, b) => b.progress.compareTo(a.progress));

    return BudgetSummary(statuses);
  }
}
