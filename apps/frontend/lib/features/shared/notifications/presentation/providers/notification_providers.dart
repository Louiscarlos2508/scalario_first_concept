import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/shared/notifications/data/models/notification_model.dart';
import 'package:frontend/features/shared/notifications/data/repositories/notification_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;

// ── Repository ────────────────────────────────────────────────────────────────

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(
    tokenGetter: () =>
        Supabase.instance.client.auth.currentSession?.accessToken,
  );
});

// ── Unread count — polls every 60 s ──────────────────────────────────────────

final unreadNotificationCountProvider = StreamProvider<int>((ref) async* {
  final tenantId = ref.watch(activeTenantProvider);
  if (tenantId == null) {
    yield 0;
    return;
  }
  final repo = ref.read(notificationRepositoryProvider);
  while (true) {
    try {
      yield await repo.getUnreadCount(tenantId);
    } catch (_) {
      yield 0;
    }
    await Future.delayed(const Duration(seconds: 60));
  }
});

// ── Notifications list ────────────────────────────────────────────────────────

final notificationsProvider =
    FutureProvider<List<NotificationModel>>((ref) async {
  final tenantId = ref.watch(activeTenantProvider);
  if (tenantId == null) return [];
  return ref.read(notificationRepositoryProvider).getNotifications(tenantId);
});
