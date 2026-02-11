import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:http/http.dart' as http;
import 'package:frontend/features/pos/data/repositories/order_repository.dart';
import 'package:frontend/features/pos/data/repositories/product_repository.dart';
import 'package:frontend/features/pos/data/repositories/session_repository.dart';
import 'package:frontend/features/pos/data/models/product.dart';
import 'package:frontend/features/pos/data/models/order.dart';
import 'package:frontend/features/pos/data/models/pos_session.dart';
import 'package:frontend/features/pos/data/models/parked_cart.dart';
import 'package:frontend/core/services/isar_service.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

class SyncService {
  Isolate? _isolate;
  ReceivePort? _receivePort;
  SendPort? _sendPort;
  bool _isStarting = false;

  // Local NestJS backend URL
  static const String _baseUrl = 'http://127.0.0.1:3000';

  SyncService(OrderRepository orderRepository, ProductRepository productRepository, SessionRepository sessionRepository);

  Future<void> startSync() async {
    if (_isolate != null || _isStarting) return;
    _isStarting = true;

    try {
      _receivePort?.close();
      final dir = await getApplicationDocumentsDirectory();
    _receivePort = ReceivePort();
    
    _isolate = await Isolate.spawn(
      _syncIsolateEntryPoint,
      _SyncIsolateConfig(
        directoryPath: dir.path,
        receivePort: _receivePort!.sendPort,
        baseUrl: _baseUrl,
      ),
    );

    _receivePort!.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
      } else {
        print('[SyncManager] Message from isolate: $message');
      }
    });

    print('[SyncManager] Background sync isolate started.');
    } finally {
      _isStarting = false;
    }
  }

  void stopSync() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _receivePort?.close();
    _receivePort = null;
    print('[SyncManager] Background sync isolate stopped.');
  }

  Future<void> forceSync() async {
    _sendPort?.send('sync_now');
  }

  // --- Isolate Entry Point ---

  static void _syncIsolateEntryPoint(_SyncIsolateConfig config) async {
    final receivePort = ReceivePort();
    config.receivePort.send(receivePort.sendPort);

    // Initialize Services in Isolate
    final isarService = IsarServiceForIsolate(config.directoryPath);
    final orderRepo = OrderRepository(isarService);
    final productRepo = ProductRepository(isarService);
    final sessionRepo = SessionRepository(isarService);

    int retryCount = 0;
    const baseDelay = Duration(seconds: 30);
    const maxDelay = Duration(minutes: 5);

    print('[SyncIsolate] Worker initialized.');

    Timer? periodicTimer;

    void runSyncPass() async {
      try {
        print('[SyncIsolate] Starting sync pass...');
        await _performSyncInIsolate(orderRepo, productRepo, sessionRepo, config.baseUrl);
        retryCount = 0; // Reset on success
        print('[SyncIsolate] Sync pass completed successfully.');
      } catch (e) {
        retryCount++;
        print('[SyncIsolate] Sync failed (retry $retryCount): $e');
      }
      
      // Reschedule next sync with exponential backoff
      final delaySeconds = (baseDelay.inSeconds * (1 << (retryCount > 6 ? 6 : retryCount)));
      Duration nextDelay = Duration(seconds: delaySeconds);
      if (nextDelay < baseDelay) nextDelay = baseDelay;
      if (nextDelay > maxDelay) nextDelay = maxDelay;
      
      periodicTimer?.cancel();
      periodicTimer = Timer(nextDelay, runSyncPass);
      print('[SyncIsolate] Next sync scheduled in ${nextDelay.inSeconds}s');
    }

    // Handle signals from main isolate
    receivePort.listen((message) {
      if (message == 'sync_now') {
        runSyncPass();
      }
    });

    // Start the first pass
    runSyncPass();
  }

  static Future<void> _performSyncInIsolate(
    OrderRepository orderRepo,
    ProductRepository productRepo,
    SessionRepository sessionRepo,
    String baseUrl,
  ) async {
    await _sendHeartbeat(baseUrl); // Call heartbeat
    await _pushSessions(sessionRepo, baseUrl);
    await _pushPendingOrders(orderRepo, baseUrl);
    await _pullProducts(productRepo, baseUrl);
  }

  static Future<void> _sendHeartbeat(String baseUrl) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/pos/heartbeat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'deviceId': 'terminal_linux_1', // In a real app, this would be a persistent ID
          'status': 'online',
          'metadata': {
            'platform': 'linux',
            'version': '1.0.0',
          },
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Heartbeat failure shouldn't stop sync
    }
  }

  static Future<void> _pushPendingOrders(OrderRepository orderRepo, String baseUrl) async {
    final pendingOrders = await orderRepo.getPendingOrders();
    if (pendingOrders.isEmpty) return;

    for (final order in pendingOrders) {
      if (order.uuid.isEmpty || order.sessionId == null || order.sessionId!.isEmpty) continue;
      final response = await http.post(
        Uri.parse('$baseUrl/pos/orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(order.toJson()),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        await orderRepo.markAsSynced(order.uuid);
      }
    }
  }

  static Future<void> _pushSessions(SessionRepository sessionRepo, String baseUrl) async {
    final pendingSessions = await sessionRepo.getPendingSessions();
    if (pendingSessions.isEmpty) return;

    for (final session in pendingSessions) {
      if (session.uuid.isEmpty || session.userId.isEmpty || session.tenantId.isEmpty) continue;
      final response = await http.post(
        Uri.parse('$baseUrl/pos/sessions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(session.toJson()),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await sessionRepo.markAsSynced(session.id, data['id'] ?? session.uuid);
      }
    }
  }

  static Future<void> _pullProducts(ProductRepository productRepo, String baseUrl) async {
    // For background sync, we want ALL products, so we use a large limit
    final response = await http.get(Uri.parse('$baseUrl/pos/products?limit=10000'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> items = data['items'];
      final List<Product> products = items.map((json) => Product.fromJson(json)).toList();
      await productRepo.upsertProducts(products);
    }
  }
}

class _SyncIsolateConfig {
  final String directoryPath;
  final SendPort receivePort;
  final String baseUrl;

  _SyncIsolateConfig({
    required this.directoryPath,
    required this.receivePort,
    required this.baseUrl,
  });
}

// Special IsarService variant for the Isolate that doesn't use path_provider (unavailable in background)
class IsarServiceForIsolate extends IsarService {
  final String _path;
  IsarServiceForIsolate(this._path);

  @override
  Future<Isar> initDb() async {
    if (Isar.instanceNames.isEmpty) {
      return await Isar.open(
        [ProductSchema, OrderSchema, PosSessionSchema, ParkedCartSchema],
        directory: _path,
        inspector: false,
      );
    }
    return Future.value(Isar.getInstance());
  }
}
