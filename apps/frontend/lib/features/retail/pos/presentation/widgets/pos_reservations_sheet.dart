import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/providers/payment_methods_provider.dart';
import 'package:frontend/core/theme/sheet_style.dart';
import 'package:frontend/features/shared/reservations/presentation/providers/reservations_provider.dart';

String _fcfa(double v) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(v);

double _toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? 0.0;
}

class PosReservationsSheet extends ConsumerWidget {
  const PosReservationsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(reservationsListProvider('pending'));
    final role = ref.watch(userProfileProvider).valueOrNull?.role ?? '';
    final canCancel = role == 'manager' || role == 'owner';

    final allMethods =
        ref.watch(enabledPaymentMethodsProvider).valueOrNull ??
            kDefaultPaymentMethods;
    final reservationPaymentMethods =
        allMethods.where((m) => m.code != 'CREDIT' && m.code != 'SPLIT').toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────
          SheetTitleRow(
            title: 'Réservations en cours',
            icon: Icons.bookmark_outlined,
            iconColor: kSheetBlue,
            trailing: IconButton(
              icon: const Icon(Icons.refresh_outlined,
                  size: 18, color: kSheetSlate500),
              tooltip: 'Rafraîchir',
              onPressed: () =>
                  ref.invalidate(reservationsListProvider('pending')),
            ),
          ),
          const SheetDivider(),
          const SizedBox(height: 12),

