import '../../domain/entities/app_user.dart';

class AppUserModel extends AppUser {
  const AppUserModel({
    required super.uid,
    required super.email,
    required super.displayName,
    super.photoUrl,
    super.currency,
    super.onboardingCompleted,
    required super.createdAt,
    super.householdId,
    super.reminderTime,
    super.exchangeRates,
  });

  factory AppUserModel.fromFirestore(Map<String, dynamic> map, String uid) {
    return AppUserModel(
      uid: uid,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      currency: map['currency'] as String? ?? 'COP',
      onboardingCompleted: map['onboardingCompleted'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['createdAt'] as dynamic).millisecondsSinceEpoch as int,
            )
          : DateTime.now(),
      householdId: map['householdId'] as String?,
      reminderTime: map['reminderTime'] as String?,
      exchangeRates: _ratesFromMap(map['exchangeRates']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'currency': currency,
      'onboardingCompleted': onboardingCompleted,
      'createdAt': createdAt,
      if (householdId != null) 'householdId': householdId,
      if (reminderTime != null) 'reminderTime': reminderTime,
      if (exchangeRates.isNotEmpty) 'exchangeRates': exchangeRates,
    };
  }

  /// Firestore gives back `num`, and a rate that arrived as 0 or negative
  /// (a bad manual edit) would divide the totals into nonsense — drop those.
  static Map<String, double> _ratesFromMap(Object? raw) {
    if (raw is! Map) return const {};
    final out = <String, double>{};
    raw.forEach((key, value) {
      final rate = (value as num?)?.toDouble();
      if (key is String && rate != null && rate > 0) {
        out[key.toUpperCase()] = rate;
      }
    });
    return out;
  }

  factory AppUserModel.fromFirebaseUser({
    required String uid,
    required String email,
    required String displayName,
    String? photoUrl,
  }) {
    return AppUserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      currency: 'COP',
      onboardingCompleted: false,
      createdAt: DateTime.now(),
    );
  }
}
