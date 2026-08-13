import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../transactions/domain/entities/transaction_type.dart';
import '../../data/datasources/category_datasource.dart';
import '../../data/models/category_model.dart';
import '../../domain/category_registry.dart';
import '../../domain/entities/transaction_category.dart';
import 'categories_state.dart';

/// Why deleting a category didn't happen.
enum DeleteCategoryResult { deleted, inUse, protected, failed }

@lazySingleton
class CategoriesCubit extends Cubit<CategoriesState> {
  final CategoryDataSource _dataSource;
  final Uuid _uuid;
  StreamSubscription<List<CategoryModel>>? _subscription;
  String? _userId;

  CategoriesCubit(this._dataSource, this._uuid)
      : super(const CategoriesState.initial());

  /// Seeds the catalog on first use, then keeps [CategoryRegistry] in sync so
  /// every screen — including the ones that read it without a BuildContext —
  /// resolves the same labels.
  Future<void> watchCategories(String userId) async {
    if (_userId == userId && state.isLoaded) return;
    _userId = userId;
    emit(const CategoriesState.loading());
    try {
      await _dataSource.ensureSeeded(userId);
    } catch (_) {
      // Seeding is best-effort: the registry still serves the shipped
      // defaults, so the app stays usable offline.
    }
    _subscription?.cancel();
    _subscription = _dataSource.watchCategories(userId).listen(
      (categories) {
        CategoryRegistry.snapshot(categories);
        emit(CategoriesState.loaded(categories));
      },
      onError: (e) => emit(CategoriesState.error(e.toString())),
    );
  }

  Future<bool> createCategory({
    required String label,
    required String icon,
    required List<TransactionType> types,
  }) async {
    final userId = _userId;
    if (userId == null) return false;
    final nextOrder = state.all.isEmpty
        ? DefaultCategories.all.length
        : state.all.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
    final model = CategoryModel(
      id: _uuid.v4(),
      label: label.trim(),
      icon: icon,
      types: types,
      sortOrder: nextOrder,
    );
    try {
      await _dataSource.saveCategory(userId, model);
      return true;
    } catch (e) {
      emit(CategoriesState.error(e.toString()));
      return false;
    }
  }

  Future<bool> updateCategory(TransactionCategory category) async {
    final userId = _userId;
    if (userId == null || category.isProtected) return false;
    try {
      await _dataSource.saveCategory(
          userId, CategoryModel.fromEntity(category));
      return true;
    } catch (e) {
      emit(CategoriesState.error(e.toString()));
      return false;
    }
  }

  /// Hiding is the safe alternative to deleting: movements already filed under
  /// the category keep resolving, it just leaves the pickers.
  Future<bool> setActive(TransactionCategory category, bool isActive) async {
    final userId = _userId;
    if (userId == null) return false;
    if (category.isProtected && !isActive) return false;
    // Never leave a movement type with no category to choose from.
    if (!isActive) {
      for (final type in category.types) {
        final remaining = state.all
            .where((c) => c.isActive && c.appliesTo(type) && c.id != category.id)
            .length;
        if (remaining == 0) return false;
      }
    }
    try {
      await _dataSource.setActive(userId, category.id, isActive);
      return true;
    } catch (e) {
      emit(CategoriesState.error(e.toString()));
      return false;
    }
  }

  /// Deletes a user-created category, but only when nothing points at it.
  Future<DeleteCategoryResult> deleteCategory(
      TransactionCategory category) async {
    final userId = _userId;
    if (userId == null) return DeleteCategoryResult.failed;
    if (category.isDefault || category.isProtected) {
      return DeleteCategoryResult.protected;
    }
    try {
      final used = await _dataSource.usageCount(userId, category.id);
      if (used > 0) return DeleteCategoryResult.inUse;
      await _dataSource.deleteCategory(userId, category.id);
      return DeleteCategoryResult.deleted;
    } catch (e) {
      emit(CategoriesState.error(e.toString()));
      return DeleteCategoryResult.failed;
    }
  }

  void clear() {
    _subscription?.cancel();
    _subscription = null;
    _userId = null;
    CategoryRegistry.reset();
    emit(const CategoriesState.initial());
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
