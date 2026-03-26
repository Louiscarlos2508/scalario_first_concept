import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/providers/payment_methods_provider.dart';
import 'package:frontend/features/shared/reservations/presentation/providers/reservations_provider.dart';

String _fcfa(double v) => NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    ).format(v);

double _toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? 0.0;
}

/// POS bottom sheet — liste des réservations en attente avec actions
/// Compléter / Annuler directement depuis la caisse.
class PosReservationsSheet extends ConsumerWidget {
  const PosReservationsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(reservationsListProvider('pending'));
    final role = ref.watch(userProfileProvider).valueOrNull?.role ?? '';
    final canCancel = role == 'manager' || role == 'owner';

    // Enabled methods, minus CREDIT and SPLIT (not valid for reservation settlement)
    final allMethods = ref.watch(enabledPaymentMethodsProvider).valueOrNull ??
        kDefaultPaymentMethods;
    final reservationPaymentMethods =
        allMethods.where((m) => m != 'CREDIT' && m != 'SPLIT').toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Réservations en cours',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Rafraîchir',
                onPressed: () =>
                    ref.invalidate(reservationsListProvider('pending')),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: listAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur : $e')),
            data: (items) {
              if (items.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Aucune réservation en cours',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, i) => _PosReservationCard(
                  reservation: items[i] as Map<String, dynamic>,
                  canCancel: canCancel,
                  paymentMethods: reservationPaymentMethods,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Reservation card ──────────────────────────────────────────────────────────

class _PosReservationCard extends ConsumerWidget {
  final Map<String, dynamic> reservation;
  final bool canCancel;
  final List<String> paymentMethods;

  const _PosReservationCard({
    required this.reservation,
    required this.canCancel,
    required this.paymentMethods,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = _toDouble(reservation['totalAmount']);
    final deposit = _toDouble(reservation['depositAmount']);
    final remaining = _toDouble(reservation['remainingAmount']);
    final createdAt = reservation['createdAt'] != null
        ? DateTime.tryParse(reservation['createdAt'].toString())
        : null;

    final customerName = reservation['customerName']?.toString() ??
        reservation['customer']?['name']?.toString() ??
        '—';
    final customerPhone = reservation['customerPhone']?.toString() ??
        reservation['customer']?['phone']?.toString();

    final items = reservation['itemsJson'] is List
        ? (reservation['itemsJson'] as List)
        : <dynamic>[];

    final initial =
        customerName.isNotEmpty && customerName != '—' ? customerName[0].toUpperCase() : '?';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: avatar + name + date ──
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.teal.withValues(alpha: 0.15),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (customerPhone != null)
                        Text(
                          customerPhone,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                if (createdAt != null)
                  Text(
                    DateFormat('dd/MM HH:mm').format(createdAt),
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // ── Items list ──
            if (items.isNotEmpty) ...[
              Text(
                '${items.length} article(s) réservé(s)',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 4),
              ...items.take(3).map((item) {
                final name = item['name']?.toString() ?? 'Article inconnu';
                final qty = item['quantity'];
                final price = (item['unitPrice'] as num?)?.toDouble();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      const Text('• ',
                          style: TextStyle(color: Colors.grey)),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '× $qty',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                      if (price != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          _fcfa(price * (qty as num).toDouble()),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                );
              }),
              if (items.length > 3)
                Text(
                  '+ ${items.length - 3} autre(s)…',
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              const SizedBox(height: 10),
            ],

            // ── Amounts ──
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _amountCol('Total', total, Colors.black87),
                  _amountCol('Acompte reçu', deposit, Colors.blue),
                  _amountCol('Solde à payer', remaining, Colors.orange,
                      bold: true),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Actions ──
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.payments_outlined, size: 16),
                    label: Text('Encaisser ${_fcfa(remaining)}'),
                    onPressed: () =>
                        _showCompleteDialog(context, ref, remaining, paymentMethods),
                  ),
                ),
                if (canCancel) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red),
                    onPressed: () => _showCancelDialog(context, ref, deposit),
                    child: const Text('Annuler'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _methodIcon(String method) {
    switch (method.toUpperCase()) {
      case 'CASH':
        return Icons.payments_outlined;
      case 'MOBILE_MONEY':
        return Icons.phone_android_outlined;
      case 'CARD':
        return Icons.credit_card_outlined;
      case 'TRANSFER':
        return Icons.swap_horiz_outlined;
      default:
        return Icons.attach_money;
    }
  }

  Widget _amountCol(String label, double amount, Color color,
      {bool bold = false}) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          _fcfa(amount),
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: color,
            fontSize: bold ? 14 : 12,
          ),
        ),
      ],
    );
  }

  Future<void> _showCompleteDialog(
    BuildContext context,
    WidgetRef ref,
    double remaining,
    List<String> paymentMethods,
  ) async {
    String paymentMethod =
        paymentMethods.contains('CASH') ? 'CASH' : paymentMethods.first;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Encaisser le solde'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Montant à encaisser'),
                    Text(
                      _fcfa(remaining),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Mode de paiement',
                  border: OutlineInputBorder(),
                ),
                items: paymentMethods
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Row(
                            children: [
                              Icon(_methodIcon(m), size: 18),
                              const SizedBox(width: 8),
                              Text(paymentMethodLabel(m)),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => paymentMethod = v!),
              ),
              const SizedBox(height: 12),
              const Text(
                'Le stock sera automatiquement mis à jour.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmer'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final tenantId = ref.read(activeTenantProvider) ?? '';
      await ref.read(reservationsRepositoryProvider).completeReservation(
            tenantId: tenantId,
            id: reservation['id'].toString(),
            paymentMethod: paymentMethod,
            amount: remaining,
          );
      ref.invalidate(reservationsListProvider('pending'));
      ref.invalidate(reservationsKpiProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paiement encaissé — Réservation clôturée'),
            backgroundColor: Colors.green,
          ),
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

  Future<void> _showCancelDialog(
      BuildContext context, WidgetRef ref, double deposit) async {
    String resolution = 'cash_refund';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Annuler la réservation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Acompte à restituer'),
                    Text(
                      _fcfa(deposit),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text("Comment restituer l'acompte ?"),
              const SizedBox(height: 8),
              RadioListTile<String>(
                value: 'cash_refund',
                groupValue: resolution,
                onChanged: (v) => setState(() => resolution = v!),
                title: const Text('Rembourser en espèces'),
                subtitle: Text(
                  'Remettre ${_fcfa(deposit)} en cash au client',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              RadioListTile<String>(
                value: 'credit_note',
                groupValue: resolution,
                onChanged: (v) => setState(() => resolution = v!),
                title: const Text('Avoir client'),
                subtitle: Text(
                  '${_fcfa(deposit)} créditées sur son compte',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Retour'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Confirmer l'annulation"),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final tenantId = ref.read(activeTenantProvider) ?? '';
      final userProfile = ref.read(userProfileProvider).value;
      await ref.read(reservationsRepositoryProvider).cancelReservation(
            tenantId: tenantId,
            userId: userProfile?.id ?? '',
            role: userProfile?.role ?? '',
            id: reservation['id'].toString(),
            depositResolution: resolution,
          );
      ref.invalidate(reservationsListProvider('pending'));
      ref.invalidate(reservationsKpiProvider);
      if (context.mounted) {
        final label =
            resolution == 'cash_refund' ? 'Remboursement cash' : 'Avoir client';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Réservation annulée — $label')),
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
}
