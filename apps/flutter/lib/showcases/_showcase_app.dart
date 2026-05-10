// Dev-only — utilisé uniquement par les showcases.
// L'app prod (main.dart) ne contient pas de toggle, elle suit l'OS.
import 'package:flutter/material.dart';

import '../core/theme/scalario_theme.dart';

/// Wrapper partagé par tous les showcases Scalario.
///
/// Fournit un `MaterialApp` avec thème Scalario light+dark et un toggle
/// dark/light dans l'AppBar. Ne jamais utiliser en dehors des showcases.
class ScalarioShowcaseApp extends StatefulWidget {
  const ScalarioShowcaseApp({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  State<ScalarioShowcaseApp> createState() => _ScalarioShowcaseAppState();
}

class _ScalarioShowcaseAppState extends State<ScalarioShowcaseApp> {
  ThemeMode _mode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: widget.title,
      debugShowCheckedModeBanner: false,
      theme: ScalarioTheme.light(),
      darkTheme: ScalarioTheme.dark(),
      themeMode: _mode,
      home: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: <Widget>[
            IconButton(
              icon: Icon(
                _mode == ThemeMode.light
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
              ),
              tooltip: 'Toggle thème',
              onPressed: () => setState(() {
                _mode =
                    _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
              }),
            ),
          ],
        ),
        body: widget.child,
      ),
    );
  }
}
