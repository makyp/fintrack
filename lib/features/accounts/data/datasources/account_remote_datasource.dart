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
