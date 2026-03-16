import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/auth/auth_repository.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/auth/user_profile.dart';
import 'package:frontend/core/models/sync_ui_status.dart';
import 'package:frontend/core/services/sync_service.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/retail/settings/presentation/screens/settings_screen.dart';
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
}

// ── Fixtures ──────────────────────────────────────────────────────────────────

final _mockProfile = UserProfile(
  id: 'u-settings-1',
  email: 'owner@settings.test',
  memberships: [
    TenantMembership(tenantId: 'tenant-settings', role: 'owner'),
  ],
);

// ── Helper ────────────────────────────────────────────────────────────────────

Widget _buildScreen(
  _StubSyncService syncService, {
  _StubAuthRepo? authRepo,
}) {
  return ProviderScope(
    overrides: [
      userProfileProvider.overrideWith((ref) => Future.value(_mockProfile)),
      activeTenantProvider.overrideWith((ref) => 'tenant-settings'),
      syncServiceProvider.overrideWithValue(syncService),
      syncStatusProvider.overrideWith(
        (ref) => Stream.value(SyncUiStatus.connected),
      ),
      inventoryOutboxCountProvider.overrideWith((ref) => Stream.value(2)),
      lastSyncProvider.overrideWith(
        (ref) => Future.value(DateTime(2026, 3, 16, 10, 30)),
      ),
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

  // ── T1 : toutes les sections sont présentes ──────────────────────────────
  testWidgets('Toutes les sections et boutons clés sont présents',
      (tester) async {
    final syncService = _StubSyncService();
    await tester.pumpWidget(_buildScreen(syncService));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Section headers
    expect(find.text('Compte'), findsOneWidget);
    expect(find.text('Boutique'), findsOneWidget);
    expect(find.text('Reçu'), findsOneWidget);
    expect(find.text('Synchronisation'), findsOneWidget);
    expect(find.text('Application'), findsOneWidget);

    // Compte section content
    expect(find.text('owner@settings.test'), findsOneWidget);
    expect(find.text('Propriétaire'), findsOneWidget);
    expect(
        find.widgetWithText(OutlinedButton, 'Se déconnecter'), findsOneWidget);

    // Sync section
    expect(find.text('Forcer la synchronisation'), findsOneWidget);

    // Application section
    expect(find.text('Scalario v1.0.0'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Vider le cache local'),
      findsOneWidget,
    );
  });

  // ── T2 : logout — dialog de confirmation + appelle signOut ───────────────
  testWidgets('Se déconnecter : dialog puis signOut appelé', (tester) async {
    final syncService = _StubSyncService();
    final authRepo = _StubAuthRepo();

    await tester.pumpWidget(_buildScreen(syncService, authRepo: authRepo));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Scroll to make button visible, then tap
    final logoutBtn =
        find.widgetWithText(OutlinedButton, 'Se déconnecter');
    await tester.ensureVisible(logoutBtn);
    await tester.tap(logoutBtn);
    await tester.pumpAndSettle();

    // Dialog must be visible
    expect(
      find.text('Voulez-vous vraiment vous déconnecter ?'),
      findsOneWidget,
    );

    // Confirm logout
    await tester.tap(find.widgetWithText(TextButton, 'Confirmer'));
    await tester.pump();

    expect(authRepo.signOutCalled, isTrue);
  });

  // ── T3 : force sync — appelle syncService.forceSync ─────────────────────
  testWidgets('Forcer la synchronisation appelle syncService.forceSync()',
      (tester) async {
    final syncService = _StubSyncService();

    await tester.pumpWidget(_buildScreen(syncService));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Scroll the button into the viewport before tapping.
    await tester.ensureVisible(find.text('Forcer la synchronisation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forcer la synchronisation'));
    await tester.pump();

    expect(syncService.forceSyncCalled, isTrue);
  });
}
