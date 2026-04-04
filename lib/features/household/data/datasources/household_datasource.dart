import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../domain/entities/household.dart';

class HouseholdDataSource {
  final FirebaseFirestore _firestore;

  HouseholdDataSource(this._firestore);

  CollectionReference<Map<String, dynamic>> get _households =>
      _firestore.collection('households');

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _firestore.collection('users').doc(uid);

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  Future<Household> createHousehold(
      String userId, String displayName, String email, String name) async {
    final code = _generateCode();
    final now = DateTime.now();

    final docRef = _households.doc();
    final member = {
      'uid': userId,
      'displayName': displayName,
      'email': email,
      'role': 'admin',
      'joinedAt': Timestamp.fromDate(now),
    };

    await _firestore.runTransaction((tx) async {
      tx.set(docRef, {
        'name': name,
        'inviteCode': code,
        'createdBy': userId,
        'createdAt': Timestamp.fromDate(now),
        'members': [member],
        'memberUids': [userId],
      });
      tx.update(_userRef(userId), {'householdId': docRef.id});
    });

    AnalyticsService.logHouseholdCreated();
    return Household(
      id: docRef.id,
      name: name,
      inviteCode: code,
      createdBy: userId,
      createdAt: now,
      members: [
        HouseholdMember(
          uid: userId,
          displayName: displayName,
          email: email,
          role: 'admin',
          joinedAt: now,
        )
      ],
    );
  }

  Future<Household> joinHousehold(
      String userId, String displayName, String email, String inviteCode) async {
    final snap = await _households
        .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      throw Exception('Código de invitación inválido');
    }

    final doc = snap.docs.first;
    final data = doc.data();
    final members = (data['members'] as List<dynamic>);

    if (members.any((m) => m['uid'] == userId)) {
      throw Exception('Ya eres miembro de este hogar');
    }

    final now = DateTime.now();
    final newMember = {
      'uid': userId,
      'displayName': displayName,
      'email': email,
      'role': 'member',
      'joinedAt': Timestamp.fromDate(now),
    };

    await _firestore.runTransaction((tx) async {
      tx.update(doc.reference, {
        'members': FieldValue.arrayUnion([newMember]),
        'memberUids': FieldValue.arrayUnion([userId]),
      });
      tx.update(_userRef(userId), {'householdId': doc.id});
    });

    AnalyticsService.logHouseholdJoined();
    return _fromMap(doc.id, {
      ...data,
      'members': [...members, newMember],
    });
  }

  Future<void> leaveHousehold(String userId, String householdId) async {
    final docRef = _households.doc(householdId);
    final snap = await docRef.get();
    if (!snap.exists) return;

    final data = snap.data()!;
    final members = (data['members'] as List<dynamic>);
    final memberEntries = members.where((m) => m['uid'] == userId).toList();

    await _firestore.runTransaction((tx) async {
      if (memberEntries.isNotEmpty) {
        tx.update(docRef, {
          'members': FieldValue.arrayRemove(memberEntries),
          'memberUids': FieldValue.arrayRemove([userId]),
        });
      }
      tx.update(_userRef(userId), {'householdId': FieldValue.delete()});
    });
  }

  Stream<Household?> watchHousehold(String householdId) {
    return _households.doc(householdId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return _fromMap(snap.id, snap.data()!);
    });
  }

  Household _fromMap(String id, Map<String, dynamic> data) {
    final members = (data['members'] as List<dynamic>).map((m) {
      final map = m as Map<String, dynamic>;
      return HouseholdMember(
        uid: map['uid'] as String,
        displayName: map['displayName'] as String? ?? '',
        email: map['email'] as String? ?? '',
        role: map['role'] as String? ?? 'member',
        joinedAt: map['joinedAt'] != null
            ? (map['joinedAt'] as Timestamp).toDate()
            : DateTime.now(),
      );
    }).toList();

    return Household(
      id: id,
      name: data['name'] as String? ?? '',
      inviteCode: data['inviteCode'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      members: members,
    );
  }
}
