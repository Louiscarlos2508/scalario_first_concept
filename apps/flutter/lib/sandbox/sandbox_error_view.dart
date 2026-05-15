// STORY-009 — Sandbox dev-only.
//
// Vue d'erreur dédiée dev. Affiche le path JSON, la ligne/colonne du parse
// error (si dispo), le voisinage du fragment fautif et un bouton Réessayer.

import 'package:flutter/material.dart';

import '../engine/error_boundary/bdui_error_boundary.dart';
import 'sandbox_json_loader.dart';

class SandboxErrorView extends StatelessWidget {
  const SandboxErrorView({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final _ErrorDescription desc = _describe(error);
    return Container(
      color: cs.errorContainer,
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.error_outline, color: cs.onErrorContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  desc.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: cs.onErrorContainer,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(
            'Source : ${desc.path}',
            style: TextStyle(color: cs.onErrorContainer, fontFamily: 'monospace'),
          ),
          if (desc.position != null) ...<Widget>[
            const SizedBox(height: 4),
            SelectableText(
              'Position : ${desc.position}',
              style: TextStyle(color: cs.onErrorContainer, fontFamily: 'monospace'),
            ),
          ],
          if (desc.jsonPath != null) ...<Widget>[
            const SizedBox(height: 4),
            SelectableText(
              'Chemin JSON : ${desc.jsonPath}',
              style: TextStyle(color: cs.onErrorContainer, fontFamily: 'monospace'),
            ),
          ],
          const SizedBox(height: 12),
          SelectableText(
            desc.message,
            style: TextStyle(color: cs.onErrorContainer, fontFamily: 'monospace'),
          ),
          if (desc.snippet != null) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              'Voisinage :',
              style: TextStyle(
                color: cs.onErrorContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              color: cs.error.withValues(alpha: 0.15),
              child: SelectableText(
                desc.snippet!,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ),
          ],
        ),
      ),
    );
  }

  static _ErrorDescription _describe(Object error) {
    if (error is SandboxParseException) {
      final String? snippet = (error.source != null && error.line != null)
          ? _snippet(error.source!, error.line!)
          : null;
      return _ErrorDescription(
        title: 'JSON invalide',
        path: error.path,
        position: error.line != null
            ? 'ligne ${error.line}, col ${error.column}'
            : null,
        jsonPath: null,
        message: error.message,
        snippet: snippet,
      );
    }
    if (error is BDUIValidationException) {
      return _ErrorDescription(
        title: 'Schéma BDUI invalide',
        path: '(validateScreen)',
        position: null,
        jsonPath: error.jsonPath,
        message: error.message,
        snippet: null,
      );
    }
    return _ErrorDescription(
      title: 'Erreur de rendu',
      path: '(render pipeline)',
      position: null,
      jsonPath: null,
      message: error.toString(),
      snippet: null,
    );
  }

  static String _snippet(String source, int line) {
    final List<String> lines = source.split('\n');
    final int start = (line - 3).clamp(0, lines.length);
    final int end = (line + 2).clamp(0, lines.length);
    final StringBuffer buf = StringBuffer();
    for (int i = start; i < end; i++) {
      final String prefix = (i + 1 == line) ? '>> ' : '   ';
      buf.writeln('$prefix${i + 1}: ${lines[i]}');
    }
    return buf.toString();
  }
}

class _ErrorDescription {
  const _ErrorDescription({
    required this.title,
    required this.path,
    required this.position,
    required this.jsonPath,
    required this.message,
    required this.snippet,
  });

  final String title;
  final String path;
  final String? position;
  final String? jsonPath;
  final String message;
  final String? snippet;
}
