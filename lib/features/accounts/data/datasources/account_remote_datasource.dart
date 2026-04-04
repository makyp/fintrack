import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/account_model.dart';

abstract class AccountRemoteDataSource {
  Stream<List<AccountModel>> watchAccounts(String userId);
  Future<List<AccountModel>> getAccounts(String userId);
  Future<AccountModel> addAccount(AccountModel account);
  Future<AccountModel> updateAccount(AccountModel account);
  Future<void> archiveAccount(String userId, String accountId);
  Future<void> updateBalance(String userId, String accountId, double newBalance);
}

@LazySingleton(as: AccountRemoteDataSource)
class AccountRemoteDataSourceImpl implements AccountRemoteDataSource {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  AccountRemoteDataSourceImpl(this._firestore, this._uuid);

  CollectionReference<Map<String, dynamic>> _accountsRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('accounts');

  @override
  Stream<List<AccountModel>> watchAccounts(String userId) {
    return _accountsRef(userId)
        .where('isArchived', isEqualTo: false)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AccountModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<List<AccountModel>> getAccounts(String userId) async {
    try {
      final snap = await _accountsRef(userId)
          .where('isArchived', isEqualTo: false)
          .orderBy('createdAt', descending: false)
          .get();
      return snap.docs
          .map((doc) => AccountModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<AccountModel> addAccount(AccountModel account) async {
    try {
      // ── Prevent duplicates ──────────────────────────────────────────────
      // One cash account max; no two accounts with the same name
      final dupQuery = account.type.name == 'cash'
          ? _accountsRef(account.userId)
              .where('type', isEqualTo: 'cash')
              .where('isArchived', isEqualTo: false)
              .limit(1)
          : _accountsRef(account.userId)
              .where('name', isEqualTo: account.name)
              .where('isArchived', isEqualTo: false)
              .limit(1);

      final dupSnap = await dupQuery.get();
      if (dupSnap.docs.isNotEmpty) {
        final msg = account.type.name == 'cash'
            ? 'Ya tienes una cuenta de efectivo'
            : 'Ya existe una cuenta con el nombre "${account.name}"';
        throw ServerException(msg);
      }

      final id = account.id.isEmpty ? _uuid.v4() : account.id;
      final model = AccountModel(
        id: id,
        userId: account.userId,
        name: account.name,
        type: account.type,
        balance: account.balance,
        currency: account.currency,
        colorValue: account.colorValue,
        icon: account.icon,
        isArchived: account.isArchived,
        createdAt: account.createdAt,
      );
      await _accountsRef(account.userId).doc(id).set(model.toFirestore());
      return model;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<AccountModel> updateAccount(AccountModel account) async {
    try {
      // Check name collision against OTHER accounts (exclude itself)
      if (account.type.name != 'cash') {
        final dupSnap = await _accountsRef(account.userId)
            .where('name', isEqualTo: account.name)
            .where('isArchived', isEqualTo: false)
            .limit(2)
            .get();
        final conflict = dupSnap.docs.any((d) => d.id != account.id);
        if (conflict) {
          throw ServerException('Ya existe una cuenta con el nombre "${account.name}"');
        }
      }
      await _accountsRef(account.userId).doc(account.id).update({
        'name': account.name,
        'type': account.type.name,
        'balance': account.balance,
        'currency': account.currency,
        'colorValue': account.colorValue,
        'icon': account.icon,
      });
      return account;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> archiveAccount(String userId, String accountId) async {
    try {
      await _accountsRef(userId).doc(accountId).update({'isArchived': true});
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateBalance(String userId, String accountId, double newBalance) async {
    try {
      await _accountsRef(userId).doc(accountId).update({'balance': newBalance});
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
