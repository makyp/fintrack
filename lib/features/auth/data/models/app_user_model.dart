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
    };
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
