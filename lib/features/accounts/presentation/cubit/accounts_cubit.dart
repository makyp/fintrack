import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/account.dart';
import '../../domain/usecases/get_accounts.dart';
import '../../domain/usecases/add_account.dart';
import '../../domain/usecases/update_account.dart';
import 'accounts_state.dart';

@injectable
class AccountsCubit extends Cubit<AccountsState> {
  final GetAccounts _getAccounts;
  final AddAccount _addAccount;
  final UpdateAccount _updateAccount;
  StreamSubscription<List<Account>>? _subscription;

  AccountsCubit(this._getAccounts, this._addAccount, this._updateAccount)
      : super(const AccountsState.initial());

  void watchAccounts(String userId) {
    emit(const AccountsState.loading());
    _subscription?.cancel();
    _subscription = _getAccounts.watch(userId).listen(
      (accounts) => emit(AccountsState.loaded(accounts)),
      onError: (e) => emit(AccountsState.error(e.toString())),
    );
  }

  Future<void> addAccount(Account account) async {
    final result = await _addAccount(account);
    result.fold(
      (failure) => emit(AccountsState.error(failure.message)),
      (_) {},
    );
  }

  Future<bool> updateAccount(Account account) async {
    final result = await _updateAccount(account);
    return result.fold(
      (failure) {
        emit(AccountsState.error(failure.message));
        return false;
      },
      (_) => true,
    );
  }

  Future<bool> archiveAccount(String userId, String accountId) async {
    final result = await _updateAccount.archive(userId, accountId);
    return result.fold(
      (failure) {
        emit(AccountsState.error(failure.message));
        return false;
      },
      (_) => true,
    );
  }

  double get consolidatedBalance {
    if (state.accounts == null) return 0;
    return state.accounts!.fold(0.0, (sum, a) => sum + a.netBalance);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
