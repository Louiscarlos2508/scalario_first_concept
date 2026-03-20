import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
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
          unitPrice: (line['unitPrice'] ?? line['price'] as num? ?? 0).toDouble(),
          resolution: _resolution,
          reason: reason.isNotEmpty ? reason : null,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      final resolutionLabel = _resolutionLabel(_resolution);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Retour enregistré — $resolutionLabel'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _resolutionLabel(String resolution) {
    switch (resolution) {
      case 'cash_refund':
        return 'Remboursement cash';
      case 'credit_note':
        return 'Avoir client';
      case 'exchange':
        return 'Échange article';
      default:
        return resolution;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mode de résolution'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            RadioListTile<String>(
              value: 'cash_refund',
              groupValue: _resolution,
              onChanged: (v) => setState(() => _resolution = v!),
              title: const Text('Remboursement cash'),
              secondary: const Icon(Icons.payments),
            ),
            RadioListTile<String>(
              value: 'credit_note',
              groupValue: _resolution,
              onChanged: (v) => setState(() => _resolution = v!),
              title: const Text('Avoir client — crédité sur le compte'),
              secondary: const Icon(Icons.account_balance_wallet),
            ),
            RadioListTile<String>(
              value: 'exchange',
              groupValue: _resolution,
              onChanged: (v) => setState(() => _resolution = v!),
              title: const Text('Échange article'),
              secondary: const Icon(Icons.sync_alt),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Motif du retour',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _validate,
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Valider'),
        ),
      ],
    );
  }
}
