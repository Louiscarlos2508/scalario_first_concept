import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/providers/payment_methods_provider.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/retail/pos/data/services/z_report_service.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';

String _fcfa(double v) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(v);

/// Full-screen session close flow — replaces the multi-dialog chain.
///
/// Single page:
///   • Session info (date, cashier, opened at)
///   • Ventes de la session (breakdown by payment method)
///   • Comptage de caisse (editable cash field + live reconciliation)
///   • Explication de l'écart (shown if variance != 0)
///   • Actions: Print Z-Report + Confirmer la fermeture
class SessionCloseScreen extends ConsumerStatefulWidget {
  const SessionCloseScreen({super.key});

  @override
  ConsumerState<SessionCloseScreen> createState() => _SessionCloseScreenState();
}

class _SessionCloseScreenState extends ConsumerState<SessionCloseScreen> {
  final _cashController = TextEditingController();
  final _explanationController = TextEditingController();

  Map<String, dynamic>? _summary;
  bool _isLoadingSummary = true;
  bool _loadError = false;
  bool _isClosing = false;
  bool _showExplanationError = false;

  @override
  void initState() {
    super.initState();
    _loadSummary();
    _cashController.addListener(_onCashChanged);
  }

  @override
  void dispose() {
    _cashController.removeListener(_onCashChanged);
    _cashController.dispose();
    _explanationController.dispose();
    super.dispose();
  }

  void _onCashChanged() => setState(() {});

  Future<void> _loadSummary() async {
    if (mounted) setState(() { _loadError = false; _isLoadingSummary = true; });
    try {
      final summary = await ref
          .read(sessionProvider.notifier)
          .calculateSessionSummary()
          .timeout(const Duration(seconds: 15));
      if (mounted) {
        setState(() {
          _summary = summary.isEmpty ? _fallbackSummary() : summary;
          _isLoadingSummary = false;
        });
      }
    } catch (e, stack) {
      debugPrint('[SessionClose] calculateSessionSummary error: $e\n$stack');
      if (mounted) {
        setState(() {
          _loadError = true;
          _isLoadingSummary = false;
        });
      }
    }
  }

  static Map<String, dynamic> _fallbackSummary() => {
        'openingBalance': 0.0,
        'totalsByMethod': <String, double>{},
        'countsByMethod': <String, int>{},
        'totalSales': 0.0,
        'orderCount': 0,
        'splitCount': 0,
        'theoreticalCash': 0.0,
      };

  double get _physicalCash =>
      double.tryParse(_cashController.text.replaceAll(' ', '')) ?? 0.0;

  double get _theoreticalCash =>
      (_summary?['theoreticalCash'] as double?) ?? 0.0;

  double get _variance => _physicalCash - _theoreticalCash;

  bool get _hasVariance => _cashController.text.isNotEmpty && _variance != 0;

