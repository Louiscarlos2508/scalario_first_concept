import 'package:flutter/material.dart';

import '../../sync/sync_status_bar.dart';
import '../../../components/data_display/kpi_card.dart';
import '../../../components/data_display/chart_bar.dart';
import '../../../components/data_display/scalario_data_table.dart';
import '../../../components/feedback/alert_banner.dart';
import '../../../engine/canvas_registry/component_config.dart';
import '../../../core/design_system/tokens/tokens.dart';

class ModuleDashboardScreen extends StatelessWidget {
  const ModuleDashboardScreen({super.key, required this.config});
  final Map<String, dynamic> config;

  @override
  Widget build(BuildContext context) {
    final kpis = (config['kpis'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final alerts = (config['alerts'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final chartData = _parseChart(config['chart_data'] as List?);
    final chartTitle = config['chart_title'] as String? ?? '';
    final quickActions = (config['quick_actions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final recentSales = (config['recent_sales'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('SCALARIO'), centerTitle: false, actions: [
        Badge(label: Text('${alerts.length}'), child: const Icon(Icons.notifications_outlined)),
        const SizedBox(width: 8),
      ]),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final alert in alerts)
              AlertBanner(type: _alertType(alert['type'] as String? ?? 'info'), message: alert['message'] as String? ?? ''),
            Padding(
              padding: const EdgeInsets.all(ScalarioSpacing.space4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _sectionHeader('AUJOURD\'HUI'),
                const SizedBox(height: ScalarioSpacing.space3),
                if (kpis.isNotEmpty)
                  Wrap(spacing: ScalarioSpacing.space2, runSpacing: ScalarioSpacing.space2, children: kpis.map((kpi) {
                    return SizedBox(
                      width: (MediaQuery.of(context).size.width - 48) / 2,
                      child: KPICard(label: kpi['label'] as String? ?? '', value: kpi['value'] as String? ?? '—',
                        unit: kpi['unit'] as String?, status: _kpiStatus(kpi['status'] as String?), delta: kpi['delta'] as String?,
                        deltaPositive: kpi['delta_positive'] as bool? ?? true),
                    );
                  }).toList()),
                if (chartData.isNotEmpty) ...[
                  const SizedBox(height: ScalarioSpacing.space4),
                  SizedBox(height: 160, child: ChartBar(title: chartTitle, data: chartData)),
                ],
                if (quickActions.isNotEmpty) ...[
                  const SizedBox(height: ScalarioSpacing.space3),
                  _sectionHeader('ACTIONS RAPIDES'),
                  const SizedBox(height: ScalarioSpacing.space2),
                  Wrap(spacing: ScalarioSpacing.space2, runSpacing: ScalarioSpacing.space2, children: quickActions.map((a) {
                    return SizedBox(
                      width: (MediaQuery.of(context).size.width - 48) / 3,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFCC00), foregroundColor: Colors.black, padding: const EdgeInsets.all(8)),
                        onPressed: () {},
                        icon: Icon(_iconFor(a['icon'] as String? ?? ''), size: 16),
                        label: Text(a['label'] as String? ?? '', style: const TextStyle(fontSize: 10)),
                      ),
                    );
                  }).toList()),
                ],
                if (recentSales.isNotEmpty) ...[
                  const SizedBox(height: ScalarioSpacing.space4),
                  _sectionHeader('DERNIERES VENTES'),
                  const SizedBox(height: ScalarioSpacing.space2),
                  ScalarioDataTable<Map<String, String>>(
                    columns: [
                      DataColumnConfig(key: 'produit', label: 'Produit', cellBuilder: (r) => r['produit']!),
                      DataColumnConfig(key: 'qte', label: 'Qte', cellBuilder: (r) => r['qte']!),
                      DataColumnConfig(key: 'prix', label: 'Prix', cellBuilder: (r) => r['prix']!),
                      DataColumnConfig(key: 'heure', label: '', cellBuilder: (r) => r['heure']!),
                    ],
                    rows: recentSales.map((r) => r.map((k, v) => MapEntry(k, v.toString()))).toList(),
                    defaultSortKey: 'heure',
                  ),
                ],
              ]),
            ),
            SyncStatusBar.fromConfig(
              const ComponentConfig(type: 'SyncStatusBar', variant: 'synced', props: {}),
              context,
            ),
          ]),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(type: BottomNavigationBarType.fixed, currentIndex: 0, onTap: (_) {}, items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
        BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Stock'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Hist.'),
        BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Equipe'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Plus'),
      ]),
    );
  }

  Widget _sectionHeader(String text) => Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: ScalarioColors.textDisabled));

  List<ChartDataPoint> _parseChart(List? raw) {
    if (raw == null) return [];
    return raw.map((d) { final m = d as Map; return ChartDataPoint(label: m['label'] as String, value: (m['value'] as num).toDouble()); }).toList();
  }

  AlertType _alertType(String t) => AlertType.values.firstWhere((e) => e.name == t, orElse: () => AlertType.warning);
  KpiStatus _kpiStatus(String? s) => s == null ? KpiStatus.nominal : KpiStatus.values.firstWhere((e) => e.name == s, orElse: () => KpiStatus.nominal);

  IconData _iconFor(String name) {
    switch (name) {
      case 'bar_chart': return Icons.bar_chart;
      case 'inventory': return Icons.inventory;
      case 'group': return Icons.group;
      case 'shopping_cart': return Icons.shopping_cart;
      case 'notifications': return Icons.notifications;
      default: return Icons.circle;
    }
  }
}
