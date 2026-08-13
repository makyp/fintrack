import 'package:flutter_test/flutter_test.dart';
import 'package:fintrack/features/budgets/domain/budget_calculator.dart';
import 'package:fintrack/features/budgets/domain/entities/budget.dart';
import 'package:fintrack/features/categories/domain/category_registry.dart';
import 'package:fintrack/features/insights/domain/insights_engine.dart';
import 'package:fintrack/features/reports/domain/models/report_data.dart';

Budget cap(String categoryId, double amount) => Budget(
      categoryId: categoryId,
      amount: amount,
      updatedAt: DateTime(2026, 8, 1),
    );

CategoryData spent(String categoryId, double amount) => CategoryData(
      category: CategoryRegistry.byId(categoryId),
      amount: amount,
      percentage: 0,
    );

ReportData report({
  double income = 3000000,
  double expenses = 0,
  List<CategoryData> byCategory = const [],
}) =>
    ReportData(
      month: 8,
      year: 2026,
      totalIncome: income,
      totalExpenses: expenses,
      expensesByCategory: byCategory,
      incomeByCategory: const [],
      trend: const [],
    );

void main() {
  setUp(CategoryRegistry.reset);

  group('BudgetStatus', () {
    test('under the cap reports what is available', () {
      final s = BudgetStatus(
          category: CategoryRegistry.byId('cleaning'), limit: 100000, spent: 30000);
      expect(s.available, 70000);
      expect(s.overspent, 0);
      expect(s.isOver, isFalse);
      expect(s.isHealthy, isTrue);
      expect(s.progress, closeTo(0.3, 0.001));
    });

    test('over the cap reports the excess and nothing available', () {
      final s = BudgetStatus(
          category: CategoryRegistry.byId('services'), limit: 200000, spent: 260000);
      expect(s.overspent, 60000);
      expect(s.available, 0);
      expect(s.isOver, isTrue);
      expect(s.progress, closeTo(1.3, 0.001));
    });

    test('80% is the warning line, not the limit', () {
      final near = BudgetStatus(
          category: CategoryRegistry.byId('food'), limit: 100000, spent: 80000);
      final safe = BudgetStatus(
          category: CategoryRegistry.byId('food'), limit: 100000, spent: 79000);
      expect(near.isNearLimit, isTrue);
      expect(near.isOver, isFalse);
      expect(safe.isNearLimit, isFalse);
    });

    test('spending exactly the cap is not overspending', () {
      final s = BudgetStatus(
          category: CategoryRegistry.byId('food'), limit: 100000, spent: 100000);
      expect(s.isOver, isFalse);
      expect(s.available, 0);
      expect(s.overspent, 0);
    });
  });

  group('BudgetCalculator', () {
    test('matches each cap with what was spent in its category', () {
      final summary = BudgetCalculator.summarize(
        budgets: [cap('cleaning', 100000), cap('services', 200000)],
        spendingByCategory: [spent('cleaning', 30000), spent('services', 260000)],
      );
      expect(summary.statuses.length, 2);
      expect(
          summary.statuses.firstWhere((s) => s.category.id == 'cleaning').spent,
          30000);
      expect(
          summary.statuses.firstWhere((s) => s.category.id == 'services').spent,
          260000);
    });

    test('a cap with no spending yet still shows up, at zero', () {
      final summary = BudgetCalculator.summarize(
        budgets: [cap('cleaning', 100000)],
        spendingByCategory: const [],
      );
      expect(summary.statuses.single.spent, 0);
      expect(summary.statuses.single.available, 100000);
    });

    test('spending in a category with no cap is ignored', () {
      final summary = BudgetCalculator.summarize(
        budgets: [cap('cleaning', 100000)],
        spendingByCategory: [spent('food', 900000), spent('cleaning', 10000)],
      );
      expect(summary.statuses.length, 1);
      expect(summary.totalSpent, 10000);
    });

    test('the most urgent cap comes first', () {
      final summary = BudgetCalculator.summarize(
        budgets: [cap('food', 100000), cap('services', 100000)],
        spendingByCategory: [spent('food', 10000), spent('services', 150000)],
      );
      expect(summary.statuses.first.category.id, 'services');
      expect(summary.worst?.category.id, 'services');
    });

    test('totals separate what is left from what was exceeded', () {
      final summary = BudgetCalculator.summarize(
        budgets: [cap('cleaning', 100000), cap('services', 200000)],
        spendingByCategory: [spent('cleaning', 30000), spent('services', 260000)],
      );
      expect(summary.totalLimit, 300000);
      expect(summary.totalSpent, 290000);
      // The 70k left in Aseo is not cancelled out by the 60k overrun in
      // Servicios — they are two different facts.
      expect(summary.totalAvailable, 70000);
      expect(summary.totalSaved, 70000);
      expect(summary.totalOverspent, 60000);
      expect(summary.over.length, 1);
    });
  });

  group('budget tips', () {
    test('an exceeded cap outranks the savings-rate advice', () {
      final tips = InsightsEngine.generate(
        report(expenses: 260000, byCategory: [spent('services', 260000)]),
        budgets: BudgetCalculator.summarize(
          budgets: [cap('services', 200000)],
          spendingByCategory: [spent('services', 260000)],
        ),
      );
      expect(tips.first.id, 'budget_over');
      expect(tips.first.message, contains('60.000'));
    });

    test('a cap close to its limit warns without crying wolf', () {
      final tips = InsightsEngine.generate(
        report(expenses: 85000, byCategory: [spent('cleaning', 85000)]),
        budgets: BudgetCalculator.summarize(
          budgets: [cap('cleaning', 100000)],
          spendingByCategory: [spent('cleaning', 85000)],
        ),
      );
      final ids = tips.map((t) => t.id).toList();
      expect(ids, contains('budget_near'));
      expect(ids, isNot(contains('budget_over')));
    });

    test('respecting every cap is worth saying so', () {
      final tips = InsightsEngine.generate(
        report(expenses: 30000, byCategory: [spent('cleaning', 30000)]),
        budgets: BudgetCalculator.summarize(
          budgets: [cap('cleaning', 100000)],
          spendingByCategory: [spent('cleaning', 30000)],
        ),
      );
      expect(tips.map((t) => t.id), contains('budget_ok'));
    });

    test('without caps configured the engine behaves as before', () {
      final tips = InsightsEngine.generate(report(expenses: 500000));
      expect(tips.map((t) => t.id),
          isNot(anyOf(contains('budget_ok'), contains('budget_over'))));
    });
  });
}
