import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';
import 'package:frontend/features/retail/catalog/presentation/providers/catalog_providers.dart';
import 'package:frontend/features/retail/catalog/presentation/screens/categories_screen.dart';
import 'package:frontend/features/retail/catalog/presentation/widgets/product_form_dialog.dart';

final _fcfa = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(catalogProvider);

    return Scaffold(
      appBar: ScalarioAppBar(
        title: 'Catalogue',
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Gérer les catégories',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CategoriesScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(catalogProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('catalog_fab'),
        heroTag: null,
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => const ProductFormDialog(submitToCatalog: true),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Erreur : $err', style: const TextStyle(color: AppColors.error)),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              key: Key('catalog_empty_state'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textSecondary),
                  SizedBox(height: 12),
                  Text(
                    'Aucun produit dans le catalogue',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final id = item['id']?.toString() ?? '$index';
              return _CatalogItemTile(key: Key('catalog_item_$id'), item: item);
            },
          );
        },
      ),
    );
  }
}

class _CatalogItemTile extends StatelessWidget {
  final Map<String, dynamic> item;

  const _CatalogItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final name = item['name']?.toString() ?? '';
    final price = (item['price'] is num) ? (item['price'] as num).toDouble() : 0.0;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: const CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
        ),
        title: Text(name, style: AppTextStyles.bodyMedium, overflow: TextOverflow.ellipsis),
        trailing: Text(
          _fcfa.format(price),
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
