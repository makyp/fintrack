import 'package:equatable/equatable.dart';

class AppBadge extends Equatable {
  final String id;
  final String icon;
  final String name;
  final String description;
  final DateTime? earnedAt;

  const AppBadge({
    required this.id,
    required this.icon,
    required this.name,
    required this.description,
    this.earnedAt,
  });

  bool get isEarned => earnedAt != null;

  AppBadge withEarnedAt(DateTime? dt) => AppBadge(
        id: id,
        icon: icon,
        name: name,
        description: description,
        earnedAt: dt,
      );

  static const catalog = [
    // ── Transacciones ──────────────────────────────────────────────────────
    AppBadge(id: 'first_tx',    icon: '🌱', name: 'Primer paso',      description: 'Registra tu primera transacción'),
    AppBadge(id: 'tx_5',        icon: '✍️', name: 'Tomando el hábito', description: 'Registra 5 transacciones'),
    AppBadge(id: 'tx_10',       icon: '💰', name: 'Registrador',       description: 'Registra 10 transacciones'),
    AppBadge(id: 'tx_25',       icon: '📋', name: 'Meticuloso',        description: 'Registra 25 transacciones'),
    AppBadge(id: 'tx_50',       icon: '📊', name: 'Analista',          description: 'Registra 50 transacciones'),
    AppBadge(id: 'tx_100',      icon: '🚀', name: 'Experto',           description: 'Registra 100 transacciones'),
    AppBadge(id: 'tx_250',      icon: '💎', name: 'Maestro del control', description: 'Registra 250 transacciones'),
    AppBadge(id: 'tx_500',      icon: '👑', name: 'Leyenda financiera', description: 'Registra 500 transacciones'),

    // ── Racha diaria ───────────────────────────────────────────────────────
    AppBadge(id: 'streak_2',    icon: '⚡', name: 'Dos en fila',       description: 'Mantén una racha de 2 días'),
    AppBadge(id: 'streak_3',    icon: '📅', name: 'Constante',         description: 'Racha de 3 días seguidos'),
    AppBadge(id: 'streak_5',    icon: '🎯', name: 'Disciplinado',      description: 'Racha de 5 días seguidos'),
    AppBadge(id: 'streak_7',    icon: '🔥', name: 'En llamas',         description: 'Racha de 7 días seguidos'),
    AppBadge(id: 'streak_14',   icon: '🌟', name: 'Dos semanas',       description: 'Racha de 14 días seguidos'),
    AppBadge(id: 'streak_30',   icon: '💪', name: 'Imparable',         description: 'Racha increíble de 30 días'),
    AppBadge(id: 'streak_60',   icon: '🏅', name: 'Dos meses',         description: 'Racha de 60 días seguidos'),
    AppBadge(id: 'streak_90',   icon: '🏆', name: 'Trimestral',        description: 'Racha de 90 días consecutivos'),

    // ── Ingresos ───────────────────────────────────────────────────────────
    AppBadge(id: 'first_income',      icon: '💵', name: 'Primer ingreso',      description: 'Registra tu primer ingreso'),
    AppBadge(id: 'income_1m_total',   icon: '🏦', name: 'Primer millón',       description: 'Acumula \$1.000.000 en ingresos totales'),
    AppBadge(id: 'income_10m_total',  icon: '💸', name: 'Diez millones',       description: 'Acumula \$10.000.000 en ingresos totales'),
    AppBadge(id: 'income_1m_month',   icon: '📈', name: 'Millonario del mes',  description: 'Supera \$1.000.000 de ingresos en un mes'),
    AppBadge(id: 'income_5m_month',   icon: '🤑', name: 'Gran mes',            description: 'Supera \$5.000.000 de ingresos en un mes'),

    // ── Ahorro ─────────────────────────────────────────────────────────────
    AppBadge(id: 'saver_10',  icon: '🐷', name: 'Ahorrando algo',    description: 'Ahorra el 10% de tus ingresos en un mes'),
    AppBadge(id: 'saver_20',  icon: '💰', name: 'Buen ahorro',       description: 'Ahorra el 20% de tus ingresos en un mes'),
    AppBadge(id: 'saver_30',  icon: '🌿', name: 'Ahorrador serio',   description: 'Ahorra el 30% de tus ingresos en un mes'),
    AppBadge(id: 'saver_50',  icon: '🧠', name: 'Genio financiero',  description: 'Ahorra el 50% de tus ingresos en un mes'),

    // ── Gastos ─────────────────────────────────────────────────────────────
    AppBadge(id: 'first_expense',       icon: '🛒', name: 'Primer gasto',        description: 'Registra tu primer gasto'),
    AppBadge(id: 'big_spender_500k',    icon: '💳', name: 'Gran compra',         description: 'Un gasto mayor a \$500.000'),
    AppBadge(id: 'big_spender_2m',      icon: '🎩', name: 'Compra premium',      description: 'Un gasto mayor a \$2.000.000'),
    AppBadge(id: 'big_spender_5m',      icon: '✈️', name: 'Desembolso mayor',    description: 'Un gasto mayor a \$5.000.000'),

    // ── Categorías / diversificación ───────────────────────────────────────
    AppBadge(id: 'diversified_3',  icon: '🗂️', name: 'Variado',         description: 'Usa 3 categorías distintas'),
    AppBadge(id: 'diversified_5',  icon: '🌈', name: 'Multifacético',   description: 'Usa 5 categorías distintas'),
    AppBadge(id: 'diversified_8',  icon: '🎨', name: 'Completo',        description: 'Usa 8 categorías distintas'),

    // ── Horario especial ───────────────────────────────────────────────────
    AppBadge(id: 'night_owl',   icon: '🦉', name: 'Ave nocturna',    description: 'Registra una transacción pasada las 11pm'),
    AppBadge(id: 'early_bird',  icon: '🐦', name: 'Madrugador',      description: 'Registra una transacción antes de las 7am'),

    // ── Metas ──────────────────────────────────────────────────────────────
    AppBadge(id: 'first_goal',         icon: '🎯', name: 'Visionario',          description: 'Crea tu primera meta de ahorro'),
    AppBadge(id: 'goals_3',            icon: '🗺️', name: 'Planificador',        description: 'Crea 3 metas de ahorro'),
    AppBadge(id: 'goals_5',            icon: '📍', name: 'Ambicioso',           description: 'Crea 5 metas de ahorro'),
    AppBadge(id: 'goals_10',           icon: '🌠', name: 'Gran soñador',        description: 'Crea 10 metas de ahorro'),
    AppBadge(id: 'goal_completed',     icon: '🏆', name: 'Logrado',             description: 'Completa una meta de ahorro'),
    AppBadge(id: 'goals_3_completed',  icon: '🥉', name: 'Cumplidor',           description: 'Completa 3 metas de ahorro'),
    AppBadge(id: 'goals_5_completed',  icon: '🥇', name: 'Implacable',          description: 'Completa 5 metas de ahorro'),
    AppBadge(id: 'big_goal',           icon: '🏔️', name: 'Meta grande',         description: 'Crea una meta de \$5.000.000 o más'),

    // ── Transacciones recurrentes ──────────────────────────────────────────
    AppBadge(id: 'first_recurring',  icon: '🔄', name: 'Automatizado',    description: 'Configura tu primera transacción recurrente'),
    AppBadge(id: 'recurring_3',      icon: '📆', name: 'Organizado',      description: 'Tienes 3 transacciones recurrentes activas'),
    AppBadge(id: 'recurring_5',      icon: '⚙️', name: 'Máquina bien aceitada', description: 'Tienes 5 transacciones recurrentes activas'),
  ];

  @override
  List<Object?> get props => [id, earnedAt];
}
