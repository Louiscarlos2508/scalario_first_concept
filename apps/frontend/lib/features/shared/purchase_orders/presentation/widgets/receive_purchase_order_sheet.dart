import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/shared/purchase_orders/data/models/purchase_order_local.dart';
import 'package:frontend/features/shared/purchase_orders/presentation/providers/purchase_orders_providers.dart';

class _LineState {
  final PurchaseOrderLineLocal line;
  final TextEditingController qtyCtrl;
  final TextEditingController notesCtrl;

  _LineState(this.line)
      : qtyCtrl = TextEditingController(
            text: line.expectedQuantity.toString()),
        notesCtrl =
            TextEditingController(text: line.qualityNotes ?? '');

  double get receivedQty => double.tryParse(qtyCtrl.text) ?? 0.0;
  double get variance => receivedQty - line.expectedQuantity;

  void dispose() {
    qtyCtrl.dispose();
    notesCtrl.dispose();
  }
}

class ReceivePurchaseOrderSheet extends ConsumerStatefulWidget {
  final PurchaseOrderLocal order;
  final VoidCallback? onSuccess;

  const ReceivePurchaseOrderSheet({
    super.key,
    required this.order,
    this.onSuccess,
  });

  @override
  ConsumerState<ReceivePurchaseOrderSheet> createState() =>
      _ReceivePurchaseOrderSheetState();
}

class _ReceivePurchaseOrderSheetState
    extends ConsumerState<ReceivePurchaseOrderSheet> {
  late final List<_LineState> _lineStates;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _lineStates = widget.order.lines.map(_LineState.new).toList();
  }

  @override
  void dispose() {
    for (final s in _lineStates) {
      s.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    final tenantId = ref.read(activeTenantProvider) ?? '';
    final lines = _lineStates
        .map((s) => {
              'purchaseOrderLineId': s.line.id,
              'receivedQuantity': s.receivedQty,
              if (s.notesCtrl.text.trim().isNotEmpty)
                'qualityNotes': s.notesCtrl.text.trim(),
            })
        .toList();

    try {
      final repo = ref.read(purchaseOrdersRepositoryProvider);
      await repo.receiveOrder(widget.order.id, lines, tenantId);

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            key: const Key('snackbar_reception_ok'),
            content: Text(
                'Réception enregistrée — ${lines.length} mouvement(s) de stock créé(s)'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Réceptionner la commande',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ..._lineStates.asMap().entries.map((entry) {
              final idx = entry.key;
              final state = entry.value;
              return _ReceptionLineRow(
                key: Key('reception_line_$idx'),
                state: state,
                onChanged: () => setState(() {}),
              );
            }),

            const SizedBox(height: 16),

            SizedBox(
              height: 48,
              child: ElevatedButton(
                key: const Key('reception_submit_button'),
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Valider la réception'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceptionLineRow extends StatelessWidget {
  final _LineState state;
  final VoidCallback onChanged;

  const _ReceptionLineRow({super.key, required this.state, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final variance = state.variance;
    final showVariance = variance != 0;
    final varianceColor = variance >= 0 ? AppColors.success : AppColors.warning;
    final varianceText = variance >= 0
        ? '+${variance.toStringAsFixed(variance.truncateToDouble() == variance ? 0 : 2)}'
        : variance.toStringAsFixed(variance.truncateToDouble() == variance ? 0 : 2);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.line.itemName ?? state.line.catalogItemId ?? '—',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              'Commandé : ${state.line.expectedQuantity}',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: state.qtyCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Quantité reçue',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                if (showVariance) ...[
                  const SizedBox(width: 12),
                  Text(
                    varianceText,
                    key: Key('variance_${state.line.id}'),
                    style: TextStyle(
                      color: varianceColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: state.notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes qualité (optionnel)',
                hintText: 'ex. produits trop mûrs',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
