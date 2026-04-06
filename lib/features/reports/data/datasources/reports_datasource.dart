import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../../../goals/data/models/savings_goal_model.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../domain/models/report_data.dart';

class ReportsDataSource {
  final FirebaseFirestore _firestore;

  ReportsDataSource(this._firestore);

  CollectionReference<Map<String, dynamic>> _txCol(String userId) =>
      _firestore.collection('users').doc(userId).collection('transactions');

  CollectionReference<Map<String, dynamic>> _householdTxCol(String householdId) =>
      _firestore.collection('households').doc(householdId).collection('transactions');

  CollectionReference<Map<String, dynamic>> _goalsCol(String userId) =>
      _firestore.collection('users').doc(userId).collection('goals');

  /// Loads [ReportData] for the given month/year plus a 6-month trend.
  Future<ReportData> loadReport(
      String userId, int year, int month) async {
    // ── Current month ────────────────────────────────────────────────────────
    final monthStart = Timestamp.fromDate(DateTime(year, month, 1));
    final monthEnd   = Timestamp.fromDate(DateTime(year, month + 1, 1));

    final monthSnap = await _txCol(userId)
        .where('date', isGreaterThanOrEqualTo: monthStart)
        .where('date', isLessThan: monthEnd)
        .limit(500)
        .get();

    double totalIncome = 0;
    double totalExpenses = 0;
    final expMap = <TransactionCategory, double>{};
    final incMap = <TransactionCategory, double>{};
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final dailyIncome = List<double>.filled(daysInMonth + 1, 0);
    final dailyExpenses = List<double>.filled(daysInMonth + 1, 0);

    for (final doc in monthSnap.docs) {
      final d = doc.data();
      final amount = (d['amount'] as num).toDouble();
      final typeStr = d['type'] as String? ?? 'expense';
      final catStr  = d['categoryId'] as String? ?? 'other';
      final type = TransactionType.values.firstWhere(
          (e) => e.name == typeStr, orElse: () => TransactionType.expense);
      final cat = TransactionCategory.values.firstWhere(
          (e) => e.name == catStr, orElse: () => TransactionCategory.other);
      final day = (d['date'] as Timestamp).toDate().day;

      if (type == TransactionType.expense) {
        totalExpenses += amount;
        expMap[cat] = (expMap[cat] ?? 0) + amount;
        if (day >= 1 && day <= daysInMonth) dailyExpenses[day] += amount;
      } else if (type == TransactionType.income) {
        totalIncome += amount;
        incMap[cat] = (incMap[cat] ?? 0) + amount;
        if (day >= 1 && day <= daysInMonth) dailyIncome[day] += amount;
      }
    }

    final daily = List.generate(daysInMonth, (i) {
      final d = i + 1;
      return DailyData(day: d, income: dailyIncome[d], expenses: dailyExpenses[d]);
    });

    // ── 6-month trend ────────────────────────────────────────────────────────
    final trendStart = Timestamp.fromDate(DateTime(year, month - 5, 1));
    final trendSnap = await _txCol(userId)
        .where('date', isGreaterThanOrEqualTo: trendStart)
        .where('date', isLessThan: monthEnd)
        .limit(2000)
        .get();

    final trendMap = <String, MonthlyData>{};
    for (var m = 0; m < 6; m++) {
      final d = DateTime(year, month - 5 + m, 1);
      final key = '${d.year}-${d.month}';
      trendMap[key] = MonthlyData(year: d.year, month: d.month,
          income: 0, expenses: 0);
    }

    for (final doc in trendSnap.docs) {
      final d = doc.data();
      final amount = (d['amount'] as num).toDouble();
      final typeStr = d['type'] as String? ?? 'expense';
      final type = TransactionType.values.firstWhere(
          (e) => e.name == typeStr, orElse: () => TransactionType.expense);
      if (type == TransactionType.transfer) continue;

      final ts = (d['date'] as Timestamp).toDate();
      final key = '${ts.year}-${ts.month}';
      final existing = trendMap[key];
      if (existing == null) continue;

      if (type == TransactionType.income) {
        trendMap[key] = MonthlyData(
            year: existing.year, month: existing.month,
            income: existing.income + amount,
            expenses: existing.expenses);
      } else {
        trendMap[key] = MonthlyData(
            year: existing.year, month: existing.month,
            income: existing.income,
            expenses: existing.expenses + amount);
      }
    }

    // ── Build CategoryData lists (sorted descending) ──────────────────────
    List<CategoryData> _buildCats(Map<TransactionCategory, double> map,
        double total) {
      if (total == 0) return [];
      return map.entries
          .map((e) => CategoryData(
                category: e.key,
                amount: e.value,
                percentage: e.value / total,
              ))
          .toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));
    }

    // ── Goals progress ────────────────────────────────────────────────────
    final goalsSnap = await _goalsCol(userId)
        .where('isCompleted', isEqualTo: false)
        .get();
    final goals = goalsSnap.docs.map((doc) {
      final g = SavingsGoalModel.fromFirestore(doc.data(), doc.id);
      return GoalProgressData(
        id: g.id,
        name: g.name,
        icon: g.icon,
        currentAmount: g.currentAmount,
        targetAmount: g.targetAmount,
        progress: g.progress,
        remaining: g.remaining,
        targetDate: g.targetDate,
        isCompleted: g.isCompleted,
      );
    }).toList();

    return ReportData(
      month: month,
      year: year,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      expensesByCategory: _buildCats(expMap, totalExpenses),
      incomeByCategory: _buildCats(incMap, totalIncome),
      trend: trendMap.values.toList()
        ..sort((a, b) => a.year != b.year
            ? a.year.compareTo(b.year)
            : a.month.compareTo(b.month)),
      daily: daily,
      goals: goals,
    );
  }

  /// Loads a household report from [households/{householdId}/transactions].
  Future<ReportData> loadHouseholdReport(
      String householdId, int year, int month) async {
    final monthStart = Timestamp.fromDate(DateTime(year, month, 1));
    final monthEnd = Timestamp.fromDate(DateTime(year, month + 1, 1));

    final monthSnap = await _householdTxCol(householdId)
        .where('date', isGreaterThanOrEqualTo: monthStart)
        .where('date', isLessThan: monthEnd)
        .limit(500)
        .get();

    double totalIncome = 0;
    double totalExpenses = 0;
    final expMap = <TransactionCategory, double>{};
    final incMap = <TransactionCategory, double>{};

    for (final doc in monthSnap.docs) {
      final d = doc.data();
      final amount = (d['amount'] as num).toDouble();
      final typeStr = d['type'] as String? ?? 'expense';
      final catStr = d['categoryId'] as String? ?? 'other';
      final type = TransactionType.values.firstWhere(
          (e) => e.name == typeStr, orElse: () => TransactionType.expense);
      final cat = TransactionCategory.values.firstWhere(
          (e) => e.name == catStr, orElse: () => TransactionCategory.other);

      if (type == TransactionType.expense) {
        totalExpenses += amount;
        expMap[cat] = (expMap[cat] ?? 0) + amount;
      } else if (type == TransactionType.income) {
        totalIncome += amount;
        incMap[cat] = (incMap[cat] ?? 0) + amount;
      }
    }

    final trendStart = Timestamp.fromDate(DateTime(year, month - 5, 1));
    final trendSnap = await _householdTxCol(householdId)
        .where('date', isGreaterThanOrEqualTo: trendStart)
        .where('date', isLessThan: monthEnd)
        .limit(2000)
        .get();

    final trendMap = <String, MonthlyData>{};
    for (var m = 0; m < 6; m++) {
      final d = DateTime(year, month - 5 + m, 1);
      final key = '${d.year}-${d.month}';
      trendMap[key] =
          MonthlyData(year: d.year, month: d.month, income: 0, expenses: 0);
    }

    for (final doc in trendSnap.docs) {
      final d = doc.data();
      final amount = (d['amount'] as num).toDouble();
      final typeStr = d['type'] as String? ?? 'expense';
      final type = TransactionType.values.firstWhere(
          (e) => e.name == typeStr, orElse: () => TransactionType.expense);
      if (type == TransactionType.transfer) continue;

      final ts = (d['date'] as Timestamp).toDate();
      final key = '${ts.year}-${ts.month}';
      final existing = trendMap[key];
      if (existing == null) continue;

      if (type == TransactionType.income) {
        trendMap[key] = MonthlyData(
            year: existing.year,
            month: existing.month,
            income: existing.income + amount,
            expenses: existing.expenses);
      } else {
        trendMap[key] = MonthlyData(
            year: existing.year,
            month: existing.month,
            income: existing.income,
            expenses: existing.expenses + amount);
      }
    }

    List<CategoryData> _buildCats(
        Map<TransactionCategory, double> map, double total) {
      if (total == 0) return [];
      return map.entries
          .map((e) =>
              CategoryData(category: e.key, amount: e.value, percentage: e.value / total))
          .toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));
    }

    return ReportData(
      month: month,
      year: year,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      expensesByCategory: _buildCats(expMap, totalExpenses),
      incomeByCategory: _buildCats(incMap, totalIncome),
      trend: trendMap.values.toList()
        ..sort((a, b) => a.year != b.year
            ? a.year.compareTo(b.year)
            : a.month.compareTo(b.month)),
    );
  }
}
