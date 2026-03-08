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
import 'package:frontend/features/pos/data/models/customer.dart';
import 'package:frontend/features/pos/data/models/category.dart';
import 'package:frontend/core/models/sync_metadata.dart';
import 'package:frontend/core/services/isar_service.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'package:frontend/features/pos/data/repositories/customer_repository.dart';
import 'package:frontend/features/pos/data/repositories/category_repository.dart';

import 'package:frontend/core/models/sync_ui_status.dart';

class SyncService {
  Isolate? _isolate;
  ReceivePort? _receivePort;
  SendPort? _sendPort;
  bool _isStarting = false;

  // Local NestJS backend URL
  static const String _baseUrl = 'http://127.0.0.1:3000';

  final _statusController = StreamController<SyncUiStatus>.broadcast();
  Stream<SyncUiStatus> get statusStream => _statusController.stream;

  // ... (constructor and fields)

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
          baseUrl: _baseUrl,
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

      print(
        '[SyncManager] Background sync isolate started with tenantId: $tenantId',
      );
    } finally {
      _isStarting = false;
    }
  }

  // ... (stopSync, forceSync)

  // --- Isolate Entry Point ---

  static void _syncIsolateEntryPoint(_SyncIsolateConfig config) async {
    final receivePort = ReceivePort();
    final sendPort = config.receivePort;
    sendPort.send(receivePort.sendPort);

    // Initialize Services in Isolate
    final isarService = IsarServiceForIsolate(config.directoryPath);
    final orderRepo = OrderRepository(isarService);
    final productRepo = ProductRepository(isarService);
    final sessionRepo = SessionRepository(isarService);
    final customerRepo = CustomerRepository(isarService);
    final categoryRepo = CategoryRepository(isarService);

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
        await _performSyncInIsolate(
          orderRepo,
          productRepo,
          sessionRepo,
          customerRepo,
          categoryRepo,
          config.baseUrl,
          config.tenantId,
        );
        retryCount = 0; // Reset on success
        notifyStatus(SyncUiStatus.connected);
        print('[SyncIsolate] Sync pass completed successfully.');
      } catch (e) {
        retryCount++;
        notifyStatus(SyncUiStatus.error);
        print('[SyncIsolate] Sync failed (retry $retryCount): $e');
      }

      // Reschedule next sync with exponential backoff
      final delaySeconds =
          (baseDelay.inSeconds * (1 << (retryCount > 6 ? 6 : retryCount)));
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

  // ... (rest of the file)

  static Future<void> _performSyncInIsolate(
    OrderRepository orderRepo,
    ProductRepository productRepo,
    SessionRepository sessionRepo,
    CustomerRepository customerRepo,
    CategoryRepository categoryRepo,
    String baseUrl,
    String? tenantId,
  ) async {
    await _sendHeartbeat(baseUrl); // Call heartbeat
    await _pushSessions(sessionRepo, baseUrl);
    await _pushPendingOrders(orderRepo, baseUrl);
    await _pushPendingCustomers(customerRepo, baseUrl);

    // Delta Pull for products
    final lastProductSync = await sessionRepo.getLastSync('products');
    await _pullProducts(
      productRepo,
      sessionRepo,
      baseUrl,
      lastProductSync,
      tenantId,
    );

    if (tenantId != null) {
      // Delta Pull for customers
      final lastCustomerSync = await sessionRepo.getLastSync('customers');
      await _pullCustomers(
        customerRepo,
        sessionRepo,
        baseUrl,
        lastCustomerSync,
        tenantId,
      );

      // Pull Categories (Full Pull usually fine as list is small)
      await _pullCategories(categoryRepo, tenantId, baseUrl);
    }
  }

  static Future<void> _sendHeartbeat(String baseUrl) async {
    try {
      await http
          .post(
            Uri.parse('$baseUrl/pos/heartbeat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'deviceId':
                  'terminal_linux_1', // In a real app, this would be a persistent ID
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

  static Future<void> _pushPendingOrders(
    OrderRepository orderRepo,
    String baseUrl,
  ) async {
    final pendingOrders = await orderRepo.getPendingOrders();
    if (pendingOrders.isEmpty) return;

    for (final order in pendingOrders) {
      if (order.uuid.isEmpty ||
          order.sessionId == null ||
          order.sessionId!.isEmpty) {
        continue;
      }
      final response = await http
          .post(
            Uri.parse('$baseUrl/pos/orders'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(order.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        await orderRepo.markAsSynced(order.uuid);
      }
    }
  }

  static Future<void> _pushPendingCustomers(
    CustomerRepository customerRepo,
    String baseUrl,
  ) async {
    final pendingCustomers = await customerRepo.getPendingCustomers();
    if (pendingCustomers.isEmpty) return;
    print(
      '[SyncIsolate] Found ${pendingCustomers.length} pending customers to push.',
    );

    for (final customer in pendingCustomers) {
      // We need to know the tenantId. Ideally, it's stored on the customer or session.
      // For now, if tenantId is missing on customer, we might skip or fail.
      // Assuming Customer model has tenantId.
      if (customer.tenantId == null || customer.tenantId!.isEmpty) continue;

      final response = await http
          .post(
            Uri.parse('$baseUrl/pos/customers'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'tenantId': customer.tenantId, // backend expects this wrapper
              'data': customer.toJson(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final remoteId = data['id'];
        await customerRepo.markAsSynced(customer.uuid, remoteId);
      }
    }
  }

  static Future<void> _pushSessions(
    SessionRepository sessionRepo,
    String baseUrl,
  ) async {
    final pendingSessions = await sessionRepo.getPendingSessions();
    if (pendingSessions.isEmpty) return;

    for (final session in pendingSessions) {
      if (session.uuid.isEmpty ||
          session.userId.isEmpty ||
          session.tenantId.isEmpty) {
        continue;
      }
      final response = await http
          .post(
            Uri.parse('$baseUrl/pos/sessions'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(session.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await sessionRepo.markAsSynced(session.id, data['id'] ?? session.uuid);
      }
    }
  }

  static Future<void> _pullProducts(
    ProductRepository productRepo,
    SessionRepository sessionRepo,
    String baseUrl,
    DateTime? lastSync,
    String? tenantId,
  ) async {
    final now = DateTime.now();
    final since = lastSync?.toUtc().toIso8601String() ?? '';
    String url =
        '$baseUrl/pos/products?limit=10000${since.isNotEmpty ? '&since=$since' : ''}';
    if (tenantId != null) {
      url += '&tenantId=$tenantId';
    }

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> items = data['items'];
        final List<Product> products = items
            .map((json) => Product.fromJson(json))
            .toList();

        if (products.isNotEmpty) {
          await productRepo.upsertProducts(products);
          print('[SyncIsolate] Upserted ${products.length} products');
        }

        // Update last sync time
        await sessionRepo.updateLastSync('products', now);
      }
    } catch (e) {
      print('[SyncIsolate] Product pull failed: $e');
      rethrow;
    }
  }

  static Future<void> _pullCustomers(
    CustomerRepository customerRepo,
    SessionRepository sessionRepo,
    String baseUrl,
    DateTime? lastSync,
    String tenantId,
  ) async {
    final now = DateTime.now();
    final since = lastSync?.toUtc().toIso8601String() ?? '';
    final url =
        '$baseUrl/pos/customers?tenantId=$tenantId${since.isNotEmpty ? '&since=$since' : ''}';

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<Customer> customers = data
            .map((json) => Customer.fromJson(json))
            .toList();

        if (customers.isNotEmpty) {
          await customerRepo.upsertCustomers(customers);
          print('[SyncIsolate] Upserted ${customers.length} customers');
        }

        await sessionRepo.updateLastSync('customers', now);
      }
    } catch (e) {
      print('[SyncIsolate] Customer pull failed: $e');
      rethrow;
    }
  }

  static Future<void> _pullCategories(
    CategoryRepository categoryRepo,
    String tenantId,
    String baseUrl,
  ) async {
    try {
      final url = '$baseUrl/pos/categories?tenantId=$tenantId';
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<Category> categories = data
            .map((json) => Category.fromJson(json))
            .toList();

        if (categories.isNotEmpty) {
          await categoryRepo.upsertCategories(categories);
          print('[SyncIsolate] Upserted ${categories.length} categories');
        }
      }
    } catch (e) {
      print('[SyncIsolate] Category pull failed: $e');
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

// Special IsarService variant for the Isolate that doesn't use path_provider (unavailable in background)
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
