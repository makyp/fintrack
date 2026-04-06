import '../../../transactions/domain/entities/transaction.dart';

class CategoryData {
  final TransactionCategory category;
  final double amount;
  final double percentage;

  const CategoryData({
    required this.category,
    required this.amount,
    required this.percentage,
  });
}

class MonthlyData {
  final int year;
  final int month;
  final double income;
  final double expenses;

  const MonthlyData({
    required this.year,
    required this.month,
    required this.income,
    required this.expenses,
  });

  double get net => income - expenses;

  static const _monthAbbr = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];

  String get label => _monthAbbr[month - 1];
}

class GoalProgressData {
  final String id;
  final String name;
  final String icon;
  final double currentAmount;
  final double targetAmount;
  final double progress;
  final double remaining;
  final DateTime? targetDate;
  final bool isCompleted;

  const GoalProgressData({
    required this.id,
    required this.name,
    required this.icon,
    required this.currentAmount,
    required this.targetAmount,
    required this.progress,
    required this.remaining,
    this.targetDate,
    required this.isCompleted,
  });
}

class DailyData {
  final int day;
  final double income;
  final double expenses;

  const DailyData({
    required this.day,
    required this.income,
    required this.expenses,
  });

  double get net => income - expenses;
}

class ReportData {
  final int month;
  final int year;
  final double totalIncome;
  final double totalExpenses;
  final List<CategoryData> expensesByCategory;
  final List<CategoryData> incomeByCategory;
  final List<MonthlyData> trend;
  final List<DailyData> daily;
  final List<GoalProgressData> goals;

  const ReportData({
    required this.month,
    required this.year,
    required this.totalIncome,
    required this.totalExpenses,
    required this.expensesByCategory,
    required this.incomeByCategory,
    required this.trend,
    this.daily = const [],
    this.goals = const [],
  });

  double get netBalance => totalIncome - totalExpenses;

  CategoryData? get topExpense =>
      expensesByCategory.isEmpty ? null : expensesByCategory.first;

  CategoryData? get topIncome =>
      incomeByCategory.isEmpty ? null : incomeByCategory.first;

  static ReportData empty(int month, int year) => ReportData(
        month: month,
        year: year,
        totalIncome: 0,
        totalExpenses: 0,
        expensesByCategory: const [],
        incomeByCategory: const [],
        trend: const [],
        daily: const [],
        goals: const [],
      );
}
