import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/features/pos/data/repositories/order_repository.dart';
import 'package:frontend/features/pos/data/repositories/product_repository.dart';
import 'package:frontend/features/pos/data/repositories/session_repository.dart';
import 'package:frontend/features/pos/data/models/pos_session.dart';
import 'package:frontend/features/pos/data/models/parked_cart.dart';
import 'package:frontend/features/pos/data/models/product.dart';
import 'package:frontend/features/pos/data/models/order.dart';
import 'package:frontend/features/pos/data/models/customer.dart';
import 'package:frontend/features/pos/data/models/category.dart';
import 'package:frontend/core/models/sync_metadata.dart';
import 'package:frontend/core/services/isar_service.dart';
import 'package:frontend/core/services/sync_adapters/catalog_sync_adapter.dart';
import 'package:frontend/core/services/sync_adapters/contact_sync_adapter.dart';
import 'package:frontend/core/services/sync_adapters/transaction_sync_adapter.dart';
import 'package:frontend/core/services/sync_adapters/session_sync_adapter.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'package:frontend/features/pos/data/repositories/customer_repository.dart';
import 'package:frontend/features/pos/data/repositories/category_repository.dart';

import 'package:frontend/core/models/sync_ui_status.dart';
import 'package:frontend/core/constants/api_constants.dart';

class SyncService {
  Isolate? _isolate;
  ReceivePort? _receivePort;
  SendPort? _sendPort;
  bool _isStarting = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  final _statusController = StreamController<SyncUiStatus>.broadcast();
  Stream<SyncUiStatus> get statusStream => _statusController.stream;

  Future<void> startSync(String? tenantId) async {
    if (_isolate != null || _isStarting) return;
    _isStarting = true;
    _statusController.add(SyncUiStatus.disconnected);

    try {
      _receivePort?.close();
      final dir = await getApplicationDocumentsDirectory();
      _receivePort = ReceivePort();

      _isolate = await Isolate.spawn(
        _syncIsolateEntryPoint,
        _SyncIsolateConfig(
          directoryPath: dir.path,
          receivePort: _receivePort!.sendPort,
          baseUrl: ApiConstants.baseUrl,
          tenantId: tenantId,
        ),
      );

      _receivePort!.listen((message) {
        if (message is SendPort) {
          _sendPort = message;
          _statusController.add(SyncUiStatus.connected);
        } else if (message is SyncUiStatus) {
          _statusController.add(message);
        } else {
          print('[SyncManager] Message from isolate: $message');
        }
      });

      // Listen for connectivity changes (push-based complement to exponential backoff).
      // On reconnect → trigger immediate sync cycle; on disconnect → update UI status.
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

  // --- Isolate Entry Point ---

  static void _syncIsolateEntryPoint(_SyncIsolateConfig config) async {
    final receivePort = ReceivePort();
    final sendPort = config.receivePort;
    sendPort.send(receivePort.sendPort);

    // Initialize repositories inside the isolate
    final isarService = IsarServiceForIsolate(config.directoryPath);
    final orderRepo = OrderRepository(isarService);
    final productRepo = ProductRepository(isarService);
    final sessionRepo = SessionRepository(isarService);
    final customerRepo = CustomerRepository(isarService);
    final categoryRepo = CategoryRepository(isarService);

    // Build module-agnostic adapters
    final sessionAdapter = SessionSyncAdapter(sessionRepo: sessionRepo);
    final transactionAdapter =
        TransactionSyncAdapter(orderRepo: orderRepo);
    final contactAdapter = ContactSyncAdapter(
        customerRepo: customerRepo, sessionRepo: sessionRepo);
    final catalogAdapter = CatalogSyncAdapter(
        productRepo: productRepo,
        categoryRepo: categoryRepo,
        sessionRepo: sessionRepo);

    int retryCount = 0;
    const baseDelay = Duration(seconds: 30);
    const maxDelay = Duration(minutes: 5);

    Timer? periodicTimer;

    void notifyStatus(SyncUiStatus status) {
      sendPort.send(status);
    }

    void runSyncPass() async {
      try {
        notifyStatus(SyncUiStatus.syncing);
        print('[SyncIsolate] Starting sync pass...');
        await _performSyncWithAdapters(
          sessionAdapter: sessionAdapter,
          transactionAdapter: transactionAdapter,
          contactAdapter: contactAdapter,
          catalogAdapter: catalogAdapter,
          baseUrl: config.baseUrl,
          tenantId: config.tenantId,
          sessionRepo: sessionRepo,
        );
        retryCount = 0;
        notifyStatus(SyncUiStatus.connected);
        print('[SyncIsolate] Sync pass completed successfully.');
      } catch (e) {
        retryCount++;
        notifyStatus(SyncUiStatus.error);
        print('[SyncIsolate] Sync failed (retry $retryCount): $e');
      }

      // Reschedule with exponential backoff
      final delaySeconds =
          baseDelay.inSeconds * (1 << (retryCount > 6 ? 6 : retryCount));
      Duration nextDelay = Duration(seconds: delaySeconds);
      if (nextDelay < baseDelay) nextDelay = baseDelay;
      if (nextDelay > maxDelay) nextDelay = maxDelay;

      periodicTimer?.cancel();
      periodicTimer = Timer(nextDelay, runSyncPass);
      print('[SyncIsolate] Next sync scheduled in ${nextDelay.inSeconds}s');
    }

    // Handle force-sync signals from main isolate
    receivePort.listen((message) {
      if (message == 'sync_now') {
        runSyncPass();
      }
    });

    // Start the first pass immediately
    runSyncPass();
  }

  /// Orchestrate adapters in the required push ordering:
  /// sessions → transactions → contacts → catalog pull
  static Future<void> _performSyncWithAdapters({
    required SessionSyncAdapter sessionAdapter,
    required TransactionSyncAdapter transactionAdapter,
    required ContactSyncAdapter contactAdapter,
    required CatalogSyncAdapter catalogAdapter,
    required String baseUrl,
    required String? tenantId,
    required SessionRepository sessionRepo,
  }) async {
    await _sendHeartbeat(baseUrl);

    // Push ordering: sessions first (so transactionId→sessionId FK resolves)
    await sessionAdapter.pushPending(baseUrl, tenantId ?? '');
    await transactionAdapter.pushPending(baseUrl, tenantId ?? '');
    await contactAdapter.pushPending(baseUrl, tenantId ?? '');

    // Delta pulls
    final lastProductSync = await sessionRepo.getLastSync('products');
    await catalogAdapter.pullDelta(baseUrl, tenantId ?? '', lastProductSync);

    if (tenantId != null) {
      final lastCustomerSync = await sessionRepo.getLastSync('customers');
      await contactAdapter.pullDelta(baseUrl, tenantId, lastCustomerSync);
    }
  }

  static Future<void> _sendHeartbeat(String baseUrl) async {
    try {
      await http
          .post(
            Uri.parse('$baseUrl/pos/heartbeat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'deviceId': 'terminal_linux_1',
              'status': 'online',
              'metadata': {'platform': 'linux', 'version': '1.0.0'},
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Heartbeat failure shouldn't stop sync
    }
  }
}

class _SyncIsolateConfig {
  final String directoryPath;
  final SendPort receivePort;
  final String baseUrl;
  final String? tenantId;

  _SyncIsolateConfig({
    required this.directoryPath,
    required this.receivePort,
    required this.baseUrl,
    this.tenantId,
  });
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
        ],
        directory: _path,
        inspector: false,
      );
    }
    return Future.value(Isar.getInstance());
  }
}
