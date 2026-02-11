import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/pos/presentation/providers/pos_providers.dart';
import 'package:intl/intl.dart';

class StockHistoryScreen extends ConsumerWidget {
  const StockHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(stockHistoryProvider);
    final dateRange = ref.watch(stockHistoryDateRangeProvider);
    final dateFormat = DateFormat('MMM dd, HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock History'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: dateRange,
              );
              if (picked != null) {
                ref.read(stockHistoryDateRangeProvider.notifier).state = picked;
              }
            },
            icon: const Icon(Icons.date_range),
            label: Text(
              dateRange == null
                  ? 'All Time'
                  : '${DateFormat('MM/dd').format(dateRange.start)} - ${DateFormat('MM/dd').format(dateRange.end)}',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(stockHistoryProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: historyAsync.when(
        data: (movements) {
          if (movements.isEmpty) {
            return const Center(child: Text('No stock movements recorded.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: movements.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final m = movements[index];
              final type = m['type'] as String;
              final qty = m['quantity'] as num;
              final productName = m['product']?['name'] ?? 'Unknown Product';
              final reason = m['reason'] ?? '';
              final date = DateTime.parse(m['createdAt']);

              Color qtyColor;
              IconData icon;
              if (type == 'IN') {
                qtyColor = Colors.green;
                icon = Icons.add_circle_outline;
              } else if (type == 'OUT') {
                qtyColor = Colors.red;
                icon = Icons.remove_circle_outline;
              } else {
                qtyColor = Colors.blue;
                icon = Icons.edit_note;
              }

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: qtyColor.withOpacity(0.1),
                  child: Icon(icon, color: qtyColor),
                ),
                title: Text(productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (reason.isNotEmpty) Text(reason, style: const TextStyle(fontSize: 12)),
                    Text(dateFormat.format(date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
                trailing: Text(
                  '${qty > 0 ? "+" : ""}${qty.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: qtyColor,
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
