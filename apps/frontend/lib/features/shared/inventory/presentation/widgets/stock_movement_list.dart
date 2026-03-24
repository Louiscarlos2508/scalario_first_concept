import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/shared/business_type/data/business_type_config_repository.dart';
import 'package:frontend/features/shared/business_type/presentation/providers/business_type_config_provider.dart';

const kTypeLabels = <String, String>{
  'DELIVERY': 'Réception',
  'SALE': 'Vente',
  'LOSS': 'Perte',
  'ADJUSTMENT': 'Ajustement',
  'TRANSFER_OUT': 'Transfert ↑',
  'TRANSFER_IN': 'Transfert ↓',
  'RETURN': 'Retour',
  'REPACKAGING': 'Recond.',
};

const kPeriods = <String, Duration?>{
  'Tout': null,
  'Auj.': Duration(days: 1),
  '7 j': Duration(days: 7),
  '30 j': Duration(days: 30),
};

class StockMovementList extends ConsumerStatefulWidget {
  final Map<String, dynamic> item;
  const StockMovementList({super.key, required this.item});

  @override
  ConsumerState<StockMovementList> createState() => _StockMovementListState();
}

class _StockMovementListState extends ConsumerState<StockMovementList> {
  String? _typeFilter;
  String _periodKey = 'Tout';
  DateTimeRange? _customRange;
  int _visibleCount = 10;

