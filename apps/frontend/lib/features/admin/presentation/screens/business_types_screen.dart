import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_providers.dart';
import '../../data/models/business_type_summary.dart';

class BusinessTypesScreen extends ConsumerWidget {
  const BusinessTypesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typesAsync = ref.watch(businessTypesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Types de business')),
      body: typesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Erreur : $e')),
        data: (types) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: types.length,
          separatorBuilder: (_, i) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final type = types[index];
            return ListTile(
              leading: type.icon != null
                  ? Text(type.icon!, style: const TextStyle(fontSize: 24))
                  : const Icon(Icons.store_outlined),
              title: Text(type.name),
              subtitle: Text(
                '${type.suggestedCategories.length} catégories suggérées',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showDetail(context, type),
            );
          },
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, BusinessTypeSummary type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (ctx, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          children: [
            Text(type.name,
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Code : ${type.code}',
                style: Theme.of(ctx).textTheme.bodySmall),
            const SizedBox(height: 16),
            if (type.suggestedCategories.isNotEmpty) ...[
              Text('Catégories suggérées',
                  style: Theme.of(ctx).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: type.suggestedCategories
                    .map((c) => Chip(label: Text(c)))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],
            if ((type.defaultFlags).isNotEmpty) ...[
              Text('Flags par défaut',
                  style: Theme.of(ctx).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: type.defaultFlags.entries
                    .map((e) => Chip(
                          label: Text('${e.key}: ${e.value}'),
                          backgroundColor:
                              Theme.of(ctx).colorScheme.secondaryContainer,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
