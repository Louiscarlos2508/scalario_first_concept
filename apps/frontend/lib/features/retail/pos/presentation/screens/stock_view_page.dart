import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';

class StockViewPage extends ConsumerWidget {
  const StockViewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mon stock')),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (products) {
          if (products.isEmpty) {
            return const Center(
              child: Text(
                'Aucun produit trouvé',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, i) {
              final p = products[i];
              final qty = p.stockQuantity;
              final low = qty <= 5;
              return ListTile(
                title: Text(p.name),
                subtitle: p.barcode != null ? Text(p.barcode!) : null,
                trailing: Chip(
                  label: Text('$qty'),
                  backgroundColor: low
                      ? AppColors.error.withValues(alpha: 0.12)
                      : AppColors.success.withValues(alpha: 0.12),
                  labelStyle: TextStyle(
                    color: low ? AppColors.error : AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
