import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/social_sign_in_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthBloc>()..add(const AuthStarted()),
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
            if (state.user?.onboardingCompleted == false) {
              context.go('/onboarding');
            } else {
              context.go('/');
            }
          }
        },
        builder: (context, state) {
          return Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.pagePadding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppDimensions.xxl),
                      _buildHeader(),
                      const SizedBox(height: AppDimensions.xl),
                      _buildForm(context, state),
                      const SizedBox(height: AppDimensions.md),
                      _buildForgotPassword(context),
                      const SizedBox(height: AppDimensions.lg),
                      _buildLoginButton(context, state),
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
                      _buildRegisterLink(context),
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
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.account_balance_wallet, color: AppColors.white, size: 32),
        ),
        const SizedBox(height: AppDimensions.md),
        Text(
          'Bienvenido a FinTrack',
          style: AppTextStyles.displaySmall,
        ),
        const SizedBox(height: AppDimensions.xs),
        Text(
          'Controla tus finanzas con inteligencia',
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.grey500),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, AuthState state) {
    return Column(
      children: [
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
          hint: '••••••••',
          obscureText: _obscurePassword,
          prefixIcon: Icons.lock_outline,
          enabled: !state.isLoading,
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildForgotPassword(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => context.push('/forgot-password'),
        child: const Text('¿Olvidaste tu contraseña?'),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context, AuthState state) {
    return ElevatedButton(
      onPressed: state.isLoading
          ? null
          : () {
              if (_formKey.currentState!.validate()) {
                context.read<AuthBloc>().add(
                      AuthSignInWithEmailRequested(
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
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.white,
              ),
            )
          : const Text('Iniciar sesión'),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
          child: Text(
            'o continúa con',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildRegisterLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿No tienes cuenta? ',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
        ),
        TextButton(
          onPressed: () => context.push('/register'),
          child: const Text('Regístrate'),
        ),
      ],
    );
  }
}
