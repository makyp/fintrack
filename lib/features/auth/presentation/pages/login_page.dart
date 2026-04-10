import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_layout.dart';
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
    return BlocConsumer<AuthBloc, AuthState>(
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
        return AuthLayout(
          isLogin: true,
          form: _LoginForm(
            formKey: _formKey,
            emailCtrl: _emailCtrl,
            passwordCtrl: _passwordCtrl,
            obscurePassword: _obscurePassword,
            onToggleObscure: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            state: state,
          ),
        );
      },
    );
  }
}

class _LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final AuthState state;

  const _LoginForm({
    required this.formKey,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 800;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isWeb) ...[
            const SizedBox(height: AppDimensions.xl),
            // Mobile logo
            Image.asset(
              'assets/images/LogoFintrack.png',
              width: 64,
              height: 64,
            ),
            const SizedBox(height: AppDimensions.md),
          ],
          // Header
          Text(
            isWeb ? 'Inicia sesión' : 'Bienvenido a Fimakyp',
            style: isWeb
                ? AppTextStyles.headlineLarge
                : AppTextStyles.displaySmall,
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            'Controla tus finanzas con inteligencia',
            style: AppTextStyles.bodyLarge
                .copyWith(color: AppColors.grey500),
          ),
          const SizedBox(height: AppDimensions.xl),

          // Email
          AuthTextField(
            controller: emailCtrl,
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

          // Password
          AuthTextField(
            controller: passwordCtrl,
            label: 'Contraseña',
            hint: '••••••••',
            obscureText: obscurePassword,
            prefixIcon: Icons.lock_outline,
            enabled: !state.isLoading,
            suffixIcon: IconButton(
              icon: Icon(obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined),
              onPressed: onToggleObscure,
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
              return null;
            },
          ),
          const SizedBox(height: AppDimensions.sm),

          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/forgot-password'),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('¿Olvidaste tu contraseña?'),
            ),
          ),
          const SizedBox(height: AppDimensions.lg),

          // Login button
          ElevatedButton(
            onPressed: state.isLoading
                ? null
                : () {
                    if (formKey.currentState!.validate()) {
                      context.read<AuthBloc>().add(
                            AuthSignInWithEmailRequested(
                              email: emailCtrl.text.trim(),
                              password: passwordCtrl.text,
                            ),
                          );
                    }
                  },
            child: state.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.white),
                  )
                : const Text('Iniciar sesión'),
          ),
          const SizedBox(height: AppDimensions.lg),

          // Divider
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.md),
                child: Text('o continúa con',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.grey500)),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),

          // Google sign in
          SocialSignInButton.google(
            onTap: () => context
                .read<AuthBloc>()
                .add(const AuthSignInWithGoogleRequested()),
            isLoading: state.isLoading,
          ),
          const SizedBox(height: AppDimensions.xl),

          // Register link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '¿No tienes cuenta? ',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.grey500),
              ),
              TextButton(
                onPressed: () => context.push('/register'),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Regístrate'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
