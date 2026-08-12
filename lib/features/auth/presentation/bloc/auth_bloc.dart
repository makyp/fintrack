import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/services/session_hint.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/sign_in_with_email.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/register_with_email.dart';
import '../../domain/usecases/send_password_reset.dart';
import '../../domain/usecases/sign_out.dart';
import 'auth_event.dart';
import 'auth_state.dart';

@lazySingleton
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;
  final SignInWithEmail _signInWithEmail;
  final SignInWithGoogle _signInWithGoogle;
  final RegisterWithEmail _registerWithEmail;
  final SendPasswordReset _sendPasswordReset;
  final SignOut _signOut;
  StreamSubscription<AppUser?>? _authSubscription;
  Timer? _graceTimer;

  /// True once FirebaseAuth has handed us a real (non-null) user in this run.
  /// Until that happens every null is suspect on mobile; afterwards a null is a
  /// genuine sign-out.
  bool _sawUser = false;

  /// Whether this device had a signed-in user before (see [SessionHint]).
  bool _hadSession = false;

  /// How long we keep the splash up waiting for FirebaseAuth to hydrate a
  /// persisted session before concluding there is none. Longer when the device
  /// tells us a session existed, because then a null really is unexpected and
  /// worth waiting for; a cold, throttled device can take several seconds.
  static const _graceWithoutHint = Duration(seconds: 3);
  static const _graceWithHint = Duration(seconds: 8);
  static const _gracePollInterval = Duration(milliseconds: 250);

  AuthBloc(
    this._repository,
    this._signInWithEmail,
    this._signInWithGoogle,
    this._registerWithEmail,
    this._sendPasswordReset,
    this._signOut,
  ) : super(const AuthState.initial()) {
    on<AuthStarted>(_onStarted);
    on<AuthUserChanged>(_onUserChanged);
    on<AuthSignInWithEmailRequested>(_onSignInWithEmail);
    on<AuthSignInWithGoogleRequested>(_onSignInWithGoogle);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthPasswordResetRequested>(_onPasswordReset);
    on<AuthSignOutRequested>(_onSignOut);
    on<AuthOnboardingCompleted>(_onOnboardingCompleted);
    on<AuthHouseholdIdUpdated>(_onHouseholdIdUpdated);
    on<AuthProfileUpdateRequested>(_onProfileUpdate);
    on<AuthDeleteAccountRequested>(_onDeleteAccount);
  }

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    await _authSubscription?.cancel();
    _graceTimer?.cancel();
    _sawUser = false;
    _hadSession = await SessionHint.hadSession();

    // Fast path: if FirebaseAuth already exposes a persisted user synchronously
    // (hot restart, or platforms that hydrate currentUser eagerly), restore it
    // right away so a returning user never sees the login page.
    if (_repository.currentUser != null) {
      await _restoreCurrentUser();
    }

    _authSubscription = _repository.authStateChanges.listen((user) {
      if (user != null) {
        // Signed in (fresh login or session restore).
        _graceTimer?.cancel();
        _sawUser = true;
        add(AuthUserChanged(user));
        return;
      }

      // user == null below.
      if (_repository.currentUser != null) {
        // Transient null while the persisted session is still being restored —
        // the SDK still has the user, so keep them signed in.
        _graceTimer?.cancel();
        _sawUser = true;
        _restoreCurrentUser();
        return;
      }

      // A null after we have seen a real user = genuine sign-out, act now.
      if (_sawUser) {
        _graceTimer?.cancel();
        add(const AuthUserChanged(null));
        return;
      }

      // On web the JS SDK resolves persistence BEFORE the first callback, so a
      // null is authoritative — emit immediately (no splash delay for anonymous
      // landing visitors).
      if (kIsWeb) {
        add(const AuthUserChanged(null));
        return;
      }

      // Android cold start: Firebase emits null BEFORE it finishes restoring
      // the persisted session, and it can emit it more than once. None of those
      // nulls is trustworthy until we have seen a real user, so every one of
      // them (re)opens the same grace window instead of ending it.
      _startGrace();
    });
  }

  /// Holds the splash while polling [AuthRepository.currentUser], so a session
  /// that hydrates without producing a stream event is still picked up. Gives
  /// up — and only then reports the user as signed out — once the window
  /// closes with still no user.
  void _startGrace() {
    if (_graceTimer?.isActive ?? false) return; // window already open
    final deadline = DateTime.now().add(
      _hadSession ? _graceWithHint : _graceWithoutHint,
    );
    _graceTimer = Timer.periodic(_gracePollInterval, (timer) {
      if (_repository.currentUser != null) {
        timer.cancel();
        _restoreCurrentUser();
        return;
      }
      if (DateTime.now().isAfter(deadline)) {
        timer.cancel();
        add(const AuthUserChanged(null));
      }
    });
  }

  /// Restores the persisted session by loading the full Firestore profile, so
  /// onboardingCompleted is accurate (the bare SDK user defaults it to false,
  /// which would wrongly re-trigger onboarding). If the profile can't be loaded
  /// (e.g. offline), we still keep the user signed in and assume onboarding was
  /// already completed — a returning, persisted user has been through it.
  Future<void> _restoreCurrentUser() async {
    final result = await _repository.getCurrentUserProfile();
    result.fold(
      (_) {
        final fallback = _repository.currentUser;
        if (fallback != null) {
          add(AuthUserChanged(fallback.copyWith(onboardingCompleted: true)));
        }
      },
      (user) => add(AuthUserChanged(user)),
    );
  }

  void _onUserChanged(AuthUserChanged event, Emitter<AuthState> emit) {
    if (event.user != null) {
      // Remember for the next cold start that this device does have a session,
      // so a slow restore is waited out instead of bouncing to login.
      unawaited(SessionHint.set(true));
      emit(AuthState.authenticated(event.user!));
    } else {
      unawaited(SessionHint.set(false));
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _onSignInWithEmail(
    AuthSignInWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    final result = await _signInWithEmail(
      email: event.email,
      password: event.password,
    );
    result.fold(
      (failure) => emit(AuthState.error(failure.message)),
      (user) {
        AnalyticsService.logLogin('email');
        emit(AuthState.authenticated(user));
      },
    );
  }

  Future<void> _onSignInWithGoogle(
    AuthSignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    final result = await _signInWithGoogle();
    result.fold(
      (failure) {
        // 'cancelled' = user closed the Google picker — not an error to show
        if (failure.message == 'cancelled') {
          emit(const AuthState.unauthenticated());
        } else {
          emit(AuthState.error(failure.message));
        }
      },
      (user) {
        AnalyticsService.logLogin('google');
        emit(AuthState.authenticated(user));
      },
    );
  }

  Future<void> _onRegister(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    final result = await _registerWithEmail(
      name: event.name,
      email: event.email,
      password: event.password,
    );
    result.fold(
      (failure) => emit(AuthState.error(failure.message)),
      (user) {
        AnalyticsService.logSignUp('email');
        emit(AuthState.authenticated(user));
      },
    );
  }

  Future<void> _onPasswordReset(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    final result = await _sendPasswordReset(event.email);
    result.fold(
      (failure) => emit(AuthState.error(failure.message)),
      (_) => emit(const AuthState.passwordResetSent()),
    );
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _signOut();
    await SessionHint.set(false);
    emit(const AuthState.unauthenticated());
  }

  void _onOnboardingCompleted(
    AuthOnboardingCompleted event,
    Emitter<AuthState> emit,
  ) {
    final user = state.user;
    if (user != null) {
      emit(AuthState.authenticated(user.copyWith(onboardingCompleted: true)));
    }
  }

  void _onHouseholdIdUpdated(
    AuthHouseholdIdUpdated event,
    Emitter<AuthState> emit,
  ) {
    final user = state.user;
    if (user != null) {
      emit(AuthState.authenticated(user.copyWith(
        householdId: event.householdId,
        clearHouseholdId: event.householdId == null,
      )));
    }
  }

  Future<void> _onProfileUpdate(
    AuthProfileUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _repository.updateProfile(
      displayName: event.displayName,
      currency: event.currency,
      photoUrl: event.photoUrl,
      reminderTime: event.reminderTime,
    );
    result.fold(
      (_) {},
      (user) => emit(AuthState.authenticated(user)),
    );
  }

  Future<void> _onDeleteAccount(
    AuthDeleteAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    final result = await _repository.deleteAccount(password: event.password);
    if (result.isLeft) {
      emit(AuthState.error(result.leftValue.message));
      return;
    }
    await SessionHint.set(false);
    emit(const AuthState.unauthenticated());
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    _graceTimer?.cancel();
    return super.close();
  }
}
