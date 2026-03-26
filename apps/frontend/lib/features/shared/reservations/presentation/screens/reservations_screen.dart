import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/shared/reservations/presentation/providers/reservations_provider.dart';

String _fcfa(double amount) => NumberFormat.currency(
  locale: 'fr_FR',
  symbol: 'FCFA',
  decimalDigits: 0,
).format(amount);

class ReservationsScreen extends ConsumerStatefulWidget {
  const ReservationsScreen({super.key});

  @override
  ConsumerState<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends ConsumerState<ReservationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Réservations'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'En cours'),
            Tab(text: 'Complétées'),
            Tab(text: 'Annulées'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ReservationsList(status: 'pending', showActions: true),
          _ReservationsList(status: 'completed', showActions: false),
          _ReservationsList(status: 'cancelled', showActions: false),
        ],
      ),
    );
  }
}

class _ReservationsList extends ConsumerWidget {
  final String status;
  final bool showActions;

  const _ReservationsList({required this.status, required this.showActions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(reservationsListProvider(status));

    return listAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('Aucune réservation'));
        }
        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(reservationsListProvider(status)),
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final r = items[index] as Map<String, dynamic>;
              return _ReservationTile(reservation: r, showActions: showActions);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur : $e')),
    );
  }
}

class _ReservationTile extends ConsumerWidget {
  final Map<String, dynamic> reservation;
  final bool showActions;

  const _ReservationTile({
    required this.reservation,
    required this.showActions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalAmount = (reservation['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final depositAmount =
        (reservation['depositAmount'] as num?)?.toDouble() ?? 0.0;
    final remainingAmount =
        (reservation['remainingAmount'] as num?)?.toDouble() ?? 0.0;
    final createdAt = reservation['createdAt'] != null
        ? DateTime.tryParse(reservation['createdAt'].toString())
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  reservation['customerName']?.toString() ?? '—',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (createdAt != null)
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(createdAt),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            // Items preview
            ...(reservation['itemsJson'] as List<dynamic>? ?? [])
                .take(2)
                .map((item) => Text(
                      '• ${item['name'] ?? 'Article'}',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    )),
            const SizedBox(height: 6),
            _row('Total :', _fcfa(totalAmount)),
            _row('Acompte :', _fcfa(depositAmount)),
            _row(
              'Solde restant :',
              _fcfa(remainingAmount),
              valueStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            if (showActions) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          _showCompleteDialog(context, ref, reservation),
                      child: const Text('Compléter'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      onPressed: () =>
                          _showCancelDialog(context, ref, reservation),
                      child: const Text('Annuler'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }

  Future<void> _showCompleteDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> r,
  ) async {
    final remaining = (r['remainingAmount'] as num?)?.toDouble() ?? 0.0;
    String paymentMethod = 'CASH';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Finaliser le paiement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Solde restant : ${_fcfa(remaining)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Mode de paiement',
                ),
                items: ['CASH', 'MOBILE_MONEY']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) => setState(() => paymentMethod = v!),
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
      final repo = ref.read(reservationsRepositoryProvider);
      await repo.completeReservation(
        tenantId: tenantId,
        id: r['id'].toString(),
        paymentMethod: paymentMethod,
        amount: remaining,
      );
      ref.invalidate(reservationsListProvider('pending'));
      ref.invalidate(reservationsListProvider('completed'));
      ref.invalidate(reservationsKpiProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paiement completé — Réservation clôturée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showCancelDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> r,
  ) async {
    String resolution = 'cash_refund';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Annuler la réservation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                value: 'cash_refund',
                groupValue: resolution,
                onChanged: (v) => setState(() => resolution = v!),
                title: const Text('Rembourser l\'acompte en cash'),
              ),
              RadioListTile<String>(
                value: 'credit_note',
                groupValue: resolution,
                onChanged: (v) => setState(() => resolution = v!),
                title: const Text('Convertir en avoir client'),
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
              child: const Text('Confirmer l\'annulation'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final tenantId = ref.read(activeTenantProvider) ?? '';
      final userProfile = ref.read(userProfileProvider).value;
      final repo = ref.read(reservationsRepositoryProvider);
      await repo.cancelReservation(
        tenantId: tenantId,
        userId: userProfile?.id ?? '',
        role: userProfile?.role ?? '',
        id: r['id'].toString(),
        depositResolution: resolution,
      );
      ref.invalidate(reservationsListProvider('pending'));
      ref.invalidate(reservationsListProvider('cancelled'));
      ref.invalidate(reservationsKpiProvider);
      if (context.mounted) {
        final label = resolution == 'cash_refund'
            ? 'Remboursement cash'
            : 'Avoir client';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Réservation annulée — $label')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
