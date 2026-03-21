import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/retail/pos/data/models/product.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/shared/catalog/presentation/providers/catalog_providers.dart';
import 'package:frontend/features/shared/catalog/presentation/widgets/product_form_dialog.dart';
import 'package:frontend/features/shared/inventory/presentation/widgets/delivery_form.dart';
import 'package:frontend/features/shared/inventory/presentation/widgets/transfer_out_form.dart';
import 'package:frontend/features/shared/inventory/presentation/widgets/transfer_pending_screen.dart';
import 'package:frontend/features/shared/inventory/presentation/widgets/loss_declaration_form.dart';
import 'package:frontend/features/shared/inventory/presentation/screens/partial_inventory_screen.dart';
import 'package:frontend/features/shared/freshness/presentation/providers/freshness_provider.dart';
import 'package:frontend/features/shared/freshness/presentation/screens/freshness_screen.dart';
import 'package:frontend/features/shared/catalog/presentation/screens/categories_screen.dart';

final _fcfa = NumberFormat.currency(
  locale: 'fr_FR',
  symbol: 'FCFA',
  decimalDigits: 0,
);

// ── Main screen ───────────────────────────────────────────────────────────────

class InventoryScreen extends ConsumerStatefulWidget {
  // ignore: avoid_unused_constructor_parameters
  const InventoryScreen({super.key, int initialIndex = 0});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchController = TextEditingController();
  String _search = '';
  String? _activeFilter; // null | 'low_stock'

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
          .where((p) => (p['name']?.toString() ?? '').toLowerCase().contains(q))
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

  void _toggleFilter(String filter) {
    setState(() => _activeFilter = _activeFilter == filter ? null : filter);
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(userProfileProvider).valueOrNull?.role ?? '';
    final isOwner = role == 'owner';
    final canAct = isOwner || role == 'manager';
    final itemsAsync = ref.watch(catalogProvider);
    final lowStockCount = ref.watch(lowStockCountProvider).valueOrNull ?? 0;
    final expiringCount = ref.watch(urgentBatchCountProvider).valueOrNull ?? 0;
    final repo = ref.watch(inventoryRepositoryProvider);

    return Scaffold(
      appBar: ScalarioAppBar(
        title: 'Produits & Stock',
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.category_outlined),
              tooltip: 'Catégories',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoriesScreen()),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: () => ref.invalidate(catalogProvider),
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
                builder: (_) => const ProductFormDialog(submitToCatalog: true),
              ).then((_) => ref.invalidate(catalogProvider)),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Zone 1 — Summary stats
          _SummaryRow(
            totalCount: itemsAsync.valueOrNull?.length ?? 0,
            lowStockCount: lowStockCount,
            expiringCount: expiringCount,
            activeFilter: _activeFilter,
            onTapLowStock: () => _toggleFilter('low_stock'),
            onTapExpiring: () => _openFreshnessSheet(context),
          ),
          // Zone 2 — Action chips (owner + manager)
          if (canAct) _ActionChipsRow(repo: repo),
          // Zone 3 — Search + product list
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
              loading: () => const Center(child: CircularProgressIndicator()),
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
                          style: TextStyle(color: AppColors.textSecondary),
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
                      return _ProductTile(
                        key: Key('inv_product_$id'),
                        item: item,
                        isOwner: isOwner,
                        onTap: () => showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (_) => FractionallySizedBox(
                            heightFactor: 0.90,
                            child: _ProductDetailPage(
                              item: item,
                              isOwner: isOwner,
                            ),
                          ),
                        ).then((_) => ref.invalidate(catalogProvider)),
                        onMenuTap: isOwner
                            ? () => _showOwnerMenu(context, ref, item)
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

  // ── Owner context menu ────────────────────────────────────────────────────

  void _showOwnerMenu(
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
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Modifier'),
              onTap: () {
                Navigator.pop(ctx);
                _showEditDialog(context, ref, item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text(
                'Supprimer',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context, ref, item);
              },
            ),
          ],
        ),
      ),
    );
  }

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
    ).then((_) => ref.invalidate(catalogProvider));
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Produit supprimé')));
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

