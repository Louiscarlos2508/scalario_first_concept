import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';
import 'package:frontend/features/retail/inventory/data/models/inventory_movement_local.dart';
import 'package:frontend/features/retail/inventory/data/repositories/inventory_repository.dart';
import 'package:frontend/features/retail/pos/data/models/product.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';

// ─── Phase enum ──────────────────────────────────────────────────────────────

enum _Phase { selection, counting }

// ─── Screen ──────────────────────────────────────────────────────────────────

class PartialInventoryScreen extends ConsumerStatefulWidget {
  final InventoryRepository repository;

  /// When [embedded] is true (used as a tab inside InventoryScreen), the
  /// Scaffold/AppBar wrapper is omitted to avoid a double AppBar.
  final bool embedded;

  const PartialInventoryScreen({
    super.key,
    required this.repository,
    this.embedded = false,
  });

  @override
  ConsumerState<PartialInventoryScreen> createState() =>
      _PartialInventoryScreenState();
}

class _PartialInventoryScreenState
    extends ConsumerState<PartialInventoryScreen> {
  _Phase _phase = _Phase.selection;

  // ── Selection phase state ──
  final Set<String> _selectedIds = {};
  String _searchQuery = '';

  // ── Counting phase state ──
  // productId → counted quantity (null = not yet entered)
  final Map<String, int?> _counted = {};
  // productId → system stock loaded from API
  final Map<String, int?> _systemStock = {};
  final Map<String, bool> _loadingStock = {};
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  List<Product> _filteredProducts(List<Product> all) {
    if (_searchQuery.isEmpty) return all;
    final q = _searchQuery.toLowerCase();
    return all.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  bool get _hasAnyVariance {
    for (final id in _selectedIds) {
      final counted = _counted[id];
      final system = _systemStock[id];
      if (counted != null && system != null && counted != system) return true;
    }
    return false;
  }

  bool get _allCountsFilled =>
      _selectedIds.every((id) => _counted[id] != null);

  bool get _canSubmitCount {
    if (!_allCountsFilled) return false;
    if (_hasAnyVariance && _reasonController.text.trim().isEmpty) return false;
    return !_isSubmitting;
  }

  // ── Load system stock in parallel for all selected products ──
  void _loadSystemStocks(List<Product> selected) {
    final tenantId = ref.read(activeTenantProvider) ?? '';
    for (final p in selected) {
      if (p.remoteId == null) continue;
      final id = p.remoteId!;
      if (_systemStock.containsKey(id)) continue;
      setState(() => _loadingStock[id] = true);
      widget.repository
          .getStock(catalogItemId: id, tenantId: tenantId)
          .then((stock) {
        if (mounted) {
          setState(() {
            _systemStock[id] = stock;
            _loadingStock[id] = false;
          });
        }
      }).catchError((_) {
        if (mounted) setState(() => _loadingStock[id] = false);
      });
    }
  }

  void _startCounting(List<Product> allProducts) {
    final selected = allProducts
        .where((p) => p.remoteId != null && _selectedIds.contains(p.remoteId))
        .toList();

    for (final p in selected) {
      _counted[p.remoteId!] = null;
    }

    _loadSystemStocks(selected);
    setState(() => _phase = _Phase.counting);
  }

  Future<void> _submitCount(List<Product> allProducts) async {
    if (!_canSubmitCount) return;
    setState(() => _isSubmitting = true);

    final tenantId = ref.read(activeTenantProvider) ?? '';
    final reason = _reasonController.text.trim();
    int adjusted = 0;
    int noVariance = 0;

    for (final id in _selectedIds) {
      final counted = _counted[id];
      final system = _systemStock[id];
      if (counted == null) continue;

      if (system != null && counted == system) {
        noVariance++;
        continue; // No API call for zero-variance items
      }

      // Save locally first (offline-first outbox pattern)
      final movement = InventoryMovementLocal()
        ..type = 'ADJUSTMENT'
        ..catalogItemId = id
        ..quantity = counted
        ..reason = reason.isEmpty ? null : reason
        ..tenantId = tenantId
        ..createdAt = DateTime.now()
        ..syncStatus = 'pending';
      await widget.repository.saveLocal(movement);

      try {
        final result = await widget.repository.adjustStock(
          catalogItemId: id,
          countedQuantity: counted,
          reason: reason,
          tenantId: tenantId,
        );
        final movementMap = result['movement'] as Map<String, dynamic>?;
        final remoteId = movementMap?['id'] as String? ?? 'adjusted';
        await widget.repository.markSynced(movement.id, remoteId);
        adjusted++;
      } on SocketException {
        adjusted++; // Counted locally — will sync later
      } catch (e) {
        await widget.repository.markFailed(movement.id, e.toString());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur produit $id : $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$adjusted produit(s) ajusté(s), $noVariance sans écart.',
          ),
        ),
      );
      // Reset to selection phase
      setState(() {
        _phase = _Phase.selection;
        _selectedIds.clear();
        _counted.clear();
        _systemStock.clear();
        _loadingStock.clear();
        _reasonController.clear();
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final paginatedAsync = ref.watch(paginatedProductListProvider);
    final allProducts = paginatedAsync.maybeWhen(
      data: (data) => (data['items'] as List).cast<Product>(),
      orElse: () => <Product>[],
    );

    final phaseTitle = _phase == _Phase.selection
        ? 'Inventaire partiel — Sélection'
        : 'Feuille de comptage';

    final body = _phase == _Phase.selection
        ? _SelectionView(
            products: _filteredProducts(allProducts),
            selectedIds: _selectedIds,
            searchQuery: _searchQuery,
            onSearchChanged: (q) => setState(() => _searchQuery = q),
            onToggle: (id) => setState(() {
              if (_selectedIds.contains(id)) {
                _selectedIds.remove(id);
              } else {
                _selectedIds.add(id);
              }
            }),
            onStartCounting: _selectedIds.isNotEmpty
                ? () => _startCounting(allProducts)
                : null,
          )
        : _CountingView(
            products: allProducts
                .where((p) =>
                    p.remoteId != null &&
                    _selectedIds.contains(p.remoteId))
                .toList(),
            counted: _counted,
            systemStock: _systemStock,
            loadingStock: _loadingStock,
            onCountChanged: (id, val) =>
                setState(() => _counted[id] = val),
            hasAnyVariance: _hasAnyVariance,
            reasonController: _reasonController,
            onReasonChanged: () => setState(() {}),
            canSubmit: _canSubmitCount,
            isSubmitting: _isSubmitting,
            onSubmit: () => _submitCount(allProducts),
          );

    if (widget.embedded) {
      return Column(
        children: [
          _PhaseHeader(
            title: phaseTitle,
            onBack: _phase == _Phase.counting
                ? () => setState(() => _phase = _Phase.selection)
                : null,
          ),
          Expanded(child: body),
        ],
      );
    }

    return Scaffold(
      appBar: ScalarioAppBar(
        title: phaseTitle,
        leadingOverride: _phase == _Phase.counting
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _phase = _Phase.selection),
              )
            : null,
      ),
      body: body,
    );
  }
}

