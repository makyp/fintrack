import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../gamification/presentation/pages/badges_page.dart';
import 'preferences_page.dart';
import 'security_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state.user;
          return ListView(
            padding: const EdgeInsets.all(AppDimensions.pagePadding),
            children: [
              // ── Avatar + nombre ─────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    _Avatar(photoUrl: user?.photoUrl, displayName: user?.displayName),
                    const SizedBox(height: 12),
                    Text(user?.displayName ?? '—',
                        style: AppTextStyles.headlineMedium),
                    Text(user?.email ?? '—',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.grey500)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        user?.currency ?? 'COP',
                        style: AppTextStyles.labelMedium
                            .copyWith(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.xl),
              const Divider(),

              // ── Logros ──────────────────────────────────────────────────
              ListTile(
                leading: const Icon(Icons.emoji_events_outlined,
                    color: AppColors.warning),
                title: const Text('Logros y racha'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BadgesPage())),
              ),
              const Divider(),

              // ── Hogar ────────────────────────────────────────────────────
              ListTile(
                leading: const Icon(Icons.home_outlined, color: AppColors.primary),
                title: const Text('Mi Hogar'),
                subtitle: user?.householdId != null
                    ? const Text('Ver miembros y gastos compartidos')
                    : const Text('Crear o unirse a un hogar'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/household'),
              ),
              const Divider(),

              // ── Preferencias ─────────────────────────────────────────────
              ListTile(
                leading: const Icon(Icons.tune_outlined, color: AppColors.secondary),
                title: const Text('Preferencias'),
                subtitle: const Text('Nombre y moneda'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PreferencesPage())),
              ),

              // ── Seguridad ─────────────────────────────────────────────────
              ListTile(
                leading: const Icon(Icons.security_outlined, color: AppColors.grey600),
                title: const Text('Seguridad'),
                subtitle: const Text('Contraseña y cuenta'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SecurityPage())),
              ),
              const Divider(),

              // ── Cerrar sesión ─────────────────────────────────────────────
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.danger),
                title: Text('Cerrar sesión',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.danger)),
                onTap: () => _confirmSignOut(context),
              ),

              const SizedBox(height: AppDimensions.xl),
              Center(
                child: Text(
                  'FinTrack v1.0.0',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey300),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(const AuthSignOutRequested());
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }
}

// ── Avatar widget ─────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String? photoUrl;
  final String? displayName;
  const _Avatar({this.photoUrl, this.displayName});

  @override
  Widget build(BuildContext context) {
    return AppAvatar(photoUrl: photoUrl, displayName: displayName, radius: 44);
  }
}

