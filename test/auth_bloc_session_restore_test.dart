import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fintrack/core/services/session_hint.dart';
import 'package:fintrack/core/utils/either.dart';
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
  TestWidgetsFlutterBinding.ensureInitialized();

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

  /// [hadSession] simulates a device where the user had signed in before, which
  /// is what makes AuthBloc wait longer for a slow restore.
  void primeStorage({bool hadSession = false}) {
    SharedPreferences.setMockInitialValues({'had_session': hadSession});
    SessionHint.resetCacheForTest();
  }

  setUp(() {
    primeStorage();
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

  test(
      'REPEATED cold-start nulls: a second null must not end the grace window '
      'and send the user to login', () async {
    // Firebase can emit the pre-restore null more than once. Before the fix the
    // second one cancelled the timer and was treated as a sign-out.
    when(() => repository.currentUser).thenReturn(null);

    final emitted = <AuthState>[];
    bloc = buildBloc();
    final sub = bloc.stream.listen(emitted.add);

    bloc.add(const AuthStarted());
    await Future.delayed(const Duration(milliseconds: 50));

    authStream.add(null);
    await Future.delayed(const Duration(milliseconds: 100));
    authStream.add(null);
    await Future.delayed(const Duration(milliseconds: 100));
    authStream.add(null);
    await Future.delayed(const Duration(milliseconds: 100));

    expect(bloc.state.isUnauthenticated, isFalse,
        reason: 'repeated pre-restore nulls are still not a sign-out');

    // The persisted user finally arrives.
    authStream.add(tUser);
    await Future.delayed(const Duration(milliseconds: 100));

    expect(bloc.state.isAuthenticated, isTrue);
    expect(emitted.where((s) => s.isUnauthenticated), isEmpty,
        reason: 'user should never have seen the login page');

    await sub.cancel();
  });

  test(
      'silent restore: no further stream event, but currentUser hydrates -> '
      'the grace poll picks it up and authenticates', () async {
    // The stream stays quiet after the first null; only currentUser fills in.
    when(() => repository.currentUser).thenReturn(null);
    when(() => repository.getCurrentUserProfile())
        .thenAnswer((_) async => Either.right(tUser));

    final emitted = <AuthState>[];
    bloc = buildBloc();
    final sub = bloc.stream.listen(emitted.add);

    bloc.add(const AuthStarted());
    await Future.delayed(const Duration(milliseconds: 50));

    authStream.add(null);
    await Future.delayed(const Duration(milliseconds: 400));

    // Firebase finishes hydrating without emitting anything.
    when(() => repository.currentUser).thenReturn(tUser);
    await Future.delayed(const Duration(milliseconds: 600));

    expect(bloc.state.isAuthenticated, isTrue);
    expect(emitted.where((s) => s.isUnauthenticated), isEmpty);

    await sub.cancel();
  });

  test(
      'device that had a session waits longer: a restore at ~4s still lands on '
      'the dashboard instead of login', () async {
    primeStorage(hadSession: true);
    when(() => repository.currentUser).thenReturn(null);

    final emitted = <AuthState>[];
    bloc = buildBloc();
    final sub = bloc.stream.listen(emitted.add);

    bloc.add(const AuthStarted());
    await Future.delayed(const Duration(milliseconds: 50));

    authStream.add(null);

    // Past the 3s window used when no session was ever recorded.
    await Future.delayed(const Duration(seconds: 4));
    expect(bloc.state.isUnauthenticated, isFalse,
        reason: 'the hint says a session exists — keep waiting');

    authStream.add(tUser);
    await Future.delayed(const Duration(milliseconds: 100));

    expect(bloc.state.isAuthenticated, isTrue);
    expect(emitted.where((s) => s.isUnauthenticated), isEmpty);

    await sub.cancel();
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('a fresh device (no hint) is not made to wait the long window',
      () async {
    primeStorage(hadSession: false);
    when(() => repository.currentUser).thenReturn(null);

    bloc = buildBloc();
    bloc.add(const AuthStarted());
    await Future.delayed(const Duration(milliseconds: 50));

    authStream.add(null);
    await Future.delayed(const Duration(seconds: 3, milliseconds: 500));

    expect(bloc.state.isUnauthenticated, isTrue,
        reason: 'never signed in here — show login promptly');
  }, timeout: const Timeout(Duration(seconds: 30)));
}
