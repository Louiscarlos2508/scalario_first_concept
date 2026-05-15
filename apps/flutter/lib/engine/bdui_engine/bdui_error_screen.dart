import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../error_boundary/bdui_error_boundary.dart';

/// Écran de fallback affiché quand le pipeline `BDUIEngine` échoue
/// au-delà des boundaries par-composant (AC-12, AC-13).
///
/// - Titre i18n "Écran indisponible" (en attendant STORY-042 — placeholder FR).
/// - Détail debug-only (path JSON + message) si `kDebugMode`.
/// - Bouton "Réessayer" → callback fourni.
/// - Bouton "Signaler" → log structuré sink (STORY-026 plug-in futur).
class BDUIErrorScreen extends StatelessWidget {
  const BDUIErrorScreen({
    super.key,
    required this.error,
    this.screenId,
    this.onRetry,
    this.onReport,
  });

  final Object error;
  final String? screenId;
  final VoidCallback? onRetry;
  final VoidCallback? onReport;

  String get _title => 'Écran indisponible';

  String? get _debugDetail {
    if (!kDebugMode) return null;
    if (error is BDUIValidationException) {
      final BDUIValidationException e = error as BDUIValidationException;
      return '${e.message}${e.jsonPath != null ? "\n@ ${e.jsonPath}" : ""}';
    }
    return error.toString();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? detail = _debugDetail;
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.error_outline,
              size: 56,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Nous n\'avons pas pu afficher cet écran.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (detail != null) ...<Widget>[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  detail,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (onRetry != null)
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            if (onReport != null) ...<Widget>[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onReport,
                icon: const Icon(Icons.report_outlined),
                label: const Text('Signaler'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
