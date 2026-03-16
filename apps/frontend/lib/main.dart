import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/auth/auth_state.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/retail/dashboard/presentation/screens/dashboard_screen.dart';

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

class ScalarioApp extends ConsumerWidget {
  const ScalarioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    // Initialize Realtime & Barcode Services (pas de dépendance au tenantId)
    try {
      ref.watch(realtimeServiceProvider).init();
      ref.watch(barcodeScannerServiceProvider).init();
      // Purge old synced data on app start — fire-and-forget (60-day retention).
      ref.read(retentionServiceProvider).purgeOldData();
    } catch (e) {
      print('[Main] Error initializing services: $e');
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
        print('[Main] Error starting sync: $e');
      }
    }

    return MaterialApp(
      title: 'Scalario',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: authState.when(
        data: (state) {
          if (state.session != null) {
            final userProfileAsync = ref.watch(userProfileProvider);

            return userProfileAsync.when(
              data: (profile) {
                if (profile?.role == 'cashier') {
                  return const PosScreen();
                }
                // Default to Dashboard for other roles (admin, owner, etc.)
                return const DashboardScreen();
              },
              loading: () => const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
              error: (e, s) => Scaffold(
                body: Center(child: Text('Error loading profile: $e')),
              ),
            );
          }
          return const LoginScreen();
        },
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, __) => const LoginScreen(),
      ),
    );
  }
}
