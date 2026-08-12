import 'package:equatable/equatable.dart';

/// Severity of a financial tip. Drives the card's color + icon.
enum TipSeverity { positive, info, warning, danger }

/// A single piece of advice generated locally from the user's own data.
///
/// Tips are produced by [InsightsEngine] purely from a [ReportData] snapshot —
/// no network, no external service, no cost.
class FinancialTip extends Equatable {
  final String id;
  final TipSeverity severity;
  final String emoji;
  final String title;
  final String message;

  /// Higher shows first. See [InsightsEngine] for the scale.
  final int priority;

  /// Optional call-to-action. When both are set the card is tappable.
  final String? actionLabel;
  final String? actionRoute;

  const FinancialTip({
    required this.id,
    required this.severity,
    required this.emoji,
    required this.title,
    required this.message,
    this.priority = 0,
    this.actionLabel,
    this.actionRoute,
  });

  @override
  List<Object?> get props =>
      [id, severity, emoji, title, message, priority, actionLabel, actionRoute];
}
