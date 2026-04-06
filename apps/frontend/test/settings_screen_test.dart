import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/auth/auth_repository.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/auth/user_profile.dart';
import 'package:frontend/core/models/sync_ui_status.dart';
import 'package:frontend/core/providers/active_modules_provider.dart';
import 'package:frontend/core/services/sync_service.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/core/settings/settings_screen.dart';
import 'package:frontend/features/shared/notifications/presentation/providers/notification_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;

// ── Test doubles ──────────────────────────────────────────────────────────────

class _StubSyncService extends SyncService {
  bool forceSyncCalled = false;
  final _statusCtrl = StreamController<SyncUiStatus>.broadcast();

  @override
  Stream<SyncUiStatus> get statusStream => _statusCtrl.stream;

  @override
  Future<void> startSync(String? tenantId, {String? authToken}) async {}

  @override
  void forceSync() => forceSyncCalled = true;
}

class _StubAuthRepo implements AuthRepository {
  bool signOutCalled = false;

  @override
  Session? get currentSession => null;

  @override
  User? get currentUser => null;

  @override
  Stream<AuthState> get authStateChanges => Stream.empty();

  @override
  Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> signOut() async => signOutCalled = true;

  @override
  Future<UserProfile?> getUserProfile() async => null;

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> updateFullName(String fullName) async {}

  @override
  Future<void> changePassword(String newPassword) async {}

  @override
  Future<void> verifyPassword(String currentPassword) async {}
}

// ── Fixtures ──────────────────────────────────────────────────────────────────

final _ownerProfile = UserProfile(
  id: 'u-owner-1',
  email: 'owner@settings.test',
  memberships: [
    TenantMembership(
      tenantId: 'tenant-settings',
      role: 'owner',
      tenantName: 'Demo Store',
    ),
  ],
);

final _managerProfile = UserProfile(
  id: 'u-manager-1',
  email: 'manager@settings.test',
  memberships: [
    TenantMembership(
      tenantId: 'tenant-settings',
      role: 'manager',
      tenantName: 'Demo Store',
    ),
  ],
);

final _commercialProfile = UserProfile(
  id: 'u-commercial-1',
  email: 'commercial@settings.test',
  memberships: [
    TenantMembership(
      tenantId: 'tenant-settings',
      role: 'commercial',
      tenantName: 'Demo Store',
    ),
  ],
);

final _mockTenantInfo = {
  'id': 'tenant-settings',
  'name': 'Demo Store',
  'address': 'Ouaga, Secteur 30',
  'phone': '+226 70 00 00 00',
  'businessType': 'epicerie',
  'businessTypeName': 'Épicerie & Alimentation',
  'currency': 'XOF',
  'plan': 'standard',
};

final _mockBilling = {
  'plan': {'name': 'Standard', 'monthlyPrice': 25000},
  'billingStatus': 'active',
  'trialEndsAt': null,
  'paidUntil': DateTime.now().add(const Duration(days: 92)).toIso8601String(),
};

final _mockUsers = [
  {'userId': 'u-owner-1', 'email': 'owner@settings.test', 'role': 'owner'},
  {'userId': 'u-manager-1', 'email': 'manager@settings.test', 'role': 'manager'},
];

// ── Helper ────────────────────────────────────────────────────────────────────

