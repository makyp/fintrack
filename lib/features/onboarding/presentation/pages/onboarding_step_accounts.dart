import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';

class OnboardingStepAccounts extends StatefulWidget {
  final List<Map<String, dynamic>> accounts;

  const OnboardingStepAccounts({super.key, required this.accounts});

  @override
  State<OnboardingStepAccounts> createState() => _OnboardingStepAccountsState();
}

class _OnboardingStepAccountsState extends State<OnboardingStepAccounts> {
  void _addAccount() {
    setState(() {
      widget.accounts.add({'name': '', 'balance': 0.0, 'type': 'corriente'});
    });
  }

  void _removeAccount(int index) {
    setState(() => widget.accounts.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppDimensions.lg),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.bankColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.account_balance_outlined,
              size: 56,
              color: AppColors.bankColor,
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
          Text('Agrega tus cuentas', style: AppTextStyles.displaySmall),
          const SizedBox(height: AppDimensions.sm),
          Text(
            'Añade tus cuentas bancarias con su saldo actual para ver tu patrimonio total.',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.grey500),
          ),
          const SizedBox(height: AppDimensions.xl),
          if (widget.accounts.isEmpty)
            _buildEmptyState()
          else
            ...widget.accounts.asMap().entries.map(
                  (e) => _AccountCard(
                    data: e.value,
                    onRemove: () => _removeAccount(e.key),
                  ),
                ),
          const SizedBox(height: AppDimensions.md),
          OutlinedButton.icon(
            onPressed: _addAccount,
            icon: const Icon(Icons.add),
            label: const Text('Agregar cuenta'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.xl),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        children: [
          const Icon(Icons.account_balance_outlined, size: 40, color: AppColors.grey400),
          const SizedBox(height: AppDimensions.sm),
          Text(
            'Sin cuentas aún',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
          ),
          Text(
            'Puedes agregarlas después desde el perfil',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey400),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onRemove;

  const _AccountCard({required this.data, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.md),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          children: [
            Row(
              children: [
                Text('Cuenta bancaria', style: AppTextStyles.labelLarge),
                const Spacer(),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, size: 18),
                  color: AppColors.grey400,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.sm),
            TextFormField(
              initialValue: data['name'] as String?,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre del banco',
                hintText: 'Ej: Bancolombia',
              ),
              onChanged: (v) => data['name'] = v,
            ),
            const SizedBox(height: AppDimensions.sm),
            DropdownButtonFormField<String>(
              value: data['type'] as String? ?? 'corriente',
              decoration: const InputDecoration(labelText: 'Tipo de cuenta'),
              items: const [
                DropdownMenuItem(value: 'corriente', child: Text('Cuenta corriente')),
                DropdownMenuItem(value: 'ahorros', child: Text('Cuenta de ahorros')),
                DropdownMenuItem(value: 'inversiones', child: Text('Inversiones')),
              ],
              onChanged: (v) => data['type'] = v ?? 'corriente',
            ),
            const SizedBox(height: AppDimensions.sm),
            TextFormField(
              initialValue: data['balance']?.toString() == '0.0' ? '' : data['balance']?.toString(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
              decoration: const InputDecoration(
                labelText: 'Saldo actual',
                prefixText: '\$ ',
              ),
              onChanged: (v) => data['balance'] = double.tryParse(v) ?? 0.0,
            ),
          ],
        ),
      ),
    );
  }
}
