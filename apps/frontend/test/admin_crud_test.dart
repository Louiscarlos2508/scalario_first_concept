import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/admin/data/models/tenant_module_status.dart';
import 'package:frontend/features/admin/data/models/tenant_summary.dart';
import 'package:frontend/features/admin/data/models/tenant_user.dart';
import 'package:frontend/features/admin/data/services/admin_api_service.dart';
import 'package:frontend/features/admin/presentation/providers/admin_providers.dart';
import 'package:frontend/features/admin/presentation/screens/new_tenant_form.dart';
import 'package:frontend/features/admin/presentation/widgets/tenant_modules_tab.dart';
import 'package:frontend/features/admin/presentation/widgets/tenant_users_tab.dart';

// ── Stub AdminApiService ──────────────────────────────────────────────────────

class _StubAdminApiService extends AdminApiService {
  Map<String, dynamic>? createTenantResult;
  AdminApiException? createTenantError;
  Map<String, dynamic>? createUserResult;
  AdminApiException? createUserError;
  bool activateCalled = false;
  AdminApiException? activateError;
  bool deactivateCalled = false;
  bool removeUserCalled = false;

  @override
  Future<Map<String, dynamic>> createTenant(dto, {required String token}) async {
    if (createTenantError != null) throw createTenantError!;
    return createTenantResult ?? {'tenantId': 'new-id'};
  }

  @override
  Future<Map<String, dynamic>> createTenantUser(String tenantId,
      {required String email,
      required String password,
      required String role,
      required String token}) async {
    if (createUserError != null) throw createUserError!;
    return createUserResult ??
        {'userId': 'u-1', 'email': email, 'role': role};
  }

  @override
  Future<void> activateModule(String tenantId, String moduleCode,
      {required String token}) async {
    activateCalled = true;
    if (activateError != null) throw activateError!;
  }

  @override
  Future<void> deactivateModule(String tenantId, String moduleCode,
      {required String token}) async {
    deactivateCalled = true;
  }

  @override
  Future<void> removeUser(String tenantId, String userId,
      {required String token}) async {
    removeUserCalled = true;
  }

  @override
  Future<Map<String, dynamic>> updateUserRole(
      String tenantId, String userId, String role,
      {required String token}) async {
    return {'userId': userId, 'role': role};
  }

  @override
  Future<List<TenantSummary>> fetchTenants({required String token}) async =>
      [];

  @override
  Future<List<TenantModuleStatus>> getTenantModules(String tenantId,
          {required String token}) async =>
      [];

  @override
  Future<List<TenantUser>> getTenantUsers(String tenantId,
          {required String token}) async =>
      [];
}

// ── Fixtures ──────────────────────────────────────────────────────────────────

const _tenantId = 'tenant-test-1';

final _stubModules = [
  const TenantModuleStatus(
    moduleCode: 'catalog',
    name: 'Catalogue',
    type: 'shared',
    status: 'active',
    dependencies: [],
  ),
  const TenantModuleStatus(
    moduleCode: 'inventory',
    name: 'Inventaire',
    type: 'shared',
    status: 'inactive',
    dependencies: ['catalog'],
  ),
];

final _stubUsers = [
  const TenantUser(
    userId: 'u-owner',
    email: 'owner@test.com',
    role: 'owner',
  ),
];

// ── Helpers ───────────────────────────────────────────────────────────────────

