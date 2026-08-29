import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import '../../../core/utils/firestore_write.dart';
import '../../accounts/data/models/account_model.dart';
import '../../accounts/domain/entities/account.dart';
import '../../categories/data/models/category_model.dart';
import '../../categories/domain/entities/transaction_category.dart';

@lazySingleton
class OnboardingService {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  const OnboardingService(this._firestore, this._uuid);

  /// Writes everything the user set up during onboarding in a single batch.
  ///
  /// [activeCategoryIds] null means "keep them all"; anything not listed is
  /// written hidden rather than skipped, so it can be switched back on later
  /// from the profile without losing its id.
  Future<void> completeOnboarding({
    required String userId,
    required double cashBalance,
    required List<Map<String, dynamic>> bankAccounts,
    required List<Map<String, dynamic>> cards,
    Set<String>? activeCategoryIds,
    List<TransactionCategory> customCategories = const [],
  }) async {
    final batch = _firestore.batch();
    final now = DateTime.now();

    // ── Categories ──────────────────────────────────────────────────────────
    final categoriesRef =
        _firestore.collection('users').doc(userId).collection('categories');
    for (final c in DefaultCategories.all) {
      final isActive = c.isProtected ||
          activeCategoryIds == null ||
          activeCategoryIds.contains(c.id);
      batch.set(
        categoriesRef.doc(c.id),
        CategoryModel.fromEntity(c.copyWith(isActive: isActive)).toFirestore(),
      );
    }
    var customOrder = DefaultCategories.all.length;
    for (final custom in customCategories) {
      if (custom.label.trim().isEmpty) continue;
      final model = CategoryModel.fromEntity(
          custom.copyWith(sortOrder: customOrder++));
      batch.set(
        categoriesRef.doc(_uuid.v4()),
        model.toFirestore(),
      );
    }

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

    // Mark onboarding complete (set+merge crea el doc si no existe)
    batch.set(
      _firestore.collection('users').doc(userId),
      {
        'onboardingCompleted': true,
        'updatedAt': Timestamp.now(),
      },
      SetOptions(merge: true),
    );

    fireAndForget(batch.commit(), 'completeOnboarding');
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
