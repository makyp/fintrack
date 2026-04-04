part of 'recurring_cubit.dart';

enum RecurringStatus { initial, loading, loaded, error }

class RecurringState extends Equatable {
  final RecurringStatus status;
  final List<RecurringTransaction> items;
  final String? errorMessage;

  const RecurringState._({
    required this.status,
    this.items = const [],
    this.errorMessage,
  });

  const RecurringState.initial() : this._(status: RecurringStatus.initial);
  const RecurringState.loading() : this._(status: RecurringStatus.loading);
  const RecurringState.loaded(List<RecurringTransaction> items)
      : this._(status: RecurringStatus.loaded, items: items);
  const RecurringState.error(String msg)
      : this._(status: RecurringStatus.error, errorMessage: msg);

  bool get isLoading => status == RecurringStatus.loading;

  @override
  List<Object?> get props => [status, items, errorMessage];
}
