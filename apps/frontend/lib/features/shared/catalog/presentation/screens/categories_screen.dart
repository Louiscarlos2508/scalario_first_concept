import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/retail/pos/data/models/category.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/theme/app_theme.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: ScalarioAppBar(
        title: 'Catégories',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(categoriesProvider),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCategoryDialog(context, ref),
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(
              child: Text(
                'Aucune catégorie.\nAppuyez sur + pour en ajouter une.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
            );
          }
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return ListTile(
                title: Text(category.name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.error),
                  onPressed: () => _confirmDelete(context, ref, category),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur : $err')),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle catégorie'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nom de la catégorie'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final tenantId = ref.read(activeTenantProvider);
                if (tenantId != null) {
                  try {
                    await ref.read(categoryRepositoryProvider).createCategory(name, tenantId);
                    ref.invalidate(categoriesProvider);
                    if (context.mounted) { Navigator.pop(context); }
                  } catch (e) {
                    if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur : $e')),
                    ); }
                  }
                }
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la catégorie'),
        content: Text('Supprimer la catégorie "${category.name}" ? Les produits associés pourraient être affectés.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref.read(categoryRepositoryProvider).deleteCategory(category.remoteId);
                ref.invalidate(categoriesProvider);
                if (context.mounted) { Navigator.pop(context); }
              } catch (e) {
                if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur : $e')),
                ); }
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