// ── Zone 1: Summary row ───────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final int totalCount;
  final int lowStockCount;
  final int expiringCount;
  final String? activeFilter;
  final VoidCallback onTapLowStock;
  final VoidCallback onTapExpiring;

  const _SummaryRow({
    required this.totalCount,
    required this.lowStockCount,
    required this.expiringCount,
    required this.activeFilter,
    required this.onTapLowStock,
    required this.onTapExpiring,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.inventory_2_outlined,
              count: totalCount,
              label: 'produits',
              color: AppColors.primary,
              isActive: activeFilter == null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              icon: Icons.warning_amber_rounded,
              count: lowStockCount,
              label: 'stock bas',
              color: lowStockCount > 0
                  ? AppColors.warning
                  : AppColors.textSecondary,
              isActive: activeFilter == 'low_stock',
              onTap: onTapLowStock,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              icon: Icons.eco_outlined,
              count: expiringCount,
              label: 'expirent',
              color: expiringCount > 0
                  ? AppColors.error
                  : AppColors.textSecondary,
              onTap: onTapExpiring,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.15)
              : color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color : color.withValues(alpha: 0.35),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Zone 2: Action chips ──────────────────────────────────────────────────────

void _openFreshnessSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.90,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Fraîcheur',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const Expanded(child: FreshnessScreen()),
        ],
      ),
    ),
  );
}

class _ActionChipsRow extends ConsumerWidget {
  final dynamic repo;

  const _ActionChipsRow({required this.repo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ActionChip(
              icon: Icons.local_shipping_outlined,
              label: 'Réceptionner',
              onTap: () =>
                  _openSheet(context, child: DeliveryForm(repository: repo)),
            ),
            const SizedBox(width: 8),
            _ActionChip(
              icon: Icons.swap_horiz_outlined,
              label: 'Transférer',
              onTap: () => _openSheet(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TransferOutForm(repository: repo),
                    const SizedBox(height: 16),
                    TransferPendingScreen(repository: repo),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _ActionChip(
              icon: Icons.remove_circle_outline,
              label: 'Déclarer perte',
              onTap: () => _openSheet(
                context,
                child: LossDeclarationForm(repository: repo),
              ),
            ),
            const SizedBox(width: 8),
            _ActionChip(
              icon: Icons.fact_check_outlined,
              label: 'Comptage',
              onTap: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => FractionallySizedBox(
                  heightFactor: 0.90,
                  child: PartialInventoryScreen(
                      repository: repo, embedded: true),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _ActionChip(
              icon: Icons.eco_outlined,
              label: 'Fraîcheur',
              onTap: () => _openFreshnessSheet(context),
            ),
          ],
        ),
      ),
    );
  }

  void _openSheet(BuildContext context, {required Widget child}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.95,
        builder: (_, sc) => ListView(
          controller: sc,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

// ── Zone 3: Product tile ──────────────────────────────────────────────────────

class _ProductTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isOwner;
  final VoidCallback onTap;
  final VoidCallback? onMenuTap;

  const _ProductTile({
    super.key,
    required this.item,
    required this.isOwner,
    required this.onTap,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = item['name']?.toString() ?? '';
    final price = (item['price'] is num)
        ? (item['price'] as num).toDouble()
        : 0.0;
    final stock = (item['stockQuantity'] is num)
        ? (item['stockQuantity'] as num).toDouble()
        : 0.0;
    final minStock = (item['minStockLevel'] is num)
        ? (item['minStockLevel'] as num).toDouble()
        : null;
    final unitType = item['unitType']?.toString() ?? 'piece';
    final unit = item['weightUnit']?.toString() ?? unitType;
    final expiryDays = item['expiryDays'] as int?;

    final isRupture = stock <= 0;
    final isLowStock = !isRupture && minStock != null && stock < minStock;
    final couldExpire = expiryDays != null;

    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    if (isRupture) {
      statusColor = AppColors.error;
      statusIcon = Icons.block;
      statusLabel = 'Rupture';
    } else if (isLowStock) {
      statusColor = AppColors.warning;
      statusIcon = Icons.warning_amber_rounded;
      statusLabel = 'Stock bas';
    } else if (couldExpire) {
      statusColor = Colors.amber.shade700;
      statusIcon = Icons.eco_outlined;
      statusLabel = 'Fraîcheur';
    } else {
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle_outline;
      statusLabel = 'OK';
    }

    final stockLabel = unitType == 'piece'
        ? stock.toStringAsFixed(stock.truncateToDouble() == stock ? 0 : 1)
        : '${stock.toStringAsFixed(stock.truncateToDouble() == stock ? 0 : 1)} $unit';

    final priceLabel = unitType == 'piece'
        ? _fcfa.format(price)
        : '${_fcfa.format(price)}/$unit';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.only(
          left: 16,
          right: 4,
          top: 2,
          bottom: 2,
        ),
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.15),
          child: Icon(statusIcon, color: statusColor, size: 20),
        ),
        title: Text(
          name,
          style: AppTextStyles.bodyMedium,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(priceLabel, style: AppTextStyles.bodySmall),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  stockLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isRupture
                        ? AppColors.error
                        : isLowStock
                        ? AppColors.warning
                        : AppColors.success,
                    fontSize: 13,
                  ),
                ),
                Text(
                  statusLabel,
                  style: TextStyle(fontSize: 11, color: statusColor),
                ),
              ],
            ),
            if (onMenuTap != null)
              SizedBox(
                width: 40,
                child: IconButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onPressed: onMenuTap,
                  padding: EdgeInsets.zero,
                ),
              )
            else
              const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

