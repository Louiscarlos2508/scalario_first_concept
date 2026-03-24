import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/auth/user_profile.dart';
import 'package:frontend/core/services/isar_service.dart';
import 'package:frontend/features/retail/pos/data/models/pos_session.dart';
import 'package:frontend/features/retail/pos/data/repositories/order_repository.dart';
import 'package:frontend/features/retail/pos/data/repositories/session_repository.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/session_guard.dart';
import 'package:frontend/features/shared/business_type/data/business_type_config_repository.dart';
import 'package:frontend/features/shared/business_type/presentation/providers/business_type_config_provider.dart';
import 'package:frontend/features/shared/notifications/presentation/providers/notification_providers.dart';
import 'package:isar/isar.dart';

// ── Stub infrastructure ───────────────────────────────────────────────────────

/// IsarService dont initDb() ne résout jamais — évite l'init native Isar.
class _NullIsarService extends IsarService {
  @override
  Future<Isar> initDb() => Completer<Isar>().future;
}

/// SessionRepository dont getActiveSession() ne résout jamais.
/// Cela évite que checkActiveSession() essaie de setter l'état
/// après la fin du test (dispose).
class _NullSessionRepository extends SessionRepository {
  _NullSessionRepository() : super(_NullIsarService());

  @override
  Future<PosSession?> getActiveSession({required String userId}) =>
      Completer<PosSession?>().future;
}

/// OrderRepository minimal — aucune méthode appelée pendant le test.
class _NullOrderRepository extends OrderRepository {
  _NullOrderRepository() : super(_NullIsarService());
}

// ── Fixtures ──────────────────────────────────────────────────────────────────

final _managerProfile = UserProfile(
  id: 'u-mgr-1',
  email: 'manager@pos.test',
  memberships: [
    TenantMembership(
      tenantId: 'tenant-pos',
      role: 'manager',
      tenantName: 'Demo Store',
    ),
  ],
);

final _commercialProfile = UserProfile(
  id: 'u-com-1',
  email: 'commercial@pos.test',
  memberships: [
    TenantMembership(
      tenantId: 'tenant-pos',
      role: 'commercial',
      tenantName: 'Demo Store',
    ),
  ],
);

// ── Helper ────────────────────────────────────────────────────────────────────

Widget _buildGuard(UserProfile profile) {
  return ProviderScope(
    overrides: [
      userProfileProvider.overrideWith(
          (ref) => Future.value(profile)),
      activeTenantProvider.overrideWith((ref) => 'tenant-pos'),
      sessionRepositoryProvider.overrideWithValue(_NullSessionRepository()),
      orderRepositoryProvider.overrideWithValue(_NullOrderRepository()),
      businessTypeConfigProvider.overrideWith(
          (ref) => Future.value(BusinessTypeConfig.fallback)),
      unreadNotificationCountProvider.overrideWith(
          (ref) => Stream.value(0)),
    ],
    child: const MaterialApp(
      home: SessionGuard(child: Text('POS_CHILD')),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── T1 : manager → écran "Accès non autorisé" ────────────────────────────
  testWidgets('Manager : SessionGuard affiche "Accès non autorisé"',
      (tester) async {
    await tester.pumpWidget(_buildGuard(_managerProfile));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Accès non autorisé'), findsOneWidget);
    expect(find.text('Ouvrir la caisse'), findsNothing);
    expect(find.text('POS_CHILD'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Retour'), findsOneWidget);
  });

  // ── T2 : commercial → passe le garde, attend la session ─────────────────
  // getActiveSession ne résout jamais → sessionAsync reste en loading.
  // Le test vérifie que le garde POS est franchi (pas d'"Accès non autorisé").
  testWidgets('Commercial : SessionGuard franchit le garde POS',
      (tester) async {
    await tester.pumpWidget(_buildGuard(_commercialProfile));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Le garde POS est passé : pas d'écran "Accès non autorisé"
    expect(find.text('Accès non autorisé'), findsNothing);
    // La session est en cours de chargement (loading indicator visible)
    expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
  });
}
