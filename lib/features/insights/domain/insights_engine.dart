import '../../../core/utils/currency_formatter.dart';
import '../../budgets/domain/entities/budget.dart';
import '../../reports/domain/models/report_data.dart';
import '../../transactions/domain/entities/transaction.dart';
import 'entities/financial_tip.dart';

/// Turns a [ReportData] snapshot into personalized [FinancialTip]s.
///
/// 100% local and deterministic: every rule is a pure function of the data
/// already computed for the month. No network calls, no cost.
///
/// Priority scale (higher = more important, shown first):
///   100  deficit (spending more than you earn)
///    95  a spending cap was blown
///    85  a spending cap is about to be blown
///    80  low savings rate
///    70  a single category dominating expenses
///    65  every cap respected (praise)
///    60  healthy savings rate (praise)
///    50  moderate savings rate (encourage)
///    10  no data yet
class InsightsEngine {
  const InsightsEngine._();

  /// Generates the full list of applicable tips, sorted by priority desc.
  ///
  /// [budgets] is optional: without caps configured the engine behaves exactly
  /// as before.
  static List<FinancialTip> generate(
    ReportData data, {
    BudgetSummary budgets = const BudgetSummary([]),
  }) {
    final tips = <FinancialTip?>[
      _deficit(data),
      _savingsRate(data),
      _dominantCategory(data),
      _budgetsOver(budgets),
      _budgetsNearLimit(budgets),
      _budgetsRespected(budgets),
      _noData(data),
    ].whereType<FinancialTip>().toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
    return tips;
  }

  // ── Rule: a cap was blown ──────────────────────────────────────────────
  static FinancialTip? _budgetsOver(BudgetSummary b) {
    final over = b.over;
    if (over.isEmpty) return null;
    final worst = over.first;
    final extra = over.length - 1;
    final tail = extra > 0
        ? ' Y $extra tope${extra > 1 ? 's' : ''} más en la misma situación.'
        : '';
    return FinancialTip(
      id: 'budget_over',
      severity: TipSeverity.danger,
      emoji: '🚨',
      title: 'Te pasaste en ${worst.category.label}',
      message: 'Tu tope era ${CurrencyFormatter.format(worst.limit)} y llevas '
          '${CurrencyFormatter.format(worst.spent)}: '
          '${CurrencyFormatter.format(worst.overspent)} de más.$tail',
      priority: 95,
      actionLabel: 'Ver topes',
      actionRoute: '/budgets',
    );
  }

  // ── Rule: a cap is close ───────────────────────────────────────────────
  static FinancialTip? _budgetsNearLimit(BudgetSummary b) {
    final near = b.nearLimit;
    if (near.isEmpty) return null;
    final worst = near.first;
    return FinancialTip(
      id: 'budget_near',
      severity: TipSeverity.warning,
      emoji: '⚠️',
      title: 'Ojo con ${worst.category.label}',
      message: 'Vas en el ${(worst.progress * 100).round()}% de tu tope. Te '
          'quedan ${CurrencyFormatter.format(worst.available)} para el resto '
          'del mes.',
      priority: 85,
      actionLabel: 'Ver topes',
      actionRoute: '/budgets',
    );
  }

  // ── Rule: everything within its cap ────────────────────────────────────
  static FinancialTip? _budgetsRespected(BudgetSummary b) {
    if (b.isEmpty || b.over.isNotEmpty || b.nearLimit.isNotEmpty) return null;
    if (b.totalSpent <= 0) return null;
    return FinancialTip(
      id: 'budget_ok',
      severity: TipSeverity.positive,
      emoji: '✅',
      title: 'Tus topes van bien',
      message: 'Llevas ${CurrencyFormatter.format(b.totalSpent)} de '
          '${CurrencyFormatter.format(b.totalLimit)} presupuestados. Te quedan '
          '${CurrencyFormatter.format(b.totalAvailable)} disponibles.',
      priority: 65,
    );
  }

  // ── Rule 1: spending more than you earn ────────────────────────────────
  static FinancialTip? _deficit(ReportData d) {
    if (d.netBalance >= 0) return null;
    final over = CurrencyFormatter.format(-d.netBalance);
    return FinancialTip(
      id: 'deficit',
      severity: TipSeverity.danger,
      emoji: '⚠️',
      title: 'Gastaste más de lo que ingresó',
      message:
          'Este mes tus gastos superan tus ingresos por $over. Revisa en qué '
          'se te fue el dinero para no descapitalizarte.',
      priority: 100,
      actionLabel: 'Ver reportes',
      actionRoute: '/reports',
    );
  }

  // ── Rule 2: savings rate ───────────────────────────────────────────────
  static FinancialTip? _savingsRate(ReportData d) {
    // Deficit is handled by its own (higher priority) rule.
    if (d.totalIncome <= 0 || d.netBalance < 0) return null;
    final rate = d.netBalance / d.totalIncome;
    final pct = (rate * 100).round();

    if (rate >= 0.20) {
      return FinancialTip(
        id: 'savings_good',
        severity: TipSeverity.positive,
        emoji: '🎉',
        title: '¡Excelente ahorro!',
        message:
            'Ahorraste el $pct% de tus ingresos este mes. Vas por encima de la '
            'meta recomendada del 20%. ¡Sigue así!',
        priority: 60,
      );
    }
    if (rate < 0.10) {
      return FinancialTip(
        id: 'savings_low',
        severity: TipSeverity.warning,
        emoji: '💡',
        title: 'Tu ahorro va justo',
        message:
            'Este mes solo ahorraste el $pct% de tus ingresos. Intenta apartar '
            'al menos el 10% apenas recibas tu dinero, antes de gastarlo.',
        priority: 80,
      );
    }
    return FinancialTip(
      id: 'savings_ok',
      severity: TipSeverity.info,
      emoji: '📈',
      title: 'Vas por buen camino',
      message:
          'Ahorraste el $pct% de tus ingresos este mes. Un pequeño esfuerzo más '
          'y llegas a la meta ideal del 20%.',
      priority: 50,
    );
  }

  // ── Rule 3: one category eating most of the budget ─────────────────────
  static FinancialTip? _dominantCategory(ReportData d) {
    final top = d.topExpense;
    if (top == null || top.percentage < 0.35) return null;
    final pct = (top.percentage * 100).round();
    final TransactionCategory cat = top.category;
    return FinancialTip(
      id: 'dominant_category',
      severity: TipSeverity.info,
      emoji: cat.icon,
      title: 'Tu gasto más fuerte: ${cat.label}',
      message:
          'El $pct% de tus gastos de este mes se fue en ${cat.label}. Es tu '
          'categoría más pesada; revisar aquí es donde más puedes ahorrar.',
      priority: 70,
      actionLabel: 'Ver reportes',
      actionRoute: '/reports',
    );
  }

  // ── Fallback: nothing to analyze yet ───────────────────────────────────
  static FinancialTip? _noData(ReportData d) {
    if (d.totalIncome > 0 || d.totalExpenses > 0) return null;
    return const FinancialTip(
      id: 'no_data',
      severity: TipSeverity.info,
      emoji: '👋',
      title: 'Empieza a recibir consejos',
      message:
          'Registra tus ingresos y gastos de este mes y aquí te mostraré '
          'consejos personalizados sobre tus finanzas.',
      priority: 10,
    );
  }
}
