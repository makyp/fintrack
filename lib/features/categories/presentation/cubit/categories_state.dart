import 'package:equatable/equatable.dart';

import '../../../transactions/domain/entities/transaction_type.dart';
import '../../domain/entities/transaction_category.dart';

enum CategoriesStatus { initial, loading, loaded, error }

class CategoriesState extends Equatable {
  final CategoriesStatus status;
  final List<TransactionCategory>? categories;
  final String? errorMessage;

  const CategoriesState._({
    required this.status,
    this.categories,
    this.errorMessage,
  });

  const CategoriesState.initial() : this._(status: CategoriesStatus.initial);
  const CategoriesState.loading() : this._(status: CategoriesStatus.loading);
  const CategoriesState.loaded(List<TransactionCategory> categories)
      : this._(status: CategoriesStatus.loaded, categories: categories);
  const CategoriesState.error(String message)
      : this._(status: CategoriesStatus.error, errorMessage: message);

  bool get isLoading => status == CategoriesStatus.loading;
  bool get isLoaded => status == CategoriesStatus.loaded;

  List<TransactionCategory> get all => categories ?? const [];

  List<TransactionCategory> ofType(TransactionType type) =>
      all.where((c) => c.appliesTo(type)).toList();

  int get activeCount => all.where((c) => c.isActive).length;

  @override
  List<Object?> get props => [status, categories, errorMessage];
}
