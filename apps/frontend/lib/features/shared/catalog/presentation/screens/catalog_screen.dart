import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';
import 'package:frontend/features/shared/catalog/presentation/providers/catalog_providers.dart';
import 'package:frontend/features/shared/catalog/presentation/screens/categories_screen.dart';
import 'package:frontend/features/shared/catalog/presentation/widgets/product_form_dialog.dart';
import 'package:frontend/features/shared/inventory/presentation/screens/stock_history_screen.dart';
import 'package:frontend/features/shared/inventory/presentation/widgets/stock_adjustment_dialog.dart';
import 'package:frontend/features/retail/pos/data/models/product.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/core/auth/auth_state.dart';

final _fcfa = NumberFormat.currency(
  locale: 'fr_FR',
  symbol: 'FCFA',
  decimalDigits: 0,
);

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  // ── Build ──────────────────────────────────────────────────────────────────

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
          child: Text(
            'Erreur : $err',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              key: Key('catalog_empty_state'),
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
              return _CatalogItemTile(
                key: Key('catalog_item_$id'),
                item: item,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StockHistoryScreen(
                      catalogItemId: id,
                      productName: item['name']?.toString(),
                    ),
                  ),
                ),
                onMenuTap: () => _showMenu(context, ref, item),
                onConfirmDismiss: () => _confirmDismiss(context, item),
                onDismissed: () => _doDelete(context, ref, item),
              );
            },
          );
        },
      ),
    );
  }

  // ── ⋮ Bottom sheet — 3 actions ────────────────────────────────────────────

  void _showMenu(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> item,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('catalog_action_edit'),
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Modifier'),
              onTap: () {
                Navigator.pop(ctx);
                _showEditDialog(context, ref, item);
              },
            ),
            ListTile(
              key: const Key('catalog_action_adjust'),
              leading: const Icon(Icons.tune),
              title: const Text('Ajuster le stock'),
              onTap: () {
                Navigator.pop(ctx);
                _showAdjust(context, ref, item);
              },
            ),
            ListTile(
              key: const Key('catalog_action_delete'),
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text(
                'Supprimer',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteFromMenu(context, ref, item);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Dismissible helpers ───────────────────────────────────────────────────

  /// Shows a confirmation dialog; returns true if the user confirms.
  Future<bool?> _confirmDismiss(
    BuildContext context,
    Map<String, dynamic> item,
  ) {
    final name = item['name']?.toString() ?? 'ce produit';
    return showDialog<bool>(
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
  }

  /// Performs the actual deletion (called from Dismissible.onDismissed and
  /// from the menu flow after confirmation).
  Future<void> _doDelete(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> item,
  ) async {
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
          const SnackBar(
            key: Key('snackbar_product_deleted'),
            content: Text('Produit supprimé'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            key: const Key('snackbar_product_error'),
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Menu → Supprimer: shows confirmation, then deletes if confirmed.
  Future<void> _confirmDeleteFromMenu(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> item,
  ) async {
    final confirmed = await _confirmDismiss(context, item);
    if (confirmed != true) return;
    await _doDelete(context, ref, item);
  }

  // ── Edit dialog ───────────────────────────────────────────────────────────

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> item,
  ) {
    final product = Product()
      ..remoteId = item['id']?.toString()
      ..name = item['name']?.toString() ?? ''
      ..price = (item['price'] is num) ? (item['price'] as num).toDouble() : 0.0
      ..barcode = item['barcode']?.toString()
      ..categoryId = item['categoryId']?.toString()
      ..minStockLevel = (item['minStockLevel'] is num)
          ? (item['minStockLevel'] as num).toDouble()
          : null;

    showDialog<void>(
      context: context,
      builder: (_) =>
          ProductFormDialog(submitToCatalog: true, product: product),
    );
  }

  // ── Stock adjustment ──────────────────────────────────────────────────────

  Future<void> _showAdjust(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> item,
  ) async {
    final product = Product()
      ..remoteId = item['id']?.toString()
      ..name = item['name']?.toString() ?? '';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => StockAdjustmentDialog(product: product),
    );

    if (result != null && product.remoteId != null) {
      try {
        await ref
            .read(productRepositoryProvider)
            .adjustStock(
              productId: product.remoteId!,
              quantity: result['quantity'],
              type: result['type'],
              reason: result['reason'],
            );
        ref.invalidate(catalogProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Stock ajusté')));
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
}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _CatalogItemTile extends StatelessWidget {
  final Map<String, dynamic> item;

  /// Primary tap — navigates to StockHistoryScreen.
  final VoidCallback onTap;

  /// ⋮ button tap — opens the action bottom sheet.
  final VoidCallback onMenuTap;

  /// Called by [Dismissible.confirmDismiss]; returns true to proceed.
  final Future<bool?> Function() onConfirmDismiss;

  /// Called by [Dismissible.onDismissed] — performs the delete.
  final VoidCallback onDismissed;

  const _CatalogItemTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onMenuTap,
    required this.onConfirmDismiss,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final id = item['id']?.toString() ?? '';
    final name = item['name']?.toString() ?? '';
    final price = (item['price'] is num)
        ? (item['price'] as num).toDouble()
        : 0.0;
    final stock = (item['stockQuantity'] is num)
        ? (item['stockQuantity'] as num).toDouble()
        : 0.0;
    final minStockLevel = (item['minStockLevel'] is num)
        ? (item['minStockLevel'] as num).toDouble()
        : null;
    final isCritical = minStockLevel != null && stock <= minStockLevel;
    final lowStock = isCritical || stock <= 5;

    return Dismissible(
      key: Key('dismissible_$id'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) => onConfirmDismiss(),
      onDismissed: (_) => onDismissed(),
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.only(
            left: 20,
            right: 4,
            top: 4,
            bottom: 4,
          ),
          onTap: onTap,
          leading: const CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Icon(
              Icons.shopping_bag_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          title: Text(
            name,
            style: AppTextStyles.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(_fcfa.format(price), style: AppTextStyles.bodySmall),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCritical)
                Tooltip(
                  message: 'Stock critique : ${stock.toStringAsFixed(stock.truncateToDouble() == stock ? 0 : 1)} restants',
                  child: const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                      size: 20,
                    ),
                  ),
                ),
              // Stock badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: lowStock
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  stock.truncateToDouble() == stock
                      ? '${stock.toInt()}'
                      : stock.toStringAsFixed(1),
                  style: TextStyle(
                    color: lowStock ? AppColors.error : AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // ⋮ menu — 48×48 touch target (loi de Fitts)
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  key: Key('catalog_menu_$id'),
                  icon: const Icon(Icons.more_vert),
                  onPressed: onMenuTap,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
