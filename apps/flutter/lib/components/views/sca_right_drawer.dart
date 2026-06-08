import 'package:flutter/material.dart';
import '../../engine/canvas_registry/component_config.dart';
import '../../core/design_system/tokens/colors.dart';
import '../data_display/sca_typography.dart';

/// Layout Component: Un Side Panel (Drawer) venant de la droite pour l'édition rapide
class ScaRightDrawer extends StatelessWidget {
  final ComponentConfig config;

  const ScaRightDrawer({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final title = config.props['title'] ?? 'Détails';

    return Container(
      width: 400, // Largeur fixe typique d'un panneau latéral
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: ScalarioColors.neutral200)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000), // Shadow fine
            blurRadius: 10,
            offset: Offset(-2, 0),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header du Drawer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: ScalarioColors.neutral200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ScaTypography(
                  config: ComponentConfig(
                    id: 'drawer_title',
                    type: 'ScaTypography',
                    props: {'text': title, 'variant': 'h3'},
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: ScalarioColors.neutral500),
                  onPressed: () {
                    // Logique de fermeture (normalement gérée par le CanvasRegistry/Navigator)
                  },
                ),
              ],
            ),
          ),
          // Contenu du Drawer
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: const Placeholder(
                color: ScalarioColors.neutral200,
                fallbackWidth: double.infinity,
              ),
            ),
          ),
          // Footer du Drawer (Actions)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: ScalarioColors.neutral50,
              border: Border(top: BorderSide(color: ScalarioColors.neutral200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('Annuler', style: TextStyle(color: ScalarioColors.neutral700)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: ScalarioColors.primary500),
                  child: const Text('Sauvegarder', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
