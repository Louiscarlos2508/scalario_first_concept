// Run (standalone):  flutter run --target=lib/showcases/_dashboard_owner_showcase.dart -d <device>
// Preview (IDE):     flutter widget-preview start  → ouvrir ce fichier
// Spec:              design-process/D-Design-System/ — composition Dashboard Owner

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../components/data_display/chart_bar.dart';
import '../components/data_display/kpi_card.dart';
import '../components/feedback/alert_banner.dart';
import '../components/lists/scalario_list_tile.dart';
import '../core/design_system/tokens/tokens.dart';
import '../core/theme/scalario_theme.dart';
import '_showcase_app.dart';

PreviewThemeData scalarioDashboardOwnerThemes() => PreviewThemeData(
      materialLight: ScalarioTheme.light(),
      materialDark: ScalarioTheme.dark(),
    );

Widget scalarioDashboardOwnerWrap(Widget child) => Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ScalarioSpacing.space4),
        child: child,
      ),
    );

// Mock data — données fictives non tirées de vraies boutiques (AC sécurité).
const List<ChartDataPoint> _mockChartData = <ChartDataPoint>[
  ChartDataPoint(label: 'L', value: 38500),
  ChartDataPoint(label: 'M', value: 52000),
  ChartDataPoint(label: 'Me', value: 47500),
  ChartDataPoint(label: 'J', value: 61200),
  ChartDataPoint(label: 'V', value: 74800),
  ChartDataPoint(label: 'S', value: 89000),
  ChartDataPoint(label: 'D', value: 31200),
];

const List<({String title, String subtitle, String amount})> _mockTransactions =
    <({String title, String subtitle, String amount})>[
  (title: 'Vente — Tomates', subtitle: '10h32 · 12 kg', amount: '6 000 FCFA'),
  (title: 'Vente — Avocat', subtitle: '11h15 · 6 pcs', amount: '3 600 FCFA'),
  (title: 'Vente — Igname', subtitle: '13h47 · 2 kg', amount: '1 400 FCFA'),
  (title: 'Vente — Piment', subtitle: '15h02 · 1 kg', amount: '800 FCFA'),
];

@Preview(name: 'Dashboard Owner', theme: scalarioDashboardOwnerThemes, wrapper: scalarioDashboardOwnerWrap)
Widget previewDashboardOwner() => const _DashboardOwnerContent();

class _DashboardOwnerContent extends StatelessWidget {
  const _DashboardOwnerContent();

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Bandeau alerte stock
          const AlertBanner(
            type: AlertType.warning,
            message: 'Stock faible — Avocat (3 unités) et Piment (1 unité).',
            actionLabel: 'Voir stock',
          ),
          const SizedBox(height: ScalarioSpacing.space4),
          // KPIs 2×2
          const Row(
            children: <Widget>[
              Expanded(
                child: KPICard(
                  label: 'CA du jour',
                  value: '47 500',
                  unit: 'FCFA',
                  delta: '+12% vs hier',
                ),
              ),
              SizedBox(width: ScalarioSpacing.space3),
              Expanded(
                child: KPICard(
                  label: 'Marge brute',
                  value: '8 200',
                  unit: 'FCFA',
                  delta: '-5% vs hier',
                  deltaPositive: false,
                  status: KpiStatus.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: ScalarioSpacing.space3),
          const Row(
            children: <Widget>[
              Expanded(
                child: KPICard(
                  label: 'Transactions',
                  value: '24',
                  unit: 'ventes',
                  delta: '+3 vs hier',
                ),
              ),
              SizedBox(width: ScalarioSpacing.space3),
              Expanded(
                child: KPICard(
                  label: 'Stock critique',
                  value: '2',
                  unit: 'articles',
                  delta: '[!] alerte',
                  deltaPositive: false,
                  status: KpiStatus.critical,
                ),
              ),
            ],
          ),
          const SizedBox(height: ScalarioSpacing.space6),
          // Chart CA 7 jours
          const ChartBar(
            title: 'CA 7 derniers jours',
            data: _mockChartData,
            unit: 'FCFA',
            period: 'Semaine du 04 au 10 mai 2026',
          ),
          const SizedBox(height: ScalarioSpacing.space6),
          // Transactions récentes
          Text('Transactions récentes', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: ScalarioSpacing.space3),
          for (final ({String title, String subtitle, String amount}) tx in _mockTransactions)
            ScalarioListTile(
              title: tx.title,
              subtitle: tx.subtitle,
              trailing: Text(tx.amount, style: ScalarioTypography.bodyMono),
              onTap: () {},
            ),
        ],
      );
}

void main() => runApp(const ScalarioShowcaseApp(
      title: 'Dashboard Owner',
      child: SingleChildScrollView(
        padding: EdgeInsets.all(ScalarioSpacing.space4),
        child: _DashboardOwnerContent(),
      ),
    ));
