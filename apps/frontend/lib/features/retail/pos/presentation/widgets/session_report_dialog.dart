import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/providers/payment_methods_provider.dart';
import 'package:frontend/core/theme/sheet_style.dart';
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

    return Dialog(
      shape: kSheetDialogShape,
      child: SizedBox(
        width: 460,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────────────
              const SheetDialogHeader(
                icon: Icons.summarize_outlined,
                iconColor: kSheetBlue,
                title: 'Rapport de caisse',
                subtitle: 'Z-Report — Résumé de la session',
              ),
              const SizedBox(height: 16),
              const SheetDivider(),

              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── SECTION 1 : VENTES ──────────────────────────────
                      const SheetSectionLabel('Ventes de la session'),
                      const SizedBox(height: 6),
                      Text(
                        '$orderCount vente${orderCount != 1 ? 's' : ''}'
                        '${splitCount > 0 ? ' — dont $splitCount mixte${splitCount > 1 ? 's' : ''}' : ''}',
                        style: const TextStyle(
                            fontSize: 11, color: kSheetSlate500),
                      ),
                      const SizedBox(height: 10),

                      ...totalsByMethod.entries
                          .where((e) => e.value > 0)
                          .map((e) => _MethodRow(
                                method: e.key,
                                amount: e.value,
                                count: countsByMethod[e.key] ?? 0,
                              )),

                      const SheetDivider(),
                      const SizedBox(height: 8),
                      _SummaryRow(
                        label:
                            'Total ($orderCount vente${orderCount != 1 ? "s" : ""})',
                        value: summary['totalSales'] as double,
                        bold: true,
                      ),

                      // Retours si présents
                      Builder(builder: (context) {
                        final returns =
                            summary['returns'] as Map<String, dynamic>?;
                        final returnsCount =
                            (returns?['count'] as num?)?.toInt() ?? 0;
                        if (returnsCount == 0) return const SizedBox.shrink();

                        final grossSales =
                            summary['grossSales'] as Map<String, dynamic>?;
                        final netSales =
                            summary['netSales'] as Map<String, dynamic>?;
                        final grossAmount =
                            (grossSales?['amount'] as num?)?.toDouble() ??
                                (summary['totalSales'] as double);
                        final returnsAmount =
                            (returns?['amount'] as num?)?.toDouble() ?? 0.0;
                        final netAmount =
                            (netSales?['amount'] as num?)?.toDouble() ??
                                grossAmount;
                        final grossCount =
                            (grossSales?['count'] as num?)?.toInt() ??
                                orderCount;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            const SheetDivider(),
                            const SizedBox(height: 6),
                            _SummaryRow(
                                label:
                                    'Ventes brutes ($grossCount transactions)',
                                value: grossAmount),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Retours ($returnsCount)',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: kSheetSlate900)),
                                  Text(
                                    '− ${_fcfa(returnsAmount)}',
                                    style: const TextStyle(
                                        color: kSheetRed,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            const SheetDivider(),
                            const SizedBox(height: 4),
                            _SummaryRow(
                                label: 'Ventes nettes',
                                value: netAmount,
                                bold: true),
                          ],
                        );
                      }),

                      const SizedBox(height: 20),

                      // ── SECTION 2 : RÉCONCILIATION ESPÈCES ─────────────
                      const SheetSectionLabel('Réconciliation espèces'),
                      const SizedBox(height: 10),

                      _SummaryRow(
                          label: "Fond d'ouverture",
                          value: summary['openingBalance'] as double),
                      _SummaryRow(
                          label: '+ Espèces encaissées',
                          value: cashCollected,
                          valueColor: kSheetGreen),
                      const SheetDivider(),
                      const SizedBox(height: 4),
                      _SummaryRow(
                          label: '= Caisse théorique',
                          value: theoreticalCash,
                          valueColor: kSheetBlue,
                          bold: true),
                      const SizedBox(height: 8),
                      _SummaryRow(
                          label: 'Comptage physique',
                          value: physicalCount,
                          bold: true),
                      const SheetDivider(),
                      const SizedBox(height: 4),
                      _SummaryRow(
                        label: 'Écart',
                        value: variance,
                        valueColor: variance == 0
                            ? kSheetGreen
                            : variance > 0
                                ? kSheetAmber
                                : kSheetRed,
                        bold: true,
                      ),

                      // Explication de l'écart
                      if (variance != 0 && varianceExplanation != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: kSheetAmber.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: kSheetAmber.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Explication de l\'écart',
                                  style: TextStyle(
                                      fontSize: 11, color: kSheetSlate500)),
                              const SizedBox(height: 4),
                              Text(varianceExplanation!,
                                  style: const TextStyle(
                                      fontSize: 13, color: kSheetSlate900)),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // ── Actions ───────────────────────────────────────────────────
              const SheetDivider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    style: sheetCancelButtonStyle(),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Retour'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kSheetBlue,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: kSheetBlue),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        await ZReportService.generateAndPrintZReport(
                          summary: summary,
                          physicalCount: physicalCount,
                          userName: userProfile?.fullName ??
                              userProfile?.email ??
                              'User',
                          tenantName: 'Scalario POS',
                        );
                      },
                      icon: const Icon(Icons.print_outlined, size: 16),
                      label: const Text('Imprimer Z-Report'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: sheetPrimaryButtonStyle(color: kSheetRed),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Confirmer fermeture'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Payment method row ────────────────────────────────────────────────────────

class _MethodRow extends StatelessWidget {
  final String method;
  final double amount;
  final int count;

  const _MethodRow(
      {required this.method, required this.amount, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: kSheetBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(_icon(method), size: 15, color: kSheetBlue),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(paymentMethodLabel(method),
                style: const TextStyle(fontSize: 13, color: kSheetSlate900)),
          ),
          Text('$count tx',
              style: const TextStyle(fontSize: 11, color: kSheetSlate500)),
          const SizedBox(width: 12),
          Text(
            _fcfa(amount),
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: kSheetSlate900),
          ),
        ],
      ),
    );
  }

  IconData _icon(String m) => switch (m.toUpperCase()) {
        'CASH' => Icons.payments_outlined,
        'MOBILE_MONEY' => Icons.phone_android_outlined,
        'CARD' => Icons.credit_card_outlined,
        'CREDIT' => Icons.account_balance_wallet_outlined,
        'TRANSFER' => Icons.swap_horiz_outlined,
        'SPLIT' => Icons.call_split_outlined,
        _ => Icons.attach_money,
      };
}

// ── Summary row ───────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final Color? valueColor;
  final bool bold;

  const _SummaryRow(
      {required this.label,
      required this.value,
      this.valueColor,
      this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
                  color: kSheetSlate900)),
          Text(
            _fcfa(value),
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
              color: valueColor ?? kSheetSlate900,
            ),
          ),
        ],
      ),
    );
  }
}
