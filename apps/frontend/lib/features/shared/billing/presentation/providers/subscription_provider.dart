import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'package:frontend/core/auth/auth_state.dart';
import '../../data/repositories/subscription_repository.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (_) => SubscriptionRepository(),
);

final subscriptionProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final token =
      Supabase.instance.client.auth.currentSession?.accessToken ?? '';
  final tenantId = ref.watch(activeTenantProvider) ?? '';
  if (token.isEmpty || tenantId.isEmpty) throw Exception('Not authenticated');
  return ref
      .read(subscriptionRepositoryProvider)
      .getMySubscription(token: token, tenantId: tenantId);
});

final isSuspendedProvider = FutureProvider.autoDispose<bool>((ref) async {
  try {
    final data = await ref.watch(subscriptionProvider.future);
    return data['billingStatus'] == 'suspended';
  } catch (_) {
    return false;
  }
});
