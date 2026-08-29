import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/firestore_write.dart';
import '../../domain/entities/transaction_category.dart';
import '../models/category_model.dart';

abstract class CategoryDataSource {
  Stream<List<CategoryModel>> watchCategories(String userId);
  Future<List<CategoryModel>> getCategories(String userId);

  /// Writes the shipped catalog the first time the user needs it. Existing
  /// docs are left alone, so this is safe to call on every launch.
  Future<void> ensureSeeded(String userId, {Set<String>? activeIds});

  Future<void> saveCategory(String userId, CategoryModel category);
  Future<void> setActive(String userId, String categoryId, bool isActive);
  Future<void> deleteCategory(String userId, String categoryId);

  /// How many movements are filed under [categoryId]. Used to decide between
  /// deleting a category and offering to hide it instead.
  Future<int> usageCount(String userId, String categoryId);
}

@LazySingleton(as: CategoryDataSource)
class CategoryDataSourceImpl implements CategoryDataSource {
  final FirebaseFirestore _firestore;

  CategoryDataSourceImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> _ref(String userId) =>
      _firestore.collection('users').doc(userId).collection('categories');

  @override
  Stream<List<CategoryModel>> watchCategories(String userId) {
    return _ref(userId).snapshots().map((snap) => snap.docs
        .map((doc) => CategoryModel.fromFirestore(doc.data(), doc.id))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)));
  }

  @override
  Future<List<CategoryModel>> getCategories(String userId) async {
    try {
      final snap = await _ref(userId).get();
      return snap.docs
          .map((doc) => CategoryModel.fromFirestore(doc.data(), doc.id))
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> ensureSeeded(String userId, {Set<String>? activeIds}) async {
    try {
      final existing = await _ref(userId).limit(1).get();
      if (existing.docs.isNotEmpty) return;

      final batch = _firestore.batch();
      for (final c in DefaultCategories.all) {
        // A category the user didn't pick starts hidden, never missing: the
        // movements they may import later still have to resolve.
        final isActive =
            c.isProtected || activeIds == null || activeIds.contains(c.id);
        batch.set(
          _ref(userId).doc(c.id),
          CategoryModel.fromEntity(c.copyWith(isActive: isActive)).toFirestore(),
        );
      }
      fireAndForget(batch.commit(), 'seedCategories');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> saveCategory(String userId, CategoryModel category) async {
    try {
      fireAndForget(
          _ref(userId)
              .doc(category.id)
              .set(category.toFirestore(), SetOptions(merge: true)),
          'saveCategory');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> setActive(String userId, String categoryId, bool isActive) async {
    try {
      fireAndForget(
          _ref(userId).doc(categoryId).update({'isActive': isActive}),
          'setCategoryActive');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteCategory(String userId, String categoryId) async {
    try {
      fireAndForget(
          _ref(userId).doc(categoryId).delete(), 'deleteCategory');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<int> usageCount(String userId, String categoryId) async {
    try {
      final snap = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('categoryId', isEqualTo: categoryId)
          .limit(1)
          .get();
      return snap.docs.length;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
