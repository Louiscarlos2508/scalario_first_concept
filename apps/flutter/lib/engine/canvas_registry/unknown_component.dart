import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../../core/design_system/tokens/tokens.dart';

/// Widget de fallback pour un type non enregistré dans le ScalarioCanvasRegistry.
///
/// AC-14 : affiche un banner warning avec le type inconnu, loggue via
/// dart:developer, ne crash jamais même si le type est vide.
/// AC-15 : ne crash pas si props est null/vide.
///
/// Hauteur min = 56dp ; padding = ScalarioSpacing.space4 (AC-14).
class UnknownComponent extends StatelessWidget {
  const UnknownComponent(this.componentType, {super.key, this.message});

  final String componentType;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final String label = componentType.isEmpty
        ? 'Composant sans type'
        : 'Composant "$componentType" indisponible';

    developer.log(
      'UnknownComponent: $componentType',
      name: 'BDUI',
      level: 900, // warning
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.all(ScalarioSpacing.space4),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ScalarioSpacing.space4,
            vertical: ScalarioSpacing.space3,
          ),
          decoration: BoxDecoration(
            color: ScalarioColors.warning100,
            borderRadius: BorderRadius.circular(ScalarioRadius.sm),
            border: const Border(
              left: BorderSide(color: ScalarioColors.warning500, width: 3),
            ),
          ),
          child: Row(
            children: <Widget>[
              const Icon(
                ScalarioIcons.warning,
                size: ScalarioIconSize.sm,
                color: ScalarioColors.warning700,
              ),
              const SizedBox(width: ScalarioSpacing.space3),
              Expanded(
                child: Text(
                  label,
                  style: ScalarioTypography.fontBannerText.copyWith(
                    color: ScalarioColors.warning700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
