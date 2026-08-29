import 'entities/shared_expense.dart';

/// One member's position in the household: what they are owed (positive) or
/// what they owe (negative).
class MemberBalance {
  final String uid;
  final double net;

  const MemberBalance(this.uid, this.net);

  bool get isCreditor => net > 0.005;
  bool get isDebtor => net < -0.005;
  bool get isSettled => !isCreditor && !isDebtor;
}

/// "X le paga Y a Z" — one payment that cancels part of the debt.
class Transfer {
  final String from;
  final String to;
  final double amount;

  const Transfer({required this.from, required this.to, required this.amount});
}

/// Works out who owes whom from the shared expenses and the payments already
/// made between members.
class SettlementCalculator {
  const SettlementCalculator._();

  /// Net position per member. Everyone in [members] appears, even at zero, so
  /// the UI can show the whole household rather than only the people involved
  /// in the last expense.
  static List<MemberBalance> balances({
    required List<String> members,
    required List<SharedExpense> expenses,
    required List<Settlement> settlements,
  }) {
    final net = {for (final uid in members) uid: 0.0};

    for (final expense in expenses) {
      // Someone who left the household can still appear in an old expense;
      // keep their number so the totals stay square.
      net[expense.paidBy] = (net[expense.paidBy] ?? 0) + expense.amount;
      expense.shares.forEach((uid, share) {
        net[uid] = (net[uid] ?? 0) - share;
      });
    }

    // Paying someone back cancels the debt on both sides.
    for (final s in settlements) {
      net[s.from] = (net[s.from] ?? 0) + s.amount;
      net[s.to] = (net[s.to] ?? 0) - s.amount;
    }

    final result = net.entries
        .map((e) => MemberBalance(e.key, _round(e.value)))
        .toList();
    // Biggest creditor first: that is the order the list reads best in.
    result.sort((a, b) => b.net.compareTo(a.net));
    return result;
  }

  /// The shortest list of payments that clears every balance.
  ///
  /// Greedy largest-debtor-to-largest-creditor. It is not provably the minimum
  /// in every case — that problem is NP-hard — but for a household of three or
  /// four people it always lands on the obvious answer, and it never invents a
  /// payment that isn't owed.
  static List<Transfer> settlements(List<MemberBalance> balances) {
    final creditors = balances.where((b) => b.isCreditor).toList()
      ..sort((a, b) => b.net.compareTo(a.net));
    final debtors = balances.where((b) => b.isDebtor).toList()
      ..sort((a, b) => a.net.compareTo(b.net));

    final owed = {for (final c in creditors) c.uid: c.net};
    final owes = {for (final d in debtors) d.uid: -d.net};

    final transfers = <Transfer>[];
    var ci = 0;
    var di = 0;
    while (ci < creditors.length && di < debtors.length) {
      final creditor = creditors[ci].uid;
      final debtor = debtors[di].uid;
      final amount = _round(
          owed[creditor]! < owes[debtor]! ? owed[creditor]! : owes[debtor]!);

      if (amount > 0.005) {
        transfers.add(Transfer(from: debtor, to: creditor, amount: amount));
        owed[creditor] = _round(owed[creditor]! - amount);
        owes[debtor] = _round(owes[debtor]! - amount);
      }

      if (owed[creditor]! <= 0.005) ci++;
      if (owes[debtor]! <= 0.005) di++;
    }
    return transfers;
  }

  /// Cents, not floating dust: 0.30000000000000004 has no business in a
  /// balance the user reads.
  static double _round(double v) => (v * 100).round() / 100;
}
