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

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;
  final SignInWithEmail _signInWithEmail;
  final SignInWithGoogle _signInWithGoogle;
  final RegisterWithEmail _registerWithEmail;
  final SendPasswordReset _sendPasswordReset;
  final SignOut _signOut;
  StreamSubscription<AppUser?>? _authSubscription;

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
    _authSubscription = _repository.authStateChanges.listen(
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
    return super.close();
  }
}
