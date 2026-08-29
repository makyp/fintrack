import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../data/bank_notification_service.dart';
import '../../domain/bank_notification_parser.dart';
import '../../../transactions/domain/entities/transaction_type.dart';
import '../../domain/entities/transaction_draft.dart';

/// The movements read from the bank's own notifications, waiting to be
/// confirmed.
///
/// Picking one pops the draft, exactly like the voice and receipt sheets do:
/// it prefills the normal form and nothing is saved until the user says so.
class DetectedMovementsSheet extends StatefulWidget {
  const DetectedMovementsSheet({super.key});

  static Future<TransactionDraft?> show(BuildContext context) {
    return showModalBottomSheet<TransactionDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DetectedMovementsSheet(),
    );
  }

  @override
  State<DetectedMovementsSheet> createState() => _DetectedMovementsSheetState();
}

class _DetectedMovementsSheetState extends State<DetectedMovementsSheet> {
  bool _loading = true;
  bool _hasAccess = false;
  bool _enabled = false;
  List<BankNotification> _notifications = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final hasAccess = await BankNotificationService.hasAccess();
    final enabled = await BankNotificationService.isEnabled();
    final pending = await BankNotificationService.pending();
    if (!mounted) return;
    setState(() {
      _hasAccess = hasAccess;
      _enabled = enabled;
      // Only the ones that actually read as a movement reach the list: the
      // native side keeps anything that smells like one, the parser here is
      // the strict pass.
      _notifications = pending
          .where((n) => BankNotificationParser.parse(n) != null)
          .toList();
      _loading = false;
    });
  }

  Future<void> _turnOn() async {
    await BankNotificationService.setEnabled(true);
    if (!await BankNotificationService.hasAccess()) {
      await BankNotificationService.openSettings();
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85),
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
          Text('Movimientos detectados',
              style: AppTextStyles.headlineSmall),
          const SizedBox(height: AppDimensions.xs),
          Text(
            'Leídos de las notificaciones que te manda tu banco. Nada se '
            'guarda hasta que lo confirmes.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
          ),
          const SizedBox(height: AppDimensions.lg),
          Flexible(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (!BankNotificationService.isSupported) {
      return _message(
        Icons.phone_iphone_outlined,
        'Solo disponible en Android',
        'iOS no permite que una app lea las notificaciones de otra, así que '
            'aquí no hay nada que activar.',
      );
    }
    if (!_enabled || !_hasAccess) return _buildActivation();
    if (_notifications.isEmpty) {
      return _message(
        Icons.notifications_none_rounded,
        'Todavía no hay nada',
        'La próxima compra que te notifique el banco aparecerá aquí lista '
            'para confirmar.',
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      itemCount: _notifications.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) => _buildTile(_notifications[i]),
    );
  }

  Widget _buildActivation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cómo funciona', style: AppTextStyles.labelLarge),
              const SizedBox(height: AppDimensions.xs),
              Text(
                'Android pide un permiso especial para leer notificaciones. '
                'Se concede una sola vez en Ajustes. La app solo guarda las '
                'que hablan de un movimiento (un monto y una compra, un pago '
                'o un abono) y todo se queda en el teléfono: no se envía a '
                'ningún servidor ni se lee nada más.',
                style:
                    AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.lg),
        ElevatedButton.icon(
          onPressed: _turnOn,
          icon: const Icon(Icons.lock_open_outlined, size: 18),
          label: Text(_hasAccess ? 'Activar' : 'Conceder acceso'),
        ),
        if (_enabled && !_hasAccess) ...[
          const SizedBox(height: AppDimensions.sm),
          Text(
            'Falta el permiso del sistema. Búscanos en «Acceso a '
            'notificaciones» y vuelve a esta pantalla.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
          ),
        ],
      ],
    );
  }

  Widget _buildTile(BankNotification notification) {
    final draft = BankNotificationParser.parse(notification)!;
    final isExpense = draft.type == TransactionType.expense;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor:
            (isExpense ? AppColors.danger : AppColors.success).withOpacity(0.12),
        child: Icon(
          isExpense ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          size: 18,
          color: isExpense ? AppColors.danger : AppColors.success,
        ),
      ),
      title: Text(draft.description ?? 'Movimiento',
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${DateFormatter.formatRelative(notification.postedAt)} · '
        '${draft.category?.label ?? 'Sin categoría'}',
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            CurrencyFormatter.format(draft.amount ?? 0),
            style: AppTextStyles.monoSmall.copyWith(
              color: isExpense ? AppColors.danger : AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: AppColors.grey400,
            tooltip: 'Descartar',
            onPressed: () async {
              await BankNotificationService.remove([notification]);
              await _load();
            },
          ),
        ],
      ),
      onTap: () async {
        // Taking it out of the queue here is deliberate: if the user then
        // cancels the form, the notification is gone but nothing was booked.
        // Leaving it would mean the same purchase reappears every time.
        await BankNotificationService.remove([notification]);
        if (mounted) Navigator.of(context).pop(draft);
      },
    );
  }

  Widget _message(IconData icon, String title, String body) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(icon, size: 44, color: AppColors.grey400),
          const SizedBox(height: AppDimensions.md),
          Text(title, style: AppTextStyles.labelLarge),
          const SizedBox(height: AppDimensions.xs),
          Text(body,
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.grey500)),
        ],
      ),
    );
  }
}
