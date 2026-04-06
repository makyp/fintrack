part of 'debts_cubit.dart';

enum DebtsStatus { initial, loading, loaded, error }

class DebtsState extends Equatable {
  final DebtsStatus status;
  final List<Debt> debts;
  final String? errorMessage;

  const DebtsState._({
    required this.status,
    this.debts = const [],
    this.errorMessage,
  });

  const DebtsState.initial() : this._(status: DebtsStatus.initial);
  const DebtsState.loading() : this._(status: DebtsStatus.loading);
  const DebtsState.loaded(List<Debt> debts)
      : this._(status: DebtsStatus.loaded, debts: debts);
  const DebtsState.error(String message)
      : this._(status: DebtsStatus.error, errorMessage: message);

  bool get isLoading => status == DebtsStatus.loading;

  @override
  List<Object?> get props => [status, debts, errorMessage];
}
