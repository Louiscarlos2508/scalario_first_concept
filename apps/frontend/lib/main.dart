import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/auth/auth_state.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/retail/backoffice/presentation/screens/dashboard_screen.dart';
import 'features/splash/splash_screen.dart';
import 'features/admin/presentation/screens/admin_dashboard.dart';
import 'features/shared/billing/presentation/providers/subscription_provider.dart';
import 'features/shared/billing/presentation/screens/suspended_screen.dart';

import 'app/sdui_registry_setup.dart';
import 'features/retail/pos/presentation/screens/pos_screen.dart';
import 'features/retail/pos/presentation/providers/pos_providers.dart';
import 'features/shared/business_type/presentation/providers/business_type_config_provider.dart';
import 'features/onboarding/onboarding_wizard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);

  setupSduiRegistry();

  // Initialize Supabase
  const supabaseHost = String.fromEnvironment(
    'SUPABASE_HOST',
    defaultValue: '127.0.0.1:54321',
  );
  const supabaseUrl = 'http://$supabaseHost';
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: String.fromEnvironment('SUPABASE_ANON_KEY',
        defaultValue: 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH'),
  );

  runApp(const ProviderScope(child: ScalarioApp()));
}

List<String> _fallbackScreens(String role) {
  switch (role) {
    case 'owner':
      return ['backoffice', 'pos'];
    case 'manager':
      return ['backoffice_restricted'];
    case 'commercial':
      return ['pos', 'losses', 'transfers', 'stock_view', 'daily_sales'];
    default:
      return ['pos'];
  }
}

class ScalarioApp extends ConsumerStatefulWidget {
  const ScalarioApp({super.key});

  @override
  ConsumerState<ScalarioApp> createState() => _ScalarioAppState();
}

class _ScalarioAppState extends ConsumerState<ScalarioApp> {
  bool _splashDone = false;
  bool? _onboardingDone; // null = not yet checked
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<int>? _authExpiredSubscription;
  // Scale fix — évite un double refreshSession() si le SDK Supabase et le
  // SyncEngine déclenchent simultanément un refresh (race condition).
  bool _isRefreshingToken = false;

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() =>
          _onboardingDone = prefs.getBool(kOnboardingDonePrefKey) ?? false);
    }
  }

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        if (data.event == AuthChangeEvent.tokenRefreshed) {
          final newToken = data.session?.accessToken;
          ref.read(syncServiceProvider).updateToken(newToken);
        }
        if (data.event == AuthChangeEvent.signedIn) _checkOnboarding();
      },
    );

    // Fix 4 — JWT expiré détecté par le SyncEngine : tenter un refresh silencieux.
    // Si Supabase parvient à rafraîchir, onAuthStateChange émet tokenRefreshed
    // → updateToken() reprend le sync automatiquement.
    // Si le refresh échoue, l'utilisateur sera redirigé vers LoginScreen via
    // authStateProvider (session devient null).
    _authExpiredSubscription =
        ref.read(syncServiceProvider).authExpiredStream.listen((statusCode) {
      // Scale fix — guard contre le double refreshSession() :
      // le SDK Supabase peut déjà tenter un refresh automatique en arrière-plan
      // pendant que ce listener en déclenche un second. Les deux appels
      // simultanés peuvent produire un état incohérent sur réseau dégradé.
      if (_isRefreshingToken) return;
      _isRefreshingToken = true;
      debugPrint('[Main] Sync auth expired (HTTP $statusCode) — '
          'triggering silent token refresh');
      () async {
        try {
          await Supabase.instance.client.auth.refreshSession();
        } catch (e) {
          debugPrint('[Main] Silent token refresh failed: $e — '
              'user will be redirected to login');
        } finally {
          _isRefreshingToken = false;
        }
      }();
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _authExpiredSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    // Initialize Realtime & Barcode Services (pas de dépendance au tenantId)
    try {
      ref.watch(realtimeServiceProvider).init();
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

                      // Check billing suspension for tenant users
                      final isSuspended = ref.watch(isSuspendedProvider);
                      if (isSuspended.value == true) {
                        return const SuspendedScreen();
                      }

                      // Onboarding wizard — shown once to owner on first login.
                      if (_onboardingDone == false &&
                          profile?.role == 'owner') {
                        return const OnboardingWizardScreen();
                      }

                      // Config-driven routing: screens determined by roleScreenAccess
                      final role = profile?.role ?? '';
                      final config = ref
                          .watch(businessTypeConfigProvider)
                          .valueOrNull;
                      final screens = config != null
                          ? config.screensForRole(role)
                          : _fallbackScreens(role);
                      if (screens.contains('backoffice') ||
                          screens.contains('backoffice_restricted')) {
                        return const DashboardScreen();
                      }
                      return const PosScreen();
                    },
                    loading: () => const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Scaffold(
                      body: Center(child: Text('Erreur chargement profil : $e')),
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
