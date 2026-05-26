import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './module_dashboard/module_dashboard_screen.dart';
import './module_list/module_list_screen.dart';
import './module_form/module_form_screen.dart';
import './module_detail/module_detail_screen.dart';
import './module_report/module_report_screen.dart';
import './module_kanban/module_kanban_screen.dart';

class CatalogScreen extends StatelessWidget {
  final String jsonAssetPath;
  const CatalogScreen({super.key, required this.jsonAssetPath});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: rootBundle.loadStructuredData<Map<String, dynamic>>(jsonAssetPath, (raw) async => jsonDecode(raw) as Map<String, dynamic>),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final data = snapshot.data!;
        final config = data['config'] as Map<String, dynamic>? ?? data;
        final engine = data['engine'] as String? ?? 'ModuleDashboard';

        return switch (engine) {
          'ModuleDashboard' => ModuleDashboardScreen(config: config),
          'ModuleList' => ModuleListScreen(config: config),
          'ModuleForm' => ModuleFormScreen(config: config),
          'ModuleDetail' => ModuleDetailScreen(config: config),
          'ModuleReport' => ModuleReportScreen(config: config),
          'ModuleKanban' => ModuleKanbanScreen(config: config),
          _ => ModuleDashboardScreen(config: config),
        };
      },
    );
  }
}
