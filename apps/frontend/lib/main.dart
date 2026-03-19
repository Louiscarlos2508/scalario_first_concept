import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/auth/auth_state.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/retail/backoffice/presentation/screens/dashboard_screen.dart';
import 'features/splash/splash_screen.dart';
import 'features/admin/presentation/screens/admin_dashboard.dart';

import 'app/sdui_registry_setup.dart';
import 'features/retail/pos/presentation/screens/pos_screen.dart';
import 'features/retail/pos/presentation/providers/pos_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  setupSduiRegistry();

  // Initialize Supabase
  await Supabase.initialize(
    url: String.fromEnvironment('SUPABASE_URL',
        defaultValue: 'http://127.0.0.1:54321'),
    anonKey: String.fromEnvironment('SUPABASE_ANON_KEY',
        defaultValue: 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH'),
  );

  runApp(const ProviderScope(child: ScalarioApp()));
}

class ScalarioApp extends ConsumerStatefulWidget {
  const ScalarioApp({super.key});

  @override
  ConsumerState<ScalarioApp> createState() => _ScalarioAppState();
}

class _ScalarioAppState extends ConsumerState<ScalarioApp> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    // Initialize Realtime & Barcode Services (pas de dépendance au tenantId)
    try {
      ref.watch(realtimeServiceProvider).init();
      ref.watch(barcodeScannerServiceProvider).init();
      // Purge old synced data on app start — fire-and-forget (60-day retention).
      ref.read(retentionServiceProvider).purgeOldData();
    } catch (e) {
      debugPrint('[Main] Error initializing services: $e');
    }

    // Démarrer le sync seulement quand activeTenantProvider est résolu (non-null).
    // build() est rappelé quand activeTenantProvider change → startSync n'est
    // appelé qu'une fois grâce au guard interne (_isolate != null).
    final tenantId = ref.watch(activeTenantProvider);
    if (tenantId != null) {
      try {
        final token =
            Supabase.instance.client.auth.currentSession?.accessToken;
        ref.read(syncServiceProvider).startSync(tenantId, authToken: token);
      } catch (e) {
        debugPrint('[Main] Error starting sync: $e');
      }
    }

    return MaterialApp(
      title: 'Scalario',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: !_splashDone
          ? SplashScreen(onComplete: () => setState(() => _splashDone = true))
          : authState.when(
              data: (state) {
                if (state.session != null) {
                  final userProfileAsync = ref.watch(userProfileProvider);

                  return userProfileAsync.when(
                    data: (profile) {
                      if (profile?.role == 'superadmin') {
                        return const AdminDashboard();
                      }
                      // POS-only roles — no backoffice access
                      if (profile?.role == 'cashier' ||
                          profile?.role == 'commercial') {
                        return const PosScreen();
                      }
                      return const DashboardScreen();
                    },
                    loading: () => const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Scaffold(
                      body: Center(child: Text('Error loading profile: $e')),
                    ),
                  );
                }
                return const LoginScreen();
              },
              loading: () => const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
              error: (_, e) => const LoginScreen(),
            ),
    );
  }
}
