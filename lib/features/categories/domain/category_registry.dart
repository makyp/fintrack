import '../../transactions/domain/entities/transaction_type.dart';
import 'entities/transaction_category.dart';

/// In-memory snapshot of the user's categories.
///
/// Deserializing a transaction has to turn a stored `categoryId` into a
/// [TransactionCategory] synchronously, from places with no BuildContext and no
/// DI (models, the home-screen widget service, the PDF generator). So the
/// catalog lives here as plain static state that the categories cubit refreshes
/// whenever Firestore changes.
///
/// Until it is loaded — cold start, background isolate — [byId] still resolves
/// every default correctly, because defaults keep the ids the old enum used.
class CategoryRegistry {
  const CategoryRegistry._();

  static List<TransactionCategory> _categories = DefaultCategories.all;
  static Map<String, TransactionCategory> _byId = {
    for (final c in DefaultCategories.all) c.id: c,
  };

  /// Replaces the catalog. Called by the categories cubit on every snapshot.
  static void snapshot(List<TransactionCategory> categories) {
    if (categories.isEmpty) return;
    final sorted = [...categories]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    _categories = sorted;
    _byId = {for (final c in sorted) c.id: c};
  }

  /// Back to the shipped defaults (sign-out, tests).
  static void reset() {
    _categories = DefaultCategories.all;
    _byId = {for (final c in DefaultCategories.all) c.id: c};
  }

  /// Everything in the catalog, hidden ones included — needed to render
  /// movements already filed under a category the user has since hidden.
  static List<TransactionCategory> get all => List.unmodifiable(_categories);

  static List<TransactionCategory> get active =>
      _categories.where((c) => c.isActive).toList();

  /// Resolves a stored id. Falls back to the shipped default, then to a
  /// placeholder carrying the raw id, so a lookup never throws.
  static TransactionCategory byId(String id) =>
      _byId[id] ?? DefaultCategories.byId(id) ?? DefaultCategories.unknown(id);

  /// The categories a picker should offer for [type]: active only.
  static List<TransactionCategory> forType(TransactionType type) {
    final list = _categories
        .where((c) => c.isActive && c.appliesTo(type))
        .toList();
    // A picker with nothing in it would block the form entirely.
    if (list.isEmpty) {
      return [
        type == TransactionType.transfer
            ? byId('transfer')
            : byId('other'),
      ];
    }
    return list;
  }

  /// Same as [forType] but keeps [keep] in the list even when it is hidden —
  /// for editing a movement filed under a category the user has since hidden.
  static List<TransactionCategory> forTypeIncluding(
      TransactionType type, TransactionCategory? keep) {
    final list = forType(type);
    if (keep == null || list.any((c) => c.id == keep.id)) return list;
    return [...list, keep];
  }
}
