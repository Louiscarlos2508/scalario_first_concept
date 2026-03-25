import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/shared/inventory/presentation/providers/internal_requests_provider.dart';

Color _statusColor(String status) {
  switch (status) {
    case 'pending':
      return Colors.orange;
    case 'prepared':
      return Colors.blue;
    case 'approved':
    case 'fulfilled':
      return AppColors.success;
    case 'rejected':
      return AppColors.error;
    default:
      return Colors.grey;
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'pending':
      return 'En attente';
    case 'prepared':
      return 'Préparée';
    case 'approved':
      return 'Approuvée';
    case 'fulfilled':
      return 'Traitée';
    case 'rejected':
      return 'Refusée';
    default:
      return status;
  }
}

class InternalRequestCard extends ConsumerWidget {
  final Map<String, dynamic> request;

  const InternalRequestCard({super.key, required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userProfileProvider).valueOrNull?.role ?? '';
    final status = request['status'] as String? ?? 'pending';
    final urgency = request['urgency'] as String? ?? 'normal';
    final productName =
        (request['catalogItem'] as Map<String, dynamic>?)?['name'] ?? '—';
    final quantity = request['quantity'];
    final reason = request['reason'] as String?;

    final createdAt = request['createdAt'] != null
        ? DateTime.tryParse(request['createdAt'] as String)
        : null;
    final dateStr = createdAt != null
        ? '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}'
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$quantity unité(s)',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                      if (dateStr.isNotEmpty)
                        Text(
                          dateStr,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Badge urgence
                    if (urgency == 'urgent')
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'URGENT',
                          style: TextStyle(
                              color: Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'NORMAL',
                          style: TextStyle(
                              color: Colors.amber,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    const SizedBox(height: 4),
                    // Badge statut
                    Chip(
                      label: Text(
                        _statusLabel(status),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 11),
                      ),
                      backgroundColor: _statusColor(status),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ],
            ),

            // Motif de refus
            if (status == 'rejected' && reason != null && reason.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Motif : $reason',
                style: const TextStyle(
                    color: AppColors.error, fontSize: 12),
              ),
            ],

            // Actions selon rôle et statut
            _buildActions(context, ref, role, status),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(
      BuildContext context, WidgetRef ref, String role, String status) {
    final tenantId = ref.read(activeTenantProvider) ?? '';
    final repo = ref.read(internalRequestsRepositoryProvider);
    final id = request['id'] as String;

    // Manager : pending → Préparer
    if ((role == 'manager' || role == 'owner') && status == 'pending') {
      return _ActionRow(children: [
        OutlinedButton.icon(
          key: Key('ir_prepare_${id.substring(0, 8)}'),
          icon: const Icon(Icons.checklist_outlined, size: 16),
          label: const Text('Préparer'),
          onPressed: () async {
            try {
              await repo.prepare(id, tenantId: tenantId);
              ref.invalidate(internalRequestsProvider);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur : $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
          },
        ),
        const SizedBox(width: 8),
        _RejectButton(id: id, tenantId: tenantId, repo: repo, ref: ref),
      ]);
    }

    // Owner : prepared → Approuver / Modifier quantité / Rejeter
    if (role == 'owner' && status == 'prepared') {
      return _ActionRow(children: [
        ElevatedButton.icon(
          key: Key('ir_approve_${id.substring(0, 8)}'),
          icon: const Icon(Icons.check_circle_outline, size: 16),
          label: const Text('Approuver'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            try {
              await repo.approve(id, tenantId: tenantId);
              ref.invalidate(internalRequestsProvider);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur : $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
          },
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          key: Key('ir_edit_qty_${id.substring(0, 8)}'),
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: const Text('Modifier'),
          onPressed: () =>
              _showEditQuantityDialog(context, ref, id, tenantId, repo),
        ),
        const SizedBox(width: 8),
        _RejectButton(id: id, tenantId: tenantId, repo: repo, ref: ref),
      ]);
    }

    return const SizedBox.shrink();
  }

  void _showEditQuantityDialog(
    BuildContext context,
    WidgetRef ref,
    String id,
    String tenantId,
    dynamic repo,
  ) {
    final controller = TextEditingController(
        text: '${request['quantity']}');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier la quantité'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Quantité'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final qty = int.tryParse(controller.text);
              if (qty == null || qty <= 0) return;
              Navigator.pop(ctx);
              try {
                await repo.approve(id, tenantId: tenantId, quantity: qty);
                ref.invalidate(internalRequestsProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur : $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Approuver'),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final List<Widget> children;
  const _ActionRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 0,
        runSpacing: 4,
        children: children,
      ),
    );
  }
}

class _RejectButton extends StatelessWidget {
  final String id;
  final String tenantId;
  final dynamic repo;
  final WidgetRef ref;

  const _RejectButton({
    required this.id,
    required this.tenantId,
    required this.repo,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      key: Key('ir_reject_${id.substring(0, 8)}'),
      icon: const Icon(Icons.cancel_outlined, size: 16, color: AppColors.error),
      label: const Text('Rejeter',
          style: TextStyle(color: AppColors.error)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.error),
      ),
      onPressed: () => _showRejectDialog(context),
    );
  }

  void _showRejectDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Motif du refus'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Motif (obligatoire)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                await repo.reject(id,
                    tenantId: tenantId, reason: controller.text.trim());
                ref.invalidate(internalRequestsProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur : $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Confirmer le refus'),
          ),
        ],
      ),
    );
  }
}
