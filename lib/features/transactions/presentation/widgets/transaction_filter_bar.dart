import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
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
  DateTime? _from;
  DateTime? _to;

  void _apply() {
    context.read<TransactionsBloc>().add(TransactionsFiltered(
          userId: widget.userId,
          type: _type,
          category: _category,
          from: _from,
          to: _to,
        ));
    Navigator.pop(context);
  }

  void _clear() {
    setState(() { _type = null; _category = null; _from = null; _to = null; });
    context.read<TransactionsBloc>().add(TransactionsWatchStarted(widget.userId));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(AppDimensions.pagePadding, AppDimensions.lg,
          AppDimensions.pagePadding, MediaQuery.of(context).viewInsets.bottom + AppDimensions.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Filtros', style: AppTextStyles.headlineMedium),
              const Spacer(),
              TextButton(onPressed: _clear, child: const Text('Limpiar')),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          Text('Tipo', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppDimensions.sm),
          Wrap(
            spacing: AppDimensions.sm,
            children: TransactionType.values.map((t) {
              return ChoiceChip(
                label: Text(t == TransactionType.expense ? 'Gasto' : t == TransactionType.income ? 'Ingreso' : 'Transferencia'),
                selected: _type == t,
                onSelected: (_) => setState(() => _type = _type == t ? null : t),
              );
            }).toList(),
          ),
          const SizedBox(height: AppDimensions.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.date_range, size: 16),
                  label: Text(_from != null ? '${_from!.day}/${_from!.month}' : 'Desde'),
                  onPressed: () async {
                    final d = await showDatePicker(context: context,
                        initialDate: _from ?? DateTime.now(),
                        firstDate: DateTime(2020), lastDate: DateTime.now());
                    if (d != null) setState(() => _from = d);
                  },
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.date_range, size: 16),
                  label: Text(_to != null ? '${_to!.day}/${_to!.month}' : 'Hasta'),
                  onPressed: () async {
                    final d = await showDatePicker(context: context,
                        initialDate: _to ?? DateTime.now(),
                        firstDate: DateTime(2020), lastDate: DateTime.now());
                    if (d != null) setState(() => _to = d);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),
          ElevatedButton(onPressed: _apply, child: const Text('Aplicar filtros')),
        ],
      ),
    );
  }
}
