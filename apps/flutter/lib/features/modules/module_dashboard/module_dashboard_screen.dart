import 'package:flutter/material.dart';

import '../../../components/data_display/kpi_card.dart';
import '../../../components/data_display/scalario_data_table.dart';
import '../../../components/data_display/chart_bar.dart';
import '../../../components/feedback/alert_banner.dart';
import '../../../engine/canvas_registry/component_config.dart';
import '../../../l10n/s.dart';

class ModuleDashboardScreen extends StatelessWidget {
  const ModuleDashboardScreen({super.key, required this.config});
  final Map<String, dynamic> config;

  @override
  Widget build(BuildContext context) {
    final title = config['title'] as String? ?? S.of(context).navDashboard;
    final kpis = (config['kpis'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final alerts = (config['alerts'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final alert in alerts)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AlertBanner(
                type: _parseAlertType(alert['type'] as String? ?? 'info'),
                message: alert['message'] as String? ?? '',
              ),
            ),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: kpis.map((kpi) => SizedBox(
              width: 180,
              child: KPICard(
                label: kpi['label'] as String? ?? '',
                value: '${kpi['value'] ?? ''}',
                unit: kpi['unit'] as String?,
                status: _parseKpiStatus(kpi['status'] as String?),
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),
          if (config['chart_data'] != null)
            SizedBox(
              height: 200,
              child: ChartBar(
                title: config['chart_title'] as String? ?? '',
                data: _parseChartData(config['chart_data'] as List),
              ),
            ),
        ]),
      ),
    );
  }

  AlertType _parseAlertType(String raw) {
    return AlertType.values.firstWhere((e) => e.name == raw, orElse: () => AlertType.info);
  }

  KpiStatus _parseKpiStatus(String? raw) {
    if (raw == null) return KpiStatus.nominal;
    return KpiStatus.values.firstWhere((e) => e.name == raw, orElse: () => KpiStatus.nominal);
  }

  List<ChartDataPoint> _parseChartData(List raw) {
    return raw.map((d) {
      final m = d as Map;
      return ChartDataPoint(label: m['label'] as String, value: (m['value'] as num).toDouble());
    }).toList();
  }
}
