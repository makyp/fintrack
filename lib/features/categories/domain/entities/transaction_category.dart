import 'package:equatable/equatable.dart';

import '../../../transactions/domain/entities/transaction_type.dart';

/// A spending/income category.
///
/// This used to be an `enum`. It is now a value object so users can add their
/// own categories and hide the ones they don't use — but the read API
/// (`.label`, `.icon`) is unchanged, and every default keeps the id it had as
/// an enum constant (`food`, `salary`, …). That is what lets transactions
/// written before this feature keep resolving: their stored `categoryId` is
/// still a valid id.
class TransactionCategory extends Equatable {
  /// Stable identity. For defaults this is the old enum constant name; for
  /// user-created ones, a uuid. Never change it once transactions point at it.
  final String id;
  final String label;

  /// Emoji shown next to the label.
  final String icon;

  /// Which movement types can use this category. `other` serves both expenses
  /// and income, which is why this is a list and not a single value.
  final List<TransactionType> types;

  /// Hidden categories stay resolvable for old records but disappear from the
  /// pickers. This is how a user "removes" a default without orphaning the
  /// movements already filed under it.
  final bool isActive;

  /// True for the categories the app ships with.
  final bool isDefault;

  final int sortOrder;

  const TransactionCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.types,
    this.isActive = true,
    this.isDefault = false,
    this.sortOrder = 0,
  });

  bool appliesTo(TransactionType type) => types.contains(type);

  /// `Otro` and `Transferencia` underpin deserialization and transfers, so they
  /// can't be renamed, hidden or deleted.
  bool get isProtected => id == 'other' || id == 'transfer';

  TransactionCategory copyWith({
    String? label,
    String? icon,
    List<TransactionType>? types,
    bool? isActive,
    int? sortOrder,
  }) {
    return TransactionCategory(
      id: id,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      types: types ?? this.types,
      isActive: isActive ?? this.isActive,
      isDefault: isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [id, label, icon, types, isActive, isDefault, sortOrder];
}

/// The catalog the app ships with — the former enum constants, in the order
/// they were listed in `forType`.
class DefaultCategories {
  const DefaultCategories._();

  static const expense = TransactionType.expense;
  static const income = TransactionType.income;

  static const all = <TransactionCategory>[
    // ── Expenses ────────────────────────────────────────────────────────────
    TransactionCategory(id: 'food', label: 'Alimentación', icon: '🍔',
        types: [expense], isDefault: true, sortOrder: 0),
    TransactionCategory(id: 'transport', label: 'Transporte', icon: '🚗',
        types: [expense], isDefault: true, sortOrder: 1),
    TransactionCategory(id: 'entertainment', label: 'Entretenimiento', icon: '🎬',
        types: [expense], isDefault: true, sortOrder: 2),
    TransactionCategory(id: 'health', label: 'Salud', icon: '💊',
        types: [expense], isDefault: true, sortOrder: 3),
    TransactionCategory(id: 'education', label: 'Educación', icon: '📚',
        types: [expense], isDefault: true, sortOrder: 4),
    TransactionCategory(id: 'home', label: 'Hogar', icon: '🏠',
        types: [expense], isDefault: true, sortOrder: 5),
    TransactionCategory(id: 'clothing', label: 'Ropa', icon: '👕',
        types: [expense], isDefault: true, sortOrder: 6),
    TransactionCategory(id: 'shopping', label: 'Compras online', icon: '🛒',
        types: [expense], isDefault: true, sortOrder: 7),
    TransactionCategory(id: 'technology', label: 'Tecnología', icon: '💻',
        types: [expense], isDefault: true, sortOrder: 8),
    TransactionCategory(id: 'services', label: 'Servicios', icon: '⚡',
        types: [expense], isDefault: true, sortOrder: 9),
    TransactionCategory(id: 'cleaning', label: 'Aseo', icon: '🧹',
        types: [expense], isDefault: true, sortOrder: 10),
    // ── Income ──────────────────────────────────────────────────────────────
    TransactionCategory(id: 'salary', label: 'Salario', icon: '💼',
        types: [income], isDefault: true, sortOrder: 11),
    TransactionCategory(id: 'freelance', label: 'Freelance', icon: '🧑‍💻',
        types: [income], isDefault: true, sortOrder: 12),
    TransactionCategory(id: 'investment', label: 'Inversiones', icon: '📈',
        types: [income], isDefault: true, sortOrder: 13),
    TransactionCategory(id: 'sale', label: 'Venta', icon: '🛍️',
        types: [income], isDefault: true, sortOrder: 14),
    TransactionCategory(id: 'gift', label: 'Regalo', icon: '🎁',
        types: [income], isDefault: true, sortOrder: 15),
    TransactionCategory(id: 'bonus', label: 'Bono', icon: '⭐',
        types: [income], isDefault: true, sortOrder: 16),
    // ── Always available ────────────────────────────────────────────────────
    TransactionCategory(id: 'other', label: 'Otro', icon: '📌',
        types: [expense, income], isDefault: true, sortOrder: 17),
    TransactionCategory(id: 'transfer', label: 'Transferencia', icon: '↔️',
        types: [TransactionType.transfer], isDefault: true, sortOrder: 18),
  ];

  static TransactionCategory? byId(String id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Fallback for an id that is neither a default nor loaded yet — shows the
  /// raw id rather than silently relabelling the movement as "Otro".
  static TransactionCategory unknown(String id) => TransactionCategory(
        id: id,
        label: id.isEmpty ? 'Otro' : id,
        icon: '📌',
        types: const [expense, income],
      );
}
