// Run (standalone):  flutter run --target=lib/components/data_display/_kpi_card_showcase.dart -d <device>
// Preview (IDE):     flutter widget-preview start  → ouvrir ce fichier
// Spec:              design-process/D-Design-System/components/02-data-display.md (KPICard, lignes 14-69)

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../core/design_system/tokens/tokens.dart';
import '../../core/theme/scalario_theme.dart';
import '../../showcases/_showcase_app.dart';
import 'kpi_card.dart';

PreviewThemeData scalarioKPICardThemes() => PreviewThemeData(
      materialLight: ScalarioTheme.light(),
      materialDark: ScalarioTheme.dark(),
    );

Widget scalarioKPICardWrap(Widget child) => Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ScalarioSpacing.space4),
        child: child,
      ),
    );

@Preview(name: 'Nominal', theme: scalarioKPICardThemes, wrapper: scalarioKPICardWrap)
Widget previewKPICardNominal() => const KPICard(
      label: 'CA du jour',
      value: '47 500',
      unit: 'FCFA',
      delta: '+12% vs hier',
    );

@Preview(name: 'Warning', theme: scalarioKPICardThemes, wrapper: scalarioKPICardWrap)
Widget previewKPICardWarning() => const KPICard(
      label: 'Marge brute',
      value: '8 200',
      unit: 'FCFA',
      delta: '-5% vs hier',
      deltaPositive: false,
      status: KpiStatus.warning,
    );

@Preview(name: 'Critical', theme: scalarioKPICardThemes, wrapper: scalarioKPICardWrap)
Widget previewKPICardCritical() => const KPICard(
      label: 'Stock critique',
      value: '3',
      unit: 'articles',
      delta: '[!] alerte',
      deltaPositive: false,
      status: KpiStatus.critical,
    );

@Preview(name: 'Loading', theme: scalarioKPICardThemes, wrapper: scalarioKPICardWrap)
Widget previewKPICardLoading() => KPICard.loading(label: 'CA du jour');

@Preview(name: 'Empty', theme: scalarioKPICardThemes, wrapper: scalarioKPICardWrap)
Widget previewKPICardEmpty() => KPICard.empty('Pas de données');

@Preview(name: 'Tappable', theme: scalarioKPICardThemes, wrapper: scalarioKPICardWrap)
Widget previewKPICardTappable() => KPICard(
      label: 'Transactions',
      value: '24',
      unit: 'ventes',
      delta: '+3 vs hier',
      onTap: () {},
    );

class _KPICardShowcase extends StatelessWidget {
  const _KPICardShowcase();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(ScalarioSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            previewKPICardNominal(),
            const SizedBox(height: ScalarioSpacing.space4),
            previewKPICardWarning(),
            const SizedBox(height: ScalarioSpacing.space4),
            previewKPICardCritical(),
            const SizedBox(height: ScalarioSpacing.space4),
            previewKPICardLoading(),
            const SizedBox(height: ScalarioSpacing.space4),
            previewKPICardEmpty(),
            const SizedBox(height: ScalarioSpacing.space4),
            previewKPICardTappable(),
          ],
        ),
      );
}

void main() => runApp(const ScalarioShowcaseApp(
      title: 'KPICard Showcase',
      child: _KPICardShowcase(),
    ));
