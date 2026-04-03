import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/shell/presentation/pages/app_shell.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/transactions/presentation/pages/transactions_page.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/goals/presentation/pages/goals_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/accounts/presentation/pages/add_account_page.dart';
import '../di/injection.dart';

class AppRouter {
  static GoRouter buildRouter() {
    final authBloc = getIt<AuthBloc>();

    return GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final authState = authBloc.state;
        final isAuthRoute = state.matchedLocation.startsWith('/login') ||
            state.matchedLocation.startsWith('/register') ||
            state.matchedLocation.startsWith('/forgot-password');
        final isOnboarding = state.matchedLocation.startsWith('/onboarding');

        if (authState.status == AuthStatus.initial ||
            authState.status == AuthStatus.loading) {
          return null;
        }

        if (authState.isUnauthenticated && !isAuthRoute) {
          return '/login';
        }

        if (authState.isAuthenticated) {
          if (authState.user?.onboardingCompleted == false && !isOnboarding) {
            return '/onboarding';
          }
          if (isAuthRoute ||
              (isOnboarding && authState.user?.onboardingCompleted == true)) {
            return '/';
          }
        }
        return null;
      },
      refreshListenable: _AuthStateNotifier(authBloc),
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
        GoRoute(
            path: '/forgot-password',
            builder: (_, __) => const ForgotPasswordPage()),
        GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPage()),
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => const DashboardPage(),
            ),
            GoRoute(
              path: '/transactions',
              builder: (_, __) => const TransactionsPage(),
            ),
            GoRoute(
              path: '/transactions/new',
              builder: (_, state) {
                // type query param: expense, income, transfer
                return const TransactionsPage();
              },
            ),
            GoRoute(
              path: '/reports',
              builder: (_, __) => const ReportsPage(),
            ),
            GoRoute(
              path: '/goals',
              builder: (_, __) => const GoalsPage(),
            ),
            GoRoute(
              path: '/profile',
              builder: (_, __) => const ProfilePage(),
            ),
            GoRoute(
              path: '/accounts/new',
              builder: (_, state) =>
                  AddAccountPage(editAccount: null),
            ),
            GoRoute(
              path: '/accounts/:id/edit',
              builder: (_, state) {
                final extra = state.extra as Map<String, dynamic>?;
                return AddAccountPage(
                  editAccount: extra?['account'],
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _AuthStateNotifier extends ChangeNotifier {
  final AuthBloc _bloc;
  _AuthStateNotifier(this._bloc) {
    _bloc.stream.listen((_) => notifyListeners());
  }
}
