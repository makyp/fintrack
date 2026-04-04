// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

import 'package:cloud_firestore/cloud_firestore.dart' as _i974;
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:firebase_storage/firebase_storage.dart' as _i457;
import 'package:get_it/get_it.dart' as _i174;
import 'package:google_sign_in/google_sign_in.dart' as _i116;
import 'package:injectable/injectable.dart' as _i526;
import 'package:uuid/uuid.dart' as _i706;

import '../../features/accounts/data/datasources/account_remote_datasource.dart' as _i801;
import '../../features/accounts/data/repositories/account_repository_impl.dart' as _i802;
import '../../features/accounts/domain/repositories/account_repository.dart' as _i803;
import '../../features/accounts/domain/usecases/add_account.dart' as _i804;
import '../../features/accounts/domain/usecases/get_accounts.dart' as _i805;
import '../../features/accounts/domain/usecases/update_account.dart' as _i806;
import '../../features/accounts/presentation/cubit/accounts_cubit.dart' as _i807;
import '../../features/transactions/data/datasources/transaction_remote_datasource.dart' as _i903;
import '../../features/transactions/data/repositories/transaction_repository_impl.dart' as _i904;
import '../../features/transactions/domain/repositories/transaction_repository.dart' as _i905;
import '../../features/transactions/domain/usecases/add_transaction.dart' as _i906;
import '../../features/transactions/domain/usecases/get_transactions.dart' as _i907;
import '../../features/transactions/domain/usecases/update_transaction.dart' as _i908;
import '../../features/transactions/presentation/bloc/transactions_bloc.dart' as _i909;
import '../../features/transactions/data/datasources/recurring_transaction_datasource.dart' as _i910;
import '../../features/transactions/data/repositories/recurring_transaction_repository_impl.dart' as _i911;
import '../../features/transactions/domain/repositories/recurring_transaction_repository.dart' as _i912;
import '../../features/transactions/domain/usecases/get_recurring_transactions.dart' as _i913;
import '../../features/transactions/domain/usecases/add_recurring_transaction.dart' as _i914;
import '../../features/transactions/domain/usecases/update_recurring_transaction.dart' as _i915;
import '../../features/transactions/presentation/cubit/recurring_cubit.dart' as _i916;
import '../../features/auth/data/datasources/auth_remote_datasource.dart' as _i441;
import '../../features/auth/data/datasources/google_sign_in_module.dart' as _i860;
import '../../features/auth/data/repositories/auth_repository_impl.dart' as _i738;
import '../../features/auth/domain/repositories/auth_repository.dart' as _i305;
import '../../features/auth/domain/usecases/register_with_email.dart' as _i512;
import '../../features/auth/domain/usecases/send_password_reset.dart' as _i296;
import '../../features/auth/domain/usecases/sign_in_with_email.dart' as _i1;
import '../../features/auth/domain/usecases/sign_in_with_google.dart' as _i614;
import '../../features/auth/domain/usecases/sign_out.dart' as _i812;
import '../../features/auth/presentation/bloc/auth_bloc.dart' as _i847;
import '../../features/dashboard/presentation/cubit/dashboard_cubit.dart' as _i901;
import '../../features/onboarding/domain/onboarding_service.dart' as _i902;
import 'firebase_module.dart' as _i343;
import 'uuid_module.dart' as _i344;

