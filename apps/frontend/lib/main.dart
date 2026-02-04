import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/auth/auth_state.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  // TODO: Replace with env variables or actual config
  await Supabase.initialize(
    url: 'https://placeholder-url.supabase.co',
    anonKey: 'placeholder-anon-key',
  );

  runApp(
    const ProviderScope(
      child: ScalarioApp(),
    ),
  );
}

class ScalarioApp extends ConsumerWidget {
  const ScalarioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

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
            return const DashboardScreen();
          }
          return const LoginScreen();
        },
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, __) => const LoginScreen(),
      ),
    );
  }
}
