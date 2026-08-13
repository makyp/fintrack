import '../../../transactions/domain/entities/transaction_type.dart';
import '../../domain/entities/transaction_category.dart';

class CategoryModel extends TransactionCategory {
  const CategoryModel({
    required super.id,
    required super.label,
    required super.icon,
    required super.types,
    super.isActive,
    super.isDefault,
    super.sortOrder,
  });

  factory CategoryModel.fromFirestore(Map<String, dynamic> map, String id) {
    final rawTypes = (map['types'] as List?)?.cast<String>() ?? const ['expense'];
    final types = rawTypes
        .map((t) => TransactionType.values.firstWhere(
              (e) => e.name == t,
              orElse: () => TransactionType.expense,
            ))
        .toSet()
        .toList();
    return CategoryModel(
      id: id,
      label: map['label'] as String? ?? id,
      icon: map['icon'] as String? ?? '📌',
      types: types.isEmpty ? const [TransactionType.expense] : types,
      isActive: map['isActive'] as bool? ?? true,
      isDefault: map['isDefault'] as bool? ?? false,
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'label': label,
        'icon': icon,
        'types': types.map((t) => t.name).toList(),
        'isActive': isActive,
        'isDefault': isDefault,
        'sortOrder': sortOrder,
      };

  static CategoryModel fromEntity(TransactionCategory c) => CategoryModel(
        id: c.id,
        label: c.label,
        icon: c.icon,
        types: c.types,
        isActive: c.isActive,
        isDefault: c.isDefault,
        sortOrder: c.sortOrder,
      );
}
