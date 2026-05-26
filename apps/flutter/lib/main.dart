// Scalario — entrée Flutter.
//
// STORY-002 : `MaterialApp` consomme `ScalarioTheme.light()` /
// `ScalarioTheme.dark()` avec `ThemeMode.system` (l'OS décide). Le thème est
// entièrement construit depuis les tokens (STORY-001) ; aucun override local.
//
// STORY-005 : RegistryBootstrap.registerPhase1 est appelé avant runApp ;
// le singleton ScalarioCanvasRegistry est disponible via GetIt tout au long de
// la session. L'ordre est critique : DI d'abord, UI ensuite.
//
// STORY-010 : GlobalErrorHandler.install() est appelé avant runApp, et
// runApp est enveloppé dans runZonedGuarded pour capturer les erreurs async
// non-attrapées (niveau 3 de la stratégie 3-niveaux).
//
// STORY-033 : Drift + SQLCipher initialisé avant le ScalarioCanvas.
// `DriftDataSourceResolver` remplace `FixtureDataSourceResolver`
// au DI bootstrap pour lecture offline-first des layouts.

import 'dart:async' show runZonedGuarded;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';

import 'l10n/s.dart';
import 'components/components.dart';
import 'core/design_system/tokens/tokens.dart';
import 'engine/canvas_registry/component_config.dart';
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
import 'core/theme/theme_extensions.dart';
import 'engine/canvas/scalario_canvas_module.dart';
import 'engine/canvas_registry/scalario_canvas_registry.dart';
import 'engine/canvas_registry/registry_bootstrap.dart';
import 'engine/error_boundary/global_error_handler.dart';
import 'engine/canvas_layout/scalario_canvas_layout.dart';
import 'sandbox/sandbox_screen.dart';

/// Shared navigator key — allows [GlobalErrorHandler] to show SnackBars from
/// anywhere in the app without a BuildContext (AC-10).
final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      GlobalErrorHandler.install(navigatorKey: _navigatorKey);
      await _setupDependencies();
      runApp(ScalarioApp(navigatorKey: _navigatorKey));
    },
    GlobalErrorHandler.handleZoneError,
  );
}

Future<void> _setupDependencies() async {
  final ScalarioCanvasRegistry registry = ScalarioCanvasRegistry();
  GetIt.I.registerSingleton<ScalarioCanvasRegistry>(registry);
  RegistryBootstrap.registerPhase1(registry);

  // STORY-007 — ScalarioCanvasLayout singleton, injecté avec le registry Phase 1.
  GetIt.I.registerSingleton<ScalarioCanvasLayout>(ScalarioCanvasLayout(registry: registry));

  // STORY-033 — Persistance offline-first avec Drift + SQLCipher.
  // L'ordre est critique : la DB doit être ouverte AVANT le ScalarioCanvas
  // pour que le DriftDataSourceResolver soit prêt.
  final AuthStorage authStorage = AuthStorage();
  GetIt.I.registerSingleton<AuthStorage>(authStorage);

  final ScalarioDatabase db = ScalarioDatabase(
    executor: await DbEncryption(authStorage).openEncrypted(),
  );

  final LocalStore store = LocalStore(db);
  GetIt.I.registerSingleton<LocalStore>(store);

  final DriftDataSourceResolver driftResolver = DriftDataSourceResolver(
    layoutDao: store.cachedLayoutDao,
  );

  final CacheCleaner cleaner = CacheCleaner(
    tenantConfigDao: store.tenantConfigDao,
    cachedLayoutDao: store.cachedLayoutDao,
    localDataDao: store.localDataDao,
  );
  GetIt.I.registerSingleton<CacheCleaner>(cleaner);

  // STORY-034 — Sync Queue worker dependencies.
  GetIt.I.registerSingleton<ConnectivityListener>(ConnectivityListener());

  GetIt.I.registerSingleton<SyncQueueService>(
    SyncQueueService(
      queueDao: store.syncQueueDao,
      localDataDao: store.localDataDao,
    ),
  );

  GetIt.I.registerSingleton<SyncApiClient>(
    SyncApiClient(
      baseUrl: const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000'),
      tokenProvider: () => authStorage.readAccessToken(),
    ),
  );

  // STORY-008 — ScalarioCanvas orchestrateur (consomme registry + layoutResolver).
  // STORY-026 — appelle BduiValidator.init() en interne pour charger les schémas.
  // STORY-033 — DriftDataSourceResolver remplace FixtureDataSourceResolver.
  await ScalarioCanvasModule.register(
    GetIt.I,
    dataResolver: driftResolver,
  );
}

