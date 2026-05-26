import 'package:flutter/material.dart';

import '../../../l10n/s.dart';

class ModuleDetailScreen extends StatelessWidget {
  const ModuleDetailScreen({super.key, required this.config});
  final Map<String, dynamic> config;

  @override
  Widget build(BuildContext context) {
    final title = config['title'] as String? ?? S.of(context).moduleVentes;
    final header = config['header_template'] as String?;
    final tabs = (config['tabs'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final fields = (config['fields'] as Map?)?.cast<String, dynamic>() ?? {};

    return DefaultTabController(
      length: tabs.length > 0 ? tabs.length : 1,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          bottom: tabs.isNotEmpty
              ? TabBar(tabs: tabs.map((t) => Tab(text: t['label'] as String? ?? '')).toList())
              : null,
        ),
        body: Column(
          children: [
            if (header != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Text(header.replaceAllMapped(RegExp(r'\$\{(\w+)\}'), (m) => fields[m.group(1)!]?.toString() ?? '')),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: fields.entries.map((e) => ListTile(
                  title: Text(e.key),
                  subtitle: Text(e.value?.toString() ?? '-'),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
