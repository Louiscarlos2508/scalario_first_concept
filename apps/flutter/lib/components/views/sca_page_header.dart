import 'package:flutter/material.dart';
import '../../engine/canvas_registry/component_config.dart';
import '../../core/design_system/tokens/colors.dart';
import '../data_display/sca_typography.dart';

/// Layout Component: Un en-tête de page générique (indépendant du domaine métier)
class ScaPageHeader extends StatelessWidget {
  final ComponentConfig config;

  const ScaPageHeader({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final title = config.props['title'] ?? 'Sans Titre';
    final breadcrumbs = (config.props['breadcrumbs'] as List<dynamic>?) ?? [];
    // actions n'est pas géré ici directement, on s'attend à ce que le BDUI passe des enfants
    // dans un slot 'actions' ou directement dans children.

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: ScalarioColors.neutral200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (breadcrumbs.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    children: breadcrumbs.map((b) {
                      return Text(
                        '$b / ',
                        style: const TextStyle(fontSize: 12, color: ScalarioColors.neutral500),
                      );
                    }).toList(),
                  ),
                ),
              ScaTypography(
                config: ComponentConfig(
                  id: 'title',
                  type: 'ScaTypography',
                  props: {'text': title, 'variant': 'h1'},
                ),
              ),
            ],
          ),
          // S'il y a des enfants, on les affiche à droite (ex: boutons d'action génériques)
          if (config.children != null && config.children!.isNotEmpty)
            Row(
              children: config.children!.map((child) {
                return Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  // RenderChild callback would normally go here in a real BDUI engine
                  // Mockup pour l'instant
                  child: const Placeholder(fallbackHeight: 32, fallbackWidth: 100),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