// ── Product detail page ───────────────────────────────────────────────────────

class _ProductDetailPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> item;
  final bool isOwner;

  const _ProductDetailPage({required this.item, required this.isOwner});

  @override
  ConsumerState<_ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<_ProductDetailPage>
    with SingleTickerProviderStateMixin {
  TabController? _tabCtrl;

  @override
  void initState() {
    super.initState();
    if (widget.isOwner) {
      _tabCtrl = TabController(length: 2, vsync: this);
    }
  }

  @override
  void dispose() {
    _tabCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.item['name']?.toString() ?? 'Produit';
    final id = widget.item['id']?.toString() ?? '';

    return Column(
      children: [
        // Drag handle
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        // Title row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 4, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.isOwner)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Modifier',
                  onPressed: () => _showEdit(context),
                ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Actualiser',
                onPressed: () => ref.invalidate(stockHistoryByItemProvider(id)),
              ),
            ],
          ),
        ),
        if (widget.isOwner)
          TabBar(
            controller: _tabCtrl,
            tabs: const [Tab(text: 'Stock'), Tab(text: 'Fiche produit')],
          ),
        const Divider(height: 1),
        Expanded(
          child: widget.isOwner
              ? TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _StockSection(item: widget.item),
                    _ProductCard(
                      item: widget.item,
                      onEdit: () => _showEdit(context),
                    ),
                  ],
                )
              : _StockSection(item: widget.item),
        ),
      ],
    );
  }

  void _showEdit(BuildContext context) {
    final item = widget.item;
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
    ).then((_) {
      if (mounted) ref.invalidate(catalogProvider);
    });
  }
}

// ── Stock section ─────────────────────────────────────────────────────────────

class _StockSection extends ConsumerWidget {
  final Map<String, dynamic> item;

