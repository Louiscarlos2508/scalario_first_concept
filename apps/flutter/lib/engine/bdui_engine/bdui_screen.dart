import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../layout_resolver/screen_config.dart';
import 'bdui_engine.dart';
import 'bdui_error_screen.dart';

/// Widget public consommé par les routes Flutter (AC-03).
///
/// ```dart
/// MaterialPageRoute(
///   builder: (_) => const BDUIScreen(screenId: 'retail_dashboard'),
/// );
/// ```
///
/// Gère `FutureBuilder` autour de `engine.loadScreen` + skeleton loading
/// (placeholder Material en attendant le composant DS dédié).
class BDUIScreen extends StatefulWidget {
  const BDUIScreen({
    super.key,
    required this.screenId,
    this.engine,
  });

  /// Identifiant du screen JSON à charger.
  final String screenId;

  /// Override optionnel pour tests/showcase. Par défaut résolu via `GetIt`.
  final BDUIEngine? engine;

  @override
  State<BDUIScreen> createState() => _BDUIScreenState();
}

class _BDUIScreenState extends State<BDUIScreen> {
  late BDUIEngine _engine;
  late Future<ScreenConfig> _future;

  @override
  void initState() {
    super.initState();
    _engine = widget.engine ?? GetIt.I<BDUIEngine>();
    _future = _engine.loadScreen(widget.screenId);
  }

  void _retry() {
    _engine.invalidate();
    setState(() {
      _future = _engine.loadScreen(widget.screenId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ScreenConfig>(
      future: _future,
      builder: (BuildContext ctx, AsyncSnapshot<ScreenConfig> snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return BDUIErrorScreen(
            error: snap.error!,
            screenId: widget.screenId,
            onRetry: _retry,
          );
        }
        final ScreenConfig config = snap.data!;
        try {
          // Wrap layout output in a Scaffold so widgets that require a
          // Material ancestor (ListTile-based, ink splashes…) work without
          // each layout having to duplicate the shell.
          return Scaffold(
            appBar: config.title != null ? AppBar(title: Text(config.title!)) : null,
            body: _engine.render(config, ctx),
          );
        } catch (e) {
          return BDUIErrorScreen(
            error: e,
            screenId: widget.screenId,
            onRetry: _retry,
          );
        }
      },
    );
  }
}
