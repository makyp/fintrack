import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/account.dart';

class AccountCard extends StatelessWidget {
  final Account account;
  final VoidCallback? onTap;
  final bool compact;

  const AccountCard({
    super.key,
    required this.account,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(account.colorValue);

    if (compact) return _buildCompact(color);
    return _buildFull(color);
  }

  Widget _buildFull(Color color) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.cardPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.08),
                color.withOpacity(0.02),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(account.icon, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(account.name, style: AppTextStyles.labelLarge),
                        Text(
                          account.type.label,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.grey500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null)
                    const Icon(Icons.chevron_right, color: AppColors.grey400),
                ],
              ),
              const SizedBox(height: AppDimensions.md),
              Text(
                CurrencyFormatter.format(account.balance),
                style: AppTextStyles.monoLarge.copyWith(
                  color: account.type.isLiability
                      ? AppColors.danger
                      : AppColors.grey900,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (account.type.isLiability)
                Text(
                  'Saldo a pagar',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompact(Color color) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(account.icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  account.name,
                  style: AppTextStyles.labelMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            CurrencyFormatter.format(account.balance),
            style: AppTextStyles.monoSmall.copyWith(
              color: account.type.isLiability ? AppColors.danger : color,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            account.type.label,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
