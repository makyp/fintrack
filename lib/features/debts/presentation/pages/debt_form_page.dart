import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/thousands_separator_formatter.dart';
import '../../domain/entities/debt.dart';
import '../cubit/debts_cubit.dart';

class DebtFormPage extends StatefulWidget {
  final String userId;
  final Debt? debt;
  final DebtDirection? initialDirection;

  const DebtFormPage({
    super.key,
    required this.userId,
    this.debt,
    this.initialDirection,
  });

  @override
  State<DebtFormPage> createState() => _DebtFormPageState();
}

class _DebtFormPageState extends State<DebtFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _interestCtrl = TextEditingController();

  late DebtDirection _direction;
  DateTime _startDate = DateTime.now();
  DateTime? _dueDate;
  bool _hasInterest = false;
  bool _isLoading = false;

  bool get _isEditing => widget.debt != null;

  @override
  void initState() {
    super.initState();
    final d = widget.debt;
    if (d != null) {
      _nameCtrl.text = d.personName;
      _descCtrl.text = d.description ?? '';
      _amountCtrl.text = ThousandsSeparatorFormatter()
          .formatEditUpdate(
            const TextEditingValue(text: ''),
            TextEditingValue(text: d.originalAmount.toStringAsFixed(0)),
          )
          .text;
      _direction = d.direction;
      _startDate = d.startDate;
      _dueDate = d.dueDate;
      _hasInterest = d.hasInterest;
      _interestCtrl.text = d.monthlyInterestRate > 0
          ? d.monthlyInterestRate.toStringAsFixed(1)
          : '';
    } else {
      _direction = widget.initialDirection ?? DebtDirection.theyOweMe;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _interestCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final cubit = context.read<DebtsCubit>();
      final amount = ThousandsSeparatorFormatter.parse(_amountCtrl.text);
      final rate = double.tryParse(_interestCtrl.text) ?? 0;

      bool ok;
      if (_isEditing) {
        ok = await cubit.update(widget.debt!.copyWith(
          personName: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          originalAmount: amount,
          direction: _direction,
          startDate: _startDate,
          dueDate: _dueDate,
          clearDueDate: _dueDate == null,
          hasInterest: _hasInterest,
          monthlyInterestRate: _hasInterest ? rate : 0,
        ));
      } else {
        ok = await cubit.add(Debt(
          id: '',
          userId: widget.userId,
          personName: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          originalAmount: amount,
          direction: _direction,
          startDate: _startDate,
          dueDate: _dueDate,
          hasInterest: _hasInterest,
          monthlyInterestRate: _hasInterest ? rate : 0,
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
        title: Text(_isEditing ? 'Editar deuda' : 'Nueva deuda'),
        leading: const CloseButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.pagePadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Direction selector
              Text('Tipo de deuda', style: AppTextStyles.labelLarge),
              const SizedBox(height: AppDimensions.sm),
              Row(
                children: [
                  Expanded(
                    child: _DirectionCard(
                      selected: _direction == DebtDirection.theyOweMe,
                      icon: Icons.arrow_downward,
                      label: 'Me deben',
                      subtitle: 'Alguien te debe dinero',
                      color: AppColors.income,
                      onTap: () => setState(
                          () => _direction = DebtDirection.theyOweMe),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  Expanded(
                    child: _DirectionCard(
                      selected: _direction == DebtDirection.iOweThem,
                      icon: Icons.arrow_upward,
                      label: 'Les debo',
                      subtitle: 'Tú le debes dinero',
                      color: AppColors.expense,
                      onTap: () =>
                          setState(() => _direction = DebtDirection.iOweThem),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.lg),

              // Person name
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la persona',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ingresa el nombre' : null,
              ),
              const SizedBox(height: AppDimensions.md),

              // Description
              TextFormField(
                controller: _descCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  prefixIcon: Icon(Icons.notes),
                  hintText: 'Ej: Préstamo para viaje',
                ),
              ),
              const SizedBox(height: AppDimensions.md),

              // Amount
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  prefixIcon: Icon(Icons.attach_money),
                  prefixText: '\$ ',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresa el monto';
                  if (ThousandsSeparatorFormatter.parse(v) <= 0) {
                    return 'Monto inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppDimensions.lg),

              // Dates
              Text('Fechas', style: AppTextStyles.labelLarge),
              const SizedBox(height: AppDimensions.sm),
              _DateTile(
                icon: Icons.calendar_today_outlined,
                title: 'Fecha de inicio',
                date: _startDate,
                onPick: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (ctx, child) => Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 560),
                        child: child!,
                      ),
                    ),
                  );
                  if (d != null) setState(() => _startDate = d);
                },
              ),
              _DateTile(
                icon: Icons.event_outlined,
                title: 'Fecha límite (opcional)',
                date: _dueDate,
                onPick: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ??
                        DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2035),
                    builder: (ctx, child) => Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 560),
                        child: child!,
                      ),
                    ),
                  );
                  if (d != null) setState(() => _dueDate = d);
                },
                onClear: _dueDate != null
                    ? () => setState(() => _dueDate = null)
                    : null,
              ),
              const SizedBox(height: AppDimensions.lg),

              // Interest
              Text('Interés', style: AppTextStyles.labelLarge),
              const SizedBox(height: AppDimensions.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('¿Genera interés mensual?'),
                value: _hasInterest,
                onChanged: (v) => setState(() => _hasInterest = v),
                activeColor: AppColors.primary,
              ),
              if (_hasInterest) ...[
                const SizedBox(height: AppDimensions.sm),
                TextFormField(
                  controller: _interestCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Tasa mensual (%)',
                    prefixIcon: Icon(Icons.percent),
                    hintText: 'Ej: 2.5',
                    suffixText: '% / mes',
                  ),
                  validator: (v) {
                    if (!_hasInterest) return null;
                    if (v == null || v.isEmpty) return 'Ingresa la tasa';
                    if ((double.tryParse(v) ?? 0) <= 0) return 'Tasa inválida';
                    return null;
                  },
                ),
              ],
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
                      : Text(_isEditing ? 'Guardar cambios' : 'Crear'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widgets helpers ───────────────────────────────────────────────────────────

class _DirectionCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DirectionCard({
    required this.selected,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : AppColors.grey50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? color : AppColors.grey200,
              width: selected ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : AppColors.grey400, size: 28),
            const SizedBox(height: 4),
            Text(label,
                style: AppTextStyles.labelMedium.copyWith(
                    color: selected ? color : AppColors.grey700,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal)),
            Text(subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey400, fontSize: 10),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final DateTime? date;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  const _DateTile({
    required this.icon,
    required this.title,
    required this.date,
    required this.onPick,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.grey500),
      title: Text(title, style: AppTextStyles.labelLarge),
      subtitle: Text(
        date != null
            ? '${date!.day}/${date!.month}/${date!.year}'
            : 'No seleccionada',
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onClear != null && date != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: AppColors.grey400),
              onPressed: onClear,
            ),
          const Icon(Icons.chevron_right, color: AppColors.grey400),
        ],
      ),
      onTap: onPick,
    );
  }
}
