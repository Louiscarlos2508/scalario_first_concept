import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/providers/payment_methods_provider.dart';
import 'package:frontend/features/retail/pos/data/services/z_report_service.dart';

String _fcfa(double amount) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(amount);

class SessionReportDialog extends ConsumerWidget {
  final Map<String, dynamic> summary;
  final double physicalCount;
  final String? varianceExplanation;

  const SessionReportDialog({
    super.key,
    required this.summary,
    required this.physicalCount,
    this.varianceExplanation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theoreticalCash = summary['theoreticalCash'] as double;
    final variance = physicalCount - theoreticalCash;
    final totalsByMethod = summary['totalsByMethod'] as Map<String, double>;
    final countsByMethod =
        (summary['countsByMethod'] as Map<String, int>?) ?? {};
    final orderCount = (summary['orderCount'] as int?) ?? 0;
    final splitCount = (summary['splitCount'] as int?) ?? 0;
    final userProfile = ref.watch(userProfileProvider).value;
    final cashCollected = totalsByMethod['CASH'] ?? 0.0;

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
            // ── SECTION 1 : VENTES ──────────────────────────────────────
            _buildSectionTitle('Ventes de la session'),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '$orderCount vente${orderCount != 1 ? 's' : ''} au total'
                '${splitCount > 0 ? ' — dont $splitCount mixte${splitCount > 1 ? 's' : ''}' : ''}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),

            // Ligne par méthode de paiement
            ...totalsByMethod.entries
                .where((e) => e.value > 0)
                .map((e) => _buildPaymentMethodRow(
                      method: e.key,
                      amount: e.value,
                      count: countsByMethod[e.key] ?? 0,
                    )),

            // Total ventes
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total ($orderCount vente${orderCount != 1 ? "s" : ""})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  _fcfa(summary['totalSales'] as double),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),

            // Retours si présents
            Builder(builder: (context) {
              final returns = summary['returns'] as Map<String, dynamic>?;
              final returnsCount = (returns?['count'] as num?)?.toInt() ?? 0;
              if (returnsCount == 0) return const SizedBox.shrink();

              final grossSales =
                  summary['grossSales'] as Map<String, dynamic>?;
              final netSales = summary['netSales'] as Map<String, dynamic>?;
              final grossAmount = (grossSales?['amount'] as num?)?.toDouble() ??
                  (summary['totalSales'] as double);
              final returnsAmount =
                  (returns?['amount'] as num?)?.toDouble() ?? 0.0;
              final netAmount =
                  (netSales?['amount'] as num?)?.toDouble() ?? grossAmount;
              final grossCount =
                  (grossSales?['count'] as num?)?.toInt() ?? orderCount;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 4),
                  _buildRow(
                      'Ventes brutes ($grossCount transactions)', grossAmount),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Retours ($returnsCount)'),
                        Text(
                          '− ${_fcfa(returnsAmount)}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 8),
                  _buildRow('Ventes nettes', netAmount, bold: true),
                ],
              );
            }),

            const SizedBox(height: 16),

            // ── SECTION 2 : RÉCONCILIATION ESPÈCES ─────────────────────
            _buildSectionTitle('Réconciliation espèces'),

            _buildRow('Fond d\'ouverture', summary['openingBalance'] as double),
            _buildRow('+ Espèces encaissées', cashCollected,
                color: Colors.green),
            const Divider(height: 8),
            _buildRow('= Caisse théorique', theoreticalCash,
                color: Colors.blue, bold: true),

            const SizedBox(height: 8),
            _buildRow('Comptage physique', physicalCount, bold: true),
            const Divider(height: 8),
            _buildRow(
              'Écart',
              variance,
              color: variance == 0
                  ? Colors.green
                  : (variance > 0 ? Colors.orange : Colors.red),
              bold: true,
            ),

            // Explication de l'écart
            if (variance != 0 && varianceExplanation != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Explication de l\'écart',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(varianceExplanation!),
                  ],
                ),
              ),
            ],
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

  Widget _buildPaymentMethodRow({
    required String method,
    required double amount,
    required int count,
  }) {
    final icon = _methodIcon(method);
    final label = paymentMethodLabel(method);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(
            '$count tx',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Text(
            _fcfa(amount),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  IconData _methodIcon(String method) {
    switch (method.toUpperCase()) {
      case 'CASH':
        return Icons.payments_outlined;
      case 'MOBILE_MONEY':
        return Icons.phone_android_outlined;
      case 'CARD':
        return Icons.credit_card_outlined;
      case 'CREDIT':
        return Icons.account_balance_wallet_outlined;
      case 'TRANSFER':
        return Icons.swap_horiz_outlined;
      case 'SPLIT':
        return Icons.call_split_outlined;
      default:
        return Icons.attach_money;
    }
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
