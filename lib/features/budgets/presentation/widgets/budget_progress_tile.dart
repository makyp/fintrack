import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/budget.dart';

/// One cap with its progress bar and the plain-language verdict:
/// how much is left, or how far past the cap the user went.
class BudgetProgressTile extends StatelessWidget {
  final BudgetStatus status;
  final VoidCallback? onTap;

  const BudgetProgressTile({super.key, required this.status, this.onTap});

  Color get _color {
    if (status.isOver) return AppColors.danger;
    if (status.isNearLimit) return AppColors.warning;
    return AppColors.success;
  }

  String get _verdict {
    if (status.isOver) {
      return 'Te pasaste ${CurrencyFormatter.format(status.overspent)}';
    }
    return 'Te queda ${CurrencyFormatter.format(status.available)}';
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.sm),
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
              color: status.isHealthy ? AppColors.grey200 : color.withOpacity(0.45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(status.category.icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: Text(status.category.label,
                      style: AppTextStyles.labelLarge),
                ),
                Text(
                  '${(status.progress * 100).round()}%',
                  style: AppTextStyles.labelLarge.copyWith(color: color),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                // The bar caps at 100%; the overspend is spelled out below it.
                value: status.progress.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: AppColors.grey100,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${CurrencyFormatter.format(status.spent)} de '
                    '${CurrencyFormatter.format(status.limit)}',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.grey500),
                  ),
                ),
                Text(
                  _verdict,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
