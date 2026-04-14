import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/shared/internal_orders/data/internal_order.dart';
import 'package:frontend/features/shared/internal_orders/presentation/screens/internal_order_detail_screen.dart';
import 'package:frontend/features/shared/internal_orders/presentation/screens/internal_orders_screen.dart'
    show pendingOrderNavigationProvider;
import 'package:frontend/features/retail/backoffice/presentation/screens/dashboard_screen.dart'
    show dashboardNavigationProvider;
import 'package:frontend/features/shared/notifications/data/models/notification_model.dart';
import 'package:frontend/features/shared/notifications/presentation/providers/notification_providers.dart';

// ── Bell icon button ──────────────────────────────────────────────────────────

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(unreadNotificationCountProvider);
    final backendCount = countAsync.when(
      data: (n) => n,
      loading: () => 0,
      error: (_, _) => 0,
    );
    // Use mock count as fallback until backend is connected
    final count = backendCount > 0
        ? backendCount
        : mockNotifications.where((n) => !n.isRead).length;

    return IconButton(
      tooltip: 'Notifications',
      onPressed: () => _openPanel(context, ref),
      icon: count > 0
          ? Badge(
              label: Text('$count'),
              backgroundColor: AppColors.error,
              child: const Text('\u{1F514}',
                  style: TextStyle(fontSize: 20)),
            )
          : const Text('\u{1F514}',
              style: TextStyle(fontSize: 20)),
    );
  }

  void _openPanel(BuildContext context, WidgetRef ref) =>
      openNotificationPanel(context);

  /// Opens the notification panel. Can be called externally.
  static void openNotificationPanel(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;

    if (isDesktop) {
      // Desktop: right-side overlay panel
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Notifications',
        barrierColor: Colors.black26,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (ctx, a1, a2) {
          return Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 56),
              child: Material(
                elevation: 16,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                ),
                child: Container(
                  width: 420,
                  height: MediaQuery.sizeOf(ctx).height - 56,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                  child: const _NotificationPanelContent(isDesktop: true),
                ),
              ),
            ),
          );
        },
        transitionBuilder: (_, anim, _, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: child,
          );
        },
      );
    } else {
      // Mobile: full-screen push
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              const _NotificationPanelContent(isDesktop: false),
        ),
      );
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Notification panel content — Figma 13:11 (mobile) / 13:162 (desktop)
// ══════════════════════════════════════════════════════════════════════════════

class _NotificationPanelContent extends ConsumerStatefulWidget {
  final bool isDesktop;
  const _NotificationPanelContent({required this.isDesktop});

  @override
  ConsumerState<_NotificationPanelContent> createState() =>
      _NotificationPanelContentState();
}

