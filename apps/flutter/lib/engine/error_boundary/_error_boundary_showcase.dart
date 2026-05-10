// ignore_for_file: avoid_print
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../../core/theme/scalario_theme.dart';
import 'bdui_error_boundary.dart';
import 'error_boundary.dart';
import 'error_fallback.dart';
import 'error_logger.dart';
import 'error_payload.dart';
import 'error_screen.dart';

// ---------------------------------------------------------------------------
// Standalone preview entry-point
// ---------------------------------------------------------------------------

void main() => runApp(const _ShowcaseApp());

class _ShowcaseApp extends StatelessWidget {
  const _ShowcaseApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ScalarioTheme.light(),
      darkTheme: ScalarioTheme.dark(),

      home: const _ErrorBoundaryShowcasePage(),
    );
  }
}

// ---------------------------------------------------------------------------
// @Preview Light
// ---------------------------------------------------------------------------

/// @Preview Light — error boundary showcase
class _ErrorBoundaryShowcasePage extends StatefulWidget {
  const _ErrorBoundaryShowcasePage();

  @override
  State<_ErrorBoundaryShowcasePage> createState() =>
      _ErrorBoundaryShowcasePageState();
}

class _ErrorBoundaryShowcasePageState
    extends State<_ErrorBoundaryShowcasePage> {
  bool _triggerComponentError = false;
  bool _triggerScreenError = false;
  int _retryCount = 0;
  final List<String> _logLines = [];

  void _logError(String msg) {
    if (!mounted) return;
    setState(() => _logLines.insert(0, '[${DateTime.now().toIso8601String()}] $msg'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error Boundary Showcase')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // ----------------------------------------------------------------
            // Section 1 — Per-component boundary
            // ----------------------------------------------------------------
            const Text('Level 1 — Per-component',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
                'Tap "Crasher composant" pour simuler une exception dans '
                'le 3e composant. Les 4 autres restent intacts.'),
            const SizedBox(height: 12),
            Row(
              children: List<Widget>.generate(5, (i) {
                if (i == 2 && _triggerComponentError) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ErrorBoundary(
                        componentType: 'KPICard',
                        componentId: 'kpi_$i',
                        child: const _AlwaysThrows(),
                      ),
                    ),
                  );
                }
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text('KPI $i', textAlign: TextAlign.center),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _triggerComponentError = !_triggerComponentError;
                  if (_triggerComponentError) {
                    _logError('Component error triggered on KPI #2');
                  } else {
                    _logError('Component error cleared');
                  }
                });
              },
              child: Text(_triggerComponentError
                  ? 'Effacer erreur composant'
                  : 'Crasher composant #2'),
            ),

            const Divider(height: 32),

            // ----------------------------------------------------------------
            // Section 2 — ErrorFallback widget standalone
            // ----------------------------------------------------------------
            const Text('ErrorFallback widget (standalone)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const ErrorFallback(componentType: 'KPICard'),
            const SizedBox(height: 8),
            ErrorFallback(
              componentType: 'DataTable',
              error: Exception('Source not found'),
              stack: StackTrace.current,
            ),

            const Divider(height: 32),

            // ----------------------------------------------------------------
            // Section 3 — Per-screen boundary
            // ----------------------------------------------------------------
            const Text('Level 2 — Per-screen',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 300,
              child: _triggerScreenError
                  ? BDUIErrorBoundary(
                      screenId: 'retail_dashboard',
                      onRetry: () {
                        setState(() {
                          _triggerScreenError = false;
                          _retryCount++;
                          _logError('Retry #$_retryCount triggered');
                        });
                      },
                      child: const _AlwaysThrows(),
                    )
                  : const Center(
                      child: Text('Screen OK — tap pour crasher'),
                    ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _triggerScreenError = !_triggerScreenError;
                  if (_triggerScreenError) {
                    _logError('Screen error triggered on retail_dashboard');
                  }
                });
              },
              child: Text(_triggerScreenError
                  ? 'Reset screen'
                  : 'Crasher l\'écran entier'),
            ),

            const Divider(height: 32),

            // ----------------------------------------------------------------
            // Section 4 — BDUIErrorScreen standalone
            // ----------------------------------------------------------------
            const Text('BDUIErrorScreen (standalone)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            BDUIErrorScreen(
              screenId: 'demo_screen',
              onRetry: () => _logError('Retry pressed'),
              error: kDebugMode
                  ? const BDUIValidationException(
                      "Missing required field 'title'",
                      jsonPath: 'components[0].props',
                    )
                  : null,
            ),

            const Divider(height: 32),

            // ----------------------------------------------------------------
            // Section 5 — ErrorLogger ring buffer
            // ----------------------------------------------------------------
            const Text('ErrorLogger — ring buffer',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {
                ErrorLogger.instance.log(ErrorPayload(
                  error: Exception('Manual test error from showcase'),
                  stack: StackTrace.current,
                  componentType: 'ShowcaseWidget',
                  componentId: 'showcase_btn',
                  screenId: 'showcase_screen',
                ));
                _logError(
                    'Logged — buffer size: ${ErrorLogger.instance.length}');
              },
              child: const Text('Log une erreur test'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                ErrorLogger.instance.clear();
                _logError('Buffer cleared');
              },
              child: const Text('Vider le buffer'),
            ),
            if (_logLines.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              ...(_logLines.take(5).map(
                    (l) => Text(l,
                        style: const TextStyle(
                            fontSize: 10, fontFamily: 'monospace')),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

/// Simulates a widget that always throws during build.
class _AlwaysThrows extends StatelessWidget {
  const _AlwaysThrows();

  @override
  Widget build(BuildContext context) {
    throw Exception('Simulated build exception');
  }
}
