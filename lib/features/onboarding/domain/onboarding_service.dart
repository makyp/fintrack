import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import '../../accounts/data/models/account_model.dart';
import '../../accounts/domain/entities/account.dart';

@lazySingleton
class OnboardingService {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  const OnboardingService(this._firestore, this._uuid);

  Future<void> completeOnboarding({
    required String userId,
    required double cashBalance,
    required List<Map<String, dynamic>> bankAccounts,
    required List<Map<String, dynamic>> cards,
  }) async {
    final batch = _firestore.batch();
    final now = DateTime.now();

    // Add cash account if balance > 0
    if (cashBalance > 0) {
      final cashModel = AccountModel(
        id: _uuid.v4(),
        userId: userId,
        name: 'Efectivo',
        type: AccountType.cash,
        balance: cashBalance,
        colorValue: 0xFF059669,
        icon: '💵',
        createdAt: now,
      );
      batch.set(
        _firestore
            .collection('users')
            .doc(userId)
            .collection('accounts')
            .doc(cashModel.id),
        cashModel.toFirestore(),
      );
    }

    // Add bank accounts
    for (final acc in bankAccounts) {
      if ((acc['name'] as String).isEmpty) continue;
      final type = _typeFromString(acc['type'] as String? ?? 'checking');
      final model = AccountModel(
        id: _uuid.v4(),
        userId: userId,
        name: acc['name'] as String,
        type: type,
        balance: (acc['balance'] as num?)?.toDouble() ?? 0,
        colorValue: 0xFF2563EB,
        icon: type.icon,
        createdAt: now,
      );
      batch.set(
        _firestore
            .collection('users')
            .doc(userId)
            .collection('accounts')
            .doc(model.id),
        model.toFirestore(),
      );
    }

    // Add cards
    for (final card in cards) {
      if ((card['name'] as String).isEmpty) continue;
      final type = (card['type'] as String?) == 'debito'
          ? AccountType.checking
          : AccountType.credit;
      final model = AccountModel(
        id: _uuid.v4(),
        userId: userId,
        name: card['name'] as String,
        type: type,
        balance: (card['balance'] as num?)?.toDouble() ?? 0,
        colorValue: type == AccountType.credit ? 0xFFDC2626 : 0xFF7C3AED,
        icon: type.icon,
        createdAt: now,
      );
      batch.set(
        _firestore
            .collection('users')
            .doc(userId)
            .collection('accounts')
            .doc(model.id),
        model.toFirestore(),
      );
    }

    // Mark onboarding complete
    batch.update(
      _firestore.collection('users').doc(userId),
      {
        'onboardingCompleted': true,
        'updatedAt': Timestamp.now(),
      },
    );

    await batch.commit();
  }

  AccountType _typeFromString(String type) {
    switch (type) {
      case 'ahorros':
        return AccountType.savings;
      case 'inversiones':
        return AccountType.investment;
      default:
        return AccountType.checking;
    }
  }
}