  Future<void> _onConfirmClose() async {
    if (_cashController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir le comptage physique.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_hasVariance && _explanationController.text.trim().isEmpty) {
      setState(() => _showExplanationError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Un écart a été détecté. Veuillez l\'expliquer.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la fermeture'),
        content: const Text(
          'La session sera définitivement fermée. Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Fermer la caisse'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isClosing = true);

    await ref.read(sessionProvider.notifier).closeSession(
          _physicalCash,
          _theoreticalCash,
          varianceExplanation: _hasVariance
              ? _explanationController.text.trim()
              : null,
        );

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _onPrintZReport() async {
    if (_summary == null) return;
    final profile = ref.read(userProfileProvider).valueOrNull;
    final employee = ref.read(selectedEmployeeProvider);
    await ZReportService.generateAndPrintZReport(
      summary: _summary!,
      physicalCount: _physicalCash,
      userName: employee?.name ?? profile?.fullName ?? profile?.email ?? 'Caissier',
      tenantName: profile?.memberships.firstOrNull?.tenantName ?? 'Scalario POS',
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider).valueOrNull;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final employee = ref.watch(selectedEmployeeProvider);
    final cashierName =
        employee?.name ?? profile?.fullName ?? profile?.email ?? 'Caissier';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: const Text('Fermer la caisse'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoadingSummary
          ? const Center(child: CircularProgressIndicator())
          : _loadError
              ? _buildErrorState()
              : _buildContent(context, session, cashierName),
      bottomNavigationBar: (_isLoadingSummary || _loadError)
          ? null
          : _buildBottomBar(context),
    );
  }

  Widget _buildContent(
    BuildContext context,
    dynamic session,
    String cashierName,
  ) {
    final summary = _summary!;
    final totalsByMethod = summary['totalsByMethod'] as Map<String, double>;
    final countsByMethod =
        (summary['countsByMethod'] as Map<String, int>?) ?? {};
    final totalSales = summary['totalSales'] as double;
    final orderCount = (summary['orderCount'] as int?) ?? 0;
    final openingBalance = (summary['openingBalance'] as double?) ?? 0.0;
    final cashSales = totalsByMethod['CASH'] ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Session info ─────────────────────────────────────────────────
          _SectionCard(
            children: [
              Row(
                children: [
                  const Icon(Icons.store_outlined,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      cashierName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (session?.openedAt != null)
                    Text(
                      'Ouvert à ${DateFormat('HH:mm').format(session!.openedAt!)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.now()),
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Ventes de la session ─────────────────────────────────────────
          _SectionTitle(
            label: 'Ventes de la session',
            badge: '$orderCount vente${orderCount != 1 ? 's' : ''}',
          ),
          _SectionCard(
            children: [
              ...totalsByMethod.entries
                  .where((e) => e.value > 0)
                  .map((e) => _PaymentRow(
                        method: e.key,
                        amount: e.value,
                        count: countsByMethod[e.key] ?? 0,
                      )),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    _fcfa(totalSales),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Comptage de caisse ───────────────────────────────────────────
          _SectionTitle(label: 'Comptage de caisse'),
          _SectionCard(
            children: [
              // Readonly rows
              _ReconciliationRow(
                label: 'Fond d\'ouverture',
                value: openingBalance,
              ),
              _ReconciliationRow(
                label: '+ Espèces encaissées',
                value: cashSales,
                valueColor: Colors.green.shade700,
              ),
              const Divider(height: 16),
              _ReconciliationRow(
                label: 'Caisse théorique',
                value: _theoreticalCash,
                valueColor: AppColors.primary,
                bold: true,
              ),
              const SizedBox(height: 16),

              // Editable physical count
              TextField(
                controller: _cashController,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Comptage physique',
                  suffixText: 'FCFA',
                  border: OutlineInputBorder(),
                  helperText: 'Comptez les billets et pièces dans le tiroir',
                ),
              ),

              // Live variance
              if (_cashController.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 4),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Écart',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _variance == 0
                            ? Colors.green.shade700
                            : (_variance > 0
                                ? Colors.orange.shade800
                                : AppColors.error),
                      ),
                    ),
                    Row(
                      children: [
                        if (_variance != 0)
                          Icon(
                            _variance > 0
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 14,
                            color: _variance > 0
                                ? Colors.orange.shade800
                                : AppColors.error,
                          ),
                        const SizedBox(width: 4),
                        Text(
                          _variance == 0
                              ? '${_fcfa(_variance)} ✓'
                              : '${_variance > 0 ? '+' : ''}${_fcfa(_variance)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: _variance == 0
                                ? Colors.green.shade700
                                : (_variance > 0
                                    ? Colors.orange.shade800
                                    : AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),

          // ── Variance explanation ─────────────────────────────────────────
          if (_hasVariance) ...[
            const SizedBox(height: 12),
            _SectionTitle(label: 'Explication de l\'écart'),
            _SectionCard(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: (_variance > 0
                            ? Colors.orange
                            : AppColors.error)
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (_variance > 0
                              ? Colors.orange
                              : AppColors.error)
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: _variance > 0
                            ? Colors.orange.shade800
                            : AppColors.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Écart de ${_variance > 0 ? '+' : ''}${_fcfa(_variance)} détecté',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _variance > 0
                              ? Colors.orange.shade800
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _explanationController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Expliquer l\'écart',
                    hintText: 'Ex: Rendu de monnaie non enregistré, erreur de comptage…',
                    border: const OutlineInputBorder(),
                    errorText: _showExplanationError &&
                            _explanationController.text.trim().isEmpty
                        ? 'Explication requise'
                        : null,
                  ),
                  onChanged: (_) =>
                      setState(() => _showExplanationError = false),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Impossible de charger le résumé',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Vérifiez que la session est bien active et réessayez.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadSummary,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
              top: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
        ),
        child: Row(
          children: [
            // Print Z-Report
            OutlinedButton.icon(
              onPressed: _isClosing ? null : _onPrintZReport,
              icon: const Icon(Icons.print_outlined, size: 18),
              label: const Text('Z-Report'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(width: 12),
            // Confirm close
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isClosing ? null : _onConfirmClose,
                icon: _isClosing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.lock_outline, size: 18),
                label: Text(_isClosing ? 'Fermeture…' : 'Confirmer la fermeture'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String label;
  final String? badge;

  const _SectionTitle({required this.label, this.badge});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;

  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final String method;
  final double amount;
  final int count;

  const _PaymentRow(
      {required this.method, required this.amount, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(_icon(), size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
              child: Text(paymentMethodLabel(method),
                  style: const TextStyle(fontSize: 13))),
          Text(
            '$count tx',
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Text(
            _fcfa(amount),
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  IconData _icon() {
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
      default:
        return Icons.attach_money;
    }
  }
}

class _ReconciliationRow extends StatelessWidget {
  final String label;
  final double value;
  final Color? valueColor;
  final bool bold;

  const _ReconciliationRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 13,
                fontWeight:
                    bold ? FontWeight.bold : FontWeight.normal,
                color: bold ? null : AppColors.textSecondary),
          ),
          Text(
            _fcfa(value),
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
