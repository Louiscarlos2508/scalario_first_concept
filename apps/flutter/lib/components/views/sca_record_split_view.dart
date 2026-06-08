import 'package:flutter/material.dart';
import '../../engine/canvas_registry/component_config.dart';
import '../../core/design_system/tokens/colors.dart';

class ScaRecordSplitView extends StatelessWidget {
  final ComponentConfig config;

  const ScaRecordSplitView({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Panneau Gauche : Détails de l'Entité (Formulaire)
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ScalarioColors.neutral200),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Détails', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  SizedBox(height: 16),
                  Text('Champs générés dynamiquement ici...', style: TextStyle(color: ScalarioColors.neutral500)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Panneau Droit : Historique / Timeline
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              color: ScalarioColors.neutral50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ScalarioColors.neutral200),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Activité', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  SizedBox(height: 16),
                  Text('Timeline universelle...', style: TextStyle(color: ScalarioColors.neutral500)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
