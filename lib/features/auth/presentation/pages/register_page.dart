import 'package:flutter/gestures.dart';
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
import '../widgets/legal_modal.dart';
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
          context.go('/onboarding');
        }
      },
      builder: (context, state) {
        return AuthLayout(
          isLogin: false,
          form: _RegisterForm(
            formKey: _formKey,
            nameCtrl: _nameCtrl,
            emailCtrl: _emailCtrl,
            passwordCtrl: _passwordCtrl,
            confirmCtrl: _confirmCtrl,
            obscurePassword: _obscurePassword,
            obscureConfirm: _obscureConfirm,
            acceptTerms: _acceptTerms,
            onTogglePassword: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            onToggleConfirm: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
            onToggleTerms: (v) => setState(() => _acceptTerms = v ?? false),
            state: state,
          ),
        );
      },
    );
  }
}

class _RegisterForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController confirmCtrl;
  final bool obscurePassword;
  final bool obscureConfirm;
  final bool acceptTerms;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final ValueChanged<bool?> onToggleTerms;
  final AuthState state;

  const _RegisterForm({
    required this.formKey,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.confirmCtrl,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.acceptTerms,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onToggleTerms,
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
            const SizedBox(height: AppDimensions.sm),
            // Back button on mobile
            const BackButton(),
            const SizedBox(height: AppDimensions.sm),
          ],

          // Header
          Text(
            'Crear cuenta',
            style: isWeb
                ? AppTextStyles.headlineLarge
                : AppTextStyles.displaySmall,
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            'Empieza a controlar tus finanzas hoy',
            style: AppTextStyles.bodyLarge
                .copyWith(color: AppColors.grey500),
          ),
          const SizedBox(height: AppDimensions.xl),

          // Name
          AuthTextField(
            controller: nameCtrl,
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
            hint: 'Mínimo 6 caracteres',
            obscureText: obscurePassword,
            prefixIcon: Icons.lock_outline,
            enabled: !state.isLoading,
            suffixIcon: IconButton(
              icon: Icon(obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined),
              onPressed: onTogglePassword,
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Ingresa una contraseña';
              if (v.length < 6) return 'Mínimo 6 caracteres';
              return null;
            },
          ),
          const SizedBox(height: AppDimensions.md),

          // Confirm password
          AuthTextField(
            controller: confirmCtrl,
            label: 'Confirmar contraseña',
            hint: '••••••••',
            obscureText: obscureConfirm,
            prefixIcon: Icons.lock_outline,
            enabled: !state.isLoading,
            suffixIcon: IconButton(
              icon: Icon(obscureConfirm
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined),
              onPressed: onToggleConfirm,
            ),
            validator: (v) {
              if (v != passwordCtrl.text) {
                return 'Las contraseñas no coinciden';
              }
              return null;
            },
          ),
          const SizedBox(height: AppDimensions.md),

          // Terms checkbox
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: acceptTerms,
                  onChanged: onToggleTerms,
                  activeColor: AppColors.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'Acepto los ',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.grey600),
                    children: [
                      TextSpan(
                        text: 'Términos de servicio',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.secondary,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.secondary,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => showTermsModal(context),
                      ),
                      const TextSpan(text: ' y '),
                      TextSpan(
                        text: 'Política de privacidad',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.secondary,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.secondary,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => showPrivacyModal(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),

          // Register button
          ElevatedButton(
            onPressed: state.isLoading || !acceptTerms
                ? null
                : () {
                    if (formKey.currentState!.validate()) {
                      context.read<AuthBloc>().add(
                            AuthRegisterRequested(
                              name: nameCtrl.text.trim(),
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
                : const Text('Crear cuenta'),
          ),
          const SizedBox(height: AppDimensions.lg),

          // Divider
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.md),
                child: Text('o regístrate con',
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

          // Login link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '¿Ya tienes cuenta? ',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.grey500),
              ),
              TextButton(
                onPressed: () => context.pop(),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Inicia sesión'),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
        ],
      ),
    );
  }
}
