// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:cloud_firestore/cloud_firestore.dart' as _i974;
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:firebase_storage/firebase_storage.dart' as _i457;
import 'package:get_it/get_it.dart' as _i174;
import 'package:google_sign_in/google_sign_in.dart' as _i116;
import 'package:injectable/injectable.dart' as _i526;
import 'package:uuid/uuid.dart' as _i706;

import '../../features/accounts/data/datasources/account_remote_datasource.dart'
    as _i613;
import '../../features/accounts/data/repositories/account_repository_impl.dart'
    as _i126;
import '../../features/accounts/domain/repositories/account_repository.dart'
    as _i706;
import '../../features/accounts/domain/usecases/add_account.dart' as _i583;
import '../../features/accounts/domain/usecases/get_accounts.dart' as _i473;
import '../../features/accounts/domain/usecases/update_account.dart' as _i770;
import '../../features/accounts/presentation/cubit/accounts_cubit.dart' as _i43;
import '../../features/auth/data/datasources/auth_remote_datasource.dart'
    as _i161;
import '../../features/auth/data/datasources/google_sign_in_module.dart'
    as _i508;
import '../../features/auth/data/repositories/auth_repository_impl.dart'
    as _i153;
import '../../features/auth/domain/repositories/auth_repository.dart' as _i787;
import '../../features/auth/domain/usecases/register_with_email.dart' as _i298;
import '../../features/auth/domain/usecases/send_password_reset.dart' as _i174;
import '../../features/auth/domain/usecases/sign_in_with_email.dart' as _i485;
import '../../features/auth/domain/usecases/sign_in_with_google.dart' as _i692;
import '../../features/auth/domain/usecases/sign_out.dart' as _i568;
import '../../features/auth/presentation/bloc/auth_bloc.dart' as _i797;
import '../../features/budgets/data/budget_alert_service.dart' as _i31;
import '../../features/budgets/data/datasources/budget_datasource.dart'
    as _i455;
import '../../features/budgets/presentation/cubit/budgets_cubit.dart' as _i1056;
import '../../features/categories/data/datasources/category_datasource.dart'
    as _i555;
import '../../features/categories/presentation/cubit/categories_cubit.dart'
    as _i802;
import '../../features/dashboard/presentation/cubit/dashboard_cubit.dart'
    as _i24;
import '../../features/debts/data/datasources/debt_datasource.dart' as _i580;
import '../../features/gamification/data/datasources/gamification_datasource.dart'
    as _i625;
import '../../features/gamification/data/repositories/gamification_repository_impl.dart'
    as _i358;
import '../../features/gamification/data/services/badge_service.dart' as _i756;
import '../../features/gamification/domain/repositories/gamification_repository.dart'
    as _i97;
import '../../features/gamification/presentation/cubit/gamification_cubit.dart'
    as _i208;
import '../../features/goals/data/datasources/goal_remote_datasource.dart'
    as _i292;
import '../../features/goals/data/repositories/goal_repository_impl.dart'
    as _i942;
import '../../features/goals/domain/repositories/goal_repository.dart' as _i112;
import '../../features/goals/domain/usecases/add_contribution.dart' as _i990;
import '../../features/goals/domain/usecases/add_goal.dart' as _i178;
import '../../features/goals/domain/usecases/delete_goal.dart' as _i471;
import '../../features/goals/domain/usecases/get_goals.dart' as _i750;
import '../../features/goals/domain/usecases/update_goal.dart' as _i951;
import '../../features/goals/presentation/cubit/goals_cubit.dart' as _i154;
import '../../features/household/data/datasources/household_datasource.dart'
    as _i635;
import '../../features/household/data/repositories/household_repository_impl.dart'
    as _i244;
import '../../features/household/domain/repositories/household_repository.dart'
    as _i385;
import '../../features/household/presentation/cubit/household_cubit.dart'
    as _i812;
import '../../features/notifications/presentation/cubit/notifications_cubit.dart'
    as _i405;
import '../../features/onboarding/domain/onboarding_service.dart' as _i720;
import '../../features/reports/data/datasources/reports_datasource.dart'
    as _i112;
