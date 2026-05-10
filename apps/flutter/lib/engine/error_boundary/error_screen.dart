import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../../core/design_system/tokens/tokens.dart';

/// Full-screen fallback rendered by [BDUIErrorBoundary] when the entire
/// screen pipeline (parse → validate → layout) fails (AC-08).
///
/// Displays:
/// - An error illustration (icon + EmptyState style).
/// - Localised title + subtitle.
/// - A "Réessayer" primary button wired to [onRetry].
/// - In [kDebugMode], an expandable "Détails techniques" panel showing the
///   exception type, message, and first 10 stack frames (AC-08 debug panel).
class BDUIErrorScreen extends StatelessWidget {
  const BDUIErrorScreen({
    super.key,
    required this.screenId,
    this.onRetry,
    this.error,
    this.stack,
  });

  final String screenId;
  final VoidCallback? onRetry;
  final Object? error;
  final StackTrace? stack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ScalarioSpacing.space8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(
            ScalarioIcons.stateError,
            size: ScalarioIconSize.lg,
            color: ScalarioColors.danger500,
          ),
          const SizedBox(height: ScalarioSpacing.space4),
          Text(
            // TODO i18n: bdui.error.screen_title (AC-22)
            'Écran indisponible',
            style: ScalarioTypography.title.copyWith(
              color: ScalarioColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: ScalarioSpacing.space2),
          Text(
            // TODO i18n: bdui.error.screen_subtitle (AC-22)
            'Une erreur est survenue. Réessayez ou contactez votre administrateur.',
            style: ScalarioTypography.body.copyWith(
              color: ScalarioColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...<Widget>[
            const SizedBox(height: ScalarioSpacing.space6),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Réessayer'),
            ),
          ],
          if (kDebugMode && error != null) ...<Widget>[
            const SizedBox(height: ScalarioSpacing.space6),
            _DebugPanel(
              screenId: screenId,
              error: error!,
              stack: stack,
            ),
          ],
        ],
      ),
    );
  }
}

/// Debug-only panel — collapsed by default, reveals exception details (AC-08).
class _DebugPanel extends StatefulWidget {
  const _DebugPanel({
    required this.screenId,
    required this.error,
    this.stack,
  });

  final String screenId;
  final Object error;
  final StackTrace? stack;

  @override
  State<_DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends State<_DebugPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: ScalarioColors.neutral100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(ScalarioSpacing.space3),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Détails techniques',
                      style: ScalarioTypography.captionMedium,
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: ScalarioIconSize.sm,
                    color: ScalarioColors.neutral500,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ScalarioSpacing.space3,
                0,
                ScalarioSpacing.space3,
                ScalarioSpacing.space3,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _row('screen_id', widget.screenId),
                  _row('type', widget.error.runtimeType.toString()),
                  _row('message', widget.error.toString()),
                  if (widget.stack != null)
                    _row(
                      'stack',
                      widget.stack!
                          .toString()
                          .split('\n')
                          .take(10)
                          .join('\n'),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: ScalarioSpacing.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: ScalarioTypography.overline),
          Text(
            value,
            style: ScalarioTypography.caption.copyWith(
              fontFamily: ScalarioTypography.robotoMonoFamily,
            ),
            maxLines: 20,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
