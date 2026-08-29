part of 'shared_expenses_cubit.dart';

enum SharedExpensesStatus { initial, loading, loaded, error }

class SharedExpensesState extends Equatable {
  final SharedExpensesStatus status;
  final List<SharedExpense> expenses;
  final List<Settlement> settlements;
  final List<MemberBalance> balances;

  /// The payments that would clear every balance.
  final List<Transfer> transfers;
  final String? errorMessage;

  const SharedExpensesState._({
    required this.status,
    this.expenses = const [],
    this.settlements = const [],
    this.balances = const [],
    this.transfers = const [],
    this.errorMessage,
  });

  const SharedExpensesState.initial()
      : this._(status: SharedExpensesStatus.initial);
  const SharedExpensesState.loading()
      : this._(status: SharedExpensesStatus.loading);
  const SharedExpensesState.loaded({
    required List<SharedExpense> expenses,
    required List<Settlement> settlements,
    required List<MemberBalance> balances,
    required List<Transfer> transfers,
  }) : this._(
          status: SharedExpensesStatus.loaded,
          expenses: expenses,
          settlements: settlements,
          balances: balances,
          transfers: transfers,
        );
  const SharedExpensesState.error(String message)
      : this._(status: SharedExpensesStatus.error, errorMessage: message);

  bool get isLoading => status == SharedExpensesStatus.loading;
  bool get isLoaded => status == SharedExpensesStatus.loaded;
  bool get isSettled => transfers.isEmpty;

  double balanceOf(String uid) => balances
      .firstWhere((b) => b.uid == uid, orElse: () => MemberBalance(uid, 0))
      .net;

  @override
  List<Object?> get props =>
      [status, expenses, settlements, balances, transfers, errorMessage];
}
