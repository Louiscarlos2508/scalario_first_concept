import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/shared/client_orders/domain/models/client_order.dart';
import 'package:frontend/features/shared/client_orders/domain/models/client_order_line.dart';
import 'package:frontend/features/shared/client_orders/presentation/providers/client_orders_provider.dart';
import 'package:frontend/features/shared/client_orders/presentation/widgets/client_order_document_widget.dart';

String _fcfa(double v) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(v);

class ClientOrderDeliverScreen extends ConsumerStatefulWidget {
  final ClientOrder order;

  const ClientOrderDeliverScreen({super.key, required this.order});

  @override
  ConsumerState<ClientOrderDeliverScreen> createState() =>
      _ClientOrderDeliverScreenState();
}

class _ClientOrderDeliverScreenState
    extends ConsumerState<ClientOrderDeliverScreen> {
  late final Map<String, TextEditingController> _controllers;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final line in widget.order.lines)
        line.id: TextEditingController(
            text: line.quantity.toStringAsFixed(0)),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double get _totalDelivered => widget.order.lines.fold(0.0, (sum, line) {
        final qty =
            double.tryParse(_controllers[line.id]?.text ?? '0') ?? 0.0;
        return sum + qty * line.unitPrice;
      });

  Future<void> _confirm() async {
    setState(() => _isSubmitting = true);
    try {
      final tenantId = ref.read(activeTenantProvider) ?? '';
      final repo = ref.read(clientOrderRepositoryProvider);
      final lines = widget.order.lines.map((line) {
        final qty =
            double.tryParse(_controllers[line.id]?.text ?? '0') ?? 0.0;
        return {'lineId': line.id, 'deliveredQty': qty};
      }).toList();

      final delivered = await repo.deliverOrder(
        widget.order.id,
        tenantId: tenantId,
        lines: lines,
      );

      ref.invalidate(clientOrdersProvider);
      ref.invalidate(clientOrderDetailProvider(widget.order.id));

      if (!mounted) return;
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => ClientOrderDocumentWidget(order: delivered),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Livrer ${widget.order.orderNumber}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Saisissez les quantités livrées',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                ...widget.order.lines.map(
                    (line) => _buildLineRow(line)),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Total livré : ${_fcfa(_totalDelivered)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _isSubmitting ? null : _confirm,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Confirmer la livraison'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineRow(ClientOrderLine line) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.catalogItemId.length > 8
                        ? line.catalogItemId.substring(0, 8)
                        : line.catalogItemId,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Commandé : ${line.quantity.toStringAsFixed(0)} × ${_fcfa(line.unitPrice)}',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 90,
              child: TextFormField(
                controller: _controllers[line.id],
                decoration: const InputDecoration(
                  labelText: 'Qté livrée',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[0-9.]')),
                ],
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
