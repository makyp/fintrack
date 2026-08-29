import 'package:equatable/equatable.dart';

/// How the amount was divided between the people involved.
enum SplitMode {
  /// Same share for everyone. The rounding remainder goes to the payer, who
  /// is the one who already fronted the money.
  equal,

  /// Each person's share typed by hand — the case where one bought groceries
  /// for the house and a bottle of wine for themselves.
  custom;

  String get label => this == SplitMode.equal ? 'Partes iguales' : 'Montos a mano';
}

/// An expense one person paid and several people share.
///
/// It lives in the household, not in anyone's own books: the payer's account
/// balance is only touched if they also registered it as a normal movement.
/// What this tracks is who ended up owing whom.
class SharedExpense extends Equatable {
  final String id;
  final String householdId;
  final String description;

  /// Total paid, always positive.
  final double amount;
  final String currency;
  final DateTime date;

  /// Member who put the money in.
  final String paidBy;

  /// What each member owes of this expense, keyed by uid. Adds up to [amount].
  final Map<String, double> shares;

  final SplitMode mode;
  final String categoryId;
  final String createdBy;
  final DateTime createdAt;

  const SharedExpense({
    required this.id,
    required this.householdId,
    required this.description,
    required this.amount,
    required this.currency,
    required this.date,
    required this.paidBy,
    required this.shares,
    required this.mode,
    this.categoryId = 'other',
    required this.createdBy,
    required this.createdAt,
  });

  List<String> get participants => shares.keys.toList();

  /// What [uid] still owes for this expense: their share, minus their own
  /// money if they were the one who paid.
  double balanceFor(String uid) {
    final owed = shares[uid] ?? 0;
    final paid = paidBy == uid ? amount : 0;
    return paid - owed;
  }

  /// Splits [amount] evenly between [uids], handing the rounding leftover to
  /// [payer] so the shares always add back up to the total to the cent.
  static Map<String, double> equalShares(
    double amount,
    List<String> uids,
    String payer,
  ) {
    if (uids.isEmpty) return const {};
    final cents = (amount * 100).round();
    final base = cents ~/ uids.length;
    var remainder = cents - base * uids.length;

    final shares = <String, double>{};
    for (final uid in uids) {
      var share = base;
      // Spread the leftover cents one by one, starting with the payer.
      if (remainder > 0 && (uid == payer || !uids.contains(payer))) {
        share += remainder;
        remainder = 0;
      }
      shares[uid] = share / 100;
    }
    return shares;
  }

  @override
  List<Object?> get props =>
      [id, householdId, description, amount, currency, date, paidBy, shares, mode];
}

/// Money one member handed another to square up.
class Settlement extends Equatable {
  final String id;
  final String householdId;
  final String from;
  final String to;
  final double amount;
  final String currency;
  final DateTime date;
  final String createdBy;

  const Settlement({
    required this.id,
    required this.householdId,
    required this.from,
    required this.to,
    required this.amount,
    required this.currency,
    required this.date,
    required this.createdBy,
  });

  @override
  List<Object?> get props => [id, householdId, from, to, amount, currency, date];
}
