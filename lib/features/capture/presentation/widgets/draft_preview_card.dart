import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../domain/entities/transaction_draft.dart';

/// Shows what the parser understood before the user commits to it.
///
/// The point is honesty: anything that could not be read is called out as
/// "sin detectar" instead of being silently defaulted, so the user knows what
/// they still have to fill in on the form.
class DraftPreviewCard extends StatelessWidget {
  final TransactionDraft draft;

  const DraftPreviewCard({super.key, required this.draft});

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(draft.type);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_typeIcon(draft.type), size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                _typeLabel(draft.type),
                style: AppTextStyles.labelMedium.copyWith(color: color),
              ),
              const Spacer(),
              Text(
                draft.source.label,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          if (draft.hasAmount)
            Text(
              CurrencyFormatter.format(draft.amount!),
              style: AppTextStyles.displaySmall.copyWith(color: color),
            )
          else
            Text(
              'Monto sin detectar',
              style: AppTextStyles.headlineSmall.copyWith(color: AppColors.grey500),
            ),
          const SizedBox(height: AppDimensions.sm),
          if (draft.merchant != null)
            _row(Icons.storefront_outlined, draft.merchant!)
          else
            _row(
              Icons.notes,
              draft.description ?? 'Sin descripción',
              muted: draft.description == null,
            ),
          if (draft.products.isNotEmpty) _buildProducts(),
          if (draft.category != null)
            _row(null, '${draft.category!.icon}  ${draft.category!.label}'),
          _row(
            Icons.calendar_today_outlined,
            draft.date == null ? 'Hoy' : _formatDate(draft.date!),
            muted: draft.date == null,
          ),
        ],
      ),
    );
  }

  /// The line items read off the receipt, so the user can check at a glance
  /// that the OCR grabbed products and not codes.
  Widget _buildProducts() {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shopping_basket_outlined,
              size: 15, color: AppColors.grey500),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final product in draft.products)
                  Text(
                    '• $product',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.grey700),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData? icon, String text, {bool muted = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: AppColors.grey500),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: muted ? AppColors.grey500 : AppColors.grey700,
                fontStyle: muted ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _typeColor(TransactionType? type) {
    switch (type) {
      case TransactionType.income:
        return AppColors.success;
      case TransactionType.transfer:
        return AppColors.secondary;
      case TransactionType.expense:
      case null:
        return AppColors.danger;
    }
  }

  static IconData _typeIcon(TransactionType? type) {
    switch (type) {
      case TransactionType.income:
        return Icons.add_circle_outline;
      case TransactionType.transfer:
        return Icons.swap_horiz;
      case TransactionType.expense:
      case null:
        return Icons.remove_circle_outline;
    }
  }

  static String _typeLabel(TransactionType? type) {
    switch (type) {
      case TransactionType.income:
        return 'Ingreso';
      case TransactionType.transfer:
        return 'Transferencia';
      case TransactionType.expense:
        return 'Gasto';
      case null:
        return 'Gasto (asumido)';
    }
  }

  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    return '${date.day}/${date.month}/${date.year}';
  }
}
