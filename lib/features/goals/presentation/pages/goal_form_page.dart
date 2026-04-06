import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/thousands_separator_formatter.dart';
import '../../domain/entities/savings_goal.dart';
import '../cubit/goals_cubit.dart';

const _kIcons = [
  '🎯', '🏠', '✈️', '🚗', '💻', '📱', '🎓', '💍', '👶', '🐾',
  '🏋️', '🎸', '📸', '⛵', '🏖️', '💰', '🛍️', '🏥', '🌱', '🎁',
];

class GoalFormPage extends StatefulWidget {
  final String userId;
  final SavingsGoal? goal;

  const GoalFormPage({super.key, required this.userId, this.goal});

  @override
  State<GoalFormPage> createState() => _GoalFormPageState();
}

class _GoalFormPageState extends State<GoalFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  String _icon = '🎯';
  DateTime? _targetDate;
  bool _isLoading = false;

  bool get _isEditing => widget.goal != null;

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    if (g != null) {
      _nameCtrl.text = g.name;
      _targetCtrl.text = ThousandsSeparatorFormatter().formatEditUpdate(
        const TextEditingValue(text: ''),
        TextEditingValue(text: g.targetAmount.toStringAsFixed(0)),
      ).text;
      _icon = g.icon;
      _targetDate = g.targetDate;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final cubit = context.read<GoalsCubit>();
      final target = ThousandsSeparatorFormatter.parse(_targetCtrl.text);

      bool ok;
      if (_isEditing) {
        ok = await cubit.update(widget.goal!.copyWith(
          name: _nameCtrl.text.trim(),
          icon: _icon,
          targetAmount: target,
          targetDate: _targetDate,
          clearTargetDate: _targetDate == null,
        ));
      } else {
        ok = await cubit.add(SavingsGoal(
          id: '',
          userId: widget.userId,
          name: _nameCtrl.text.trim(),
          icon: _icon,
          targetAmount: target,
          currentAmount: 0,
          targetDate: _targetDate,
          createdAt: DateTime.now(),
        ));
      }
      if (ok && mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar meta' : 'Nueva meta'),
        leading: const CloseButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.pagePadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon picker
              Text('Ícono', style: AppTextStyles.labelLarge),
              const SizedBox(height: AppDimensions.sm),
              SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _kIcons.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final ico = _kIcons[i];
                    final sel = _icon == ico;
                    return GestureDetector(
                      onTap: () => setState(() => _icon = ico),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.primary.withOpacity(0.15)
                              : AppColors.grey100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: sel ? AppColors.primary : AppColors.grey200,
                            width: sel ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(ico,
                              style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppDimensions.lg),
              // Name
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la meta',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ingresa un nombre' : null,
              ),
              const SizedBox(height: AppDimensions.md),
              // Target amount
              TextFormField(
                controller: _targetCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Monto objetivo',
                  prefixIcon: Icon(Icons.attach_money),
                  prefixText: '\$ ',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresa el monto';
                  if (ThousandsSeparatorFormatter.parse(v) <= 0) return 'Monto inválido';
                  return null;
                },
              ),
              const SizedBox(height: AppDimensions.lg),
              // Target date (optional)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month_outlined,
                    color: AppColors.grey500),
                title: Text('Fecha objetivo', style: AppTextStyles.labelLarge),
                subtitle: Text(
                  _targetDate != null
                      ? '${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}'
                      : 'Sin fecha límite',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.grey500),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_targetDate != null)
                      IconButton(
                        icon: const Icon(Icons.close,
                            size: 18, color: AppColors.grey400),
                        onPressed: () => setState(() => _targetDate = null),
                      ),
                    const Icon(Icons.chevron_right, color: AppColors.grey400),
                  ],
                ),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _targetDate ??
                        DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2035),
                  );
                  if (d != null) setState(() => _targetDate = d);
                },
              ),
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
                              strokeWidth: 2, color: AppColors.white))
                      : Text(_isEditing ? 'Guardar cambios' : 'Crear meta'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
