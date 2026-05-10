// Widgetbook stub Sprint 1 — galerie complète dans Sprint 2+.
// Sprint 2 viendra peupler ce fichier avec tous les composants DS.
// Pour l'instant, ce stub valide que le package compile correctement.
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

void main() => runApp(const _ScalarioWidgetbook());

class _ScalarioWidgetbook extends StatelessWidget {
  const _ScalarioWidgetbook();

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      directories: <WidgetbookNode>[
        WidgetbookCategory(
          name: 'Composants Scalario',
          children: <WidgetbookNode>[
            WidgetbookComponent(
              name: 'Hello World (stub Sprint 1)',
              useCases: <WidgetbookUseCase>[
                WidgetbookUseCase(
                  name: 'Default',
                  builder: (BuildContext context) => const Center(
                    child: Text('Galerie Widgetbook → Sprint 2'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
