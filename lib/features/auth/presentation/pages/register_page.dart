import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/social_sign_in_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<AuthBloc>(),
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Error desconocido'),
                backgroundColor: AppColors.danger,
              ),
            );
          }
          if (state.isAuthenticated) {
            context.go('/onboarding');
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              leading: const BackButton(),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.pagePadding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: AppDimensions.xl),
                      _buildForm(state),
                      const SizedBox(height: AppDimensions.md),
                      _buildTermsCheckbox(),
                      const SizedBox(height: AppDimensions.lg),
                      _buildRegisterButton(context, state),
                      const SizedBox(height: AppDimensions.lg),
                      _buildDivider(),
                      const SizedBox(height: AppDimensions.lg),
                      SocialSignInButton.google(
                        onTap: () => context
                            .read<AuthBloc>()
                            .add(const AuthSignInWithGoogleRequested()),
                        isLoading: state.isLoading,
                      ),
                      const SizedBox(height: AppDimensions.xl),
                      _buildLoginLink(context),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Crear cuenta', style: AppTextStyles.displaySmall),
        const SizedBox(height: AppDimensions.xs),
        Text(
          'Empieza a controlar tus finanzas hoy',
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.grey500),
        ),
      ],
    );
  }

  Widget _buildForm(AuthState state) {
    return Column(
      children: [
        AuthTextField(
          controller: _nameCtrl,
          label: 'Nombre completo',
          hint: 'Juan García',
          prefixIcon: Icons.person_outline,
          enabled: !state.isLoading,
          textCapitalization: TextCapitalization.words,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Ingresa tu nombre';
            if (v.trim().length < 2) return 'Nombre muy corto';
            return null;
          },
        ),
        const SizedBox(height: AppDimensions.md),
        AuthTextField(
          controller: _emailCtrl,
          label: 'Correo electrónico',
          hint: 'tu@correo.com',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
          enabled: !state.isLoading,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Ingresa tu correo';
            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
              return 'Correo no válido';
            }
            return null;
          },
        ),
        const SizedBox(height: AppDimensions.md),
        AuthTextField(
          controller: _passwordCtrl,
          label: 'Contraseña',
          hint: 'Mínimo 6 caracteres',
          obscureText: _obscurePassword,
          prefixIcon: Icons.lock_outline,
          enabled: !state.isLoading,
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Ingresa una contraseña';
            if (v.length < 6) return 'Mínimo 6 caracteres';
            return null;
          },
        ),
        const SizedBox(height: AppDimensions.md),
        AuthTextField(
          controller: _confirmCtrl,
          label: 'Confirmar contraseña',
          hint: '••••••••',
          obscureText: _obscureConfirm,
          prefixIcon: Icons.lock_outline,
          enabled: !state.isLoading,
          suffixIcon: IconButton(
            icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
          validator: (v) {
            if (v != _passwordCtrl.text) return 'Las contraseñas no coinciden';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (v) => setState(() => _acceptTerms = v ?? false),
          activeColor: AppColors.primary,
        ),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: 'Acepto los ',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
              children: [
                TextSpan(
                  text: 'Términos de servicio',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondary,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(text: ' y '),
                TextSpan(
                  text: 'Política de privacidad',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton(BuildContext context, AuthState state) {
    return ElevatedButton(
      onPressed: state.isLoading || !_acceptTerms
          ? null
          : () {
              if (_formKey.currentState!.validate()) {
                context.read<AuthBloc>().add(
                      AuthRegisterRequested(
                        name: _nameCtrl.text.trim(),
                        email: _emailCtrl.text.trim(),
                        password: _passwordCtrl.text,
                      ),
                    );
              }
            },
      child: state.isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
            )
          : const Text('Crear cuenta'),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
          child: Text(
            'o regístrate con',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildLoginLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿Ya tienes cuenta? ',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
        ),
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Inicia sesión'),
        ),
      ],
    );
  }
}
