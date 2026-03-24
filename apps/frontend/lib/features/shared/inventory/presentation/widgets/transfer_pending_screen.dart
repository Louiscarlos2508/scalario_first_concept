import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/shared/business_type/data/business_type_config_repository.dart';
import 'package:frontend/features/shared/business_type/presentation/providers/business_type_config_provider.dart';
import 'package:frontend/features/shared/inventory/data/repositories/inventory_repository.dart';
import 'package:frontend/features/shared/inventory/presentation/widgets/transfer_confirm_form.dart';
import 'package:intl/intl.dart';

enum TransferPendingMode { confirm, cancel }

/// Shows pending TRANSFER_OUT movements (those without a matching TRANSFER_IN)
/// and provides a role-appropriate action per transfer:
///   - [TransferPendingMode.confirm] → ✅ Confirmer (commercial / POS)
///   - [TransferPendingMode.cancel]  → ❌ Annuler   (owner / manager / backoffice)
class TransferPendingScreen extends ConsumerStatefulWidget {
  final InventoryRepository repository;
  final TransferPendingMode mode;

  const TransferPendingScreen({
    super.key,
    required this.repository,
    this.mode = TransferPendingMode.confirm,
  });

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

    final config = ref.watch(businessTypeConfigProvider).valueOrNull ??
        BusinessTypeConfig.fallback;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            config.confirmAction,
            key: const Key('transfer_pending_title'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        ListView.builder(
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
            final refShort = referenceId.length > 8
                ? referenceId.substring(0, 8)
                : referenceId;
            final fromLocation = transfer['fromLocation'] as String?;
            final toLocation = transfer['toLocation'] as String?;

            final locationLabel = fromLocation != null && toLocation != null
                ? '${config.fromLabel} : $fromLocation → ${config.toLabel} : $toLocation'
                : fromLocation != null
                    ? '${config.fromLabel} : $fromLocation'
                    : toLocation != null
                        ? '${config.toLabel} : $toLocation'
                        : null;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              child: ListTile(
                leading:
                    const Icon(Icons.swap_horiz, color: AppColors.primary),
                title: Text('Qté déclarée : $quantity'),
                subtitle: Text(
                  [
                    'Réf. $refShort… · $dateLabel',
                    ?locationLabel,
                  ].join('\n'),
                ),
                trailing: widget.mode == TransferPendingMode.cancel
                    ? OutlinedButton.icon(
                        key: Key('transfer_cancel_button_$referenceId'),
                        icon: const Icon(Icons.close, color: AppColors.error),
                        label: const Text('Annuler',
                            style: TextStyle(color: AppColors.error)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                        ),
                        onPressed: () =>
                            _showCancelConfirmDialog(context, transfer),
                      )
                    : ElevatedButton(
                        key: Key('transfer_confirm_button_$referenceId'),
                        onPressed: () => _showConfirmDialog(context, transfer),
                        child: Text(config.confirmButton),
                      ),
              ),
            );
          },
        ),
      ],
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
    final config = ref.read(businessTypeConfigProvider).valueOrNull
        ?? BusinessTypeConfig.fallback;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: TransferConfirmForm(
          repository: widget.repository,
          referenceId: referenceId,
          catalogItemId: catalogItemId,
          declaredQuantity: declaredQty,
          confirmButton: config.confirmButton,
          onSuccess: () {
            Navigator.pop(context);
            _load();
          },
        ),
      ),
    );
  }

  Future<void> _showCancelConfirmDialog(
    BuildContext context,
    Map<String, dynamic> transfer,
  ) async {
    final referenceId = transfer['referenceId'] as String? ?? '';
    final quantity = transfer['quantity'];
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler le transfert'),
        content: Text(
          'Annuler le transfert de $quantity unité(s) ?\n'
          'Le stock sera restitué.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final tenantId = ref.read(activeTenantProvider) ?? '';
      await widget.repository.cancelTransfer(
        referenceId: referenceId,
        tenantId: tenantId,
      );
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Transfert annulé')),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
