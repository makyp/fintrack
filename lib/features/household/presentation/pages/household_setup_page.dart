import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../cubit/household_cubit.dart';

class HouseholdSetupPage extends StatefulWidget {
  const HouseholdSetupPage({super.key});

  @override
  State<HouseholdSetupPage> createState() => _HouseholdSetupPageState();
}

class _HouseholdSetupPageState extends State<HouseholdSetupPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _createFormKey = GlobalKey<FormState>();
  final _joinFormKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _create(BuildContext context) {
    if (!_createFormKey.currentState!.validate()) return;
    final user = context.read<AuthBloc>().state.user!;
    context.read<HouseholdCubit>().create(
          user.uid,
          user.displayName,
          user.email,
          _nameCtrl.text.trim(),
        );
  }

  void _join(BuildContext context) {
    if (!_joinFormKey.currentState!.validate()) return;
    final user = context.read<AuthBloc>().state.user!;
    context.read<HouseholdCubit>().join(
          user.uid,
          user.displayName,
          user.email,
          _codeCtrl.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Hogar'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Crear hogar'),
            Tab(text: 'Unirse'),
          ],
        ),
      ),
      body: BlocConsumer<HouseholdCubit, HouseholdState>(
        listener: (context, state) {
          if (state.hasHousehold) {
            context.read<AuthBloc>().add(
                  AuthHouseholdIdUpdated(state.household!.id),
                );
            Navigator.of(context).pop();
          }
          if (state.status == HouseholdStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Error'),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _CreateTab(formKey: _createFormKey, ctrl: _nameCtrl, onSubmit: _create),
              _JoinTab(formKey: _joinFormKey, ctrl: _codeCtrl, onSubmit: _join),
            ],
          );
        },
      ),
    );
  }
}

class _CreateTab extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController ctrl;
  final void Function(BuildContext) onSubmit;

  const _CreateTab({required this.formKey, required this.ctrl, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.pagePadding),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppDimensions.lg),
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.home_outlined,
                    size: 40, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: AppDimensions.lg),
            Text('Crea tu hogar', style: AppTextStyles.headlineMedium),
            const SizedBox(height: AppDimensions.sm),
            Text(
              'Invita a tu familia o pareja a compartir gastos del hogar.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
            ),
            const SizedBox(height: AppDimensions.xl),
            TextFormField(
              controller: ctrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre del hogar',
                hintText: 'Ej: Casa García',
                prefixIcon: Icon(Icons.home),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Escribe un nombre' : null,
            ),
            const SizedBox(height: AppDimensions.xl),
            ElevatedButton(
              onPressed: () => onSubmit(context),
              child: const Text('Crear hogar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinTab extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController ctrl;
  final void Function(BuildContext) onSubmit;

  const _JoinTab({required this.formKey, required this.ctrl, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.pagePadding),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppDimensions.lg),
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.group_add_outlined,
                    size: 40, color: AppColors.secondary),
              ),
            ),
            const SizedBox(height: AppDimensions.lg),
            Text('Unirse a un hogar', style: AppTextStyles.headlineMedium),
            const SizedBox(height: AppDimensions.sm),
            Text(
              'Ingresa el código de 6 caracteres que compartió el administrador del hogar.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
            ),
            const SizedBox(height: AppDimensions.xl),
            TextFormField(
              controller: ctrl,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Código de invitación',
                hintText: 'Ej: ABC123',
                prefixIcon: Icon(Icons.vpn_key_outlined),
              ),
              validator: (v) =>
                  (v == null || v.trim().length < 4) ? 'Código inválido' : null,
            ),
            const SizedBox(height: AppDimensions.lg),
            ElevatedButton(
              onPressed: () => onSubmit(context),
              child: const Text('Unirse al hogar'),
            ),
          ],
        ),
      ),
    );
  }
}