          // ── List ──────────────────────────────────────────────────────
          Expanded(
            child: listAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 40, color: kSheetRed),
                    const SizedBox(height: 8),
                    Text('Erreur : $e',
                        style: const TextStyle(color: kSheetSlate500)),
                  ],
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bookmark_border_outlined,
                            size: 48, color: kSheetSlate200),
                        const SizedBox(height: 12),
                        const Text('Aucune réservation en cours',
                            style: TextStyle(
                                color: kSheetSlate500, fontSize: 14)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _ReservationCard(
                    reservation: items[i] as Map<String, dynamic>,
                    canCancel: canCancel,
                    paymentMethods: reservationPaymentMethods,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reservation card ──────────────────────────────────────────────────────────

class _ReservationCard extends ConsumerWidget {
  final Map<String, dynamic> reservation;
  final bool canCancel;
  final List<PaymentMethod> paymentMethods;

  const _ReservationCard({
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

    final letter = customerName.isNotEmpty && customerName != '—'
        ? customerName[0].toUpperCase()
        : '?';
    final avatarColors = [
      Colors.teal, Colors.blue, Colors.orange,
      Colors.purple, Colors.green,
    ];
    final avatarColor = customerName != '—' && customerName.isNotEmpty
        ? avatarColors[customerName.codeUnitAt(0) % avatarColors.length]
        : Colors.grey;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kSheetSlate200, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Customer row ─────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: avatarColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(letter,
                        style: TextStyle(
                            color: avatarColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customerName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: kSheetSlate900)),
                      if (customerPhone != null)
                        Text(customerPhone,
                            style: const TextStyle(
                                color: kSheetSlate500, fontSize: 12)),
                    ],
                  ),
                ),
                if (createdAt != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: kSheetSlate50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      DateFormat('dd/MM HH:mm').format(createdAt),
                      style: const TextStyle(
                          color: kSheetSlate500, fontSize: 11),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),
            const SheetDivider(),
            const SizedBox(height: 10),

            // ── Items preview ────────────────────────────────────────────
            if (items.isNotEmpty) ...[
              Text('${items.length} article(s) réservé(s)',
                  style: const TextStyle(
                      fontSize: 11,
                      color: kSheetSlate500,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              ...items.take(3).map((item) {
                final name =
                    item['name']?.toString() ?? 'Article inconnu';
                final qty = item['quantity'];
                final price = (item['unitPrice'] as num?)?.toDouble();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: const BoxDecoration(
                          color: kSheetSlate200,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(name,
                            style: const TextStyle(
                                fontSize: 12, color: kSheetSlate900),
                            overflow: TextOverflow.ellipsis),
                      ),
                      Text('×$qty',
                          style: const TextStyle(
                              fontSize: 11, color: kSheetSlate500)),
                      if (price != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          _fcfa(price * (qty as num).toDouble()),
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: kSheetSlate900),
                        ),
                      ],
                    ],
                  ),
                );
              }),
              if (items.length > 3)
                Text('+ ${items.length - 3} autre(s)…',
                    style: const TextStyle(
                        color: kSheetSlate500, fontSize: 11)),
              const SizedBox(height: 10),
            ],

            // ── Amounts ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: kSheetSlate50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kSheetSlate200),
              ),
              child: Row(
                children: [
                  _AmountChip(
                      label: 'Total', amount: total, color: kSheetSlate900),
                  _vDivider(),
                  _AmountChip(
                      label: 'Acompte',
                      amount: deposit,
                      color: kSheetBlue),
                  _vDivider(),
                  _AmountChip(
                      label: 'Solde',
                      amount: remaining,
                      color: kSheetAmber,
                      bold: true),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Actions ──────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: sheetPrimaryButtonStyle(color: kSheetGreen),
                    icon: const Icon(Icons.payments_outlined, size: 15),
                    label: Text('Encaisser ${_fcfa(remaining)}',
                        style: const TextStyle(fontSize: 12)),
                    onPressed: () => _showCompleteDialog(
                        context, ref, remaining, paymentMethods),
                  ),
                ),
                if (canCancel) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kSheetRed,
                      side: BorderSide(
                          color: kSheetRed.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () =>
                        _showCancelDialog(context, ref, deposit),
                    child: const Text('Annuler',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _vDivider() => Container(
      width: 1, height: 32, color: kSheetSlate200,
      margin: const EdgeInsets.symmetric(horizontal: 12));

  IconData _methodIcon(String method) => switch (method.toUpperCase()) {
        'CASH' => Icons.payments_outlined,
        'MOBILE_MONEY' => Icons.phone_android_outlined,
        'CARD' => Icons.credit_card_outlined,
        'TRANSFER' => Icons.swap_horiz_outlined,
        _ => Icons.attach_money,
      };

  Future<void> _showCompleteDialog(
    BuildContext context,
    WidgetRef ref,
    double remaining,
    List<PaymentMethod> paymentMethods,
  ) async {
    String paymentMethod = paymentMethods.any((m) => m.code == 'CASH')
        ? 'CASH'
        : paymentMethods.first.code;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: kSheetDialogShape,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SheetDialogHeader(
                  icon: Icons.payments_outlined,
                  iconColor: kSheetGreen,
                  title: 'Encaisser le solde',
                  subtitle: 'Finaliser la réservation',
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kSheetGreen.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: kSheetGreen.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Solde à encaisser',
                          style: TextStyle(
                              fontSize: 13, color: kSheetSlate500)),
                      Text(
                        _fcfa(remaining),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            color: kSheetGreen),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const SheetSectionLabel('Mode de paiement'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: paymentMethods.map((m) {
                    final selected = m.code == paymentMethod;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => paymentMethod = m.code),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: selected ? kSheetBlue : Colors.white,
                          border: Border.all(
                            color: selected
                                ? kSheetBlue
                                : kSheetSlate200,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_methodIcon(m.code),
                                size: 14,
                                color: selected
                                    ? Colors.white
                                    : kSheetSlate500),
                            const SizedBox(width: 6),
                            Text(m.label,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? Colors.white
                                        : kSheetSlate500)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Le stock sera automatiquement mis à jour.',
                  style: TextStyle(fontSize: 11, color: kSheetSlate500),
                ),
                const SizedBox(height: 20),
                SheetActionRow(
                  confirmLabel: 'Confirmer',
                  confirmColor: kSheetGreen,
                  onConfirm: () => Navigator.pop(context, true),
                  onCancel: () => Navigator.pop(context, false),
                ),
              ],
            ),
          ),
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
            backgroundColor: kSheetGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur : $e'),
              backgroundColor: kSheetRed),
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
        builder: (context, setState) => Dialog(
          shape: kSheetDialogShape,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SheetDialogHeader(
                  icon: Icons.cancel_outlined,
                  iconColor: kSheetRed,
                  title: 'Annuler la réservation',
                  subtitle: 'Choisissez comment restituer l\'acompte',
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: kSheetAmber.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: kSheetAmber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Acompte à restituer',
                          style: TextStyle(
                              fontSize: 13, color: kSheetSlate500)),
                      Text(_fcfa(deposit),
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: kSheetAmber)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _CancelOption(
                  value: 'cash_refund',
                  groupValue: resolution,
                  icon: Icons.payments_outlined,
                  label: 'Rembourser en espèces',
                  subtitle: 'Remettre ${_fcfa(deposit)} en cash',
                  onTap: () => setState(() => resolution = 'cash_refund'),
                ),
                const SizedBox(height: 8),
                _CancelOption(
                  value: 'credit_note',
                  groupValue: resolution,
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Avoir client',
                  subtitle: '${_fcfa(deposit)} crédités sur son compte',
                  onTap: () => setState(() => resolution = 'credit_note'),
                ),
                const SizedBox(height: 20),
                SheetActionRow(
                  cancelLabel: 'Retour',
                  confirmLabel: "Confirmer l'annulation",
                  confirmColor: kSheetRed,
                  onConfirm: () => Navigator.pop(context, true),
                  onCancel: () => Navigator.pop(context, false),
                ),
              ],
            ),
          ),
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
        final label = resolution == 'cash_refund'
            ? 'Remboursement cash'
            : 'Avoir client';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Réservation annulée — $label')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur : $e'),
              backgroundColor: kSheetRed),
        );
      }
    }
  }
}

// ── Amount chip ───────────────────────────────────────────────────────────────

class _AmountChip extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool bold;
  const _AmountChip(
      {required this.label,
      required this.amount,
      required this.color,
      this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(fontSize: 10, color: kSheetSlate500)),
          const SizedBox(height: 2),
          Text(
            _fcfa(amount),
            style: TextStyle(
              fontSize: bold ? 13 : 11,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cancel option tile ────────────────────────────────────────────────────────

class _CancelOption extends StatelessWidget {
  final String value;
  final String groupValue;
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  const _CancelOption({
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
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? kSheetBlue.withValues(alpha: 0.05) : Colors.white,
          border: Border.all(
              color: selected ? kSheetBlue : kSheetSlate200, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: selected
                    ? kSheetBlue.withValues(alpha: 0.12)
                    : kSheetSlate50,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon,
                  size: 16,
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
                          color:
                              selected ? kSheetBlue : kSheetSlate900)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: kSheetSlate500)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, size: 16, color: kSheetBlue),
          ],
        ),
      ),
    );
  }
}