// ─── Selection view ───────────────────────────────────────────────────────────

class _SelectionView extends StatelessWidget {
  final List<Product> products;
  final Set<String> selectedIds;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onToggle;
  final VoidCallback? onStartCounting;

  const _SelectionView({
    required this.products,
    required this.selectedIds,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onToggle,
    required this.onStartCounting,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            key: const Key('product_search_field'),
            decoration: const InputDecoration(
              hintText: 'Rechercher un produit...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: onSearchChanged,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: products.length,
            itemBuilder: (_, i) {
              final p = products[i];
              final id = p.remoteId ?? '';
              return CheckboxListTile(
                key: Key('product_checkbox_$id'),
                title: Text(p.name),
                subtitle: Text('Stock système : ${p.stockQuantity.toInt()}'),
                value: selectedIds.contains(id),
                onChanged: (_) => onToggle(id),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              key: const Key('start_count_button'),
              onPressed: onStartCounting,
              child: Text(
                'Démarrer le comptage'
                '${selectedIds.isNotEmpty ? ' (${selectedIds.length})' : ''}',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Counting view ────────────────────────────────────────────────────────────

class _CountingView extends StatelessWidget {
  final List<Product> products;
  final Map<String, int?> counted;
  final Map<String, int?> systemStock;
  final Map<String, bool> loadingStock;
  final void Function(String id, int? val) onCountChanged;
  final bool hasAnyVariance;
  final TextEditingController reasonController;
  final VoidCallback onReasonChanged;
  final bool canSubmit;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const _CountingView({
    required this.products,
    required this.counted,
    required this.systemStock,
    required this.loadingStock,
    required this.onCountChanged,
    required this.hasAnyVariance,
    required this.reasonController,
    required this.onReasonChanged,
    required this.canSubmit,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...products.map((p) {
            final id = p.remoteId ?? '';
            final system = systemStock[id];
            final isLoading = loadingStock[id] ?? false;
            final countedVal = counted[id];

            bool? isOk;
            if (countedVal != null && system != null) {
              isOk = countedVal == system;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(p.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                        ),
                        if (isLoading)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Text(
                            'Système : ${system ?? '—'}',
                            style: const TextStyle(
                                color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            key: Key('count_quantity_field_$id'),
                            initialValue: countedVal?.toString(),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Qté comptée',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (v) {
                              final n = int.tryParse(v);
                              onCountChanged(id, n);
                            },
                          ),
                        ),
                        if (isOk != null) ...[
                          const SizedBox(width: 12),
                          isOk
                              ? Icon(
                                  key: Key('variance_ok_$id'),
                                  Icons.check_circle,
                                  color: AppColors.success,
                                )
                              : Icon(
                                  key: Key('variance_error_$id'),
                                  Icons.error,
                                  color: AppColors.error,
                                ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),

          if (hasAnyVariance) ...[
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('count_reason_field'),
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Motif global *',
                hintText: 'ex. Inventaire mensuel mars',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => onReasonChanged(),
            ),
            const SizedBox(height: 8),
          ],

          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              key: const Key('submit_count_button'),
              onPressed: canSubmit ? onSubmit : null,
              child: isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Soumettre l\'inventaire'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Phase header (embedded mode) ──────────────────────────────────────────────

class _PhaseHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;

  const _PhaseHeader({required this.title, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBack,
              visualDensity: VisualDensity.compact,
            ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
