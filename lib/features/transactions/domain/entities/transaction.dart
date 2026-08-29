import 'package:equatable/equatable.dart';

import '../../../../core/domain/currency_registry.dart';

import '../../../categories/domain/category_registry.dart';
import '../../../categories/domain/entities/transaction_category.dart';
import 'transaction_type.dart';

// Categories used to be an enum declared right here. They are now user-editable
// entities, but every file that imports this one for `TransactionType` /
// `TransactionCategory` keeps working through these re-exports.
export '../../../categories/domain/entities/transaction_category.dart';
export 'transaction_type.dart';

class Transaction extends Equatable {
  final String id;
  final String userId;
  final double amount;
  final TransactionType type;

  /// Only the id is stored. The category itself is resolved on read so a
  /// rename — or a catalog that finished loading after this movement was
  /// built — shows up without having to rebuild the entity.
  final String categoryId;
  final String accountId;
  final String? toAccountId; // for transfers
  final String description;
  final DateTime date;
  final bool isRecurring;
  final String? householdId;
  final String? receiptUrl;
  final List<String> tags;
  final DateTime createdAt;

  /// Number of monthly instalments this purchase was deferred to on a credit
  /// card ("a cuántas cuotas"). null or 1 = paid in a single instalment.
  /// The account balance always carries the full amount: the whole purchase
  /// joins the card debt, the instalments only split how it is paid back.
  final int? installments;

  /// Currency this amount is expressed in — always the one of the account it
  /// was booked against. Copied at write time instead of resolved from the
  /// account later, so changing an account's currency never rewrites history.
  final String currency;

  Transaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required TransactionCategory category,
    required this.accountId,
    this.toAccountId,
    required this.description,
    required this.date,
    this.isRecurring = false,
    this.householdId,
    this.receiptUrl,
    this.tags = const [],
    required this.createdAt,
    this.installments,
    String? currency,
  })  : categoryId = category.id,
        currency = (currency ?? CurrencyRegistry.base).toUpperCase();

  TransactionCategory get category => CategoryRegistry.byId(categoryId);

  /// True when the purchase was split into more than one instalment.
  bool get isDeferred => (installments ?? 1) > 1;

  /// What each monthly instalment costs. Null when it was not deferred.
  double? get installmentAmount =>
      isDeferred ? amount / installments! : null;

  Transaction copyWith({
    double? amount,
    TransactionType? type,
    TransactionCategory? category,
    String? accountId,
    String? toAccountId,
    String? description,
    DateTime? date,
    bool? isRecurring,
    String? receiptUrl,
    List<String>? tags,
    int? installments,
    bool clearInstallments = false,
    String? currency,
  }) {
    return Transaction(
      id: id,
      userId: userId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      description: description ?? this.description,
      date: date ?? this.date,
      isRecurring: isRecurring ?? this.isRecurring,
      householdId: householdId,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      installments:
          clearInstallments ? null : (installments ?? this.installments),
      currency: currency ?? this.currency,
    );
  }

  @override
  List<Object?> get props => [id, userId, amount, type, categoryId, accountId, description, date, installments, currency];
}
