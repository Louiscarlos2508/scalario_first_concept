import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';
import 'package:frontend/features/shared/catalog/presentation/providers/serials_provider.dart';
import 'package:intl/intl.dart';

/// AC5 — Backoffice screen listing all serial records for a catalog item.
class SerialRecordsScreen extends ConsumerStatefulWidget {
  final String catalogItemId;
  final String? productName;

  const SerialRecordsScreen({
    super.key,
    required this.catalogItemId,
    this.productName,
  });

  @override
  ConsumerState<SerialRecordsScreen> createState() => _SerialRecordsScreenState();
}

class _SerialRecordsScreenState extends ConsumerState<SerialRecordsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serialsAsync = ref.watch(serialsProvider(widget.catalogItemId));

    return Scaffold(
      appBar: ScalarioAppBar(
        title: widget.productName != null
            ? 'Séries — ${widget.productName}'
            : 'Numéros de série',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(serialsProvider(widget.catalogItemId)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              key: const Key('serial_search_field'),
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Rechercher un numéro de série…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: serialsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text('Erreur : $err', style: const TextStyle(color: AppColors.error)),
              ),
              data: (serials) {
                final filtered = _query.isEmpty
                    ? serials
                    : serials
                        .where((s) => s.serial.toLowerCase().contains(_query))
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    key: const Key('serials_empty_state'),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.qr_code_2, size: 48, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        Text(
                          _query.isNotEmpty
                              ? 'Aucun résultat pour "$_query"'
                              : 'Aucun numéro de série enregistré',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final s = filtered[index];
                    return _SerialRecordTile(record: s);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SerialRecordTile extends StatelessWidget {
  final SerialRecord record;

  const _SerialRecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final isSold = record.soldAt != null;

    return ListTile(
      key: Key('serial_record_${record.id}'),
      leading: CircleAvatar(
        backgroundColor: isSold
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.success.withValues(alpha: 0.1),
        child: Icon(
          isSold ? Icons.sell_outlined : Icons.inventory_2_outlined,
          color: isSold ? AppColors.primary : AppColors.success,
          size: 20,
        ),
      ),
      title: Text(
        record.serial,
        style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'monospace'),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isSold)
            Text(
              'Vendu le ${dateFormat.format(record.soldAt!)}',
              style: const TextStyle(fontSize: 12),
            ),
          if (record.warrantyUntil != null)
            Text(
              'Garantie jusqu\'au ${dateFormat.format(record.warrantyUntil!)}',
              style: TextStyle(
                fontSize: 12,
                color: record.warrantyUntil!.isAfter(DateTime.now())
                    ? AppColors.success
                    : AppColors.error,
              ),
            ),
          Text(
            'Ajouté le ${dateFormat.format(record.createdAt)}',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
      trailing: isSold
          ? const Chip(
              label: Text('Vendu', style: TextStyle(fontSize: 11)),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            )
          : Chip(
              label: const Text('En stock', style: TextStyle(fontSize: 11, color: AppColors.success)),
              backgroundColor: AppColors.success.withValues(alpha: 0.1),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
    );
  }
}
