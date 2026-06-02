import 'dart:async' show runZonedGuarded;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';

import 'l10n/s.dart';
import 'core/theme/scalario_theme.dart';
import 'engine/canvas/scalario_canvas_module.dart';
import 'engine/canvas_registry/scalario_canvas_registry.dart';
import 'engine/canvas_registry/registry_bootstrap.dart';
import 'engine/error_boundary/global_error_handler.dart';
import 'sandbox/sandbox_screen.dart';
import 'app/app_shell.dart';

const _appMode = String.fromEnvironment('APP_MODE', defaultValue: 'sandbox');

void main() {
  runZonedGuarded<void>(
    () async {
      try {
        WidgetsFlutterBinding.ensureInitialized();
        GlobalErrorHandler.install();
        final registry = ScalarioCanvasRegistry();
        GetIt.I.registerSingleton<ScalarioCanvasRegistry>(registry);
        RegistryBootstrap.registerPhase1(registry);
        RegistryBootstrap.registerAliases(registry);
        ScalarioCanvasRegistry.instance = registry;

        if (_appMode == 'app') {
          await ScalarioCanvasModule.register(GetIt.I);
        }

        runApp(const ScalarioApp());
      } catch (e, s) {
        print('FATAL INIT ERROR: $e');
        print('STACK: $s');
      }
    },
    (e, s) => print('ZONE: $e'),
  );
}

class ScalarioApp extends StatefulWidget {
  const ScalarioApp({super.key});

  @override
  State<ScalarioApp> createState() => _ScalarioAppState();
}

class _ScalarioAppState extends State<ScalarioApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scalario',
      debugShowCheckedModeBanner: false,
      theme: ScalarioTheme.light(),
      darkTheme: ScalarioTheme.light(),
      themeMode: ThemeMode.light,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr', 'BF'), Locale('en', 'US')],
      locale: const Locale('fr', 'BF'),
      home: _appMode == 'app' ? const AppShell() : const SandboxScreen(),
    );
  }
}
