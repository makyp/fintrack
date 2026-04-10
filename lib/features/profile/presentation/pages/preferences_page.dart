import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/local_notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class PreferencesPage extends StatefulWidget {
  const PreferencesPage({super.key});

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late String _currency;
  // Multiple reminder times stored as TimeOfDay list (max 5)
  final List<TimeOfDay> _reminders = [];
  bool _isLoading = false;

  static const _currencies = ['COP', 'USD', 'EUR', 'MXN', 'ARS', 'BRL', 'PEN', 'CLP'];
  static const _maxReminders = 5;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthBloc>().state.user;
    _nameCtrl = TextEditingController(text: user?.displayName ?? '');
    _currency = user?.currency ?? 'COP';

    // Parse stored reminders — stored as comma-separated "HH:mm" values
    final stored = user?.reminderTime ?? '';
    for (final part in stored.split(',')) {
      final s = part.trim();
      if (s.isEmpty) continue;
      final p = s.split(':');
      if (p.length != 2) continue;
      final h = int.tryParse(p[0]);
      final m = int.tryParse(p[1]);
      if (h != null && m != null) {
        _reminders.add(TimeOfDay(hour: h, minute: m));
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _addReminder() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 20, minute: 0),
    );
    if (picked != null && mounted) {
      // Avoid exact duplicates
      final dup = _reminders.any(
          (t) => t.hour == picked.hour && t.minute == picked.minute);
      if (!dup) {
        setState(() {
          _reminders.add(picked);
          _reminders.sort(
              (a, b) => a.hour * 60 + a.minute - (b.hour * 60 + b.minute));
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final user = context.read<AuthBloc>().state.user;
    final newName = _nameCtrl.text.trim();
    final reminderStr = _reminders.map(_fmt).join(',');

    context.read<AuthBloc>().add(AuthProfileUpdateRequested(
          displayName: newName != user?.displayName ? newName : null,
          currency: _currency != user?.currency ? _currency : null,
          reminderTime: reminderStr,
        ));

    // Schedule local notifications
    if (_reminders.isEmpty) {
      await LocalNotificationService.cancelAll();
    } else {
      await LocalNotificationService.scheduleReminders(
          _reminders.map(_fmt).toList());
    }

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferencias guardadas')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preferencias')),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.pagePadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Nombre ─────────────────────────────────────────────
                  Text('Información personal', style: AppTextStyles.labelLarge),
                  const SizedBox(height: AppDimensions.md),
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'El nombre no puede estar vacío'
                        : null,
                  ),

                  // ── Moneda ─────────────────────────────────────────────
                  const SizedBox(height: AppDimensions.xl),
                  Text('Moneda', style: AppTextStyles.labelLarge),
                  const SizedBox(height: AppDimensions.sm),
                  Text(
                    'Afecta cómo se muestran los valores en toda la app.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.grey500),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  Wrap(
                    spacing: AppDimensions.sm,
                    runSpacing: AppDimensions.sm,
                    children: _currencies.map((c) {
                      final isSelected = _currency == c;
                      return ChoiceChip(
                        label: Text(c),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _currency = c),
                        selectedColor: AppColors.primary.withOpacity(0.15),
                        labelStyle: AppTextStyles.labelMedium.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.grey700,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),

                  // ── Recordatorios ──────────────────────────────────────
                  const SizedBox(height: AppDimensions.xl),
                  Row(
                    children: [
                      Text('Recordatorios', style: AppTextStyles.labelLarge),
                      const Spacer(),
                      if (_reminders.length < _maxReminders)
                        TextButton.icon(
                          onPressed: _addReminder,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Agregar'),
                          style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  Text(
                    'Puedes configurar hasta $_maxReminders recordatorios diarios. '
                    'Te aparecerán como notificaciones en tu dispositivo.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.grey500),
                  ),
                  const SizedBox(height: AppDimensions.md),

                  if (_reminders.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.grey200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_off_outlined,
                              color: AppColors.grey400),
                          const SizedBox(width: 12),
                          Text('Sin recordatorios configurados',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.grey400)),
                        ],
                      ),
                    )
                  else
                    ...List.generate(_reminders.length, (i) {
                      final t = _reminders[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.alarm_rounded,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              t.format(context),
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close,
                                  size: 18, color: AppColors.grey400),
                              onPressed: () =>
                                  setState(() => _reminders.removeAt(i)),
                              tooltip: 'Eliminar',
                            ),
                          ],
                        ),
                      );
                    }),

                  // ── Guardar ────────────────────────────────────────────
                  const SizedBox(height: AppDimensions.xl),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white))
                          : const Text('Guardar cambios'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
