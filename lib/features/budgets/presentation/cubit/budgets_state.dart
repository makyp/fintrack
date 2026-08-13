import 'package:equatable/equatable.dart';

import '../../domain/entities/budget.dart';

enum BudgetsStatus { initial, loading, loaded, error }

class BudgetsState extends Equatable {
  final BudgetsStatus status;
  final List<Budget> budgets;

  /// Caps measured against this month's spending. Empty until the spending
  /// snapshot has been loaded at least once.
  final BudgetSummary summary;
  final String? errorMessage;

  const BudgetsState._({
    required this.status,
    this.budgets = const [],
    this.summary = const BudgetSummary([]),
    this.errorMessage,
  });

  const BudgetsState.initial() : this._(status: BudgetsStatus.initial);
  const BudgetsState.loading() : this._(status: BudgetsStatus.loading);
  const BudgetsState.loaded({
    required List<Budget> budgets,
    required BudgetSummary summary,
  }) : this._(
            status: BudgetsStatus.loaded, budgets: budgets, summary: summary);
  const BudgetsState.error(String message)
      : this._(status: BudgetsStatus.error, errorMessage: message);

  bool get isLoading => status == BudgetsStatus.loading;
  bool get isLoaded => status == BudgetsStatus.loaded;
  bool get hasBudgets => budgets.isNotEmpty;

  double? limitFor(String categoryId) {
    for (final b in budgets) {
      if (b.categoryId == categoryId) return b.amount;
    }
    return null;
  }

  @override
  List<Object?> get props => [status, budgets, summary, errorMessage];
}
