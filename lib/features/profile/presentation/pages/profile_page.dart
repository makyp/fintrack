import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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
                    _Avatar(
                        photoUrl: user?.photoUrl,
                        displayName: user?.displayName,
                        userId: user?.uid ?? ''),
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

const _kAvatarEmojis = [
  '🧑', '👩', '👨', '🧒', '👦', '👧', '🧓', '👴', '👵',
  '🐱', '🐶', '🦊', '🐺', '🦁', '🐯', '🐻', '🐼', '🐨',
  '🚀', '⭐', '🎯', '💎', '🌟', '🔥', '🌈', '🎮', '🎸',
];

class _Avatar extends StatelessWidget {
  final String? photoUrl;
  final String? displayName;
  final String userId;
  const _Avatar({this.photoUrl, this.displayName, required this.userId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPhotoOptions(context),
      child: Stack(
        children: [
          AppAvatar(photoUrl: photoUrl, displayName: displayName, radius: 44),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showPhotoOptions(BuildContext context) {
    final authBloc = context.read<AuthBloc>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Cambiar foto de perfil',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppColors.primary),
                title: const Text('Subir desde galería'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picker = ImagePicker();
                  final file = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 60,
                      maxWidth: 300,
                      maxHeight: 300);
                  if (file == null || !context.mounted) return;
                  try {
                    final bytes = await file.readAsBytes();
                    // Resize to keep Firestore document small (~50KB limit)
                    // Store as data URI: "data:image/jpeg;base64,..."
                    final b64 = base64Encode(bytes);
                    final dataUri = 'data:image/jpeg;base64,$b64';
                    authBloc.add(AuthProfileUpdateRequested(photoUrl: dataUri));
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Error al procesar la foto')));
                    }
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.emoji_emotions_outlined,
                  color: AppColors.secondary),
              title: const Text('Elegir ícono'),
              onTap: () {
                Navigator.pop(ctx);
                _showEmojiPicker(context, authBloc);
              },
            ),
            if (photoUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: AppColors.danger),
                title: const Text('Quitar foto'),
                onTap: () {
                  Navigator.pop(ctx);
                  authBloc.add(const AuthProfileUpdateRequested(photoUrl: ''));
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showEmojiPicker(BuildContext context, AuthBloc authBloc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elige un ícono'),
        content: SizedBox(
          width: 300,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: _kAvatarEmojis.length,
            itemBuilder: (_, i) {
              final emoji = _kAvatarEmojis[i];
              return GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  authBloc.add(
                      AuthProfileUpdateRequested(photoUrl: 'emoji://$emoji'));
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(emoji,
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
        ],
      ),
    );
  }
}

