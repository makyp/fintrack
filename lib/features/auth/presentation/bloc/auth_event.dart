import 'package:equatable/equatable.dart';
import '../../domain/entities/app_user.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthUserChanged extends AuthEvent {
  final AppUser? user;
  const AuthUserChanged(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthSignInWithEmailRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthSignInWithEmailRequested({required this.email, required this.password});
  @override
  List<Object> get props => [email, password];
}

class AuthSignInWithGoogleRequested extends AuthEvent {
  const AuthSignInWithGoogleRequested();
}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
  });
  @override
  List<Object> get props => [name, email, password];
}

class AuthPasswordResetRequested extends AuthEvent {
  final String email;
  const AuthPasswordResetRequested(this.email);
  @override
  List<Object> get props => [email];
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

class AuthOnboardingCompleted extends AuthEvent {
  const AuthOnboardingCompleted();
}

class AuthHouseholdIdUpdated extends AuthEvent {
  final String? householdId;
  const AuthHouseholdIdUpdated(this.householdId);
  @override
  List<Object?> get props => [householdId];
}

class AuthProfileUpdateRequested extends AuthEvent {
  final String? displayName;
  final String? currency;
  final String? photoUrl;
  final String? reminderTime; // "HH:mm" format
  const AuthProfileUpdateRequested({
    this.displayName,
    this.currency,
    this.photoUrl,
    this.reminderTime,
  });
  @override
  List<Object?> get props => [displayName, currency, photoUrl, reminderTime];
}

class AuthDeleteAccountRequested extends AuthEvent {
  final String password;
  const AuthDeleteAccountRequested(this.password);
  @override
  List<Object> get props => [password];
}
