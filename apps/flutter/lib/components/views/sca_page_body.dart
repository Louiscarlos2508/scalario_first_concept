import 'package:flutter/material.dart';
import '../../engine/canvas_registry/component_config.dart';
import '../../core/design_system/tokens/colors.dart';

/// Layout Component: Conteneur de page avec marges et max-width standardisés
class ScaPageBody extends StatelessWidget {
  final ComponentConfig config;

  const ScaPageBody({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ScalarioColors.neutral50,
      width: double.infinity,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200), // Max-width pour Desktop/Tablette
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            // Dans un vrai BDUI, on utiliserait le `ScalarioCanvasRegistry` pour rendre `config.children`.
            // Ici nous mettons un Placeholder générique pour l'instant.
            child: const Placeholder(
              color: ScalarioColors.neutral200,
              fallbackHeight: 400,
              fallbackWidth: double.infinity,
            ),
          ),
        ),
      ),
    );
  }
}
