import 'package:equatable/equatable.dart';

import '../../../transactions/domain/entities/transaction.dart';

/// How a draft was captured.
enum CaptureSource {
  voice,
  receipt,
  manual;

  String get label {
    switch (this) {
      case CaptureSource.voice:
        return 'Dictado por voz';
      case CaptureSource.receipt:
        return 'Leído del recibo';
      case CaptureSource.manual:
        return 'Manual';
    }
  }
}

/// A *preregistro*: everything the parser could pull out of a dictation or a
/// receipt photo. It is never persisted — it only prefills
/// `TransactionFormPage`, where the user confirms before anything is saved.
///
/// Every field is nullable on purpose: the form keeps its own default for
/// whatever the parser could not determine.
class TransactionDraft extends Equatable {
  final double? amount;
  final TransactionType? type;
  final TransactionCategory? category;
  final String? description;
  final DateTime? date;
  final CaptureSource source;

  /// Receipt only: the store name read from the header.
  final String? merchant;

  /// Receipt only: the line items identified on the receipt.
  final List<String> products;

  /// The dictation transcript or the raw OCR text, kept so the user can see
  /// what was understood when something looks off.
  final String rawText;

  const TransactionDraft({
    this.amount,
    this.type,
    this.category,
    this.description,
    this.date,
    required this.source,
    this.merchant,
    this.products = const [],
    this.rawText = '',
  });

  /// True when nothing useful was extracted — the sheet then shows a hint
  /// instead of an empty preview.
  bool get isEmpty => amount == null && (description == null || description!.isEmpty);

  /// The amount is what makes a draft worth confirming; without it the user
  /// still has to type the most important field.
  bool get hasAmount => amount != null && amount! > 0;

  TransactionDraft copyWith({
    double? amount,
    TransactionType? type,
    TransactionCategory? category,
    String? description,
    DateTime? date,
  }) {
    return TransactionDraft(
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      source: source,
      merchant: merchant,
      products: products,
      rawText: rawText,
    );
  }

  @override
  List<Object?> get props => [
        amount,
        type,
        category,
        description,
        date,
        source,
        merchant,
        products,
        rawText,
      ];
}
