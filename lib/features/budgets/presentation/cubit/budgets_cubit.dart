import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../reports/data/datasources/reports_datasource.dart';
import '../../../reports/domain/models/report_data.dart';
import '../../data/datasources/budget_datasource.dart';
import '../../data/models/budget_model.dart';
import '../../domain/budget_calculator.dart';
import '../../domain/entities/budget.dart';
import 'budgets_state.dart';

@lazySingleton
class BudgetsCubit extends Cubit<BudgetsState> {
  final BudgetDataSource _dataSource;
  final ReportsDataSource _reports;
  StreamSubscription<List<BudgetModel>>? _subscription;
  String? _userId;

  /// This month's spending per category. Cached so a change to a cap
  /// recomputes instantly without re-reading the movements.
  List<CategoryData> _spending = const [];

  BudgetsCubit(this._dataSource, this._reports)
      : super(const BudgetsState.initial());

  Future<void> watchBudgets(String userId) async {
    if (_userId != userId) {
      _userId = userId;
      _spending = const [];
      emit(const BudgetsState.loading());
    }
    _subscription?.cancel();
    _subscription = _dataSource.watchBudgets(userId).listen(
      (budgets) => _recompute(budgets),
      onError: (e) => emit(BudgetsState.error(e.toString())),
    );
    await refreshSpending();
  }

  /// Re-reads the current month's spending. Called on load and after a
  /// movement is added or edited.
  Future<void> refreshSpending() async {
    final userId = _userId;
    if (userId == null) return;
    try {
      final now = DateTime.now();
      final data = await _reports.loadReport(userId, now.year, now.month);
      _spending = data.expensesByCategory;
      _recompute(state.budgets);
    } catch (_) {
      // Keep whatever we already had rather than blanking the caps.
    }
  }

  void _recompute(List<Budget> budgets) {
    emit(BudgetsState.loaded(
      budgets: budgets,
      summary: BudgetCalculator.summarize(
        budgets: budgets,
        spendingByCategory: _spending,
      ),
    ));
  }

  Future<bool> setBudget(String categoryId, double amount) async {
    final userId = _userId;
    if (userId == null) return false;
    try {
      if (amount <= 0) {
        await _dataSource.deleteBudget(userId, categoryId);
      } else {
        await _dataSource.saveBudget(
          userId,
          BudgetModel(
            categoryId: categoryId,
            amount: amount,
            updatedAt: DateTime.now(),
          ),
        );
      }
      return true;
    } catch (e) {
      emit(BudgetsState.error(e.toString()));
      return false;
    }
  }

  Future<bool> removeBudget(String categoryId) => setBudget(categoryId, 0);

  void clear() {
    _subscription?.cancel();
    _subscription = null;
    _userId = null;
    _spending = const [];
    emit(const BudgetsState.initial());
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
