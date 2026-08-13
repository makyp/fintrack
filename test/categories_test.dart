import 'package:flutter_test/flutter_test.dart';
import 'package:fintrack/features/categories/domain/category_registry.dart';
import 'package:fintrack/features/transactions/domain/category_matcher.dart';
import 'package:fintrack/features/transactions/domain/entities/transaction.dart';

TransactionCategory custom(String id, String label,
        {List<TransactionType> types = const [TransactionType.expense],
        bool isActive = true}) =>
    TransactionCategory(
        id: id, label: label, icon: '🐾', types: types, isActive: isActive);

Transaction tx(TransactionCategory category) => Transaction(
      id: 't1',
      userId: 'u1',
      amount: 1000,
      type: TransactionType.expense,
      category: category,
      accountId: 'a1',
      description: 'x',
      date: DateTime(2026, 8, 13),
      createdAt: DateTime(2026, 8, 13),
    );

void main() {
  setUp(CategoryRegistry.reset);
  tearDownAll(CategoryRegistry.reset);

  group('registry', () {
    test('resolves the shipped defaults before anything is loaded', () {
      expect(CategoryRegistry.byId('food').label, 'Alimentación');
      expect(CategoryRegistry.byId('salary').icon, '💼');
    });

    test('an unknown id keeps its id instead of silently becoming Otro', () {
      final resolved = CategoryRegistry.byId('some-uuid');
      expect(resolved.id, 'some-uuid');
      expect(resolved.label, 'some-uuid');
    });

    test('a loaded catalog overrides the defaults', () {
      CategoryRegistry.snapshot([
        ...DefaultCategories.all.where((c) => c.id != 'food'),
        DefaultCategories.byId('food')!.copyWith(label: 'Comidita'),
      ]);
      expect(CategoryRegistry.byId('food').label, 'Comidita');
    });

    test('hidden categories leave the pickers but still resolve', () {
      CategoryRegistry.snapshot([
        ...DefaultCategories.all.where((c) => c.id != 'clothing'),
        DefaultCategories.byId('clothing')!.copyWith(isActive: false),
      ]);
      final picker = CategoryRegistry.forType(TransactionType.expense);
      expect(picker.any((c) => c.id == 'clothing'), isFalse);
      expect(CategoryRegistry.byId('clothing').label, 'Ropa');
    });

    test('forType never hands back an empty picker', () {
      CategoryRegistry.snapshot(
          DefaultCategories.all.map((c) => c.copyWith(isActive: false)).toList());
      expect(CategoryRegistry.forType(TransactionType.expense), isNotEmpty);
      expect(CategoryRegistry.forType(TransactionType.income), isNotEmpty);
      expect(CategoryRegistry.forType(TransactionType.transfer), isNotEmpty);
    });

    test('forTypeIncluding keeps a hidden category so editing does not '
        're-categorise the movement', () {
      final hidden = DefaultCategories.byId('clothing')!.copyWith(isActive: false);
      CategoryRegistry.snapshot([
        ...DefaultCategories.all.where((c) => c.id != 'clothing'),
        hidden,
      ]);
      final list = CategoryRegistry.forTypeIncluding(
          TransactionType.expense, CategoryRegistry.byId('clothing'));
      expect(list.any((c) => c.id == 'clothing'), isTrue);
    });
  });

  group('transaction', () {
    test('stores only the id', () {
      expect(tx(CategoryRegistry.byId('food')).categoryId, 'food');
    });

    test('picks up a rename that lands after the movement was built', () {
      final movement = tx(CategoryRegistry.byId('food'));
      expect(movement.category.label, 'Alimentación');

      CategoryRegistry.snapshot([
        ...DefaultCategories.all.where((c) => c.id != 'food'),
        DefaultCategories.byId('food')!.copyWith(label: 'Mercado'),
      ]);
      expect(movement.category.label, 'Mercado');
    });

    test('a custom category resolves once the catalog arrives', () {
      final movement = tx(custom('uuid-1', 'Mascotas'));
      // Catalog not loaded yet: the raw id is shown, never a wrong label.
      expect(movement.category.label, 'uuid-1');

      CategoryRegistry.snapshot([
        ...DefaultCategories.all,
        custom('uuid-1', 'Mascotas'),
      ]);
      expect(movement.category.label, 'Mascotas');
      expect(movement.category.icon, '🐾');
    });
  });

  group('matcher', () {
    test('suggests a default from its keywords', () {
      final suggestion =
          CategoryMatcher.suggest('almuerzo', type: TransactionType.expense);
      expect(suggestion?.id, 'food');
    });

    test('never suggests a category the user hid', () {
      CategoryRegistry.snapshot([
        ...DefaultCategories.all.where((c) => c.id != 'food'),
        DefaultCategories.byId('food')!.copyWith(isActive: false),
      ]);
      final suggestion =
          CategoryMatcher.suggest('almuerzo', type: TransactionType.expense);
      expect(suggestion?.id, isNot('food'));
    });

    test('matches a user-created category by its own name', () {
      CategoryRegistry.snapshot([
        ...DefaultCategories.all,
        custom('uuid-1', 'Mascotas'),
      ]);
      final suggestion = CategoryMatcher.suggest('compre comida para mascotas',
          type: TransactionType.expense);
      expect(suggestion?.id, 'uuid-1');
    });

    test('respects the movement type', () {
      final suggestion =
          CategoryMatcher.suggest('salario', type: TransactionType.income);
      expect(suggestion?.id, 'salary');
      expect(
          CategoryMatcher.suggest('salario', type: TransactionType.expense)?.id,
          isNot('salary'));
    });
  });
}