extension GetItInjectableX on _i174.GetIt {
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);

    // ── Modules ──────────────────────────────────────────
    final firebaseModule = _$FirebaseModule();
    final googleSignInModule = _$GoogleSignInModule();
    final uuidModule = _$UuidModule();

    // ── Primitives ────────────────────────────────────────
    gh.lazySingleton<_i59.FirebaseAuth>(() => firebaseModule.firebaseAuth);
    gh.lazySingleton<_i974.FirebaseFirestore>(() => firebaseModule.firestore);
    gh.lazySingleton<_i457.FirebaseStorage>(() => firebaseModule.firebaseStorage);
    gh.lazySingleton<_i116.GoogleSignIn>(() => googleSignInModule.googleSignIn);
    gh.lazySingleton<_i706.Uuid>(() => uuidModule.uuid);

    // ── Auth ──────────────────────────────────────────────
    gh.lazySingleton<_i441.AuthRemoteDataSource>(
      () => _i441.AuthRemoteDataSourceImpl(
        gh<_i59.FirebaseAuth>(),
        gh<_i974.FirebaseFirestore>(),
        gh<_i116.GoogleSignIn>(),
      ),
    );
    gh.lazySingleton<_i305.AuthRepository>(
      () => _i738.AuthRepositoryImpl(gh<_i441.AuthRemoteDataSource>()),
    );
    gh.lazySingleton<_i1.SignInWithEmail>(
        () => _i1.SignInWithEmail(gh<_i305.AuthRepository>()));
    gh.lazySingleton<_i614.SignInWithGoogle>(
        () => _i614.SignInWithGoogle(gh<_i305.AuthRepository>()));
    gh.lazySingleton<_i512.RegisterWithEmail>(
        () => _i512.RegisterWithEmail(gh<_i305.AuthRepository>()));
    gh.lazySingleton<_i296.SendPasswordReset>(
        () => _i296.SendPasswordReset(gh<_i305.AuthRepository>()));
    gh.lazySingleton<_i812.SignOut>(
        () => _i812.SignOut(gh<_i305.AuthRepository>()));
    gh.lazySingleton<_i847.AuthBloc>(
      () => _i847.AuthBloc(
        gh<_i305.AuthRepository>(),
        gh<_i1.SignInWithEmail>(),
        gh<_i614.SignInWithGoogle>(),
        gh<_i512.RegisterWithEmail>(),
        gh<_i296.SendPasswordReset>(),
        gh<_i812.SignOut>(),
      ),
    );

    // ── Accounts ──────────────────────────────────────────
    gh.lazySingleton<_i801.AccountRemoteDataSource>(
      () => _i801.AccountRemoteDataSourceImpl(
        gh<_i974.FirebaseFirestore>(),
        gh<_i706.Uuid>(),
      ),
    );
    gh.lazySingleton<_i803.AccountRepository>(
      () => _i802.AccountRepositoryImpl(gh<_i801.AccountRemoteDataSource>()),
    );
    gh.lazySingleton<_i805.GetAccounts>(
        () => _i805.GetAccounts(gh<_i803.AccountRepository>()));
    gh.lazySingleton<_i804.AddAccount>(
        () => _i804.AddAccount(gh<_i803.AccountRepository>()));
    gh.lazySingleton<_i806.UpdateAccount>(
        () => _i806.UpdateAccount(gh<_i803.AccountRepository>()));
    gh.factory<_i807.AccountsCubit>(
      () => _i807.AccountsCubit(
        gh<_i805.GetAccounts>(),
        gh<_i804.AddAccount>(),
        gh<_i806.UpdateAccount>(),
      ),
    );

    // ── Dashboard ─────────────────────────────────────────
    gh.factory<_i901.DashboardCubit>(
        () => _i901.DashboardCubit(gh<_i805.GetAccounts>()));

    // ── Transactions ─────────────────────────────────────
    gh.lazySingleton<_i903.TransactionRemoteDataSource>(
      () => _i903.TransactionRemoteDataSourceImpl(
        gh<_i974.FirebaseFirestore>(),
        gh<_i706.Uuid>(),
      ),
    );
    gh.lazySingleton<_i905.TransactionRepository>(
      () => _i904.TransactionRepositoryImpl(gh<_i903.TransactionRemoteDataSource>()),
    );
    gh.lazySingleton<_i906.AddTransaction>(
        () => _i906.AddTransaction(gh<_i905.TransactionRepository>()));
    gh.lazySingleton<_i907.GetTransactions>(
        () => _i907.GetTransactions(gh<_i905.TransactionRepository>()));
    gh.lazySingleton<_i908.UpdateTransaction>(
        () => _i908.UpdateTransaction(gh<_i905.TransactionRepository>()));
    gh.factory<_i909.TransactionsBloc>(
      () => _i909.TransactionsBloc(
        gh<_i907.GetTransactions>(),
        gh<_i906.AddTransaction>(),
        gh<_i908.UpdateTransaction>(),
      ),
    );

    // ── Recurring Transactions ───────────────────────────
    gh.lazySingleton<_i910.RecurringTransactionDataSource>(
      () => _i910.RecurringTransactionDataSourceImpl(
        gh<_i974.FirebaseFirestore>(),
        gh<_i706.Uuid>(),
      ),
    );
    gh.lazySingleton<_i912.RecurringTransactionRepository>(
      () => _i911.RecurringTransactionRepositoryImpl(
        gh<_i910.RecurringTransactionDataSource>(),
      ),
    );
    gh.lazySingleton<_i913.GetRecurringTransactions>(
        () => _i913.GetRecurringTransactions(gh<_i912.RecurringTransactionRepository>()));
    gh.lazySingleton<_i914.AddRecurringTransaction>(
        () => _i914.AddRecurringTransaction(gh<_i912.RecurringTransactionRepository>()));
    gh.lazySingleton<_i915.UpdateRecurringTransaction>(
        () => _i915.UpdateRecurringTransaction(gh<_i912.RecurringTransactionRepository>()));
    gh.factory<_i916.RecurringCubit>(
      () => _i916.RecurringCubit(
        gh<_i913.GetRecurringTransactions>(),
        gh<_i914.AddRecurringTransaction>(),
        gh<_i915.UpdateRecurringTransaction>(),
      ),
    );

    // ── Onboarding ────────────────────────────────────────
    gh.lazySingleton<_i902.OnboardingService>(
      () => _i902.OnboardingService(
        gh<_i974.FirebaseFirestore>(),
        gh<_i706.Uuid>(),
      ),
    );

    return this;
  }
}

class _$FirebaseModule extends _i343.FirebaseModule {}
class _$GoogleSignInModule extends _i860.GoogleSignInModule {}
class _$UuidModule extends _i344.UuidModule {}
