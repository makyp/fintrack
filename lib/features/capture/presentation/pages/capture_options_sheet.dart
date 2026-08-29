import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/capture_platform.dart';
import '../../domain/entities/transaction_draft.dart';
import 'receipt_capture_sheet.dart';
import 'voice_capture_sheet.dart';
import '../../data/bank_notification_service.dart';
import 'detected_movements_sheet.dart';

/// Runs the whole capture flow: asks *how* the user wants to register, runs
/// that route, and returns the resulting draft.
///
/// Returns `null` if the user backs out at any point. A draft with
/// [CaptureSource.manual] and no fields means "just open the empty form".
Future<TransactionDraft?> showCaptureFlow(BuildContext context) async {
  final choice = await showModalBottomSheet<CaptureSource>(
    context: context,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const CaptureOptionsSheet(),
  );
  if (choice == null || !context.mounted) return null;

  switch (choice) {
    case CaptureSource.voice:
      return VoiceCaptureSheet.show(context);
    case CaptureSource.receipt:
      return ReceiptCaptureSheet.show(context);
    case CaptureSource.notification:
      return DetectedMovementsSheet.show(context);
    case CaptureSource.manual:
      return const TransactionDraft(source: CaptureSource.manual);
  }
}

/// The three ways to start a transaction. Pops with the chosen route.
class CaptureOptionsSheet extends StatelessWidget {
  const CaptureOptionsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pagePadding,
        AppDimensions.sm,
        AppDimensions.pagePadding,
        AppDimensions.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppDimensions.md),
              decoration: BoxDecoration(
                color: AppColors.grey200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Nuevo movimiento', style: AppTextStyles.headlineSmall),
          const SizedBox(height: AppDimensions.xs),
          Text(
            'Elige cómo prefieres registrarlo',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
          ),
          const SizedBox(height: AppDimensions.lg),
          if (CapturePlatform.supportsVoice)
            _option(
              context,
              icon: Icons.mic_none_rounded,
              color: primary,
              title: 'Dictar por voz',
              subtitle: '«gasté 25 mil en almuerzo»',
              source: CaptureSource.voice,
            ),
          if (CapturePlatform.supportsReceiptOcr)
            _option(
              context,
              icon: Icons.receipt_long_outlined,
              color: AppColors.secondary,
              title: 'Foto del recibo',
              subtitle: 'Leo el total sin que escribas nada',
              source: CaptureSource.receipt,
            ),
          if (BankNotificationService.isSupported)
            _option(
              context,
              icon: Icons.notifications_active_outlined,
              color: AppColors.warning,
              title: 'Detectados por el banco',
              subtitle: 'De las notificaciones que ya te llegan',
              source: CaptureSource.notification,
            ),
          _option(
            context,
            icon: Icons.edit_outlined,
            color: AppColors.grey600,
            title: 'Escribirlo yo',
            subtitle: 'El formulario de siempre',
            source: CaptureSource.manual,
          ),
        ],
      ),
    );
  }

  Widget _option(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required CaptureSource source,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.sm),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(source),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: color.withOpacity(0.18)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.labelLarge),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.grey500),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.grey400),
            ],
          ),
        ),
      ),
    );
  }
}
