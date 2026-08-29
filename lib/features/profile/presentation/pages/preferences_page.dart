import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/domain/currency.dart';
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
  /// Units of the base currency one unit of each foreign currency is worth.
  /// Kept as text while editing so a half-typed "4." doesn't reset the field.
  final Map<String, TextEditingController> _rateCtrls = {};
  // Multiple reminder times stored as TimeOfDay list (max 5)
  final List<TimeOfDay> _reminders = [];
  bool _isLoading = false;

  static final _currencies = Currency.catalog.map((c) => c.code).toList();
  static const _maxReminders = 5;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthBloc>().state.user;
    _nameCtrl = TextEditingController(text: user?.displayName ?? '');
    _currency = user?.currency ?? 'COP';
    for (final e in (user?.exchangeRates ?? const <String, double>{}).entries) {
      _rateCtrls[e.key] = TextEditingController(text: _rateText(e.value));
    }

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
    for (final c in _rateCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Drops the trailing ".0" on whole rates (4000, not 4000.0) but keeps the
  /// decimals of a rate like 0.92 EUR.
  static String _rateText(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  Map<String, double> get _editedRates {
    final out = <String, double>{};
    for (final e in _rateCtrls.entries) {
      if (e.key == _currency) continue; // the base is always 1
      final v = double.tryParse(e.value.text.trim().replaceAll(',', '.'));
      if (v != null && v > 0) out[e.key] = v;
    }
    return out;
  }

  Future<void> _addRateCurrency() async {
    final available = Currency.catalog
        .where((c) => c.code != _currency && !_rateCtrls.containsKey(c.code))
        .toList();
    if (available.isEmpty) return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final c in available)
              ListTile(
                title: Text(c.label),
                trailing: Text(c.symbol, style: AppTextStyles.labelMedium),
                onTap: () => Navigator.of(ctx).pop(c.code),
              ),
          ],
        ),
      ),
    );
    if (picked != null && mounted) {
      setState(() => _rateCtrls[picked] = TextEditingController());
    }
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
          exchangeRates: _editedRates,
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

  Widget _buildRateRow(String code) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.sm),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Text('1 $code',
                style: AppTextStyles.labelMedium),
          ),
          Text('=', style: AppTextStyles.bodyMedium),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: TextFormField(
              controller: _rateCtrls[code],
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                isDense: true,
                hintText: '0',
                suffixText: _currency,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null; // se descarta
                final n = double.tryParse(v.trim().replaceAll(',', '.'));
                return (n == null || n <= 0) ? 'Tasa inválida' : null;
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: AppColors.grey500,
            tooltip: 'Quitar $code',
            onPressed: () => setState(() {
              _rateCtrls.remove(code)?.dispose();
            }),
          ),
        ],
      ),
    );
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

                  // ── Tasas de cambio ────────────────────────────────────
                  const SizedBox(height: AppDimensions.xl),
                  Row(
                    children: [
                      Text('Tasas de cambio', style: AppTextStyles.labelLarge),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _addRateCurrency,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Agregar'),
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  Text(
                    'Solo hacen falta si tienes cuentas en otra moneda. Las '
                    'escribes tú: así sabes exactamente con qué tasa se está '
                    'sumando tu balance, y no cambian solas de un día a otro.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.grey500),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  if (_rateCtrls.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                      child: Text(
                        'Todas tus cuentas están en $_currency.',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.grey600),
                      ),
                    )
                  else
                    ..._rateCtrls.keys.map(_buildRateRow),

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
