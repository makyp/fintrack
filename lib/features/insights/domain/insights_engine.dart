import '../../../core/utils/currency_formatter.dart';
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
///    80  low savings rate
///    70  a single category dominating expenses
///    60  healthy savings rate (praise)
///    50  moderate savings rate (encourage)
///    10  no data yet
class InsightsEngine {
  const InsightsEngine._();

  /// Generates the full list of applicable tips, sorted by priority desc.
  static List<FinancialTip> generate(ReportData data) {
    final tips = <FinancialTip?>[
      _deficit(data),
      _savingsRate(data),
      _dominantCategory(data),
      _noData(data),
    ].whereType<FinancialTip>().toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
    return tips;
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
