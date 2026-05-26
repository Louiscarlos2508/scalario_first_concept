import 'dart:async' show runZonedGuarded;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';

import 'l10n/s.dart';
import 'core/design_system/tokens/tokens.dart';
import 'core/vault/auth_storage.dart';
import 'core/vault/cache_cleaner.dart';
import 'core/vault/database.dart';
import 'core/vault/db_encryption.dart';
import 'core/vault/drift_data_source_resolver.dart';
import 'core/vault/local_store.dart';
import 'core/sync/connectivity_listener.dart';
import 'core/sync/sync_api_client.dart';
import 'core/sync/sync_queue_service.dart';
import 'core/theme/scalario_theme.dart';
import 'engine/canvas_registry/scalario_canvas_registry.dart';
import 'engine/canvas_registry/registry_bootstrap.dart';
import 'engine/canvas/scalario_canvas_module.dart';
import 'engine/canvas_layout/scalario_canvas_layout.dart';
import 'engine/error_boundary/global_error_handler.dart';
import 'sandbox/sandbox_screen.dart';
import 'features/modules/catalog_screen.dart';

const kSandboxRouteName = '/dev/sandbox';
final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      GlobalErrorHandler.install(navigatorKey: _navigatorKey);
      await _setupDependencies();
      runApp(const ScalarioApp());
    },
    GlobalErrorHandler.handleZoneError,
  );
}

Future<void> _setupDependencies() async {
  final registry = ScalarioCanvasRegistry();
  GetIt.I.registerSingleton<ScalarioCanvasRegistry>(registry);
  RegistryBootstrap.registerPhase1(registry);
  GetIt.I.registerSingleton<ScalarioCanvasLayout>(ScalarioCanvasLayout(registry: registry));

  final authStorage = AuthStorage();
  GetIt.I.registerSingleton<AuthStorage>(authStorage);
  final db = ScalarioDatabase(executor: await DbEncryption(authStorage).openEncrypted());
  final store = LocalStore(db);
  GetIt.I.registerSingleton<LocalStore>(store);

  GetIt.I.registerSingleton(CacheCleaner(
    tenantConfigDao: store.tenantConfigDao, cachedLayoutDao: store.cachedLayoutDao, localDataDao: store.localDataDao));
  GetIt.I.registerSingleton(ConnectivityListener());
  GetIt.I.registerSingleton(SyncQueueService(queueDao: store.syncQueueDao, localDataDao: store.localDataDao));
  GetIt.I.registerSingleton(SyncApiClient(
    baseUrl: const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000'),
    tokenProvider: () => authStorage.readAccessToken()));

  await ScalarioCanvasModule.register(GetIt.I, dataResolver: DriftDataSourceResolver(layoutDao: store.cachedLayoutDao));
}

class ScalarioApp extends StatelessWidget {
  const ScalarioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scalario',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: ScalarioTheme.light(),
      darkTheme: ScalarioTheme.dark(),
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr', 'BF'), Locale('en', 'US')],
      locale: const Locale('fr', 'BF'),
      home: const CatalogScreen(jsonAssetPath: 'assets/catalog/modules/gestion/retail_fresh_produce.json'),
      routes: { if (kDebugMode) kSandboxRouteName: (_) => const SandboxScreen() },
    );
  }
}
