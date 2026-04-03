import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/domain/usecases/get_accounts.dart';
import 'dashboard_state.dart';

@injectable
class DashboardCubit extends Cubit<DashboardState> {
  final GetAccounts _getAccounts;
  StreamSubscription<List<Account>>? _accountsSub;

  DashboardCubit(this._getAccounts) : super(const DashboardState.initial());

  void load(String userId) {
    emit(const DashboardState.loading());
    _accountsSub?.cancel();
    _accountsSub = _getAccounts.watch(userId).listen(
      (accounts) {
        final totalBalance = accounts.fold(0.0, (sum, a) => sum + a.netBalance);
        emit(DashboardState.loaded(
          accounts: accounts,
          totalBalance: totalBalance,
        ));
      },
      onError: (e) => emit(DashboardState.error(e.toString())),
    );
  }

  @override
  Future<void> close() {
    _accountsSub?.cancel();
    return super.close();
  }
}
