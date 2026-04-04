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
    AppBadge(id: 'first_tx',        icon: '🌱', name: 'Primer paso',   description: 'Registra tu primera transacción'),
    AppBadge(id: 'tx_10',           icon: '💰', name: 'Registrador',   description: 'Registra 10 transacciones'),
    AppBadge(id: 'tx_50',           icon: '📊', name: 'Analista',      description: 'Registra 50 transacciones'),
    AppBadge(id: 'tx_100',          icon: '🚀', name: 'Experto',       description: 'Registra 100 transacciones'),
    AppBadge(id: 'streak_3',        icon: '📅', name: 'Constante',     description: 'Mantén una racha de 3 días seguidos'),
    AppBadge(id: 'streak_7',        icon: '🔥', name: 'En llamas',     description: 'Racha de 7 días seguidos'),
    AppBadge(id: 'streak_30',       icon: '💪', name: 'Imparable',     description: 'Racha increíble de 30 días'),
    AppBadge(id: 'first_goal',      icon: '🎯', name: 'Visionario',    description: 'Crea tu primera meta de ahorro'),
    AppBadge(id: 'goal_completed',  icon: '🏆', name: 'Logrado',       description: 'Completa una meta de ahorro'),
    AppBadge(id: 'first_recurring', icon: '🔄', name: 'Planificador',  description: 'Configura una transacción recurrente'),
  ];

  @override
  List<Object?> get props => [id, earnedAt];
}