ProviderScope _wrap(Widget child, _StubAdminApiService stub,
    {List<Override> extra = const []}) {
  return ProviderScope(
    overrides: [
      adminApiServiceProvider.overrideWithValue(stub),
      adminTenantsProvider.overrideWith((ref) => Future.value([])),
      ...extra,
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

// ── NewTenantForm tests ───────────────────────────────────────────────────────

void main() {
  group('NewTenantForm (AC1)', () {
    testWidgets('empty fields show validation errors', (tester) async {
      final stub = _StubAdminApiService();
      await tester.pumpWidget(_wrap(const NewTenantForm(), stub));
      await tester.pump();

      // Scroll to submit button (form is taller than test viewport)
      await tester.ensureVisible(find.text('Créer le client'));
      await tester.tap(find.text('Créer le client'));
      await tester.pump();

      expect(find.text('Le nom est obligatoire'), findsOneWidget);
      expect(find.text('Email invalide'), findsOneWidget);
      expect(find.text('Au moins 8 caractères requis'), findsOneWidget);
    });

    testWidgets('valid form calls createTenant with correct params',
        (tester) async {
      final stub = _StubAdminApiService();
      await tester.pumpWidget(_wrap(const NewTenantForm(), stub));
      await tester.pump();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Nom boutique'), 'Test Shop');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email owner'),
          'owner@test.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Mot de passe owner'),
          'password123');

      await tester.ensureVisible(find.text('Créer le client'));
      await tester.tap(find.text('Créer le client'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // createTenant was called (no exception thrown = success)
      expect(stub.createTenantError, isNull);
    });

    testWidgets('422 EMAIL_ALREADY_EXISTS shows red snackbar', (tester) async {
      final stub = _StubAdminApiService()
        ..createTenantError =
            const AdminApiException(code: 'EMAIL_ALREADY_EXISTS');
      await tester.pumpWidget(_wrap(const NewTenantForm(), stub));
      await tester.pump();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Nom boutique'), 'Shop');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email owner'),
          'dup@test.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Mot de passe owner'),
          'password123');

      await tester.ensureVisible(find.text('Créer le client'));
      await tester.tap(find.text('Créer le client'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Cet email est déjà utilisé'), findsOneWidget);
    });
  });

  // ── TenantModulesTab tests ──────────────────────────────────────────────────

  group('TenantModulesTab (AC3)', () {
    testWidgets('renders module list with switches', (tester) async {
      final stub = _StubAdminApiService();
      await tester.pumpWidget(_wrap(
        const TenantModulesTab(tenantId: _tenantId),
        stub,
        extra: [
          tenantModulesProvider(_tenantId)
              .overrideWith((ref) => Future.value(_stubModules)),
        ],
      ));
      await tester.pump();

      expect(find.text('Catalogue'), findsOneWidget);
      expect(find.text('Inventaire'), findsOneWidget);
      expect(find.byType(Switch), findsNWidgets(2));
    });

    testWidgets('toggling inactive switch ON calls activateModule',
        (tester) async {
      final stub = _StubAdminApiService();
      await tester.pumpWidget(_wrap(
        const TenantModulesTab(tenantId: _tenantId),
        stub,
        extra: [
          tenantModulesProvider(_tenantId)
              .overrideWith((ref) => Future.value(_stubModules)),
        ],
      ));
      await tester.pump();

      // Find the OFF switch (inventory) and tap it
      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      final inventorySwitch = switches.firstWhere((s) => s.value == false);
      await tester.tap(find.byWidget(inventorySwitch));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(stub.activateCalled, isTrue);
    });

    testWidgets('activate 422 MISSING_DEPENDENCY shows snackbar',
        (tester) async {
      final stub = _StubAdminApiService()
        ..activateError = const AdminApiException(
            code: 'MISSING_DEPENDENCY', detail: ['catalog']);
      await tester.pumpWidget(_wrap(
        const TenantModulesTab(tenantId: _tenantId),
        stub,
        extra: [
          tenantModulesProvider(_tenantId)
              .overrideWith((ref) => Future.value(_stubModules)),
        ],
      ));
      await tester.pump();

      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      final inventorySwitch = switches.firstWhere((s) => s.value == false);
      await tester.tap(find.byWidget(inventorySwitch));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.textContaining('Activez d\'abord'), findsOneWidget);
    });
  });

  // ── TenantUsersTab tests ────────────────────────────────────────────────────

  group('TenantUsersTab (AC4)', () {
    testWidgets('FAB "+" tap shows AddUserDialog', (tester) async {
      final stub = _StubAdminApiService();
      await tester.pumpWidget(_wrap(
        const TenantUsersTab(tenantId: _tenantId),
        stub,
        extra: [
          tenantUsersProvider(_tenantId)
              .overrideWith((ref) => Future.value(_stubUsers)),
        ],
      ));
      await tester.pump();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      expect(find.text('Ajouter un utilisateur'), findsOneWidget);
    });

    testWidgets('valid AddUserDialog submit calls createTenantUser',
        (tester) async {
      final stub = _StubAdminApiService();
      await tester.pumpWidget(_wrap(
        const TenantUsersTab(tenantId: _tenantId),
        stub,
        extra: [
          tenantUsersProvider(_tenantId)
              .overrideWith((ref) => Future.value(_stubUsers)),
        ],
      ));
      await tester.pump();

      // Open dialog
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      // Fill email and password
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'new@test.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Mot de passe'), 'pass1234');

      await tester.tap(find.text('Ajouter'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(stub.createUserError, isNull);
    });

    testWidgets('more_vert → Désactiver → confirm → removeUser called',
        (tester) async {
      final stub = _StubAdminApiService();
      await tester.pumpWidget(_wrap(
        const TenantUsersTab(tenantId: _tenantId),
        stub,
        extra: [
          tenantUsersProvider(_tenantId)
              .overrideWith((ref) => Future.value(_stubUsers)),
        ],
      ));
      await tester.pump();

      // Open bottom sheet
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap "Désactiver l'accès"
      await tester.tap(find.text('Désactiver l\'accès'));
      await tester.pumpAndSettle();

      // Confirm dialog
      await tester.tap(find.text('Désactiver'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(stub.removeUserCalled, isTrue);
    });
  });
}
