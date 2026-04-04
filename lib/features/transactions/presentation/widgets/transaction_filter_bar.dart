import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/cubit/accounts_state.dart';
import '../../domain/entities/transaction.dart';
import '../bloc/transactions_bloc.dart';
import '../bloc/transactions_event.dart';

class TransactionFilterBar extends StatefulWidget {
  final String userId;
  const TransactionFilterBar({super.key, required this.userId});

  @override
  State<TransactionFilterBar> createState() => _TransactionFilterBarState();
}

class _TransactionFilterBarState extends State<TransactionFilterBar> {
  TransactionType? _type;
  TransactionCategory? _category;
  String? _accountId;
  DateTime? _from;
  DateTime? _to;

  late final AccountsCubit _accountsCubit;

  @override
  void initState() {
    super.initState();
    _accountsCubit = getIt<AccountsCubit>()..watchAccounts(widget.userId);
  }

  @override
  void dispose() {
    _accountsCubit.close();
    super.dispose();
  }

  void _apply() {
    context.read<TransactionsBloc>().add(TransactionsFiltered(
          userId: widget.userId,
          type: _type,
          category: _category,
          accountId: _accountId,
          from: _from,
          to: _to,
        ));
    Navigator.pop(context);
  }

  void _clear() {
    setState(() {
      _type = null;
      _category = null;
      _accountId = null;
      _from = null;
      _to = null;
    });
    context.read<TransactionsBloc>().add(TransactionsWatchStarted(widget.userId));
    Navigator.pop(context);
  }

  List<TransactionCategory> get _availableCategories {
    if (_type == null) return TransactionCategory.values;
    return TransactionCategory.forType(_type!);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _accountsCubit,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppDimensions.pagePadding,
          AppDimensions.lg,
          AppDimensions.pagePadding,
          MediaQuery.of(context).viewInsets.bottom + AppDimensions.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text('Filtros', style: AppTextStyles.headlineMedium),
                const Spacer(),
                TextButton(onPressed: _clear, child: const Text('Limpiar todo')),
              ],
            ),
            const Divider(),

            // Tipo
            const SizedBox(height: AppDimensions.sm),
            Text('Tipo', style: AppTextStyles.labelLarge),
            const SizedBox(height: AppDimensions.sm),
            Wrap(
              spacing: AppDimensions.sm,
              children: TransactionType.values.map((t) {
                final label = t == TransactionType.expense
                    ? 'Gasto'
                    : t == TransactionType.income
                        ? 'Ingreso'
                        : 'Transferencia';
                final color = t == TransactionType.expense
                    ? AppColors.expense
                    : t == TransactionType.income
                        ? AppColors.income
                        : AppColors.secondary;
                final isSelected = _type == t;
                return ChoiceChip(
                  label: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? AppColors.white : AppColors.grey700,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: color,
                  backgroundColor: AppColors.grey100,
                  side: BorderSide(
                    color: isSelected ? color : AppColors.grey200,
                  ),
                  checkmarkColor: AppColors.white,
                  showCheckmark: false,
                  onSelected: (_) => setState(() {
                    _type = _type == t ? null : t;
                    _category = null;
                  }),
                );
              }).toList(),
            ),

            // Categoría
            const SizedBox(height: AppDimensions.md),
            Text('Categoría', style: AppTextStyles.labelLarge),
            const SizedBox(height: AppDimensions.sm),
            Wrap(
              spacing: AppDimensions.sm,
              runSpacing: AppDimensions.sm,
              children: _availableCategories.map((cat) {
                final isSelected = _category == cat;
                return FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(cat.icon, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        cat.label,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isSelected
                              ? AppColors.white
                              : AppColors.grey700,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.grey100,
                  checkmarkColor: AppColors.white,
                  showCheckmark: false,
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.grey200,
                  ),
                  onSelected: (_) => setState(
                      () => _category = _category == cat ? null : cat),
                );
              }).toList(),
            ),

            // Cuenta
            const SizedBox(height: AppDimensions.md),
            Text('Cuenta', style: AppTextStyles.labelLarge),
            const SizedBox(height: AppDimensions.sm),
            BlocBuilder<AccountsCubit, AccountsState>(
              builder: (context, state) {
                final accounts = state.activeAccounts;
                if (accounts.isEmpty) {
                  return Text('Sin cuentas',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500));
                }
                return _AccountFilterChips(
                  accounts: accounts,
                  selectedId: _accountId,
                  onSelected: (id) => setState(() => _accountId = _accountId == id ? null : id),
                );
              },
            ),

            // Rango de fechas
            const SizedBox(height: AppDimensions.md),
            Text('Fecha', style: AppTextStyles.labelLarge),
            const SizedBox(height: AppDimensions.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.date_range, size: 16),
                    label: Text(_from != null
                        ? '${_from!.day}/${_from!.month}/${_from!.year}'
                        : 'Desde'),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _from ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (d != null) setState(() => _from = d);
                    },
                  ),
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.date_range, size: 16),
                    label: Text(_to != null
                        ? '${_to!.day}/${_to!.month}/${_to!.year}'
                        : 'Hasta'),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _to ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (d != null) setState(() => _to = d);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.xl),
            ElevatedButton(
              onPressed: _apply,
              child: const Text('Aplicar filtros'),
            ),
            const SizedBox(height: AppDimensions.sm),
          ],
        ),
      ),
    );
  }
}

class _AccountFilterChips extends StatelessWidget {
  final List<Account> accounts;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  const _AccountFilterChips({
    required this.accounts,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDimensions.sm,
      runSpacing: AppDimensions.sm,
      children: accounts.map((a) {
        final isSelected = selectedId == a.id;
        return FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(a.icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                a.name,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isSelected ? AppColors.white : AppColors.grey700,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
          selected: isSelected,
          selectedColor: AppColors.secondary,
          backgroundColor: AppColors.grey100,
          checkmarkColor: AppColors.white,
          showCheckmark: false,
          side: BorderSide(
            color: isSelected ? AppColors.secondary : AppColors.grey200,
          ),
          onSelected: (_) => onSelected(a.id),
        );
      }).toList(),
    );
  }
}
