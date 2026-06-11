import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/analytics/analytics_service.dart';
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
  Timer? _firstNullTimer;
  bool _sawAuthEvent = false;

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
    _firstNullTimer?.cancel();
    _sawAuthEvent = false;

    // Fast path: if FirebaseAuth already exposes a persisted user synchronously
    // (hot restart, or platforms that hydrate currentUser eagerly), restore it
    // right away so a returning user never sees the login page.
    if (_repository.currentUser != null) {
      await _restoreCurrentUser();
    }

    _authSubscription = _repository.authStateChanges.listen((user) {
      // Any concrete event supersedes the pending first-null grace timer.
      _firstNullTimer?.cancel();

      if (user != null) {
        // Signed in (fresh login or session restore).
        _sawAuthEvent = true;
        add(AuthUserChanged(user));
        return;
      }

      // user == null below.
      if (_repository.currentUser != null) {
        // Transient null while the persisted session is still being restored —
        // the SDK still has the user, so keep them signed in.
        _sawAuthEvent = true;
        _restoreCurrentUser();
        return;
      }

      if (!_sawAuthEvent) {
        // VERY FIRST event is null with no SDK user. On Android cold start
        // Firebase emits null BEFORE it finishes restoring the persisted
        // session, so this null is not yet trustworthy. Wait briefly: if the
        // real user (or a hydrated currentUser) shows up we go straight to the
        // dashboard; only if nothing appears do we conclude there is no session.
        _sawAuthEvent = true;
        _firstNullTimer = Timer(const Duration(seconds: 3), () {
          if (_repository.currentUser != null) {
            _restoreCurrentUser();
          } else {
            add(const AuthUserChanged(null));
          }
        });
        return;
      }

      // A later null with no SDK user = genuine sign-out.
      add(const AuthUserChanged(null));
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
      emit(AuthState.authenticated(event.user!));
    } else {
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
    result.fold(
      (failure) => emit(AuthState.error(failure.message)),
      (_) => emit(const AuthState.unauthenticated()),
    );
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    _firstNullTimer?.cancel();
    return super.close();
  }
}
