import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../data/datasources/household_datasource.dart';
import '../../domain/entities/shared_expense.dart';
import '../../domain/settlement_calculator.dart';

part 'shared_expenses_state.dart';

/// Shared expenses of one household, plus the balances they add up to.
///
/// Expenses and settlements arrive on two separate Firestore streams, so the
/// cubit holds the last value of each and recomputes the balances whenever
/// either side moves — otherwise a settlement would land with stale expenses.
@injectable
class SharedExpensesCubit extends Cubit<SharedExpensesState> {
  final HouseholdDataSource _dataSource;

  StreamSubscription<List<SharedExpense>>? _expensesSub;
  StreamSubscription<List<Settlement>>? _settlementsSub;

  String _householdId = '';
  List<String> _members = const [];
  List<SharedExpense> _expenses = const [];
  List<Settlement> _settlements = const [];

  SharedExpensesCubit(this._dataSource)
      : super(const SharedExpensesState.initial());

  void watch(String householdId, List<String> memberUids) {
    _householdId = householdId;
    _members = memberUids;
    emit(const SharedExpensesState.loading());

    _expensesSub?.cancel();
    _settlementsSub?.cancel();

    _expensesSub = _dataSource.watchSharedExpenses(householdId).listen(
      (expenses) {
        _expenses = expenses;
        _emitLoaded();
      },
      onError: (e) => emit(SharedExpensesState.error(e.toString())),
    );

    _settlementsSub = _dataSource.watchSettlements(householdId).listen(
      (settlements) {
        _settlements = settlements;
        _emitLoaded();
      },
      onError: (e) => emit(SharedExpensesState.error(e.toString())),
    );
  }

  void _emitLoaded() {
    final balances = SettlementCalculator.balances(
      members: _members,
      expenses: _expenses,
      settlements: _settlements,
    );
    emit(SharedExpensesState.loaded(
      expenses: _expenses,
      settlements: _settlements,
      balances: balances,
      transfers: SettlementCalculator.settlements(balances),
    ));
  }

  Future<void> addExpense(SharedExpense expense) =>
      _dataSource.addSharedExpense(expense);

  Future<void> deleteExpense(String expenseId) =>
      _dataSource.deleteSharedExpense(_householdId, expenseId);

  Future<void> settle(Settlement settlement) =>
      _dataSource.addSettlement(settlement);

  @override
  Future<void> close() {
    _expensesSub?.cancel();
    _settlementsSub?.cancel();
    return super.close();
  }
}
