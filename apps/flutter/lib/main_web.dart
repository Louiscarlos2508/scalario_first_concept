import 'dart:async' show runZonedGuarded;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';

import 'l10n/s.dart';
import 'core/theme/scalario_theme.dart';
import 'engine/canvas_registry/scalario_canvas_registry.dart';
import 'engine/canvas_registry/registry_bootstrap.dart';
import 'engine/canvas_layout/scalario_canvas_layout.dart';
import 'engine/error_boundary/global_error_handler.dart';
import 'sandbox/sandbox_screen.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      GlobalErrorHandler.install();
      final registry = ScalarioCanvasRegistry();
      GetIt.I.registerSingleton<ScalarioCanvasRegistry>(registry);
      RegistryBootstrap.registerPhase1(registry);
      RegistryBootstrap.registerAliases(registry);
      GetIt.I.registerSingleton<ScalarioCanvasLayout>(ScalarioCanvasLayout(registry: registry));
      ScalarioCanvasRegistry.instance = registry;
      runApp(const ScalarioApp());
    },
    (e, s) => debugPrint('Zone error: $e'),
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
      darkTheme: ScalarioTheme.dark(),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr', 'BF'), Locale('en', 'US')],
      locale: const Locale('fr', 'BF'),
      home: const SandboxScreen(),
    );
  }
}
