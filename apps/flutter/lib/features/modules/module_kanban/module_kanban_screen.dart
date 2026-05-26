import 'package:flutter/material.dart';

import '../../../l10n/s.dart';

class ModuleKanbanScreen extends StatelessWidget {
  const ModuleKanbanScreen({super.key, required this.config});
  final Map<String, dynamic> config;

  @override
  Widget build(BuildContext context) {
    final title = config['title'] as String? ?? S.of(context).moduleLivraisons;
    final columns = (config['columns_order'] as List?)?.cast<String>() ?? ['to_do', 'in_progress', 'done'];
    final columnLabels = (config['column_labels'] as Map?)?.cast<String, String>() ?? {};
    final cards = (config['cards'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: columns.map((col) {
            final colCards = cards.where((c) => c[config['column_field'] as String? ?? 'status'] == col).toList();
            return Container(
              width: 280,
              margin: const EdgeInsets.only(right: 12),
              child: Card(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(columnLabels[col] ?? col, style: Theme.of(context).textTheme.titleSmall),
                  ),
                  ...colCards.map((card) {
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(card['title'] as String? ?? '', style: Theme.of(context).textTheme.bodyMedium),
                          if (card['subtitle'] != null)
                            Text(card['subtitle'] as String, style: Theme.of(context).textTheme.bodySmall),
                        ]),
                      ),
                    );
                  }),
                  if (colCards.isEmpty)
                    const Padding(padding: EdgeInsets.all(32), child: Center(child: Icon(Icons.inbox, color: Colors.grey))),
                ]),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
