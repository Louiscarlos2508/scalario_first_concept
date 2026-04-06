import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/features/retail/pos/data/repositories/order_repository.dart';
import 'package:frontend/features/retail/pos/data/repositories/product_repository.dart';
import 'package:frontend/features/retail/pos/data/repositories/session_repository.dart';
import 'package:frontend/features/retail/pos/data/models/pos_session.dart';
import 'package:frontend/features/retail/pos/data/models/parked_cart.dart';
import 'package:frontend/features/retail/pos/data/models/product.dart';
import 'package:frontend/features/retail/pos/data/models/order.dart';
import 'package:frontend/features/retail/pos/data/models/customer.dart';
import 'package:frontend/features/retail/pos/data/models/category.dart';
import 'package:frontend/features/shared/inventory/data/repositories/inventory_repository.dart';
import 'package:frontend/features/shared/inventory/data/models/inventory_movement_local.dart';
import 'package:frontend/core/models/sync_metadata.dart';
import 'package:frontend/core/services/isar_service.dart';
import 'package:frontend/core/services/sync_adapters/catalog_sync_adapter.dart';
import 'package:frontend/core/services/sync_adapters/contact_sync_adapter.dart';
import 'package:frontend/core/services/sync_adapters/transaction_sync_adapter.dart';
import 'package:frontend/core/services/sync_adapters/session_sync_adapter.dart';
import 'package:frontend/core/services/sync_adapters/inventory_sync_adapter.dart';
import 'package:frontend/core/services/sync_auth_exception.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'package:frontend/features/retail/pos/data/repositories/customer_repository.dart';
import 'package:frontend/features/retail/pos/data/repositories/category_repository.dart';

import 'package:frontend/core/models/sync_ui_status.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/core/services/device_identity_service.dart';

class SyncService {
  Isolate? _isolate;
  ReceivePort? _receivePort;
  SendPort? _sendPort;
  bool _isStarting = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  final _statusController = StreamController<SyncUiStatus>.broadcast();
  Stream<SyncUiStatus> get statusStream => _statusController.stream;

  /// Fix 4 — Émet le code HTTP (401/403) quand le JWT est expiré.
  /// L'UI peut s'abonner pour afficher un bandeau ou forcer la reconnexion.
  final _authExpiredController = StreamController<int>.broadcast();
  Stream<int> get authExpiredStream => _authExpiredController.stream;

  Future<void> startSync(String? tenantId, {String? authToken}) async {
    if (_isolate != null || _isStarting) return;
    _isStarting = true;
    _statusController.add(SyncUiStatus.disconnected);

    try {
      _receivePort?.close();
      final dir = await getApplicationDocumentsDirectory();
      final deviceId = await DeviceIdentityService().getDeviceId();
      _receivePort = ReceivePort();

      _isolate = await Isolate.spawn(
        _syncIsolateEntryPoint,
        _SyncIsolateConfig(
          directoryPath: dir.path,
          receivePort: _receivePort!.sendPort,
          baseUrl: ApiConstants.baseUrl,
          tenantId: tenantId,
          authToken: authToken,
          deviceId: deviceId,
        ),
      );

      _receivePort!.listen((message) {
        if (message is SendPort) {
          _sendPort = message;
          _statusController.add(SyncUiStatus.connected);
        } else if (message is SyncUiStatus) {
          _statusController.add(message);
        } else if (message is _AuthExpiredEvent) {
          // Fix 4 — JWT expiré : notifier l'UI, le sync est suspendu dans l'isolate.
          _statusController.add(SyncUiStatus.error);
          _authExpiredController.add(message.statusCode);
          print('[SyncManager] Auth expired (HTTP ${message.statusCode}) — '
              'sync suspended until token refresh');
        } else {
          print('[SyncManager] Message from isolate: $message');
        }
      });

      _connectivitySubscription?.cancel();
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
        results,
      ) {
        final isOffline =
            results.isEmpty ||
            results.every((r) => r == ConnectivityResult.none);
        if (isOffline) {
          _statusController.add(SyncUiStatus.disconnected);
        } else {
          forceSync();
        }
      });