  List _applyFilters(List movements) {
    List result = movements;

    if (_typeFilter != null) {
      result = result
          .where((m) => (m as Map<String, dynamic>)['type'] == _typeFilter)
          .toList();
    }

    if (_periodKey == 'custom' && _customRange != null) {
      final start = _customRange!.start;
      final end = _customRange!.end.add(const Duration(days: 1));
      result = result.where((m) {
        final raw = (m as Map<String, dynamic>)['createdAt'] as String?;
        if (raw == null) return false;
        final d = DateTime.tryParse(raw)?.toLocal();
        return d != null && !d.isBefore(start) && d.isBefore(end);
      }).toList();
    } else {
      final duration = kPeriods[_periodKey];
      if (duration != null) {
        final cutoff = DateTime.now().subtract(duration);
        result = result.where((m) {
          final raw = (m as Map<String, dynamic>)['createdAt'] as String?;
          if (raw == null) return false;
          final d = DateTime.tryParse(raw);
          return d != null && d.isAfter(cutoff);
        }).toList();
      }
    }

    return result;
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: _customRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _periodKey = 'custom';
        _visibleCount = 10;
      });
    }
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  String _customRangeLabel() {
    if (_customRange == null) return 'Période…';
    return '${_fmt(_customRange!.start)}→${_fmt(_customRange!.end)}';
  }

  void _resetPagination() => _visibleCount = 10;

  @override
  Widget build(BuildContext context) {
    final id = widget.item['id']?.toString() ?? '';
    final historyAsync = ref.watch(stockHistoryByItemProvider(id));
    final stock = (widget.item['stockQuantity'] is num)
        ? (widget.item['stockQuantity'] as num).toDouble()
        : 0.0;
    final minStock = (widget.item['minStockLevel'] is num)
        ? (widget.item['minStockLevel'] as num).toDouble()
        : null;
    final unitType = widget.item['unitType']?.toString() ?? 'piece';
    final unit = widget.item['weightUnit']?.toString() ?? unitType;

    final stockLabel = unitType == 'piece'
        ? stock.toStringAsFixed(stock.truncateToDouble() == stock ? 0 : 1)
        : '${stock.toStringAsFixed(stock.truncateToDouble() == stock ? 0 : 1)} $unit';

    final btConfig = ref.watch(businessTypeConfigProvider).valueOrNull ??
        BusinessTypeConfig.fallback;
    final typeLabels = {
      ...kTypeLabels,
      'TRANSFER_OUT': btConfig.sendAction,
      'TRANSFER_IN': btConfig.confirmAction,
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoRow(label: 'Stock actuel', value: stockLabel),
        if (minStock != null)
          _InfoRow(
            label: 'Seuil minimum',
            value: minStock.toStringAsFixed(
                minStock.truncateToDouble() == minStock ? 0 : 1),
          ),
        const SizedBox(height: 16),
        Text(
          'Mouvements récents',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),

        // ── Type filter chips ──
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                label: const Text('Tous'),
                selected: _typeFilter == null,
                onSelected: (_) => setState(() {
                  _typeFilter = null;
                  _resetPagination();
                }),
              ),
              ...typeLabels.entries.map((e) => Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: FilterChip(
                      label: Text(e.value),
                      selected: _typeFilter == e.key,
                      onSelected: (_) => setState(() {
                        _typeFilter = _typeFilter == e.key ? null : e.key;
                        _resetPagination();
                      }),
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // ── Period filter chips ──
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...kPeriods.keys.map((label) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(label),
                      selected: _periodKey == label,
                      onSelected: (_) => setState(() {
                        _periodKey = label;
                        _customRange = null;
                        _resetPagination();
                      }),
                    ),
                  )),
              FilterChip(
                avatar: const Icon(Icons.calendar_today_outlined, size: 14),
                label: Text(_customRangeLabel()),
                selected: _periodKey == 'custom',
                onSelected: (_) => _pickDateRange(context),
                deleteIcon: _periodKey == 'custom'
                    ? const Icon(Icons.close, size: 14)
                    : null,
                onDeleted: _periodKey == 'custom'
                    ? () => setState(() {
                          _periodKey = 'Tout';
                          _customRange = null;
                          _resetPagination();
                        })
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) =>
              Text('Erreur : $e', style: const TextStyle(color: AppColors.error)),
          data: (movements) {
            final filtered = _applyFilters(movements);
            if (filtered.isEmpty) {
              return const Text(
                'Aucun mouvement',
                style: TextStyle(color: AppColors.textSecondary),
              );
            }
            final visible = filtered.take(_visibleCount).toList();
            return Column(
              children: [
                ...visible.map(
                    (m) => _MovementTile(movement: m, typeLabels: typeLabels)),
                if (filtered.length > _visibleCount)
                  TextButton(
                    onPressed: () => setState(() => _visibleCount += 10),
                    child: Text(
                      'Voir plus (${filtered.length - _visibleCount} restants)',
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MovementTile extends StatelessWidget {
  final dynamic movement;
  final Map<String, String> typeLabels;
  const _MovementTile({required this.movement, required this.typeLabels});

  @override
  Widget build(BuildContext context) {
    final m = movement as Map<String, dynamic>;
    final type = m['type'] as String? ?? '';
    final rawQty = double.tryParse(m['quantity']?.toString() ?? '0') ?? 0.0;
    final qty = rawQty.abs();
    final rawDate = m['createdAt'] as String?;
    final date = rawDate != null ? DateTime.tryParse(rawDate)?.toLocal() : null;
    final reason = m['reason'] as String?;

    final isIn = type == 'ADJUSTMENT'
        ? rawQty >= 0
        : (type == 'DELIVERY' || type == 'TRANSFER_IN' || type == 'RETURN');
    final color = isIn ? AppColors.success : AppColors.error;
    final sign = isIn ? '+' : '-';
    final label = typeLabels[type] ?? type;

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isIn ? Icons.add_circle_outline : Icons.remove_circle_outline,
        color: color,
        size: 20,
      ),
      title: Text(label, style: const TextStyle(fontSize: 13)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (date != null)
            Text(
              '${date.day.toString().padLeft(2, '0')}/'
              '${date.month.toString().padLeft(2, '0')}/'
              '${date.year} '
              '${date.hour.toString().padLeft(2, '0')}:'
              '${date.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 11),
            ),
          if (reason != null && reason.isNotEmpty)
            Text(
              reason,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      trailing: Text(
        '$sign$qty',
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
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