import '../../features/reports/presentation/cubit/reports_cubit.dart' as _i671;
import '../../features/transactions/data/datasources/recurring_transaction_datasource.dart'
    as _i701;
import '../../features/transactions/data/datasources/transaction_remote_datasource.dart'
    as _i634;
import '../../features/transactions/data/repositories/recurring_transaction_repository_impl.dart'
    as _i974;
import '../../features/transactions/data/repositories/transaction_repository_impl.dart'
    as _i443;
import '../../features/transactions/domain/repositories/recurring_transaction_repository.dart'
    as _i54;
import '../../features/transactions/domain/repositories/transaction_repository.dart'
    as _i421;
import '../../features/transactions/domain/usecases/add_recurring_transaction.dart'
    as _i195;
import '../../features/transactions/domain/usecases/add_transaction.dart'
    as _i5;
import '../../features/transactions/domain/usecases/get_recurring_transactions.dart'
    as _i964;
import '../../features/transactions/domain/usecases/get_transactions.dart'
    as _i439;
import '../../features/transactions/domain/usecases/update_recurring_transaction.dart'
    as _i553;
import '../../features/transactions/domain/usecases/update_transaction.dart'
    as _i373;
import '../../features/transactions/presentation/bloc/transactions_bloc.dart'
    as _i439;
import '../../features/transactions/presentation/cubit/recurring_cubit.dart'
    as _i578;
