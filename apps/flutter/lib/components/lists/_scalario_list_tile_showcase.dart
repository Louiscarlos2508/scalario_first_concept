// Run (standalone):  flutter run --target=lib/components/lists/_scalario_list_tile_showcase.dart -d <device>
// Preview (IDE):     flutter widget-preview start  → ouvrir ce fichier
// Spec:              design-process/D-Design-System/components/06-lists.md

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../core/design_system/tokens/tokens.dart';
import '../../core/theme/scalario_theme.dart';
import '../../showcases/_showcase_app.dart';
import 'scalario_list_tile.dart';

PreviewThemeData scalarioListTileThemes() => PreviewThemeData(
      materialLight: ScalarioTheme.light(),
      materialDark: ScalarioTheme.dark(),
    );

Widget scalarioListTileWrap(Widget child) => Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ScalarioSpacing.space4),
        child: child,
      ),
    );

@Preview(name: 'Simple', theme: scalarioListTileThemes, wrapper: scalarioListTileWrap)
Widget previewListTileSimple() => const ScalarioListTile(
      title: 'Vente — Tomates',
      subtitle: '12 kg × 500 FCFA',
    );

@Preview(name: 'Avec leading + trailing', theme: scalarioListTileThemes, wrapper: scalarioListTileWrap)
Widget previewListTileLeadingTrailing() => ScalarioListTile(
      leading: const CircleAvatar(radius: 18, child: Icon(Icons.person, size: 18)),
      title: 'Boutique Kouamé',
      subtitle: 'Abidjan — Yopougon',
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );

@Preview(name: 'Status success', theme: scalarioListTileThemes, wrapper: scalarioListTileWrap)
Widget previewListTileStatusSuccess() => const ScalarioListTile(
      title: 'Synchronisation complète',
      subtitle: 'Toutes les données sont à jour',
      status: ListTileStatus.success,
    );

@Preview(name: 'Status warning', theme: scalarioListTileThemes, wrapper: scalarioListTileWrap)
Widget previewListTileStatusWarning() => const ScalarioListTile(
      title: 'Stock faible — Avocat',
      subtitle: '3 unités restantes',
      status: ListTileStatus.warning,
    );

@Preview(name: 'Status danger', theme: scalarioListTileThemes, wrapper: scalarioListTileWrap)
Widget previewListTileStatusDanger() => const ScalarioListTile(
      title: 'Rupture de stock — Tomates',
      subtitle: '0 unité disponible',
      status: ListTileStatus.danger,
    );

@Preview(name: 'Loading', theme: scalarioListTileThemes, wrapper: scalarioListTileWrap)
Widget previewListTileLoading() => const ScalarioListTile.loading();

@Preview(name: 'Empty', theme: scalarioListTileThemes, wrapper: scalarioListTileWrap)
Widget previewListTileEmpty() => ScalarioListTile.empty('Aucune transaction aujourd\'hui');

class _ScalarioListTileShowcase extends StatelessWidget {
  const _ScalarioListTileShowcase();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(ScalarioSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            previewListTileSimple(),
            const SizedBox(height: ScalarioSpacing.space4),
            previewListTileLeadingTrailing(),
            const SizedBox(height: ScalarioSpacing.space4),
            previewListTileStatusSuccess(),
            const SizedBox(height: ScalarioSpacing.space4),
            previewListTileStatusWarning(),
            const SizedBox(height: ScalarioSpacing.space4),
            previewListTileStatusDanger(),
            const SizedBox(height: ScalarioSpacing.space4),
            previewListTileLoading(),
            const SizedBox(height: ScalarioSpacing.space4),
            previewListTileEmpty(),
          ],
        ),
      );
}

void main() => runApp(const ScalarioShowcaseApp(
      title: 'ListTile Showcase',
      child: _ScalarioListTileShowcase(),
    ));
