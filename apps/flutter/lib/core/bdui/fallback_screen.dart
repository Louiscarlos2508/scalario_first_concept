import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../../core/design_system/tokens/tokens.dart' show ScalarioColors, ScalarioTypography;
import 'validation/validation_result.dart' show ValidationError;

class FallbackScreen extends StatelessWidget {
  final List<ValidationError> errors;
  final VoidCallback? onRetry;
  final String? errorId;

  const FallbackScreen({
    super.key,
    required this.errors,
    this.onRetry,
    this.errorId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: ScalarioColors.warning500,
              ),
              const SizedBox(height: 16),
              Text(
                "Cet écran n'a pas pu être chargé.\nNous avons enregistré le problème.",
                textAlign: TextAlign.center,
                style: ScalarioTypography.bodyLg,
              ),
              if (errorId != null) ...[
                const SizedBox(height: 8),
                Text(
                  'error_id: $errorId',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontFamily: 'RobotoMono',
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (onRetry != null)
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Réessayer'),
                ),
              if (kDebugMode && errors.isNotEmpty) ...[
                const SizedBox(height: 24),
                ExpansionTile(
                  title: const Text('Détails techniques (debug)'),
                  initiallyExpanded: true,
                  children: errors.map((e) => ListTile(
                    dense: true,
                    title: Text(
                      e.path,
                      style: const TextStyle(fontFamily: 'RobotoMono', fontSize: 12),
                    ),
                    subtitle: Text(
                      '${e.keyword}: ${e.message}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
