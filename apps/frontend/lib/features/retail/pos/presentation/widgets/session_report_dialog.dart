import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/retail/pos/data/services/z_report_service.dart';

String _fcfa(double amount) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(amount);

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
          Text('Rapport de caisse (Z-Report)'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Ventes par méthode'),
            ...totalsByMethod.entries.map((e) => _buildRow(e.key, e.value)),
            const Divider(),
            // Story 27-3 — 3-line Z-report: gross / returns / net
            Builder(builder: (context) {
              final returns = summary['returns'] as Map<String, dynamic>?;
              final returnsCount = (returns?['count'] as num?)?.toInt() ?? 0;
              if (returnsCount > 0) {
                final grossSales = summary['grossSales'] as Map<String, dynamic>?;
                final netSales = summary['netSales'] as Map<String, dynamic>?;
                final grossCount = (grossSales?['count'] as num?)?.toInt() ?? 0;
                final grossAmount = (grossSales?['amount'] as num?)?.toDouble() ?? (summary['totalSales'] as double);
                final returnsAmount = (returns?['amount'] as num?)?.toDouble() ?? 0.0;
                final netAmount = (netSales?['amount'] as num?)?.toDouble() ?? grossAmount;
                return Column(
                  children: [
                    _buildRow('Ventes brutes ($grossCount transactions)', grossAmount),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Retours ($returnsCount retour${returnsCount > 1 ? 's' : ''})'),
                          Text(
                            '− ${_fcfa(returnsAmount)}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                    _buildRow('Ventes nettes', netAmount, bold: true),
                  ],
                );
              }
              return _buildRow('Total des ventes', summary['totalSales'] as double, bold: true);
            }),
            const SizedBox(height: 20),
            _buildSectionTitle('Réconciliation espèces'),
            _buildRow('Fond de caisse', summary['openingBalance'] as double),
            _buildRow('Espèces théoriques', theoreticalCash,
                color: Colors.blue),
            _buildRow('Compte physique', physicalCount,
                color: Colors.black, bold: true),
            const Divider(),
            _buildRow(
              'Écart',
              variance,
              color: variance == 0
                  ? Colors.green
                  : (variance > 0 ? Colors.orange : Colors.red),
              bold: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Retour'),
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
          label: const Text('Imprimer Z-Report'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, foregroundColor: Colors.white),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Confirmer la fermeture'),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  Widget _buildRow(String label, double value,
      {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(
            _fcfa(value),
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
