import 'package:equatable/equatable.dart';
import '../../domain/entities/account.dart';

enum AccountsStatus { initial, loading, loaded, error }

class AccountsState extends Equatable {
  final AccountsStatus status;
  final List<Account>? accounts;
  final String? errorMessage;

  const AccountsState._({
    required this.status,
    this.accounts,
    this.errorMessage,
  });

  const AccountsState.initial() : this._(status: AccountsStatus.initial);
  const AccountsState.loading() : this._(status: AccountsStatus.loading);
  const AccountsState.loaded(List<Account> accounts)
      : this._(status: AccountsStatus.loaded, accounts: accounts);
  const AccountsState.error(String message)
      : this._(status: AccountsStatus.error, errorMessage: message);

  bool get isLoading => status == AccountsStatus.loading;
  bool get isLoaded => status == AccountsStatus.loaded;

  double get totalBalance =>
      accounts?.fold<double>(0.0, (sum, a) => sum + a.netBalance) ?? 0.0;

  List<Account> get activeAccounts =>
      accounts?.where((a) => !a.isArchived).toList() ?? [];

  @override
  List<Object?> get props => [status, accounts, errorMessage];
}
