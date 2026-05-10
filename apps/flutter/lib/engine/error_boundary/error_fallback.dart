import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../../core/design_system/tokens/tokens.dart';

/// Per-component fallback widget shown when an [ErrorBoundary] catches a
/// build exception (AC-03, AC-04).
///
/// Visually: AlertBanner danger variant — height ≥ 56dp, horizontal padding
/// [ScalarioSpacing.space4], background [ScalarioColors.danger100].
///
/// In [kDebugMode], a tappable "Details" chip reveals the exception type.
class ErrorFallback extends StatelessWidget {
  const ErrorFallback({
    super.key,
    required this.componentType,
    this.error,
    this.stack,
  });

  final String componentType;
  final Object? error;
  final StackTrace? stack;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56), // AC-04
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ScalarioSpacing.space4, // AC-04
          vertical: ScalarioSpacing.space3,
        ),
        decoration: const BoxDecoration(
          color: ScalarioColors.danger100, // AC-04
          border: Border(
            left: BorderSide(
              color: ScalarioColors.danger500,
              width: 3,
            ),
          ),
          borderRadius: BorderRadius.all(Radius.circular(ScalarioRadius.sm)),
        ),
        child: Row(
          children: <Widget>[
            const Icon(
              ScalarioIcons.stateError,
              size: ScalarioIconSize.sm,
              color: ScalarioColors.danger700,
            ),
            const SizedBox(width: ScalarioSpacing.space3),
            Expanded(
              child: Text(
                // TODO i18n: bdui.error.component_unavailable (AC-22)
                'Composant indisponible',
                style: ScalarioTypography.fontBannerText.copyWith(
                  color: ScalarioColors.danger700,
                ),
              ),
            ),
            if (kDebugMode && error != null) ...<Widget>[
              const SizedBox(width: ScalarioSpacing.space2),
              Tooltip(
                message: '[$componentType] ${error.runtimeType}',
                child: const Icon(
                  ScalarioIcons.stateInfo,
                  size: ScalarioIconSize.xs,
                  color: ScalarioColors.danger500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
