import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fintrack/core/utils/either.dart';
import 'package:fintrack/core/errors/failures.dart';
import 'package:fintrack/features/auth/domain/entities/app_user.dart';
import 'package:fintrack/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintrack/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:fintrack/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:fintrack/features/auth/domain/usecases/register_with_email.dart';
import 'package:fintrack/features/auth/domain/usecases/send_password_reset.dart';
import 'package:fintrack/features/auth/domain/usecases/sign_out.dart';
import 'package:fintrack/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:fintrack/features/auth/presentation/bloc/auth_event.dart';
import 'package:fintrack/features/auth/presentation/bloc/auth_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSignInWithEmail extends Mock implements SignInWithEmail {}

class MockSignInWithGoogle extends Mock implements SignInWithGoogle {}

class MockRegisterWithEmail extends Mock implements RegisterWithEmail {}

class MockSendPasswordReset extends Mock implements SendPasswordReset {}

class MockSignOut extends Mock implements SignOut {}

void main() {
  late MockAuthRepository repository;
  late StreamController<AppUser?> authStream;
  late AuthBloc bloc;

  final tUser = AppUser(
    uid: 'u1',
    email: 'a@b.com',
    displayName: 'Test',
    createdAt: DateTime(2026, 1, 1),
    onboardingCompleted: true,
  );

  AuthBloc buildBloc() => AuthBloc(
        repository,
        MockSignInWithEmail(),
        MockSignInWithGoogle(),
        MockRegisterWithEmail(),
        MockSendPasswordReset(),
        MockSignOut(),
      );

  setUp(() {
    repository = MockAuthRepository();
    authStream = StreamController<AppUser?>.broadcast();
    when(() => repository.authStateChanges).thenAnswer((_) => authStream.stream);
  });

  tearDown(() async {
    await authStream.close();
    await bloc.close();
  });

  test(
      'Android cold start: stream emits null FIRST then the persisted user -> '
      'ends authenticated and NEVER emits a premature unauthenticated',
      () async {
    // Cold start: FirebaseAuth.currentUser is null at this instant (the
    // persisted session has not been hydrated yet).
    when(() => repository.currentUser).thenReturn(null);

    final emitted = <AuthState>[];
    bloc = buildBloc();
    final sub = bloc.stream.listen(emitted.add);

    bloc.add(const AuthStarted());
    await Future.delayed(const Duration(milliseconds: 50));

    // 1) Firebase fires the spurious cold-start null.
    authStream.add(null);
    await Future.delayed(const Duration(milliseconds: 100));

    // The grace timer is pending: we must NOT have concluded unauthenticated.
    expect(bloc.state.isUnauthenticated, isFalse,
        reason: 'first null must be held, not treated as sign-out');

    // 2) The real persisted user arrives a moment later.
    authStream.add(tUser);
    await Future.delayed(const Duration(milliseconds: 100));

    expect(bloc.state.isAuthenticated, isTrue);
    expect(bloc.state.user, tUser);
    expect(emitted.where((s) => s.isUnauthenticated), isEmpty,
        reason: 'user should never have seen the login page');

    await sub.cancel();
  });

  test(
      'genuine no session: first null with no currentUser -> unauthenticated '
      'after the grace period elapses', () async {
    when(() => repository.currentUser).thenReturn(null);

    bloc = buildBloc();
    bloc.add(const AuthStarted());
    await Future.delayed(const Duration(milliseconds: 50));

    authStream.add(null);

    // Before the grace period: still not unauthenticated.
    await Future.delayed(const Duration(milliseconds: 100));
    expect(bloc.state.isUnauthenticated, isFalse);

    // After the 3s grace period with still no user: now unauthenticated.
    await Future.delayed(const Duration(seconds: 3, milliseconds: 200));
    expect(bloc.state.isUnauthenticated, isTrue);
  });

  test(
      'sign-out after being authenticated: later null is acted on immediately, '
      'no 3s wait', () async {
    when(() => repository.currentUser).thenReturn(null);

    bloc = buildBloc();
    bloc.add(const AuthStarted());
    await Future.delayed(const Duration(milliseconds: 50));

    authStream.add(tUser);
    await Future.delayed(const Duration(milliseconds: 100));
    expect(bloc.state.isAuthenticated, isTrue);

    // Real sign-out: stream null AND currentUser null, but we've already seen
    // a real event -> must go unauthenticated right away.
    authStream.add(null);
    await Future.delayed(const Duration(milliseconds: 100));
    expect(bloc.state.isUnauthenticated, isTrue);
  });
}
