import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/shared/client_orders/domain/models/client_order.dart';
import 'package:frontend/features/shared/client_orders/presentation/providers/client_orders_provider.dart';
import 'package:frontend/features/shared/client_orders/domain/models/client_order_line.dart';
import 'package:frontend/features/shared/client_orders/presentation/screens/client_order_deliver_screen.dart';

({Color bg, Color fg, String label}) _statusInfo(String status) =>
    switch (status) {
      'draft' => (bg: Colors.grey.shade200, fg: Colors.grey.shade700, label: 'Brouillon'),
      'confirmed' => (bg: Colors.blue.shade100, fg: Colors.blue.shade800, label: 'Confirmée'),
      'in-progress' => (bg: Colors.orange.shade100, fg: Colors.orange.shade800, label: 'En préparation'),
      'ready' => (bg: Colors.orange.shade200, fg: Colors.orange.shade900, label: 'Prête'),
      'delivered' => (bg: Colors.green.shade100, fg: Colors.green.shade800, label: 'Livrée'),
      'invoiced' => (bg: Colors.green.shade200, fg: Colors.green.shade900, label: 'Facturée'),
      'paid' => (bg: Colors.green.shade300, fg: Colors.green.shade900, label: 'Payée'),
      'cancelled' => (bg: Colors.red.shade100, fg: Colors.red.shade800, label: 'Annulée'),
      _ => (bg: Colors.grey.shade200, fg: Colors.grey.shade700, label: status),
    };

String _fcfa(double amount) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(amount);

class ClientOrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const ClientOrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(clientOrderDetailProvider(orderId));
    final role = ref.watch(userProfileProvider).valueOrNull?.role;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail commande'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(clientOrderDetailProvider(orderId)),
          ),
        ],
      ),
      body: orderAsync.when(
        data: (order) => _buildBody(context, ref, order, role),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, WidgetRef ref, ClientOrder order, String? role) {
    final info = _statusInfo(order.status);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Header ─────────────────────────────────────────────────────────
        Row(
          children: [
            Text(order.orderNumber,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: info.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(info.label,
                  style: TextStyle(
                      color: info.fg, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _row('Client',
            order.customerName ?? order.customerId.substring(0, 8)),
        _row('Créée le',
            DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)),
        if (order.deliveredAt != null)
          _row('Livrée le',
              DateFormat('dd/MM/yyyy').format(order.deliveredAt!)),
        if (order.notes != null && order.notes!.isNotEmpty)
          _row('Notes', order.notes!),
        const Divider(height: 24),

        // ── Lines ───────────────────────────────────────────────────────────
        Text('Articles',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ...order.lines.map((line) => _buildLineRow(line)),
        const Divider(height: 24),

        // ── Footer ──────────────────────────────────────────────────────────
        _row('Total commande', _fcfa(order.totalAmount),
            bold: true),
        if (order.depositAmount != null && order.depositAmount! > 0)
          _row('Acompte versé', _fcfa(order.depositAmount!)),
        const SizedBox(height: 24),

        // ── Actions ─────────────────────────────────────────────────────────
        ..._buildActions(context, ref, order, role),
      ],
    );
  }

  Widget _buildLineRow(ClientOrderLine line) {
    final qty = line.quantity;
    final delivered = line.deliveredQty;
    final subtotal = qty * line.unitPrice;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.catalogItemId.length > 8
                    ? line.catalogItemId.substring(0, 8)
                    : line.catalogItemId),
                if (delivered > 0 && delivered < qty)
                  Text('Livré: $delivered / $qty',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.orange)),
              ],
            ),
          ),
          Text('${qty.toStringAsFixed(0)} × ${_fcfa(line.unitPrice)}'),
          const SizedBox(width: 8),
          Text(_fcfa(subtotal),
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context, WidgetRef ref,
      ClientOrder order, String? role) {
    final isOwnerOrManager = role == 'owner' || role == 'manager';

    Future<void> callTransition(Future<void> Function() action) async {
      try {
        await action();
        ref.invalidate(clientOrderDetailProvider(orderId));
        ref.invalidate(clientOrdersProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Statut mis à jour'),
                backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Erreur : $e'), backgroundColor: Colors.red),
          );
        }
      }
    }

    final tenantId = ref.read(activeTenantProvider) ?? '';
    final repo = ref.read(clientOrderRepositoryProvider);
    final actions = <Widget>[];

    if (order.status == 'confirmed') {
      actions.add(_actionBtn('Préparer', Colors.orange, () => callTransition(
            () => repo.prepareOrder(order.id, tenantId: tenantId))));
    }
    if (order.status == 'in-progress') {
      actions.add(_actionBtn('Marquer prête', Colors.blue, () => callTransition(
            () => repo.markReady(order.id, tenantId: tenantId))));
    }
    if (order.status == 'ready') {
      actions.add(_actionBtn('Livrer', Colors.green, () async {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => ClientOrderDeliverScreen(order: order),
          ),
        );
        if (result == true) {
          ref.invalidate(clientOrderDetailProvider(orderId));
          ref.invalidate(clientOrdersProvider);
        }
      }));
    }
    if (order.status == 'delivered' && isOwnerOrManager) {
      actions.add(_actionBtn('Facturer', Colors.purple, () => callTransition(
            () => repo.invoiceOrder(order.id, tenantId: tenantId))));
    }
    if (order.status == 'invoiced' && isOwnerOrManager) {
      actions.add(_actionBtn('Encaisser', Colors.green, () => callTransition(
            () => repo.payOrder(order.id, tenantId: tenantId))));
    }
    if (order.status == 'draft' && isOwnerOrManager) {
      actions.add(_actionBtn('Modifier', Colors.grey.shade700, () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => _EditClientOrderSheet(
            order: order,
            onSuccess: () {
              ref.invalidate(clientOrderDetailProvider(orderId));
              ref.invalidate(clientOrdersProvider);
            },
          ),
        );
      }));
    }
    if ((order.status == 'draft' || order.status == 'confirmed') &&
        isOwnerOrManager) {
      actions.add(_actionBtn('Annuler', Colors.red, () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Annuler la commande'),
            content: Text('Confirmer l\'annulation de ${order.orderNumber} ?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Retour')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Annuler la commande'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await callTransition(
              () => repo.cancelOrder(order.id, tenantId: tenantId));
        }
      }));
    }

    if (actions.isEmpty) return [];
    return [
      Wrap(spacing: 8, runSpacing: 8, children: actions),
      const SizedBox(height: 16),
    ];
  }

  Widget _actionBtn(
      String label, Color color, VoidCallback onPressed) {
    return FilledButton(
      style: FilledButton.styleFrom(backgroundColor: color),
      onPressed: onPressed,
      child: Text(label),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text('$label  ', style: const TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontWeight:
                        bold ? FontWeight.bold : FontWeight.normal)),
          ),
        ],
      ),
    );
  }
}

// ── Edit draft client order sheet ─────────────────────────────────────────────

class _EditClientOrderSheet extends ConsumerStatefulWidget {
  final ClientOrder order;
  final VoidCallback onSuccess;

  const _EditClientOrderSheet({required this.order, required this.onSuccess});

  @override
  ConsumerState<_EditClientOrderSheet> createState() =>
      _EditClientOrderSheetState();
}

class _EditClientOrderSheetState extends ConsumerState<_EditClientOrderSheet> {
  late final TextEditingController _notesCtrl;
  late final TextEditingController _depositCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController(text: widget.order.notes ?? '');
    _depositCtrl = TextEditingController(
      text: widget.order.depositAmount != null &&
              widget.order.depositAmount! > 0
          ? widget.order.depositAmount!.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _depositCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final tenantId = ref.read(activeTenantProvider);
    if (tenantId == null) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(clientOrderRepositoryProvider);
      final deposit = double.tryParse(_depositCtrl.text.trim());
      await repo.updateDraft(
        widget.order.id,
        tenantId: tenantId,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        depositAmount: deposit,
      );
      widget.onSuccess();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commande mise à jour'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Modifier la commande',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 20),
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _depositCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Acompte (FCFA)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
