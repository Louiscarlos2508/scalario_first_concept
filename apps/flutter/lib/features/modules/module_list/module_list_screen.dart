import 'package:flutter/material.dart';

import '../../../components/data_display/scalario_data_table.dart';
import '../../../engine/canvas_registry/component_config.dart';
import '../../../engine/canvas_registry/scalario_canvas_resolver.dart';
import '../../../l10n/s.dart';

class ModuleListScreen extends StatelessWidget {
  const ModuleListScreen({super.key, required this.config});
  final Map<String, dynamic> config;

  @override
  Widget build(BuildContext context) {
    final title = config['title'] as String? ?? S.of(context).moduleCommandes;
    final columns = (config['columns'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final rows = _buildRows();

    final dataColumns = columns.map((c) {
      final key = c['key'] as String;
      return DataColumnConfig<Map<String, String>>(
        key: key, label: c['label'] as String? ?? key,
        cellBuilder: (row) => row[key] ?? '',
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(title), actions: [
        if (config['can_create'] == true)
          IconButton(icon: const Icon(Icons.add), onPressed: () {}),
        IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
      ]),
      body: rows.isEmpty
          ? Center(child: Text(S.of(context).emptyList))
          : ScalarioDataTable<Map<String, String>>(
              columns: dataColumns, rows: rows, defaultSortKey: dataColumns.isNotEmpty ? dataColumns.first.key : '',
            ),
    );
  }

  List<Map<String, String>> _buildRows() {
    final raw = config['sample_data'] as List?;
    if (raw == null) return [];
    return raw.map((r) => (r as Map).map((k, v) => MapEntry(k.toString(), v.toString()))).toList();
  }
}
