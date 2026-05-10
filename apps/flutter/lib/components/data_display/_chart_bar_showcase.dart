// Run (standalone):  flutter run --target=lib/components/data_display/_chart_bar_showcase.dart -d <device>
// Preview (IDE):     flutter widget-preview start  → ouvrir ce fichier
// Spec:              design-process/D-Design-System/components/02-data-display.md (ChartBar, lignes 182-222)

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../core/design_system/tokens/tokens.dart';
import '../../core/theme/scalario_theme.dart';
import '../../showcases/_showcase_app.dart';
import 'chart_bar.dart';

PreviewThemeData scalarioChartBarThemes() => PreviewThemeData(
      materialLight: ScalarioTheme.light(),
      materialDark: ScalarioTheme.dark(),
    );

Widget scalarioChartBarWrap(Widget child) => Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ScalarioSpacing.space4),
        child: child,
      ),
    );

// 7 jours CA — données fictives.
const List<ChartDataPoint> _mockData = <ChartDataPoint>[
  ChartDataPoint(label: 'L', value: 38500),
  ChartDataPoint(label: 'M', value: 52000),
  ChartDataPoint(label: 'Me', value: 47500),
  ChartDataPoint(label: 'J', value: 61200),
  ChartDataPoint(label: 'V', value: 74800),
  ChartDataPoint(label: 'S', value: 89000),
  ChartDataPoint(label: 'D', value: 31200),
];

@Preview(name: 'Normal 7 jours', theme: scalarioChartBarThemes, wrapper: scalarioChartBarWrap)
Widget previewChartBarNormal() => const ChartBar(
      title: 'CA des 7 derniers jours',
      data: _mockData,
      unit: 'FCFA',
      period: 'Semaine du 04 au 10 mai 2026',
    );

@Preview(name: 'Loading shimmer', theme: scalarioChartBarThemes, wrapper: scalarioChartBarWrap)
Widget previewChartBarLoading() => ChartBar.loading(title: 'CA des 7 derniers jours');

@Preview(name: 'Empty', theme: scalarioChartBarThemes, wrapper: scalarioChartBarWrap)
Widget previewChartBarEmpty() => const ChartBar(
      title: 'CA des 7 derniers jours',
      data: <ChartDataPoint>[],
      period: 'Aucune donnée pour cette période',
    );

@Preview(name: 'Erreur', theme: scalarioChartBarThemes, wrapper: scalarioChartBarWrap)
Widget previewChartBarError() => ChartBar.error(
      title: 'CA des 7 derniers jours',
      message: 'Impossible de charger les données du graphique.',
    );

class _ChartBarShowcase extends StatelessWidget {
  const _ChartBarShowcase();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(ScalarioSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            previewChartBarNormal(),
            const SizedBox(height: ScalarioSpacing.space6),
            previewChartBarLoading(),
            const SizedBox(height: ScalarioSpacing.space6),
            previewChartBarEmpty(),
            const SizedBox(height: ScalarioSpacing.space6),
            previewChartBarError(),
          ],
        ),
      );
}

void main() => runApp(const ScalarioShowcaseApp(
      title: 'ChartBar Showcase',
      child: _ChartBarShowcase(),
    ));