  const _StockSection({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = item['id']?.toString() ?? '';
    final stock = (item['stockQuantity'] is num)
        ? (item['stockQuantity'] as num).toDouble()
        : 0.0;
    final minStock = (item['minStockLevel'] is num)
        ? (item['minStockLevel'] as num).toDouble()
        : null;
    final unitType = item['unitType']?.toString() ?? 'piece';
    final unit = item['weightUnit']?.toString() ?? unitType;
    final expiryDays = item['expiryDays'] as int?;

    final isRupture = stock <= 0;
    final isLowStock = !isRupture && minStock != null && stock < minStock;

    final stockColor = isRupture
        ? AppColors.error
        : isLowStock
        ? AppColors.warning
        : AppColors.success;

    final stockStr = unitType == 'piece'
        ? stock.toStringAsFixed(stock.truncateToDouble() == stock ? 0 : 1)
        : '${stock.toStringAsFixed(stock.truncateToDouble() == stock ? 0 : 1)} $unit';

    final movementsAsync = ref.watch(stockHistoryByItemProvider(id));
    final dateRange = ref.watch(stockHistoryDateRangeProvider);
    final fmt = DateFormat('dd/MM/yy');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Current stock card
        Card(
          color: stockColor.withValues(alpha: 0.07),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: stockColor.withValues(alpha: 0.4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stock actuel',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isRupture ? 'Rupture de stock' : stockStr,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: stockColor,
                  ),
                ),
                if (minStock != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Seuil alerte : ${minStock.toStringAsFixed(0)} $unit',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
                if (expiryDays != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Fraîcheur : $expiryDays jours',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Movements header + date filter
        Row(
          children: [
            const Text(
              'Mouvements',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            if (dateRange != null)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: InputChip(
                  label: Text(
                    '${fmt.format(dateRange.start)} – ${fmt.format(dateRange.end)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onDeleted: () {
                    ref.read(stockHistoryDateRangeProvider.notifier).state =
                        null;
                  },
                ),
              ),
            IconButton(
              icon: Icon(
                Icons.filter_list,
                color: dateRange != null
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              tooltip: 'Filtrer par date',
              onPressed: () async {
                final now = DateTime.now();
                final start = await showDatePicker(
                  context: context,
                  initialDate: dateRange?.start ?? now,
                  firstDate: DateTime(2020),
                  lastDate: now,
                  helpText: 'Date de début',
                );
                if (start == null || !context.mounted) return;
                final end = await showDatePicker(
                  context: context,
                  initialDate:
                      dateRange?.end != null && dateRange!.end.isAfter(start)
                          ? dateRange.end
                          : start,
                  firstDate: start,
                  lastDate: now,
                  helpText: 'Date de fin',
                );
                if (end == null) return;
                ref.read(stockHistoryDateRangeProvider.notifier).state =
                    DateTimeRange(start: start, end: end);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        movementsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => Text(
            'Erreur : $err',
            style: const TextStyle(color: AppColors.error),
          ),
          data: (movements) {
            if (movements.isEmpty) {
              return const Text(
                'Aucun mouvement enregistré',
                style: TextStyle(color: AppColors.textSecondary),
              );
            }
            final list =
                dateRange != null ? movements : movements.take(20).toList();
            return Column(
              children: list
                  .map((m) => _MovementTile(m: m as Map<String, dynamic>))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _MovementTile extends StatelessWidget {
  final Map<String, dynamic> m;

  const _MovementTile({required this.m});

  @override
  Widget build(BuildContext context) {
    final type = m['type']?.toString() ?? '';
    final rawQty = m['quantity'];
    final qty = rawQty is num
        ? rawQty.toDouble()
        : double.tryParse(rawQty?.toString() ?? '') ?? 0;
    final reason = m['reason']?.toString();
    final createdAt = m['createdAt']?.toString();
    final date = createdAt != null ? DateTime.tryParse(createdAt) : null;
    final dateStr = date != null
        ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}h${date.minute.toString().padLeft(2, '0')}'
        : '—';

    final isPositive =
        type == 'DELIVERY' || type == 'TRANSFER_IN' || type == 'ADJUSTMENT';
    final sign = isPositive ? '+' : '−';
    final color = isPositive ? AppColors.success : AppColors.error;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _typeLabel(type),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (reason != null && reason.isNotEmpty)
                  Text(
                    reason,
                    style: AppTextStyles.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            '$sign${qty.toStringAsFixed(qty.truncateToDouble() == qty ? 0 : 1)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            dateStr,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'DELIVERY':
        return 'Réception';
      case 'SALE':
        return 'Vente';
      case 'LOSS':
        return 'Perte';
      case 'TRANSFER_OUT':
        return 'Transfert sortant';
      case 'TRANSFER_IN':
        return 'Transfert entrant';
      case 'ADJUSTMENT':
        return 'Ajustement';
      default:
        return type;
    }
  }
}

// ── Product card (owner only) ─────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onEdit;

  const _ProductCard({required this.item, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final price = (item['price'] is num)
        ? (item['price'] as num).toDouble()
        : 0.0;
    final unitType = item['unitType']?.toString() ?? 'piece';
    final unit = item['weightUnit']?.toString() ?? unitType;
    final barcode = item['barcode']?.toString();
    final expiryDays = item['expiryDays'] as int?;
    final minStock = item['minStockLevel'];
    final hasVariants = item['hasVariants'] == true;
    final trackSN = item['trackSerialNumbers'] == true;
    final dynamicPricing = item['dynamicPricing'] == true;

    final priceLabel = unitType == 'piece'
        ? _fcfa.format(price)
        : '${_fcfa.format(price)}/$unit';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(label: 'Prix', value: priceLabel),
                _InfoRow(label: 'Unité', value: unit),
                if (barcode != null)
                  _InfoRow(label: 'Code-barres', value: barcode),
                if (minStock != null)
                  _InfoRow(
                    label: 'Seuil alerte',
                    value:
                        '${(minStock as num).toDouble().toStringAsFixed(0)} $unit',
                  ),
                if (expiryDays != null)
                  _InfoRow(label: 'Fraîcheur', value: '$expiryDays jours'),
                if (hasVariants) _InfoRow(label: 'Variantes', value: 'Oui'),
                if (trackSN) _InfoRow(label: 'N° de série', value: 'Activé'),
                if (dynamicPricing)
                  _InfoRow(label: 'Prix dynamique', value: 'Activé'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Modifier ce produit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: onEdit,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