import '../services/app_startup_service.dart' as _i25;
import 'firebase_module.dart' as _i616;
import 'uuid_module.dart' as _i78;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final firebaseModule = _$FirebaseModule();
    final uuidModule = _$UuidModule();
    final googleSignInModule = _$GoogleSignInModule();
    gh.lazySingleton<_i59.FirebaseAuth>(() => firebaseModule.firebaseAuth);
    gh.lazySingleton<_i974.FirebaseFirestore>(() => firebaseModule.firestore);
    gh.lazySingleton<_i457.FirebaseStorage>(
        () => firebaseModule.firebaseStorage);
    gh.lazySingleton<_i706.Uuid>(() => uuidModule.uuid);
    gh.lazySingleton<_i116.GoogleSignIn>(() => googleSignInModule.googleSignIn);
    gh.lazySingleton<_i161.AuthRemoteDataSource>(
        () => _i161.AuthRemoteDataSourceImpl(
              gh<_i59.FirebaseAuth>(),
              gh<_i974.FirebaseFirestore>(),
              gh<_i116.GoogleSignIn>(),
            ));
    gh.lazySingleton<_i756.BadgeService>(
        () => _i756.BadgeService(gh<_i974.FirebaseFirestore>()));
    gh.lazySingleton<_i635.HouseholdDataSource>(
        () => _i635.HouseholdDataSource(gh<_i974.FirebaseFirestore>()));
    gh.lazySingleton<_i112.ReportsDataSource>(
        () => _i112.ReportsDataSource(gh<_i974.FirebaseFirestore>()));
    gh.lazySingleton<_i625.GamificationDataSource>(
        () => _i625.GamificationDataSourceImpl(gh<_i974.FirebaseFirestore>()));
    gh.lazySingleton<_i634.TransactionRemoteDataSource>(
        () => _i634.TransactionRemoteDataSourceImpl(
              gh<_i974.FirebaseFirestore>(),
              gh<_i706.Uuid>(),
              gh<_i756.BadgeService>(),
            ));
    gh.lazySingleton<_i25.AppStartupService>(() => _i25.AppStartupService(
          gh<_i974.FirebaseFirestore>(),
          gh<_i706.Uuid>(),
        ));
    gh.lazySingleton<_i385.HouseholdRepository>(
        () => _i244.HouseholdRepositoryImpl(gh<_i635.HouseholdDataSource>()));
    gh.lazySingleton<_i701.RecurringTransactionDataSource>(
        () => _i701.RecurringTransactionDataSourceImpl(
              gh<_i974.FirebaseFirestore>(),
              gh<_i706.Uuid>(),
            ));
    gh.lazySingleton<_i580.DebtDataSource>(() => _i580.DebtDataSource(
          gh<_i974.FirebaseFirestore>(),
          gh<_i706.Uuid>(),
        ));
    gh.lazySingleton<_i720.OnboardingService>(() => _i720.OnboardingService(
          gh<_i974.FirebaseFirestore>(),
          gh<_i706.Uuid>(),
        ));
    gh.lazySingleton<_i455.BudgetDataSource>(
        () => _i455.BudgetDataSourceImpl(gh<_i974.FirebaseFirestore>()));
    gh.factory<_i405.NotificationsCubit>(
        () => _i405.NotificationsCubit(gh<_i974.FirebaseFirestore>()));
    gh.lazySingleton<_i555.CategoryDataSource>(
        () => _i555.CategoryDataSourceImpl(gh<_i974.FirebaseFirestore>()));
    gh.lazySingleton<_i292.GoalRemoteDataSource>(
        () => _i292.GoalRemoteDataSourceImpl(
              gh<_i974.FirebaseFirestore>(),
              gh<_i706.Uuid>(),
            ));
    gh.lazySingleton<_i802.CategoriesCubit>(() => _i802.CategoriesCubit(
          gh<_i555.CategoryDataSource>(),
          gh<_i706.Uuid>(),
        ));
    gh.lazySingleton<_i613.AccountRemoteDataSource>(
        () => _i613.AccountRemoteDataSourceImpl(
              gh<_i974.FirebaseFirestore>(),
              gh<_i706.Uuid>(),
            ));
    gh.lazySingleton<_i421.TransactionRepository>(() =>
        _i443.TransactionRepositoryImpl(
            gh<_i634.TransactionRemoteDataSource>()));
    gh.factory<_i812.HouseholdCubit>(
        () => _i812.HouseholdCubit(gh<_i385.HouseholdRepository>()));
    gh.lazySingleton<_i97.GamificationRepository>(() =>
        _i358.GamificationRepositoryImpl(gh<_i625.GamificationDataSource>()));
    gh.lazySingleton<_i31.BudgetAlertService>(() => _i31.BudgetAlertService(
          gh<_i455.BudgetDataSource>(),
          gh<_i112.ReportsDataSource>(),
        ));
    gh.lazySingleton<_i706.AccountRepository>(
        () => _i126.AccountRepositoryImpl(gh<_i613.AccountRemoteDataSource>()));
    gh.factory<_i671.ReportsCubit>(
        () => _i671.ReportsCubit(gh<_i112.ReportsDataSource>()));
    gh.lazySingleton<_i787.AuthRepository>(
        () => _i153.AuthRepositoryImpl(gh<_i161.AuthRemoteDataSource>()));
    gh.lazySingleton<_i54.RecurringTransactionRepository>(() =>
        _i974.RecurringTransactionRepositoryImpl(
            gh<_i701.RecurringTransactionDataSource>()));
    gh.lazySingleton<_i112.GoalRepository>(
        () => _i942.GoalRepositoryImpl(gh<_i292.GoalRemoteDataSource>()));
    gh.lazySingleton<_i298.RegisterWithEmail>(
        () => _i298.RegisterWithEmail(gh<_i787.AuthRepository>()));
    gh.lazySingleton<_i174.SendPasswordReset>(
        () => _i174.SendPasswordReset(gh<_i787.AuthRepository>()));
    gh.lazySingleton<_i485.SignInWithEmail>(
        () => _i485.SignInWithEmail(gh<_i787.AuthRepository>()));
    gh.lazySingleton<_i692.SignInWithGoogle>(
        () => _i692.SignInWithGoogle(gh<_i787.AuthRepository>()));
    gh.lazySingleton<_i568.SignOut>(
        () => _i568.SignOut(gh<_i787.AuthRepository>()));
    gh.lazySingleton<_i5.AddTransaction>(
        () => _i5.AddTransaction(gh<_i421.TransactionRepository>()));
    gh.lazySingleton<_i439.GetTransactions>(
        () => _i439.GetTransactions(gh<_i421.TransactionRepository>()));
    gh.lazySingleton<_i373.UpdateTransaction>(
        () => _i373.UpdateTransaction(gh<_i421.TransactionRepository>()));
    gh.lazySingleton<_i990.AddContribution>(
        () => _i990.AddContribution(gh<_i112.GoalRepository>()));
    gh.lazySingleton<_i178.AddGoal>(
        () => _i178.AddGoal(gh<_i112.GoalRepository>()));
    gh.lazySingleton<_i471.DeleteGoal>(
        () => _i471.DeleteGoal(gh<_i112.GoalRepository>()));
    gh.lazySingleton<_i750.GetGoals>(
        () => _i750.GetGoals(gh<_i112.GoalRepository>()));
    gh.lazySingleton<_i951.UpdateGoal>(
        () => _i951.UpdateGoal(gh<_i112.GoalRepository>()));
    gh.lazySingleton<_i1056.BudgetsCubit>(() => _i1056.BudgetsCubit(
          gh<_i455.BudgetDataSource>(),
          gh<_i112.ReportsDataSource>(),
        ));
    gh.lazySingleton<_i195.AddRecurringTransaction>(() =>
        _i195.AddRecurringTransaction(
            gh<_i54.RecurringTransactionRepository>()));
    gh.lazySingleton<_i964.GetRecurringTransactions>(() =>
        _i964.GetRecurringTransactions(
            gh<_i54.RecurringTransactionRepository>()));
    gh.lazySingleton<_i553.UpdateRecurringTransaction>(() =>
        _i553.UpdateRecurringTransaction(
            gh<_i54.RecurringTransactionRepository>()));
    gh.factory<_i208.GamificationCubit>(
        () => _i208.GamificationCubit(gh<_i97.GamificationRepository>()));
    gh.lazySingleton<_i583.AddAccount>(
        () => _i583.AddAccount(gh<_i706.AccountRepository>()));
    gh.lazySingleton<_i473.GetAccounts>(
        () => _i473.GetAccounts(gh<_i706.AccountRepository>()));
    gh.lazySingleton<_i770.UpdateAccount>(
        () => _i770.UpdateAccount(gh<_i706.AccountRepository>()));
    gh.factory<_i24.DashboardCubit>(
        () => _i24.DashboardCubit(gh<_i473.GetAccounts>()));
    gh.factory<_i439.TransactionsBloc>(() => _i439.TransactionsBloc(
          gh<_i439.GetTransactions>(),
          gh<_i5.AddTransaction>(),
          gh<_i373.UpdateTransaction>(),
          gh<_i31.BudgetAlertService>(),
        ));
    gh.lazySingleton<_i797.AuthBloc>(() => _i797.AuthBloc(
          gh<_i787.AuthRepository>(),
          gh<_i485.SignInWithEmail>(),
          gh<_i692.SignInWithGoogle>(),
          gh<_i298.RegisterWithEmail>(),
          gh<_i174.SendPasswordReset>(),
          gh<_i568.SignOut>(),
        ));
    gh.factory<_i578.RecurringCubit>(() => _i578.RecurringCubit(
          gh<_i964.GetRecurringTransactions>(),
          gh<_i195.AddRecurringTransaction>(),
          gh<_i553.UpdateRecurringTransaction>(),
        ));
    gh.factory<_i43.AccountsCubit>(() => _i43.AccountsCubit(
          gh<_i473.GetAccounts>(),
          gh<_i583.AddAccount>(),
          gh<_i770.UpdateAccount>(),
        ));
    gh.factory<_i154.GoalsCubit>(() => _i154.GoalsCubit(
          gh<_i750.GetGoals>(),
          gh<_i178.AddGoal>(),
          gh<_i951.UpdateGoal>(),
          gh<_i471.DeleteGoal>(),
          gh<_i990.AddContribution>(),
        ));
    return this;
  }
}

class _$FirebaseModule extends _i616.FirebaseModule {}

class _$UuidModule extends _i78.UuidModule {}

class _$GoogleSignInModule extends _i508.GoogleSignInModule {}
