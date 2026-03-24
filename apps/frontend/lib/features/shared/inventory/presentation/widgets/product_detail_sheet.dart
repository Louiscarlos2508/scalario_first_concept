import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/shared/catalog/presentation/providers/catalog_providers.dart';
import 'package:frontend/features/shared/catalog/presentation/widgets/product_form_dialog.dart';
import 'package:frontend/features/shared/inventory/presentation/widgets/product_stock_card.dart';
import 'package:frontend/features/shared/inventory/presentation/widgets/stock_movement_list.dart';

final _fcfa = NumberFormat.currency(
  locale: 'fr_FR',
  symbol: 'FCFA',
  decimalDigits: 0,
);

class ProductDetailSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> item;
  final bool isOwner;

  const ProductDetailSheet({
    super.key,
    required this.item,
    required this.isOwner,
  });

  @override
  ConsumerState<ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends ConsumerState<ProductDetailSheet>
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
                onPressed: () =>
                    ref.invalidate(stockHistoryByItemProvider(id)),
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
                    StockMovementList(item: widget.item),
                    _ProductCard(
                      item: widget.item,
                      onEdit: () => _showEdit(context),
                    ),
                  ],
                )
              : StockMovementList(item: widget.item),
        ),
      ],
    );
  }

  void _showEdit(BuildContext context) {
    final product = productFromMap(widget.item);
    showDialog<void>(
      context: context,
      builder: (_) =>
          ProductFormDialog(submitToCatalog: true, product: product),
    ).then((_) => ref.invalidate(catalogProvider));
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onEdit;
  const _ProductCard({required this.item, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final price =
        (item['price'] is num) ? (item['price'] as num).toDouble() : 0.0;
    final barcode = item['barcode']?.toString();
    final category = item['categoryName']?.toString();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoRow(label: 'Prix', value: _fcfa.format(price)),
        if (barcode != null) _InfoRow(label: 'Code-barres', value: barcode),
        if (category != null) _InfoRow(label: 'Catégorie', value: category),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Modifier ce produit'),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
