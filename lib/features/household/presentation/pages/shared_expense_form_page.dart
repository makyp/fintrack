import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/currency.dart';
import '../../../../core/domain/currency_registry.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/thousands_separator_formatter.dart';
import '../../../categories/domain/category_registry.dart';
import '../../../categories/domain/entities/transaction_category.dart';
import '../../../transactions/domain/category_matcher.dart';
import '../../../transactions/domain/entities/transaction_type.dart';
import '../../domain/entities/household.dart';
import '../../domain/entities/shared_expense.dart';
import '../cubit/shared_expenses_cubit.dart';

/// Registers an expense one member paid for several.
class SharedExpenseFormPage extends StatefulWidget {
  final Household household;
  final String userId;

  const SharedExpenseFormPage({
    super.key,
    required this.household,
    required this.userId,
  });

  @override
  State<SharedExpenseFormPage> createState() => _SharedExpenseFormPageState();
}

class _SharedExpenseFormPageState extends State<SharedExpenseFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  /// One controller per participant for the "montos a mano" mode.
  final Map<String, TextEditingController> _shareCtrls = {};

  late String _paidBy;
  late Set<String> _participants;
  late TransactionCategory _category;
  SplitMode _mode = SplitMode.equal;
  DateTime _date = DateTime.now();
  bool _isSaving = false;

  List<String> get _memberUids =>
      widget.household.members.map((m) => m.uid).toList();

  @override
  void initState() {
    super.initState();
    // Whoever is registering it usually paid it, and by default everybody in
    // the house is in — the two most common answers, prefilled.
    _paidBy = widget.userId;
    _participants = _memberUids.toSet();
    _category = CategoryRegistry.forType(TransactionType.expense).first;
    for (final uid in _memberUids) {
      _shareCtrls[uid] = TextEditingController();
    }
    _descCtrl.addListener(_onDescriptionChanged);
  }

  @override
  void dispose() {
    _descCtrl.removeListener(_onDescriptionChanged);
    _descCtrl.dispose();
    _amountCtrl.dispose();
    for (final c in _shareCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _onDescriptionChanged() {
    final text = _descCtrl.text;
    if (text.length < 3) return;
    final suggested =
        CategoryMatcher.suggest(text, type: TransactionType.expense);
    if (suggested != null && suggested != _category) {
      setState(() => _category = suggested);
    }
  }

  String _nameOf(String uid) {
    final member =
        widget.household.members.where((m) => m.uid == uid).firstOrNull;
    if (member == null) return uid;
    if (uid == widget.userId) return 'Tú';
    final name = member.displayName.trim();
    return name.isEmpty ? member.email : name;
  }

  double get _amount => ThousandsSeparatorFormatter.parse(_amountCtrl.text);

  /// What each participant owes, per the chosen mode.
  Map<String, double> get _shares {
    if (_mode == SplitMode.equal) {
      return SharedExpense.equalShares(
          _amount, _participants.toList(), _paidBy);
    }
    final shares = <String, double>{};
    for (final uid in _participants) {
      shares[uid] = ThousandsSeparatorFormatter.parse(_shareCtrls[uid]!.text);
    }
    return shares;
  }

  double get _sharesTotal =>
      _shares.values.fold(0.0, (sum, v) => sum + v);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_participants.isEmpty) {
      _snack('Elige al menos una persona que participa');
      return;
    }
    if (!_participants.contains(_paidBy) && _mode == SplitMode.equal) {
      // Perfectly legal — someone can pay for a dinner they didn't eat — the
      // shares just go entirely to the others. Nothing to block here.
    }
    if (_mode == SplitMode.custom &&
        (_sharesTotal - _amount).abs() > 0.01) {
      _snack('Los montos deben sumar '
          '${CurrencyFormatter.format(_amount)}; van '
          '${CurrencyFormatter.format(_sharesTotal)}');
      return;
    }

    setState(() => _isSaving = true);
    final now = DateTime.now();
    await context.read<SharedExpensesCubit>().addExpense(SharedExpense(
          id: '',
          householdId: widget.household.id,
          description: _descCtrl.text.trim(),
          amount: _amount,
          currency: CurrencyRegistry.base,
          date: _date,
          paidBy: _paidBy,
          shares: _shares,
          mode: _mode,
          categoryId: _category.id,
          createdBy: widget.userId,
          createdAt: now,
        ));
    if (mounted) Navigator.of(context).pop();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    final symbol = Currency.byCode(CurrencyRegistry.base).symbol;
    return Scaffold(
      appBar: AppBar(title: const Text('Gasto compartido')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.pagePadding),
          children: [
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorFormatter()],
              textAlign: TextAlign.center,
              style: AppTextStyles.displaySmall
                  .copyWith(color: AppColors.danger),
              decoration: InputDecoration(
                hintText: '0',
                prefixText: '$symbol ',
                prefixStyle: AppTextStyles.displaySmall
                    .copyWith(color: AppColors.danger),
                border: InputBorder.none,
                filled: false,
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Ingresa el monto';
                return ThousandsSeparatorFormatter.parse(v) <= 0
                    ? 'El monto debe ser mayor a 0'
                    : null;
              },
            ),
            const SizedBox(height: AppDimensions.md),
            TextFormField(
              controller: _descCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                hintText: 'Ej: Mercado de la semana',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Escribe de qué fue el gasto'
                  : null,
            ),
            const SizedBox(height: AppDimensions.md),
            _buildCategoryPicker(),
            const SizedBox(height: AppDimensions.md),
            _buildDateTile(),
            const SizedBox(height: AppDimensions.lg),
            Text('¿Quién pagó?', style: AppTextStyles.labelLarge),
            const SizedBox(height: AppDimensions.sm),
            _buildPayerPicker(),
            const SizedBox(height: AppDimensions.lg),
            Text('¿Entre quiénes se divide?',
                style: AppTextStyles.labelLarge),
            const SizedBox(height: AppDimensions.sm),
            _buildModeToggle(),
            const SizedBox(height: AppDimensions.sm),
            ..._memberUids.map(_buildParticipantTile),
            if (_mode == SplitMode.custom) _buildCustomTotalHint(),
            const SizedBox(height: AppDimensions.xl),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.white))
                  : const Text('Guardar gasto'),
            ),
            const SizedBox(height: AppDimensions.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPicker() {
    final categories =
        CategoryRegistry.forTypeIncluding(TransactionType.expense, _category);
    return DropdownButtonFormField<String>(
      value: _category.id,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Categoría',
        prefixIcon: Icon(Icons.category_outlined),
      ),
      items: [
        for (final c in categories)
          DropdownMenuItem(value: c.id, child: Text('${c.icon}  ${c.label}')),
      ],
      onChanged: (v) {
        if (v != null) setState(() => _category = CategoryRegistry.byId(v));
      },
    );
  }

  Widget _buildDateTile() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.calendar_today_outlined),
      title: const Text('Fecha'),
      trailing: Text(DateFormatter.formatShortDate(_date),
          style: AppTextStyles.bodyMedium),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 1)),
        );
        if (picked != null) setState(() => _date = picked);
      },
    );
  }

  Widget _buildPayerPicker() {
    return Wrap(
      spacing: AppDimensions.sm,
      runSpacing: AppDimensions.sm,
      children: [
        for (final uid in _memberUids)
          ChoiceChip(
            label: Text(_nameOf(uid)),
            selected: _paidBy == uid,
            onSelected: (_) => setState(() => _paidBy = uid),
          ),
      ],
    );
  }

  Widget _buildModeToggle() {
    return SegmentedButton<SplitMode>(
      segments: [
        for (final mode in SplitMode.values)
          ButtonSegment(value: mode, label: Text(mode.label)),
      ],
      selected: {_mode},
      onSelectionChanged: (s) => setState(() {
        _mode = s.first;
        if (_mode == SplitMode.custom) {
          // Seed the fields with the even split, which is the answer people
          // start from before adjusting one line.
          final even = SharedExpense.equalShares(
              _amount, _participants.toList(), _paidBy);
          even.forEach((uid, value) {
            _shareCtrls[uid]?.text = value.toStringAsFixed(0);
          });
        }
      }),
    );
  }

  Widget _buildParticipantTile(String uid) {
    final selected = _participants.contains(uid);
    final share = selected ? (_shares[uid] ?? 0) : 0.0;
    return Column(
      children: [
        CheckboxListTile(
          value: selected,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          title: Text(_nameOf(uid)),
          subtitle: _mode == SplitMode.equal && selected
              ? Text('le toca ${CurrencyFormatter.format(share)}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.grey500))
              : null,
          onChanged: (checked) => setState(() {
            if (checked ?? false) {
              _participants.add(uid);
            } else {
              _participants.remove(uid);
            }
          }),
        ),
        if (_mode == SplitMode.custom && selected)
          Padding(
            padding: const EdgeInsets.only(
                left: 40, bottom: AppDimensions.sm),
            child: TextFormField(
              controller: _shareCtrls[uid],
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorFormatter()],
              decoration: InputDecoration(
                isDense: true,
                labelText: 'Le toca',
                prefixText: '${Currency.byCode(CurrencyRegistry.base).symbol} ',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
      ],
    );
  }

  Widget _buildCustomTotalHint() {
    final difference = _sharesTotal - _amount;
    final matches = difference.abs() <= 0.01;
    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.sm),
      child: Text(
        matches
            ? 'Los montos cuadran con el total'
            : difference > 0
                ? 'Sobran ${CurrencyFormatter.format(difference)}'
                : 'Faltan ${CurrencyFormatter.format(-difference)}',
        style: AppTextStyles.bodySmall.copyWith(
          color: matches ? AppColors.success : AppColors.warning,
        ),
      ),
    );
  }
}
