import 'package:flutter/material.dart';

import '../../../components/data_display/chart_bar.dart';
import '../../../l10n/s.dart';
import '../../../engine/canvas_registry/component_config.dart';

class ModuleReportScreen extends StatelessWidget {
  const ModuleReportScreen({super.key, required this.config});
  final Map<String, dynamic> config;

  @override
  Widget build(BuildContext context) {
    final title = config['title'] as String? ?? S.of(context).moduleRapports;
    final chartType = config['chart_type'] as String? ?? 'bar';
    final chartData = _parseData();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(icon: const Icon(Icons.picture_as_pdf), tooltip: 'PDF', onPressed: () {}),
          IconButton(icon: const Icon(Icons.download), tooltip: 'CSV', onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
            height: 250,
            child: ChartBar(title: title, data: chartData),
          ),
          const SizedBox(height: 16),
          Text('Resume', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final d in chartData)
            ListTile(title: Text(d.label), trailing: Text('${d.value}')),
        ]),
      ),
    );
  }

  List<ChartDataPoint> _parseData() {
    final raw = config['data'] as List?;
    if (raw == null) return [];
    return raw.map((d) {
      final m = d as Map;
      return ChartDataPoint(label: m['label'] as String, value: (m['value'] as num).toDouble());
    }).toList();
  }
}
