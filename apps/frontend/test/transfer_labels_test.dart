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
import 'package:frontend/features/shared/inventory/data/repositories/inventory_repository.dart';
import 'package:frontend/features/shared/inventory/presentation/widgets/action_chips_row.dart';
import 'package:frontend/features/shared/inventory/presentation/widgets/transfer_out_form.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// ─── Stub SyncService ─────────────────────────────────────────────────────────

class _StubSyncService extends SyncService {
  final _ctrl = StreamController<SyncUiStatus>.broadcast();
  @override
  Stream<SyncUiStatus> get statusStream => _ctrl.stream;
  @override
  Future<void> startSync(String? tenantId, {String? authToken}) async {}
}

// ─── Configs ──────────────────────────────────────────────────────────────────

const _epicerieConfig = BusinessTypeConfig(
  code: 'epicerie',
  name: 'Épicerie',
  defaultFlags: {},
  visibleSections: ['transfers'],
  suggestedCategories: [],
  transferLabels: {
    'sendAction': 'Envoi magasin → rayon',
    'sendButton': 'Envoyer au rayon',
    'confirmAction': 'Réception rayon',
    'confirmButton': 'Confirmer la réception au rayon',
    'fromLabel': 'Magasin',
    'toLabel': 'Rayon',
  },
);

const _stationConfig = BusinessTypeConfig(
  code: 'station',
  name: 'Station',
  defaultFlags: {},
  visibleSections: ['transfers'],
  suggestedCategories: [],
  transferLabels: {
    'sendAction': 'Approvisionnement pompe',
    'sendButton': 'Approvisionner',
    'confirmAction': 'Réception pompe',
    'confirmButton': 'Confirmer l\'approvisionnement',
    'fromLabel': 'Citerne',
    'toLabel': 'Pompe',
  },
);

const _generalisteConfig = BusinessTypeConfig(
  code: 'generaliste',
  name: 'Généraliste',
  defaultFlags: {},
  visibleSections: [], // pas de 'transfers'
  suggestedCategories: [],
);

// ─── Helpers ──────────────────────────────────────────────────────────────────

final _mockProfile = UserProfile(
  id: 'user-1',
  email: 'test@example.com',
  memberships: [TenantMembership(tenantId: 'tenant-1', role: 'manager')],
);

InventoryRepository _mockRepo() => InventoryRepository(
      httpClient: MockClient((_) async => http.Response('{}', 200)),
    );

Widget _buildChipsRow(BusinessTypeConfig config) {
  return ProviderScope(
    overrides: [
      userProfileProvider.overrideWith((ref) => Future.value(_mockProfile)),
      activeTenantProvider.overrideWith((ref) => 'tenant-1'),
      syncServiceProvider.overrideWithValue(_StubSyncService()),
      inventoryRepositoryProvider.overrideWithValue(_mockRepo()),
      businessTypeConfigProvider
          .overrideWith((ref) => Future.value(config)),
    ],
    child: const MaterialApp(
      home: Scaffold(body: StockActionChipsRow()),
    ),
  );
}

Widget _buildTransferForm(BusinessTypeConfig config) {
  return ProviderScope(
    overrides: [
      userProfileProvider.overrideWith((ref) => Future.value(_mockProfile)),
      activeTenantProvider.overrideWith((ref) => 'tenant-1'),
      syncServiceProvider.overrideWithValue(_StubSyncService()),
      paginatedProductListProvider.overrideWith(
        (ref) => Future.value({'items': [], 'total': 0, 'totalPages': 1}),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: TransferOutForm(repository: _mockRepo(), config: config),
      ),
    ),
  );
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('transferLabels — chip adaptatif', () {
    testWidgets('config épicerie → chip label = sendAction épicerie',
        (tester) async {
      await tester.pumpWidget(_buildChipsRow(_epicerieConfig));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Envoi magasin → rayon'), findsOneWidget);
    });

    testWidgets('config station → chip label = sendAction station',
        (tester) async {
      await tester.pumpWidget(_buildChipsRow(_stationConfig));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Approvisionnement pompe'), findsOneWidget);
    });

    testWidgets(
        'config généraliste (pas de transfers) → chip Transfert absent',
        (tester) async {
      await tester.pumpWidget(_buildChipsRow(_generalisteConfig));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Aucun des chips de transfert ne doit apparaître
      expect(find.text('Envoi de stock'), findsNothing);
      expect(find.text('Envoi magasin → rayon'), findsNothing);
      expect(find.text('Approvisionnement pompe'), findsNothing);
    });
  });

  group('transferLabels — TransferOutForm adaptatif', () {
    testWidgets('config épicerie → fromLabel=Magasin, toLabel=Rayon, bouton=Envoyer au rayon',
        (tester) async {
      await tester.pumpWidget(_buildTransferForm(_epicerieConfig));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Champ source
      expect(find.byKey(const Key('transfer_from_field')), findsOneWidget);
      expect(find.text('Magasin'), findsWidgets);

      // Champ destination
      expect(find.text('Rayon'), findsWidgets);

      // Bouton submit
      final btn = tester.widget<ElevatedButton>(
        find.byKey(const Key('transfer_out_submit_button')),
      );
      final label = (btn.child as Text).data;
      expect(label, equals('Envoyer au rayon'));
    });

    testWidgets('config station → fromLabel=Citerne, toLabel=Pompe, bouton=Approvisionner',
        (tester) async {
      await tester.pumpWidget(_buildTransferForm(_stationConfig));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Champ source
      expect(find.byKey(const Key('transfer_from_field')), findsOneWidget);
      expect(find.text('Citerne'), findsWidgets);

      // Champ destination
      expect(find.text('Pompe'), findsWidgets);

      // Bouton submit
      final btn = tester.widget<ElevatedButton>(
        find.byKey(const Key('transfer_out_submit_button')),
      );
      final label = (btn.child as Text).data;
      expect(label, equals('Approvisionner'));
    });

    testWidgets('fallback config → labels génériques, aucun crash',
        (tester) async {
      await tester.pumpWidget(
        _buildTransferForm(BusinessTypeConfig.fallback),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const Key('transfer_from_field')), findsOneWidget);
      expect(find.byKey(const Key('transfer_out_submit_button')), findsOneWidget);

      // Labels de fallback
      expect(find.text('Magasin'), findsWidgets);
      expect(find.text('Emplacement'), findsWidgets);

      final btn = tester.widget<ElevatedButton>(
        find.byKey(const Key('transfer_out_submit_button')),
      );
      final label = (btn.child as Text).data;
      expect(label, equals('Envoyer'));
    });
  });
}
