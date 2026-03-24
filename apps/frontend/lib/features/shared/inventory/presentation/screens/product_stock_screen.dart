import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';
import 'package:frontend/features/shared/catalog/presentation/providers/catalog_providers.dart';
import 'package:frontend/features/shared/catalog/presentation/screens/categories_screen.dart';
import 'package:frontend/features/shared/catalog/presentation/widgets/product_form_dialog.dart';
import 'package:frontend/features/shared/freshness/presentation/providers/freshness_provider.dart';
import 'package:frontend/features/shared/inventory/presentation/widgets/action_chips_row.dart';
import 'package:frontend/features/shared/inventory/presentation/widgets/product_detail_sheet.dart';
import 'package:frontend/features/shared/inventory/presentation/widgets/product_stock_card.dart';
import 'package:frontend/features/shared/inventory/presentation/widgets/stock_summary_row.dart';

class ProductStockScreen extends ConsumerStatefulWidget {
  const ProductStockScreen({super.key});

  @override
  ConsumerState<ProductStockScreen> createState() =>
      _ProductStockScreenState();
}

class _ProductStockScreenState extends ConsumerState<ProductStockScreen> {
  final _searchController = TextEditingController();
  String _search = '';
  String? _activeFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> items) {
    List<Map<String, dynamic>> result = items;
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      result = result
          .where(
              (p) => (p['name']?.toString() ?? '').toLowerCase().contains(q))
          .toList();
    }
    if (_activeFilter == 'low_stock') {
      result = result.where((p) {
        final minStock = p['minStockLevel'];
        if (minStock == null) return false;
        final stock = (p['stockQuantity'] as num?)?.toDouble() ?? 0.0;
        return stock < (minStock as num).toDouble();
      }).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(userProfileProvider).valueOrNull?.role ?? '';
    final isOwner = role == 'owner';
    final itemsAsync = ref.watch(catalogProvider);
    final lowStockCount = ref.watch(lowStockCountProvider).valueOrNull ?? 0;
    final expiringCount =
        ref.watch(urgentBatchCountProvider).valueOrNull ?? 0;

    return Scaffold(
      appBar: ScalarioAppBar(
        title: 'Produits & Stock',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: () => ref.invalidate(catalogProvider),
          ),
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.category_outlined),
              tooltip: 'Catégories',
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                showDragHandle: true,
                builder: (_) => FractionallySizedBox(
                  heightFactor: 0.85,
                  child: const CategoriesScreen(embedded: true),
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: isOwner
          ? FloatingActionButton(
              heroTag: 'inventory_fab',
              tooltip: 'Nouveau produit',
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) =>
                    const ProductFormDialog(submitToCatalog: true),
              ).then((_) => ref.invalidate(catalogProvider)),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StockSummaryRow(
            totalCount: itemsAsync.valueOrNull?.length ?? 0,
            lowStockCount: lowStockCount,
            expiringCount: expiringCount,
            activeFilter: _activeFilter,
            onTapLowStock: () => setState(
              () => _activeFilter =
                  _activeFilter == 'low_stock' ? null : 'low_stock',
            ),
            onTapExpiring: () => openFreshnessSheet(context),
          ),
          const StockActionChipsRow(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Rechercher un produit...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Expanded(
            child: itemsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text(
                  'Erreur : $err',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
              data: (items) {
                final filtered = _applyFilter(items);
                if (filtered.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Aucun produit',
                          style:
                              TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(catalogProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final item = filtered[i];
                      final id = item['id']?.toString() ?? '$i';
                      return ProductStockCard(
                        key: Key('inv_product_$id'),
                        item: item,
                        isOwner: isOwner,
                        onTap: () => showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (_) => FractionallySizedBox(
                            heightFactor: 0.90,
                            child: ProductDetailSheet(
                              item: item,
                              isOwner: isOwner,
                            ),
                          ),
                        ).then((_) => ref.invalidate(catalogProvider)),
                        onMenuTap: isOwner
                            ? () => _showOwnerMenu(context, item)
                            : null,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showOwnerMenu(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Modifier'),
              onTap: () {
                Navigator.pop(ctx);
                _showEditDialog(context, item);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text(
                'Supprimer',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context, item);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Map<String, dynamic> item) {
    final product = productFromMap(item);
    showDialog<void>(
      context: context,
      builder: (_) =>
          ProductFormDialog(submitToCatalog: true, product: product),
    ).then((_) => ref.invalidate(catalogProvider));
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Map<String, dynamic> item,
  ) async {
    final name = item['name']?.toString() ?? 'ce produit';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le produit ?'),
        content: Text('Supprimer "$name" définitivement ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final id = item['id']?.toString();
    if (id == null) return;
    final tenantId = ref.read(activeTenantProvider);
    if (tenantId == null) return;
    try {
      await ref
          .read(catalogRepositoryProvider)
          .deleteItem(id: id, tenantId: tenantId);
      ref.invalidate(catalogProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produit supprimé')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
