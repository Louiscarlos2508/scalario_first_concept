import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/retail/inventory/data/repositories/inventory_repository.dart';
import 'package:intl/intl.dart';

/// Shows pending TRANSFER_OUT movements (those without a matching TRANSFER_IN)
/// and provides a "Confirmer la réception" button per transfer.
class TransferPendingScreen extends ConsumerStatefulWidget {
  final InventoryRepository repository;

  const TransferPendingScreen({super.key, required this.repository});

  @override
  ConsumerState<TransferPendingScreen> createState() =>
      _TransferPendingScreenState();
}

class _TransferPendingScreenState
    extends ConsumerState<TransferPendingScreen> {
  List<Map<String, dynamic>>? _pending;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tenantId = ref.read(activeTenantProvider) ?? '';
      final data = await widget.repository.getPendingTransfers(
        tenantId: tenantId,
      );
      if (mounted) {
        setState(() {
          _pending = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Erreur : $_error',
                style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: const Text('Réessayer')),
          ],
        ),
      );
    }

    final pending = _pending ?? [];

    if (pending.isEmpty) {
      return const Center(
        key: Key('transfer_pending_empty'),
        child: Text(
          'Aucun transfert en attente de confirmation.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pending.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, i) {
        final transfer = pending[i];
        final referenceId = transfer['referenceId'] as String? ?? '';
        final quantity = transfer['quantity'];
        final createdAt = transfer['createdAt'] as String?;
        final dateLabel = createdAt != null
            ? DateFormat('dd/MM HH:mm')
                .format(DateTime.parse(createdAt).toLocal())
            : '—';
        final refShort =
            referenceId.length > 8 ? referenceId.substring(0, 8) : referenceId;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: ListTile(
            leading: const Icon(Icons.swap_horiz, color: AppColors.primary),
            title: Text('Qté déclarée : $quantity'),
            subtitle: Text('Réf. $refShort… · $dateLabel'),
            trailing: ElevatedButton(
              key: Key('transfer_confirm_button_$referenceId'),
              onPressed: () => _showConfirmDialog(context, transfer),
              child: const Text('Confirmer'),
            ),
          ),
        );
      },
    );
  }

  void _showConfirmDialog(
    BuildContext context,
    Map<String, dynamic> transfer,
  ) {
    final referenceId = transfer['referenceId'] as String? ?? '';
    final catalogItemId = transfer['catalogItemId'] as String?;
    final declaredQty = transfer['quantity'] is int
        ? transfer['quantity'] as int
        : int.tryParse(transfer['quantity'].toString()) ?? 0;

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer la réception'),
        content: Text('Référence : $referenceId\nQté déclarée : $declaredQty'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _confirm(referenceId, catalogItemId, declaredQty);
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm(
    String referenceId,
    String? catalogItemId,
    int quantity,
  ) async {
    try {
      final tenantId = ref.read(activeTenantProvider) ?? '';
      await widget.repository.confirmTransfer(
        referenceId: referenceId,
        catalogItemId: catalogItemId,
        quantity: quantity,
        tenantId: tenantId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Réception confirmée')),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