class _NotificationPanelContentState
    extends ConsumerState<_NotificationPanelContent>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  bool _markingAll = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

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

  void _handleAction(BuildContext context, NotificationModel notification) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;

    // Close the notification panel first
    Navigator.pop(context);

    // Navigate based on notification type
    switch (notification.type) {
      case 'internal_order':
        if (isDesktop) {
          // Switch to Commandes tab, then signal the order to open inline
          ref.read(dashboardNavigationProvider.notifier).state = 'Commandes';
          if (notification.targetId != null) {
            ref.read(pendingOrderNavigationProvider.notifier).state =
                notification.targetId;
          }
        } else {
          // Mobile: push the detail screen
          final order = mockInternalOrders
              .where((o) => notification.targetId != null
                  ? o.id == notification.targetId
                  : true)
              .firstOrNull;
          if (order != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => InternalOrderDetailScreen(order: order),
              ),
            );
          }
        }
      case 'low_stock':
        break;
      case 'loss':
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use mock notifications for now (replace with provider when backend ready)
    final notifications = mockNotifications;
    final actionCount =
        notifications.where((n) => n.category == 'action').length;
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.isDesktop ? null : AppBar(
        backgroundColor: AppColors.appbar,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Text('\u2039',
              style: TextStyle(fontSize: 28, color: Colors.white)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notifications',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          Opacity(
            opacity: 0.9,
            child: IconButton(
              icon: const Text('\u2699',
                  style: TextStyle(fontSize: 20, color: Colors.white)),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Desktop header ──────────────────────────────────────────
          if (widget.isDesktop)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  const Text('Notifications',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  if (unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$unreadCount nouvelles',
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  const Spacer(),
                  if (unreadCount > 0)
                    TextButton(
                      onPressed: _markingAll ? null : _markAllRead,
                      child: _markingAll
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Tout marquer lu',
                              style: TextStyle(fontSize: 12)),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

          // ── Tabs ────────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 0.8),
              ),
            ),
            padding: EdgeInsets.only(left: widget.isDesktop ? 20 : 16),
            child: TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 1.6,
              labelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              tabs: [
                _buildToutTab(notifications.length),
                _buildPlainTab('Action requise', actionCount),
                const Tab(child: Text('Info')),
              ],
            ),
          ),

          // ── List ────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _NotificationList(
                  notifications: notifications,
                  onMarkRead: _markRead,
                  onAction: (n) => _handleAction(context, n),
                ),
                _NotificationList(
                  notifications: notifications
                      .where((n) => n.category == 'action')
                      .toList(),
                  onMarkRead: _markRead,
                  onAction: (n) => _handleAction(context, n),
                ),
                _NotificationList(
                  notifications: notifications
                      .where((n) => n.category == 'info')
                      .toList(),
                  onMarkRead: _markRead,
                  onAction: (n) => _handleAction(context, n),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// "Tout" tab — blue pill badge with count (Figma 13:27)
  Widget _buildToutTab(int count) {
    final isActive = _tabCtrl.index == 0;
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Tout'),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// "Action requise" tab — plain number, no pill (Figma 13:33)
  Widget _buildPlainTab(String label, int count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 4),
          Text('$count',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Notification list with date grouping
// ══════════════════════════════════════════════════════════════════════════════

class _NotificationList extends StatelessWidget {
  final List<NotificationModel> notifications;
  final ValueChanged<String> onMarkRead;
  final void Function(NotificationModel notification)? onAction;

  const _NotificationList({
    required this.notifications,
    required this.onMarkRead,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return const _EmptyState();
    }

    // Group by date
    final grouped = <String, List<NotificationModel>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];

    for (final n in notifications) {
      final nDay = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      String label;
      if (nDay == today) {
        label = "Aujourd'hui \u00B7 ${n.createdAt.day} ${months[n.createdAt.month - 1]}";
      } else if (nDay == yesterday) {
        label = 'Hier \u00B7 ${n.createdAt.day} ${months[n.createdAt.month - 1]}';
      } else {
        label = '${n.createdAt.day} ${months[n.createdAt.month - 1]}';
      }
      grouped.putIfAbsent(label, () => []).add(n);
    }

    return ListView.builder(
      itemCount: grouped.length,
      itemBuilder: (_, i) {
        final entry = grouped.entries.elementAt(i);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                entry.key.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            // Notification tiles
            ...entry.value.map((n) => _NotificationTile(
                  notification: n,
                  onTap: n.isRead ? null : () => onMarkRead(n.id),
                  onAction: onAction != null ? () => onAction!(n) : null,
                )),
          ],
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Single notification tile — Figma 13:48
// ══════════════════════════════════════════════════════════════════════════════

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onAction;

  const _NotificationTile({required this.notification, this.onTap, this.onAction});

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final icon = _iconData();
    final time =
        '${notification.createdAt.hour.toString().padLeft(2, '0')}:${notification.createdAt.minute.toString().padLeft(2, '0')}';

    return Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            color: isUnread ? const Color(0xFFF3F8FE) : Colors.white,
            border: const Border(
              bottom: BorderSide(color: AppColors.border, width: 0.8),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: icon.bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(icon.emoji,
                    style: TextStyle(fontSize: 18, color: icon.fgColor)),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + time
                    Row(
                      children: [
                        Expanded(
                          child: Text(notification.title,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3)),
                        ),
                        const SizedBox(width: 8),
                        Text(time,
                            style: const TextStyle(
                                fontFamily: 'Cousine',
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Body
                    Text(notification.body,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    // Actor
                    if (notification.actor != null) ...[
                      const SizedBox(height: 4),
                      Text(notification.actor!,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary)),
                    ],
                    // Action button
                    if (notification.actionLabel != null) ...[
                      const SizedBox(height: 10),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: onAction,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(notification.actionLabel!,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
    );
  }

  ({String emoji, Color bgColor, Color fgColor}) _iconData() {
    switch (notification.type) {
      case 'internal_order':
        return (
          emoji: '\u26A1',
          bgColor: const Color(0xFFFFEBEE),
          fgColor: const Color(0xFFC62828),
        );
      case 'low_stock':
        return (
          emoji: '\u{1F4E6}',
          bgColor: const Color(0xFFFFF8E1),
          fgColor: const Color(0xFFB27A00),
        );
      case 'loss':
        return (
          emoji: '\u26A0',
          bgColor: const Color(0xFFFFF8E1),
          fgColor: const Color(0xFFB27A00),
        );
      case 'session_closed':
        return (
          emoji: '\u2713',
          bgColor: const Color(0xFFE8F5E9),
          fgColor: const Color(0xFF2E7D32),
        );
      case 'expense':
        return (
          emoji: '\u{1F4B8}',
          bgColor: const Color(0xFFE3F2FD),
          fgColor: const Color(0xFF1565C0),
        );
      case 'sync':
        return (
          emoji: '\u21BB',
          bgColor: const Color(0xFFECEFF1),
          fgColor: const Color(0xFF757575),
        );
      default:
        return (
          emoji: '\u{1F514}',
          bgColor: const Color(0xFFF5F5F5),
          fgColor: const Color(0xFF757575),
        );
    }
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('\u{1F389}', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text('Tout est sous contrôle',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            const Text(
              'Aucune notification pour le moment.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
