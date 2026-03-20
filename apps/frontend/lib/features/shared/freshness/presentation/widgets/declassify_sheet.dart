import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/constants/api_constants.dart';

/// AC3 (Story 24-3) — Bottom sheet for declassifying (writing off) a batch.
class DeclassifySheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> batch;

  const DeclassifySheet({super.key, required this.batch});

  @override
  ConsumerState<DeclassifySheet> createState() => _DeclassifySheetState();
}

class _DeclassifySheetState extends ConsumerState<DeclassifySheet> {
  late final TextEditingController _qtyController;
  String _reason = 'Péremption';
  bool _loading = false;

  static const _reasons = [
    'Péremption',
    'Détérioration qualité',
    'Variance naturelle',
  ];

  @override
  void initState() {
    super.initState();
    final qty = widget.batch['remainingQty'];
    _qtyController = TextEditingController(text: qty?.toString() ?? '0');
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  bool get _isNaturalVariance => _reason == 'Variance naturelle';

  Future<void> _submit() async {
    final qty = double.tryParse(_qtyController.text.trim());
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantité invalide')),
      );
      return;
    }

    setState(() => _loading = true);

    final tenantId = ref.read(activeTenantProvider);
    final token = Supabase.instance.client.auth.currentSession?.accessToken;

    // Map reason to backend value
    final backendReason = _isNaturalVariance ? 'NATURAL_VARIANCE' : _reason;

    final headers = {
      'Content-Type': 'application/json',
      if (tenantId != null) 'x-tenant-id': tenantId,
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      // 1. Create LOSS movement
      final lossResponse = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/inventory/movements'),
        headers: headers,
        body: jsonEncode({
          'catalogItemId': widget.batch['catalogItemId'],
          'quantity': qty,
          'type': 'LOSS',
          'reason': backendReason,
          if (tenantId != null) 'tenantId': tenantId,
        }),
      );

      if (lossResponse.statusCode != 201 && lossResponse.statusCode != 200) {
        throw Exception('Erreur déclaration perte: ${lossResponse.statusCode}');
      }

      // 2. Mark batch depleted
      final batchId = widget.batch['batchId']?.toString();
      if (batchId != null) {
        await http.patch(
          Uri.parse(
            '${ApiConstants.baseUrl}/batches/$batchId/deplete',
          ).replace(queryParameters: {if (tenantId != null) 'tenantId': tenantId}),
          headers: headers,
        );
      }

      if (mounted) {
        Navigator.pop(context, true); // true = refresh list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lot déclassé avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemName = widget.batch['itemName']?.toString() ?? '—';

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Déclasser — $itemName',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _qtyController,
            decoration:
                const InputDecoration(labelText: 'Quantité à déclasser'),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _reason,
            decoration: const InputDecoration(labelText: 'Motif'),
            items: _reasons
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (v) => setState(() => _reason = v ?? _reason),
          ),
          if (_isNaturalVariance) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'ℹ️ Sera enregistré comme variance naturelle si dans la tolérance configurée.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Valider le déclassement'),
            ),
          ),
        ],
      ),
    );
  }
}
