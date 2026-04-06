import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String currency;
  final bool onboardingCompleted;
  final DateTime createdAt;
  final String? householdId;
  final String? reminderTime; // "HH:mm" format, e.g. "20:00"

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.currency = 'COP',
    this.onboardingCompleted = false,
    required this.createdAt,
    this.householdId,
    this.reminderTime,
  });

  AppUser copyWith({
    String? displayName,
    String? photoUrl,
    String? currency,
    bool? onboardingCompleted,
    String? householdId,
    bool clearHouseholdId = false,
    String? reminderTime,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      currency: currency ?? this.currency,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt,
      householdId: clearHouseholdId ? null : (householdId ?? this.householdId),
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }

  @override
  List<Object?> get props => [uid, email, displayName, photoUrl, currency, onboardingCompleted, createdAt, householdId, reminderTime];
}