Widget _buildScreen(
  _StubSyncService syncService, {
  UserProfile? profile,
  _StubAuthRepo? authRepo,
  bool withBillingAndUsers = true,
}) {
  final resolvedProfile = profile ?? _ownerProfile;
  return ProviderScope(
    overrides: [
      userProfileProvider.overrideWith(
          (ref) => Future.value(resolvedProfile)),
      activeTenantProvider.overrideWith((ref) => 'tenant-settings'),
      syncServiceProvider.overrideWithValue(syncService),
      syncStatusProvider.overrideWith(
        (ref) => Stream.value(SyncUiStatus.connected),
      ),
      inventoryOutboxCountProvider.overrideWith(
          (ref) => Stream.value(2)),
      lastSyncProvider.overrideWith(
        (ref) => Future.value(DateTime(2026, 3, 16, 10, 30)),
      ),
      tenantInfoProvider.overrideWith(
          (ref) => Future.value(_mockTenantInfo)),
      activeModulesProvider.overrideWith(
        (ref) => Future.value({'catalog', 'clients', 'inventory',
            'transactions', 'expenses', 'reports', 'retail'}),
      ),
      unreadNotificationCountProvider.overrideWith(
        (ref) => Stream.value(0),
      ),
      if (withBillingAndUsers) ...[
        tenantBillingProvider.overrideWith(
            (ref) => Future.value(_mockBilling)),
        tenantUsersProvider.overrideWith(
            (ref) => Future.value(_mockUsers)),
      ],
      if (authRepo != null)
        authRepositoryProvider.overrideWithValue(authRepo),
    ],
    child: const MaterialApp(home: SettingsScreen()),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ── T1 : sections communes présentes (owner) ──────────────────────────────
  testWidgets('Owner : toutes les sections sont présentes', (tester) async {
    final syncService = _StubSyncService();
    await tester.pumpWidget(_buildScreen(syncService));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Section headers
    expect(find.text('Compte'), findsOneWidget);
    expect(find.text('Boutique & Configuration'), findsOneWidget);
    expect(find.text('Modules actifs'), findsOneWidget);
    expect(find.text('Reçu'), findsOneWidget);
    expect(find.text('Synchronisation'), findsOneWidget);
    expect(find.text('Application'), findsOneWidget);

    // Nav tiles inside "Boutique & Configuration"
    expect(find.text('Paramètres généraux'), findsOneWidget);
    expect(find.text('Équipe & Utilisateurs'), findsOneWidget);
    expect(find.text('Mon abonnement'), findsOneWidget);
    expect(find.text('Intégrations'), findsOneWidget);

    // Compte section (email/role may also appear in Utilisateurs section)
    expect(find.text('owner@settings.test'), findsAtLeastNWidgets(1));
    expect(find.text('Propriétaire'), findsAtLeastNWidgets(1));
    expect(find.widgetWithText(OutlinedButton, 'Se déconnecter'),
        findsOneWidget);

    // Sync section
    expect(find.text('Forcer la synchronisation'), findsOneWidget);

    // Application section
    expect(find.text('Scalario v1.0.0'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Vider le cache local'),
      findsOneWidget,
    );
  });

  // ── T2 : manager ne voit pas les sections owner-only ─────────────────────
  testWidgets('Manager : sections owner-only absentes', (tester) async {
    final syncService = _StubSyncService();
    await tester.pumpWidget(
        _buildScreen(syncService, profile: _managerProfile));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Toujours là
    expect(find.text('Compte'), findsOneWidget);
    expect(find.text('Boutique'), findsOneWidget);
    expect(find.text('Synchronisation'), findsOneWidget);
    expect(find.text('Application'), findsOneWidget);

    // Absentes pour manager
    expect(find.text('Boutique & Configuration'), findsNothing);
    expect(find.text('Mon abonnement'), findsNothing);
    expect(find.text('Méthodes de paiement'), findsNothing);
    expect(find.text('Reçu'), findsNothing);
  });

  // ── T3 : logout — dialog de confirmation + appelle signOut ───────────────
  testWidgets('Se déconnecter : dialog puis signOut appelé', (tester) async {
    final syncService = _StubSyncService();
    final authRepo = _StubAuthRepo();

    await tester.pumpWidget(
        _buildScreen(syncService, authRepo: authRepo));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final logoutBtn = find.widgetWithText(OutlinedButton, 'Se déconnecter');
    await tester.ensureVisible(logoutBtn);
    await tester.tap(logoutBtn);
    await tester.pumpAndSettle();

    expect(
      find.text('Voulez-vous vraiment vous déconnecter ?'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(TextButton, 'Confirmer'));
    await tester.pump();

    expect(authRepo.signOutCalled, isTrue);
  });

  // ── T4 : force sync ───────────────────────────────────────────────────────
  testWidgets('Forcer la synchronisation appelle syncService.forceSync()',
      (tester) async {
    final syncService = _StubSyncService();

    await tester.pumpWidget(_buildScreen(syncService));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.ensureVisible(find.text('Forcer la synchronisation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forcer la synchronisation'));
    await tester.pump();

    expect(syncService.forceSyncCalled, isTrue);
  });

  // ── T5 : vider cache — dialog de confirmation ─────────────────────────────
  testWidgets('Vider le cache : dialog de confirmation affiché',
      (tester) async {
    final syncService = _StubSyncService();

    await tester.pumpWidget(_buildScreen(syncService));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final clearBtn =
        find.widgetWithText(OutlinedButton, 'Vider le cache local');
    await tester.ensureVisible(clearBtn);
    await tester.tap(clearBtn);
    await tester.pumpAndSettle();

    expect(find.text('Vider le cache local'), findsWidgets);
    expect(
      find.text(
          'Toutes les données locales seront supprimées. '
          "Redémarrez l'application pour recharger les données."),
      findsOneWidget,
    );

    // Dismiss
    await tester.tap(find.widgetWithText(TextButton, 'Annuler'));
    await tester.pumpAndSettle();
  });

  // ── T6 : boutique owner — nav tiles vers écrans dédiés ─────────────────────
  testWidgets('Owner : section Boutique & Configuration avec nav tiles',
      (tester) async {
    final syncService = _StubSyncService();

    await tester.pumpWidget(_buildScreen(syncService));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Paramètres généraux'), findsOneWidget);
    expect(find.text('Équipe & Utilisateurs'), findsOneWidget);
    expect(find.text('Mon abonnement'), findsOneWidget);
  });

  // ── T7 : rôle affiché en label lisible ───────────────────────────────────
  testWidgets('Rôle owner affiché en "Propriétaire"', (tester) async {
    final syncService = _StubSyncService();

    await tester.pumpWidget(_buildScreen(syncService));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Propriétaire'), findsAtLeastNWidgets(1));
  });

  // ── T8 : manager voit Boutique + Équipe + Modules ─────────────────────────
  testWidgets('Manager : sections attendues présentes', (tester) async {
    final syncService = _StubSyncService();
    await tester.pumpWidget(
        _buildScreen(syncService, profile: _managerProfile));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Boutique'), findsOneWidget);
    expect(find.text('Équipe'), findsOneWidget);
    expect(find.text('Modules actifs'), findsOneWidget);
    expect(find.text('Synchronisation'), findsOneWidget);
    expect(find.text('Application'), findsOneWidget);

    // Sections owner-only absentes
    expect(find.text('Boutique & Configuration'), findsNothing);
    expect(find.text('Mon abonnement'), findsNothing);
    expect(find.text('Méthodes de paiement'), findsNothing);
    expect(find.text('Reçu'), findsNothing);
  });

  // ── T9 : manager boutique en lecture seule ────────────────────────────────
  testWidgets('Manager : Boutique en lecture seule', (tester) async {
    final syncService = _StubSyncService();
    await tester.pumpWidget(
        _buildScreen(syncService, profile: _managerProfile));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Pas de champs éditables ni de bouton Save
    expect(find.byType(TextField), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Enregistrer les modifications'),
        findsNothing);
    // Nom de la boutique affiché en lecture seule
    expect(find.text('Demo Store'), findsAtLeastNWidgets(1));
  });

  // ── T10 : commercial voit seulement Compte + Sync + App ───────────────────
  testWidgets('Commercial : sections minimales seulement', (tester) async {
    final syncService = _StubSyncService();
    await tester.pumpWidget(
        _buildScreen(syncService,
            profile: _commercialProfile, withBillingAndUsers: false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Compte'), findsOneWidget);
    expect(find.text('Synchronisation'), findsOneWidget);
    expect(find.text('Application'), findsOneWidget);

    // Sections non visibles pour commercial
    expect(find.text('Boutique'), findsNothing);
    expect(find.text('Boutique & Configuration'), findsNothing);
    expect(find.text('Équipe'), findsNothing);
    expect(find.text('Mon abonnement'), findsNothing);
    expect(find.text('Modules actifs'), findsNothing);
  });

  // ── T11 : owner voit Intégrations dans Boutique & Configuration ──────────
  testWidgets('Owner : section Intégrations présente', (tester) async {
    final syncService = _StubSyncService();
    await tester.pumpWidget(_buildScreen(syncService));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Intégrations'), findsOneWidget);
    expect(find.textContaining('Orange Money'), findsAtLeastNWidgets(1));
  });
}
