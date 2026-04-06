import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/auth/user_profile.dart';
import 'package:frontend/core/models/sync_ui_status.dart';
import 'package:frontend/core/services/sync_service.dart';
import 'package:frontend/features/shared/business_type/data/business_type_config_repository.dart';
import 'package:frontend/features/shared/business_type/presentation/providers/business_type_config_provider.dart';
import 'package:frontend/features/shared/catalog/presentation/providers/catalog_providers.dart';
import 'package:frontend/features/shared/freshness/presentation/providers/freshness_provider.dart';
import 'package:frontend/features/shared/inventory/presentation/screens/product_stock_screen.dart';
import 'package:frontend/features/shared/reports/data/models/sales_stat.dart';
import 'package:frontend/features/shared/reports/presentation/providers/report_providers.dart';
import 'package:frontend/features/shared/stock_alerts/presentation/providers/stock_alerts_provider.dart';
import 'package:frontend/features/shared/inventory/presentation/providers/internal_requests_provider.dart';
import 'package:frontend/features/shared/notifications/presentation/providers/notification_providers.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';

class _StubSyncService extends SyncService {
  final _ctrl = StreamController<SyncUiStatus>.broadcast();
  @override
  Stream<SyncUiStatus> get statusStream => _ctrl.stream;
  @override
  Future<void> startSync(String? tenantId, {String? authToken}) async {}
}

final _mockProfile = UserProfile(
  id: 'user-1',
  email: 'test@example.com',
  memberships: [TenantMembership(tenantId: 'tenant-1', role: 'manager')],
);

/// Config with transfers, losses, freshness enabled.
const _testConfig = BusinessTypeConfig(
  code: 'generaliste',
  name: 'Généraliste',
  defaultFlags: {},
  visibleSections: ['transfers', 'losses', 'freshness'],
  suggestedCategories: [],
  roleLabels: {},
  documentType: 'receipt',
  roleScreenAccess: {
    'manager': [
      'backoffice_restricted',
      'deliveries',
      'losses',
      'transfers',
    ],
  },
  transferLabels: {'sendAction': 'Transfert'},
);

Widget _buildScreen() {
  return ProviderScope(
    overrides: [
      userProfileProvider.overrideWith((ref) => Future.value(_mockProfile)),
      activeTenantProvider.overrideWith((ref) => 'tenant-1'),
      syncServiceProvider.overrideWithValue(_StubSyncService()),
      catalogProvider.overrideWith((ref) => Future.value(<Map<String, dynamic>>[])),
      businessTypeConfigProvider
          .overrideWith((ref) => Future.value(_testConfig)),
      salesStatsProvider.overrideWith((ref) => Future.value(<SalesStat>[])),
      stockAlertsProvider.overrideWith((ref) => Future.value(<Map<String, dynamic>>[])),
      lowStockCountProvider.overrideWith((ref) async => 0),
      urgentBatchCountProvider.overrideWith((ref) async => 0),
      internalRequestsPendingCountProvider('manager')
          .overrideWith((ref) => Future.value(0)),
      unreadNotificationCountProvider.overrideWith((ref) => const Stream<int>.empty()),
    ],
    child: const MaterialApp(home: ProductStockScreen()),
  );
}

void main() {
  group('ProductStockScreen — action chips (pas de TabBar)', () {
    testWidgets('pas de TabBar — les 4 action chips sont présents', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      expect(find.byType(TabBar), findsNothing);
      expect(find.text('Réception'), findsOneWidget);
      expect(find.text('Transfert'), findsOneWidget);
      expect(find.text('Perte'), findsOneWidget);
      expect(find.text('Comptage'), findsOneWidget);
    });

    testWidgets('titre AppBar est "Produits & Stock"', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      expect(find.text('Produits & Stock'), findsOneWidget);
    });

    testWidgets('tap chip "Réception" → DeliveryForm visible', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      await tester.tap(find.text('Réception'));
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('delivery_product_field')), findsOneWidget);
    });

    testWidgets('tap chip "Perte" → LossDeclarationForm visible', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      await tester.tap(find.text('Perte'));
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('loss_product_field')), findsOneWidget);
    });

    testWidgets('tap chip "Transfert" → TransferOutForm visible', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      await tester.tap(find.text('Transfert'));
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      expect(
        find.byKey(const Key('transfer_out_product_field')),
        findsOneWidget,
      );
    });
  });
}