      print(
        '[SyncManager] Background sync isolate started with tenantId: $tenantId',
      );
    } finally {
      _isStarting = false;
    }
  }

  void stopSync() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _receivePort?.close();
    _receivePort = null;
    _sendPort = null;
    _statusController.add(SyncUiStatus.disconnected);
  }

  void forceSync() {
    _sendPort?.send('sync_now');
  }

  void updateToken(String? token) {
    _sendPort?.send(_TokenUpdate(token));
  }

  // ---------------------------------------------------------------------------
  // Isolate Entry Point
  // ---------------------------------------------------------------------------

  static void _syncIsolateEntryPoint(_SyncIsolateConfig config) async {
    final receivePort = ReceivePort();
    final sendPort = config.receivePort;
    sendPort.send(receivePort.sendPort);

    final isarService = IsarServiceForIsolate(config.directoryPath);
    final orderRepo = OrderRepository(isarService);
    final productRepo = ProductRepository(isarService);
    final sessionRepo = SessionRepository(isarService);
    final customerRepo = CustomerRepository(isarService);
    final categoryRepo = CategoryRepository(isarService);
    final inventoryRepo = InventoryRepository(isarService: isarService);

    final sessionAdapter = SessionSyncAdapter(sessionRepo: sessionRepo);
    final transactionAdapter = TransactionSyncAdapter(orderRepo: orderRepo);
    final contactAdapter = ContactSyncAdapter(
      customerRepo: customerRepo,
      sessionRepo: sessionRepo,
    );
    final catalogAdapter = CatalogSyncAdapter(
      productRepo: productRepo,
      categoryRepo: categoryRepo,
      sessionRepo: sessionRepo,
    );
    final inventoryAdapter = InventorySyncAdapter(repo: inventoryRepo);

    int retryCount = 0;
    const baseDelay = Duration(seconds: 30);
    const maxDelay = Duration(minutes: 5);
    bool isFirstPass = true;
    String? currentToken = config.authToken;

    // Fix 4 — quand true, le sync est suspendu (JWT expiré).
    // Reprend uniquement quand un _TokenUpdate est reçu.
    bool authSuspended = false;

    // Fix 6 — empêche deux passes concurrentes (ex: sync_now pendant un full pull).
    bool isSyncing = false;

    Timer? periodicTimer;

    void notifyStatus(SyncUiStatus status) {
      sendPort.send(status);
    }

    void runSyncPass() async {
      // Fix 4 — ne pas relancer de pass si l'auth est suspendue.
      // Fix 6 — ignorer si une passe est déjà en cours (évite la double-écriture).
      if (authSuspended || isSyncing) return;
      isSyncing = true;

      bool authExpiredDuringRun = false;
      try {
        notifyStatus(SyncUiStatus.syncing);
        print('[SyncIsolate] Starting sync pass...');
        final hadChanges = await _performSyncWithAdapters(
          sessionAdapter: sessionAdapter,
          transactionAdapter: transactionAdapter,
          contactAdapter: contactAdapter,
          catalogAdapter: catalogAdapter,
          inventoryAdapter: inventoryAdapter,
          baseUrl: config.baseUrl,
          tenantId: config.tenantId,
          authToken: currentToken,
          deviceId: config.deviceId,
          sessionRepo: sessionRepo,
          forceFullCatalogPull: isFirstPass,
        );
        isFirstPass = false;
        retryCount = 0;
        notifyStatus(SyncUiStatus.connected);
        if (hadChanges) {
          print('[SyncIsolate] Sync pass completed successfully.');
        }
      } on SyncAuthException catch (e) {
        // Fix 4 — JWT expiré : suspendre le timer, notifier le thread principal.
        authSuspended = true;
        periodicTimer?.cancel();
        periodicTimer = null;
        sendPort.send(_AuthExpiredEvent(e.statusCode));
        print('[SyncIsolate] Auth expired (${e.statusCode}) — sync suspended');
        authExpiredDuringRun = true;
      } catch (e) {
        retryCount++;
        notifyStatus(SyncUiStatus.error);
        print('[SyncIsolate] Sync failed (retry $retryCount): $e');
      } finally {
        isSyncing = false;
      }

      if (authExpiredDuringRun) return;

      final delaySeconds =
          baseDelay.inSeconds * (1 << (retryCount > 6 ? 6 : retryCount));
      Duration nextDelay = Duration(seconds: delaySeconds);
      if (nextDelay < baseDelay) nextDelay = baseDelay;
      if (nextDelay > maxDelay) nextDelay = maxDelay;

      periodicTimer?.cancel();
      periodicTimer = Timer(nextDelay, runSyncPass);
      print('[SyncIsolate] Next sync scheduled in ${nextDelay.inSeconds}s');
    }

    receivePort.listen((message) async {
      if (message == 'sync_now') {
        periodicTimer?.cancel();
        runSyncPass();
      } else if (message is _TokenUpdate) {
        currentToken = message.token;
        // Fix 4 — token rafraîchi : lever la suspension et relancer.
        authSuspended = false;
        print('[SyncIsolate] Auth token refreshed — resetting error orders');
        await orderRepo.resetErrorOrders();
        runSyncPass();
      }
    });

    runSyncPass();
  }

  static Future<bool> _performSyncWithAdapters({
    required SessionSyncAdapter sessionAdapter,
    required TransactionSyncAdapter transactionAdapter,
    required ContactSyncAdapter contactAdapter,
    required CatalogSyncAdapter catalogAdapter,
    required InventorySyncAdapter inventoryAdapter,
    required String baseUrl,
    required String? tenantId,
    required String? authToken,
    String? deviceId,
    required SessionRepository sessionRepo,
    bool forceFullCatalogPull = false,
  }) async {
    // Fix 5 — heartbeat retourne la version de schéma du serveur.
    final serverSchemaVersion = await _sendHeartbeat(
      baseUrl,
      tenantId: tenantId,
      deviceId: deviceId,
    );

    // Fix 5 — si la version diverge, forcer un re-provisioning complet.
    bool forceFullPull = forceFullCatalogPull;
    if (serverSchemaVersion != null) {
      final localSchemaVersion = await sessionRepo.getSchemaVersion();
      if (serverSchemaVersion != localSchemaVersion) {
        print('[SyncEngine] Schema version mismatch '
            '(local=$localSchemaVersion, server=$serverSchemaVersion) — '
            'forcing full re-provisioning');
        forceFullPull = true;
        await sessionRepo.updateSchemaVersion(serverSchemaVersion);
      }
    }

    bool hadChanges = forceFullPull;

    final pendingInventory = await inventoryAdapter.pendingCount();
    if (pendingInventory > 0) hadChanges = true;

    // Push ordering: sessions first (FK sessionId resolves before transactions)
    await sessionAdapter.pushPending(baseUrl, tenantId ?? '', token: authToken);
    await transactionAdapter.pushPending(
      baseUrl,
      tenantId ?? '',
      token: authToken,
    );
    await contactAdapter.pushPending(baseUrl, tenantId ?? '', token: authToken);
    await inventoryAdapter.pushPending(
      baseUrl,
      tenantId ?? '',
      token: authToken,
    );

    // Delta pulls — forceFullPull force un full replace si schema change.
    final lastProductSync =
        forceFullPull ? null : await sessionRepo.getLastSync('products');
    await catalogAdapter.pullDelta(
      baseUrl,
      tenantId ?? '',
      lastProductSync,
      token: authToken,
    );

    if (tenantId != null) {
      final lastCustomerSync =
          forceFullPull ? null : await sessionRepo.getLastSync('customers');
      await contactAdapter.pullDelta(
        baseUrl,
        tenantId,
        lastCustomerSync,
        token: authToken,
      );
    }

    return hadChanges;
  }

  /// Fix 5 — retourne la version de schéma du serveur lue dans le header
  /// `X-Schema-Version`, ou `null` si le heartbeat échoue / header absent.
  static Future<int?> _sendHeartbeat(
    String baseUrl, {
    String? tenantId,
    String? deviceId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/pos/heartbeat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'deviceId': deviceId ?? 'terminal_unknown',
              'status': 'online',
              'tenantId': ?tenantId,
              'metadata': {'platform': 'linux', 'version': '1.0.0'},
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 5));

      // Fix 5 — lire X-Schema-Version depuis la réponse heartbeat.
      final versionHeader = response.headers['x-schema-version'];
      return versionHeader != null ? int.tryParse(versionHeader) : null;
    } catch (_) {
      // Heartbeat failure ne doit pas bloquer le sync.
      return null;
    }
  }
}

