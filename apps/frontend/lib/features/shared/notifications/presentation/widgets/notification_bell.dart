import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/shared/notifications/data/models/notification_model.dart';
import 'package:frontend/features/shared/notifications/presentation/providers/notification_providers.dart';
import 'package:intl/intl.dart';

// ── Bell icon button ──────────────────────────────────────────────────────────

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(unreadNotificationCountProvider);
    final count = countAsync.when(
      data: (n) => n,
      loading: () => 0,
      error: (_, _) => 0,
    );

    return IconButton(
      tooltip: 'Notifications',
      onPressed: () => _openPanel(context, ref),
      icon: count > 0
          ? Badge(
              label: Text('$count'),
              backgroundColor: AppColors.error,
              child: const Icon(Icons.notifications_outlined),
            )
          : const Icon(Icons.notifications_outlined),
    );
  }

  void _openPanel(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const _NotificationPanel(),
    );
  }
}

// ── Notification panel ────────────────────────────────────────────────────────

class _NotificationPanel extends ConsumerStatefulWidget {
  const _NotificationPanel();

  @override
  ConsumerState<_NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends ConsumerState<_NotificationPanel> {
  bool _markingAll = false;

  Future<void> _markAllRead() async {
    final tenantId = ref.read(activeTenantProvider);
    if (tenantId == null) return;
    setState(() => _markingAll = true);
    try {
      await ref.read(notificationRepositoryProvider).markAllRead(tenantId);
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationCountProvider);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  Future<void> _markRead(String id) async {
    final tenantId = ref.read(activeTenantProvider);
    if (tenantId == null) return;
    try {
      await ref.read(notificationRepositoryProvider).markRead(id, tenantId);
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationCountProvider);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 4, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  notificationsAsync.maybeWhen(
                    data: (list) {
                      final hasUnread = list.any((n) => !n.isRead);
                      if (!hasUnread) return const SizedBox.shrink();
                      return TextButton(
                        onPressed: _markingAll ? null : _markAllRead,
                        child: _markingAll
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Tout marquer lu'),
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: notificationsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text(
                    'Erreur : $e',
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
                data: (notifications) {
                  if (notifications.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aucune notification.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: scrollController,
                    itemCount: notifications.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, indent: 56),
                    itemBuilder: (_, i) {
                      final n = notifications[i];
                      return _NotificationTile(
                        notification: n,
                        onTap: n.isRead ? null : () => _markRead(n.id),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Notification tile ─────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;

  const _NotificationTile({required this.notification, this.onTap});

  IconData _icon() {
    switch (notification.type) {
      case 'low_stock':
        return Icons.inventory_2_outlined;
      case 'transfer_pending':
        return Icons.swap_horiz;
      case 'session_closed':
        return Icons.point_of_sale;
      case 'session_variance':
        return Icons.warning_amber_outlined;
      case 'daily_summary':
        return Icons.bar_chart;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _iconColor() {
    switch (notification.type) {
      case 'low_stock':
        return AppColors.warning;
      case 'session_variance':
        return AppColors.error;
      case 'transfer_pending':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final timeLabel = _formatTime(notification.createdAt);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _iconColor().withValues(alpha: 0.12),
        child: Icon(_icon(), color: _iconColor(), size: 20),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notification.body, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(
            timeLabel,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      trailing: isUnread
          ? Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
            )
          : null,
      onTap: onTap,
      tileColor: isUnread
          ? AppColors.primary.withValues(alpha: 0.04)
          : null,
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inHours < 1) return 'Il y a ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'Il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} j';
    return DateFormat('dd/MM/yyyy').format(dt);
  }
}
