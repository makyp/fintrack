import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../cubit/notifications_cubit.dart';
import '../../domain/entities/notification_item.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthBloc>().state.user?.uid ?? '';
    return BlocProvider(
      create: (_) => NotificationsCubit(getIt())..watch(userId),
      child: _NotificationsView(userId: userId),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  final String userId;
  const _NotificationsView({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, state) {
              if (state.unreadCount == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: () =>
                    context.read<NotificationsCubit>().markAllRead(userId),
                child: const Text('Marcar todas'),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          if (state.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications_none_outlined,
                      size: 64, color: AppColors.grey300),
                  const SizedBox(height: AppDimensions.md),
                  Text('Sin notificaciones',
                      style: AppTextStyles.headlineSmall
                          .copyWith(color: AppColors.grey500)),
                  const SizedBox(height: AppDimensions.sm),
                  Text(
                    'Aquí verás logros, alertas de pagos\ny recordatorios.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.grey400),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: state.items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final notif = state.items[i];
              return _NotifTile(
                notif: notif,
                onTap: () {
                  if (!notif.read) {
                    context
                        .read<NotificationsCubit>()
                        .markRead(userId, notif.id);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final NotificationItem notif;
  final VoidCallback onTap;
  const _NotifTile({required this.notif, required this.onTap});

  IconData get _icon {
    switch (notif.type) {
      case 'badge':
        return Icons.emoji_events_outlined;
      case 'recurring':
        return Icons.repeat_outlined;
      case 'interest':
        return Icons.trending_up_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color get _color {
    switch (notif.type) {
      case 'badge':
        return const Color(0xFFD97706);
      case 'recurring':
        return AppColors.primary;
      case 'interest':
        return AppColors.success;
      default:
        return AppColors.grey500;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'hace ${diff.inDays} d';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: notif.read ? null : AppColors.primary.withOpacity(0.04),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.pagePadding,
          vertical: AppDimensions.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon, color: _color, size: 20),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notif.title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight:
                            notif.read ? FontWeight.normal : FontWeight.w600,
                      )),
                  const SizedBox(height: 2),
                  Text(notif.body,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.grey500)),
                  const SizedBox(height: 4),
                  Text(_timeAgo(notif.createdAt),
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.grey400, fontSize: 11)),
                ],
              ),
            ),
            if (!notif.read)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6, left: 8),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