class _SyncIsolateConfig {
  final String directoryPath;
  final SendPort receivePort;
  final String baseUrl;
  final String? tenantId;
  final String? authToken;
  final String? deviceId;

  _SyncIsolateConfig({
    required this.directoryPath,
    required this.receivePort,
    required this.baseUrl,
    this.tenantId,
    this.authToken,
    this.deviceId,
  });
}

class _TokenUpdate {
  final String? token;
  _TokenUpdate(this.token);
}

/// Fix 4 — message isolate → main thread quand le JWT est expiré.
class _AuthExpiredEvent {
  final int statusCode;
  _AuthExpiredEvent(this.statusCode);
}

/// Special IsarService for the isolate — opens DB using pre-resolved directory path
/// (path_provider is unavailable in background isolates).
class IsarServiceForIsolate extends IsarService {
  final String _path;
  IsarServiceForIsolate(this._path);

  @override
  Future<Isar> initDb() async {
    if (Isar.instanceNames.isEmpty) {
      return await Isar.open(
        [
          ProductSchema,
          OrderSchema,
          PosSessionSchema,
          ParkedCartSchema,
          CustomerSchema,
          SyncMetadataSchema,
          CategorySchema,
          InventoryMovementLocalSchema,
        ],
        directory: _path,
        inspector: false,
      );
    }
    return Future.value(Isar.getInstance());
  }
}
