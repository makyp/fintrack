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

  /// How many units of [currency] one unit of each foreign currency is worth
  /// ({'USD': 4000} = "el dólar está a 4.000"). Entered by hand: fetching live
  /// rates would mean a paid API, and a stale rate the user typed is easier to
  /// reason about than one that moved overnight.
  final Map<String, double> exchangeRates;

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
    this.exchangeRates = const {},
  });

  AppUser copyWith({
    String? displayName,
    String? photoUrl,
    String? currency,
    bool? onboardingCompleted,
    String? householdId,
    bool clearHouseholdId = false,
    String? reminderTime,
    Map<String, double>? exchangeRates,
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
      exchangeRates: exchangeRates ?? this.exchangeRates,
    );
  }

  @override
  List<Object?> get props => [uid, email, displayName, photoUrl, currency, onboardingCompleted, createdAt, householdId, reminderTime, exchangeRates];
}
