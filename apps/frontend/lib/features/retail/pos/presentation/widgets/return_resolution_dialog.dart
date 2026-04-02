import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/theme/sheet_style.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';

class ReturnResolutionDialog extends ConsumerStatefulWidget {
  final String? originalTxId;
  final List<Map<String, dynamic>> lines;

  const ReturnResolutionDialog({
    super.key,
    this.originalTxId,
    required this.lines,
  });

  @override
  ConsumerState<ReturnResolutionDialog> createState() =>
      _ReturnResolutionDialogState();
}

class _ReturnResolutionDialogState
    extends ConsumerState<ReturnResolutionDialog> {
  String _resolution = 'cash_refund';
  final _reasonController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _validate() async {
    final reason = _reasonController.text.trim();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final tenantId = ref.read(activeTenantProvider) ?? '';
      final userProfile = ref.read(userProfileProvider).value;
      final userId = userProfile?.id ?? '';
      final repo = ref.read(returnsRepositoryProvider);

      for (final line in widget.lines) {
        await repo.createReturn(
          tenantId: tenantId,
          userId: userId,
          originalTxId: widget.originalTxId,
          catalogItemId: line['catalogItemId']?.toString() ?? '',
          variantId: line['variantId']?.toString(),
          quantity: (line['returnQuantity'] as num).toDouble(),
          unitPrice:
              (line['unitPrice'] ?? line['price'] as num? ?? 0).toDouble(),
          resolution: _resolution,
          reason: reason.isNotEmpty ? reason : null,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Retour enregistré — ${_resolutionLabel(_resolution)}'),
          backgroundColor: kSheetGreen,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _resolutionLabel(String r) => switch (r) {
        'cash_refund' => 'Remboursement cash',
        'credit_note' => 'Avoir client',
        'exchange' => 'Échange article',
        _ => r,
      };

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: kSheetDialogShape,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────────
            const SheetDialogHeader(
              icon: Icons.undo_outlined,
              iconColor: kSheetAmber,
              title: 'Mode de résolution',
              subtitle: 'Choisissez comment traiter le retour',
            ),
            const SizedBox(height: 16),

            // ── Error banner ────────────────────────────────────────────────
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: kSheetRed.withValues(alpha: 0.07),
                  border: Border.all(color: kSheetRed.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        size: 15, color: kSheetRed),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_errorMessage!,
                          style: const TextStyle(
                              fontSize: 12, color: kSheetRed)),
                    ),
                  ],
                ),
              ),
            ],

            // ── Resolution options ──────────────────────────────────────────
            _ResolutionOption(
              value: 'cash_refund',
              groupValue: _resolution,
              icon: Icons.payments_outlined,
              label: 'Remboursement cash',
              subtitle: 'Remettre l\'argent au client',
              onTap: () => setState(() => _resolution = 'cash_refund'),
            ),
            const SizedBox(height: 8),
            _ResolutionOption(
              value: 'credit_note',
              groupValue: _resolution,
              icon: Icons.account_balance_wallet_outlined,
              label: 'Avoir client',
              subtitle: 'Créditer sur son compte',
              onTap: () => setState(() => _resolution = 'credit_note'),
            ),
            const SizedBox(height: 8),
            _ResolutionOption(
              value: 'exchange',
              groupValue: _resolution,
              icon: Icons.sync_alt_outlined,
              label: 'Échange article',
              subtitle: 'Remplacer par un autre produit',
              onTap: () => setState(() => _resolution = 'exchange'),
            ),
            const SizedBox(height: 16),

            // ── Reason field ────────────────────────────────────────────────
            TextField(
              controller: _reasonController,
              decoration: sheetInputDecoration(
                label: 'Motif du retour (optionnel)',
                hint: 'Ex: Article défectueux, mauvaise taille…',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            SheetActionRow(
              cancelLabel: 'Annuler',
              confirmLabel: 'Valider le retour',
              onCancel: _isLoading ? null : () => Navigator.of(context).pop(),
              onConfirm: _isLoading ? null : _validate,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Resolution option tile ─────────────────────────────────────────────────────

class _ResolutionOption extends StatelessWidget {
  final String value;
  final String groupValue;
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ResolutionOption({
    required this.value,
    required this.groupValue,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? kSheetBlue.withValues(alpha: 0.05) : Colors.white,
          border: Border.all(
            color: selected ? kSheetBlue : kSheetSlate200,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: selected
                    ? kSheetBlue.withValues(alpha: 0.12)
                    : kSheetSlate50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon,
                  size: 18,
                  color: selected ? kSheetBlue : kSheetSlate500),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? kSheetBlue : kSheetSlate900,
                      )),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: kSheetSlate500)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, size: 18, color: kSheetBlue),
          ],
        ),
      ),
    );
  }
}
