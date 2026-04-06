import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  TimeOfDay? _reminderTime;
  bool _isLoading = false;

  static const _currencies = ['COP', 'USD', 'EUR', 'MXN', 'ARS', 'BRL', 'PEN', 'CLP'];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthBloc>().state.user;
    _nameCtrl = TextEditingController(text: user?.displayName ?? '');
    _currency = user?.currency ?? 'COP';
    final rt = user?.reminderTime;
    if (rt != null) {
      final parts = rt.split(':');
      if (parts.length == 2) {
        _reminderTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 20,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final user = context.read<AuthBloc>().state.user;
    final newName = _nameCtrl.text.trim();
    final reminderStr = _reminderTime != null
        ? '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}'
        : null;

    context.read<AuthBloc>().add(AuthProfileUpdateRequested(
          displayName: newName != user?.displayName ? newName : null,
          currency: _currency != user?.currency ? _currency : null,
          reminderTime: reminderStr,
        ));

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
                  Text('Información personal', style: AppTextStyles.labelLarge),
                  const SizedBox(height: AppDimensions.md),
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'El nombre no puede estar vacío' : null,
                  ),
                  const SizedBox(height: AppDimensions.xl),
                  Text('Moneda', style: AppTextStyles.labelLarge),
                  const SizedBox(height: AppDimensions.sm),
                  Text(
                    'Afecta cómo se muestran los valores en toda la app.',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
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
                          color: isSelected ? AppColors.primary : AppColors.grey700,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppDimensions.xl),
                  Text('Recordatorios', style: AppTextStyles.labelLarge),
                  const SizedBox(height: AppDimensions.sm),
                  Text(
                    'Configura a qué hora quieres recibir el recordatorio diario para registrar tus gastos.',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.notifications_outlined,
                        color: AppColors.primary),
                    title: const Text('Hora del recordatorio'),
                    subtitle: Text(
                      _reminderTime != null
                          ? _reminderTime!.format(context)
                          : 'Sin recordatorio',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.grey500),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_reminderTime != null)
                          IconButton(
                            icon: const Icon(Icons.close,
                                size: 18, color: AppColors.grey400),
                            onPressed: () =>
                                setState(() => _reminderTime = null),
                          ),
                        const Icon(Icons.chevron_right,
                            color: AppColors.grey400),
                      ],
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _reminderTime ?? const TimeOfDay(hour: 20, minute: 0),
                      );
                      if (picked != null) {
                        setState(() => _reminderTime = picked);
                      }
                    },
                  ),
                  const SizedBox(height: AppDimensions.xl),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                        : const Text('Guardar cambios'),
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
