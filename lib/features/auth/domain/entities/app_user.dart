import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String currency;
  final bool onboardingCompleted;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.currency = 'COP',
    this.onboardingCompleted = false,
    required this.createdAt,
  });

  AppUser copyWith({
    String? displayName,
    String? photoUrl,
    String? currency,
    bool? onboardingCompleted,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      currency: currency ?? this.currency,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [uid, email, displayName, photoUrl, currency, onboardingCompleted, createdAt];
}
