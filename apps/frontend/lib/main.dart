import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/auth/auth_state.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';

import 'features/pos/presentation/screens/pos_screen.dart';
import 'features/pos/presentation/providers/pos_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'http://127.0.0.1:54321',
    anonKey: 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH',
  );

  runApp(const ProviderScope(child: ScalarioApp()));
}

class ScalarioApp extends ConsumerWidget {
  const ScalarioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    // Initialize Sync, Realtime & Barcode Services
    try {
      ref.watch(syncServiceProvider).startSync(ref.read(activeTenantProvider));
      ref.watch(realtimeServiceProvider).init();
      ref.watch(barcodeScannerServiceProvider).init();
      // Purge old synced data on app start — fire-and-forget (60-day retention).
      ref.read(retentionServiceProvider).purgeOldData();
    } catch (e) {
      print('[Main] Error initializing services: $e');
    }

    return MaterialApp(
      title: 'Scalario',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
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