class ScalarioApp extends StatelessWidget {
  const ScalarioApp({super.key, this.navigatorKey});

  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scalario',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ScalarioTheme.light(),
      darkTheme: ScalarioTheme.dark(),
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'BF'),
        Locale('en', 'US'),
      ],
      locale: const Locale('fr', 'BF'),
      home: const _DashboardPage(),
      // STORY-009 — la route sandbox dev-only est enregistrée **uniquement**
      // en `kDebugMode`. En release build, naviguer vers `/dev/sandbox`
      // n'expose aucune route (test couvert dans sandbox_release_exclusion_test).
      routes: <String, WidgetBuilder>{
        if (kDebugMode) kSandboxRouteName: (BuildContext _) => const SandboxScreen(),
      },
    );
  }
}

/// Page de smoke-test du thème — affiche un échantillon des composants M3
/// pour valider visuellement le wiring tokens → ThemeData.
class _DashboardPage extends StatelessWidget {
  const _DashboardPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scalario — Blandine Shop'),
        actions: <Widget>[
          if (kDebugMode)
            IconButton(
              key: const Key('home.openSandbox'),
              tooltip: 'BDUI Sandbox (dev)',
              icon: const Icon(Icons.science_outlined),
              onPressed: () =>
                  Navigator.of(context).pushNamed(kSandboxRouteName),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ScalarioSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const AlertBanner(type: AlertType.warning, message: '3 produits sous le seuil d\'alerte stock'),
            const SizedBox(height: ScalarioSpacing.space3),
            Text('KPIs', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: ScalarioSpacing.space2),
            Wrap(
              spacing: ScalarioSpacing.space2,
              runSpacing: ScalarioSpacing.space2,
              children: const [
                SizedBox(width: 180, child: KPICard(label: 'CA du jour', value: '142 500', unit: 'FCFA')),
                SizedBox(width: 180, child: KPICard(label: 'Nb ventes', value: '47')),
                SizedBox(width: 180, child: KPICard(label: 'Alertes stock', value: '3', status: KpiStatus.warning)),
                SizedBox(width: 180, child: KPICard(label: 'Pertes jour', value: '12 000', unit: 'FCFA', status: KpiStatus.critical)),
              ],
            ),
            const SizedBox(height: ScalarioSpacing.space4),
            Text('Tendance des ventes (7j)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: ScalarioSpacing.space2),
            SizedBox(
              height: 150,
              child: ChartBar(
                title: 'Ventes',
                data: [
                  ChartDataPoint(label: 'Lun', value: 32),
                  ChartDataPoint(label: 'Mar', value: 45),
                  ChartDataPoint(label: 'Mer', value: 38),
                  ChartDataPoint(label: 'Jeu', value: 55),
                  ChartDataPoint(label: 'Ven', value: 62),
                  ChartDataPoint(label: 'Sam', value: 47),
                  ChartDataPoint(label: 'Dim', value: 28),
                ],
              ),
            ),
            const SizedBox(height: ScalarioSpacing.space4),
            Text('Dernieres ventes', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: ScalarioSpacing.space2),
            ScalarioDataTable<Map<String, String>>(
              columns: [
                DataColumnConfig(key: 'produit', label: 'Produit', cellBuilder: (row) => row['produit']!),
                DataColumnConfig(key: 'qte', label: 'Qte', cellBuilder: (row) => row['qte']!),
                DataColumnConfig(key: 'prix', label: 'Prix', cellBuilder: (row) => row['prix']!),
                DataColumnConfig(key: 'heure', label: 'Heure', cellBuilder: (row) => row['heure']!),
              ],
              rows: const [
                {'produit': 'Tomates', 'qte': '5kg', 'prix': '2 500 F', 'heure': '14:32'},
                {'produit': 'Oignons', 'qte': '3kg', 'prix': '1 200 F', 'heure': '13:45'},
                {'produit': 'Riz 5kg', 'qte': '2', 'prix': '7 000 F', 'heure': '12:10'},
                {'produit': 'Huile 1L', 'qte': '1', 'prix': '1 800 F', 'heure': '11:30'},
                {'produit': 'Bananes', 'qte': '2kg', 'prix': '800 F', 'heure': '10:15'},
              ],
              defaultSortKey: 'heure',
            ),
            const SizedBox(height: ScalarioSpacing.space4),
            Wrap(
              spacing: ScalarioSpacing.space2,
              runSpacing: ScalarioSpacing.space2,
              children: [
                StatCard.fromConfig(
                  const ComponentConfig(type: 'StatCard', variant: 'trend-up', props: {'label': 'Marge', 'value': '22 430', 'delta': '+8% vs hier'}),
                  context,
                ),
                StatCard.fromConfig(
                  const ComponentConfig(type: 'StatCard', variant: 'trend-down', props: {'label': 'Retours', 'value': '3 200', 'delta': '-2 vs hier'}),
                  context,
                ),
              ],
            ),
            const SizedBox(height: ScalarioSpacing.space4),
            SyncStatusBar.fromConfig(
              const ComponentConfig(type: 'SyncStatusBar', variant: 'synced', props: {}),
              context,
            ),
          ],
        ),
      ),
    );
  }
}
