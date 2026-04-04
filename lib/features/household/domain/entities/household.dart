import 'package:equatable/equatable.dart';

class HouseholdMember extends Equatable {
  final String uid;
  final String displayName;
  final String email;
  final String role; // 'admin' | 'member'
  final DateTime joinedAt;

  const HouseholdMember({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.role,
    required this.joinedAt,
  });

  bool get isAdmin => role == 'admin';

  @override
  List<Object?> get props => [uid, displayName, email, role, joinedAt];
}

class Household extends Equatable {
  final String id;
  final String name;
  final String inviteCode;
  final String createdBy;
  final DateTime createdAt;
  final List<HouseholdMember> members;

  const Household({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.createdBy,
    required this.createdAt,
    required this.members,
  });

  @override
  List<Object?> get props => [id, name, inviteCode, createdBy, createdAt, members];
}
