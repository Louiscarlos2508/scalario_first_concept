import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/pos/data/services/z_report_service.dart';

class SessionReportDialog extends ConsumerWidget {
  final Map<String, dynamic> summary;
  final double physicalCount;

  const SessionReportDialog({
    super.key,
    required this.summary,
    required this.physicalCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theoreticalCash = summary['theoreticalCash'] as double;
    final variance = physicalCount - theoreticalCash;
    final totalsByMethod = summary['totalsByMethod'] as Map<String, double>;
    final userProfile = ref.watch(userProfileProvider).value;

    return AlertDialog(
      title: Row(
        children: const [
          Icon(Icons.summarize, color: Colors.blue),
          SizedBox(width: 10),
          Text('Session Summary (Z-Report)'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Sales by Method'),
            ...totalsByMethod.entries.map((e) => _buildRow(e.key, e.value)),
            const Divider(),
            _buildRow('Total Sales', summary['totalSales'] as double, bold: true),
            const SizedBox(height: 20),
            _buildSectionTitle('Cash Reconciliation'),
            _buildRow('Opening Balance', summary['openingBalance'] as double),
            _buildRow('Theoretical Cash', theoreticalCash, color: Colors.blue),
            _buildRow('Physical Count', physicalCount, color: Colors.black, bold: true),
            const Divider(),
            _buildRow(
              'Variance',
              variance,
              color: variance == 0 ? Colors.green : (variance > 0 ? Colors.orange : Colors.red),
              bold: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Back'),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            await ZReportService.generateAndPrintZReport(
              summary: summary,
              physicalCount: physicalCount,
              userName: userProfile?.fullName ?? userProfile?.email ?? 'User',
              tenantName: 'Scalario POS',
            );
          },
          icon: const Icon(Icons.print),
          label: const Text('Print Z-Report'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Confirm Closure'),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  Widget _buildRow(String label, double value, {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
