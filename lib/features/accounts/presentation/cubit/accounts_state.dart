import 'package:equatable/equatable.dart';
import '../../../../core/domain/currency_registry.dart';
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

  /// Net worth in the user's base currency. Accounts in a currency with no
  /// rate yet are excluded and listed in [missingRates].
  ConsolidatedAmount get consolidated =>
      (accounts ?? const <Account>[]).consolidatedNet;

  double get totalBalance => consolidated.amount;

  List<String> get missingRates => consolidated.missingRates;

  List<Account> get activeAccounts =>
      accounts?.where((a) => !a.isArchived).toList() ?? [];

  @override
  List<Object?> get props => [status, accounts, errorMessage];
}
