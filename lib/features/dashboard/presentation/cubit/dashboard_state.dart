import 'package:equatable/equatable.dart';
import '../../../accounts/domain/entities/account.dart';

enum DashboardStatus { initial, loading, loaded, error }

class DashboardState extends Equatable {
  final DashboardStatus status;
  final List<Account> accounts;
  final double totalBalance;
  final String? errorMessage;

  const DashboardState._({
    required this.status,
    this.accounts = const [],
    this.totalBalance = 0,
    this.errorMessage,
  });

  const DashboardState.initial() : this._(status: DashboardStatus.initial);
  const DashboardState.loading() : this._(status: DashboardStatus.loading);
  const DashboardState.loaded({
    required List<Account> accounts,
    required double totalBalance,
  }) : this._(
          status: DashboardStatus.loaded,
          accounts: accounts,
          totalBalance: totalBalance,
        );
  const DashboardState.error(String message)
      : this._(status: DashboardStatus.error, errorMessage: message);

  bool get isLoading => status == DashboardStatus.loading;
  bool get isLoaded => status == DashboardStatus.loaded;

  @override
  List<Object?> get props => [status, accounts, totalBalance, errorMessage];
}
