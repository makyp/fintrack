import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../gamification/presentation/pages/badges_page.dart';

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
            padding: const EdgeInsets.all(16),
            children: [
              // Avatar + nombre
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        user?.displayName.isNotEmpty == true
                            ? user!.displayName[0].toUpperCase()
                            : '?',
                        style: AppTextStyles.displaySmall
                            .copyWith(color: AppColors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(user?.displayName ?? '—',
                        style: AppTextStyles.headlineMedium),
                    Text(user?.email ?? '—',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.grey500)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Divider(),

              ListTile(
                leading: const Icon(Icons.emoji_events_outlined,
                    color: AppColors.warning),
                title: const Text('Logros y racha'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BadgesPage())),
              ),
              const Divider(),

              // Más opciones — Sprint 10
              ListTile(
                leading: const Icon(Icons.tune_outlined),
                title: const Text('Preferencias'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.security_outlined),
                title: const Text('Seguridad'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              const Divider(),

              // Cerrar sesión
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.danger),
                title: Text('Cerrar sesión',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.danger)),
                onTap: () => _confirmSignOut(context),
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
