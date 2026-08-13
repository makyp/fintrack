import 'package:equatable/equatable.dart';

import '../../../categories/domain/entities/transaction_category.dart';

/// A monthly spending cap for one category ("tope").
///
/// The doc id in Firestore is the category id, so a category can only ever
/// have one cap and saving is idempotent.
class Budget extends Equatable {
  final String categoryId;

  /// Monthly limit in the user's currency. Always > 0 — removing a cap
  /// deletes the document instead of storing a zero.
  final double amount;

  final DateTime updatedAt;

  const Budget({
    required this.categoryId,
    required this.amount,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [categoryId, amount, updatedAt];
}

/// A cap measured against what the user actually spent this month.
class BudgetStatus extends Equatable {
  final TransactionCategory category;
  final double limit;
  final double spent;

  const BudgetStatus({
    required this.category,
    required this.limit,
    required this.spent,
  });

  /// Positive: still available. Negative: how far past the cap.
  double get remaining => limit - spent;

  /// How much is left to spend, floored at zero.
  double get available => remaining > 0 ? remaining : 0;

  /// How much the cap was exceeded by, floored at zero.
  double get overspent => remaining < 0 ? -remaining : 0;

  /// Share of the cap already used. Not clamped — 1.4 means 40% over.
  double get progress => limit <= 0 ? 0 : spent / limit;

  bool get isOver => spent > limit;

  /// Close enough to warn about, but not over yet.
  bool get isNearLimit => !isOver && progress >= kNearLimitThreshold;

  bool get isHealthy => !isOver && !isNearLimit;

  static const kNearLimitThreshold = 0.8;

  @override
  List<Object?> get props => [category, limit, spent];
}

/// Roll-up of every cap for the month — what the reports header shows.
class BudgetSummary extends Equatable {
  final List<BudgetStatus> statuses;

  const BudgetSummary(this.statuses);

  bool get isEmpty => statuses.isEmpty;

  double get totalLimit =>
      statuses.fold(0.0, (sum, s) => sum + s.limit);

  double get totalSpent =>
      statuses.fold(0.0, (sum, s) => sum + s.spent);

  /// Left across every cap, floored at zero.
  double get totalAvailable =>
      statuses.fold(0.0, (sum, s) => sum + s.available);

  /// Total overspend across the caps that were exceeded.
  double get totalOverspent =>
      statuses.fold(0.0, (sum, s) => sum + s.overspent);

  /// What the user did NOT spend of the caps they respected — the "ahorraste"
  /// figure. Caps that were blown contribute nothing here, they show up in
  /// [totalOverspent] instead.
  double get totalSaved => totalAvailable;

  List<BudgetStatus> get over => statuses.where((s) => s.isOver).toList();
  List<BudgetStatus> get nearLimit =>
      statuses.where((s) => s.isNearLimit).toList();

  /// The cap in the most trouble, for a one-line summary.
  BudgetStatus? get worst {
    if (statuses.isEmpty) return null;
    final sorted = [...statuses]
      ..sort((a, b) => b.progress.compareTo(a.progress));
    return sorted.first;
  }

  @override
  List<Object?> get props => [statuses];
}
