import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/providers/payment_methods_provider.dart';
import 'package:frontend/core/theme/sheet_style.dart';
import 'package:frontend/features/shared/client_orders/domain/models/client_order.dart';
import 'package:frontend/features/shared/client_orders/presentation/providers/client_order_kpis_provider.dart';
import 'package:frontend/features/shared/client_orders/presentation/providers/client_orders_provider.dart';
import 'package:frontend/features/shared/client_orders/presentation/screens/client_order_form_screen.dart';

String _fcfa(double amount) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(amount);

// ── Status helpers ─────────────────────────────────────────────────────────────

(Color, String) _statusInfo(String status) => switch (status) {
      'draft'       => (kSheetSlate500, 'Brouillon'),
      'confirmed'   => (kSheetBlue, 'Confirmée'),
      'in-progress' => (kSheetAmber, 'En préparation'),
      'ready'       => (const Color(0xFF0D9488), 'Prête'),
      'delivered'   => (kSheetGreen, 'Livrée'),
      'invoiced'    => (const Color(0xFF7C3AED), 'Facturée'),
      'paid'        => (kSheetGreen, 'Payée ✓'),
      'cancelled'   => (kSheetRed, 'Annulée'),
      _             => (kSheetSlate500, status),
    };

// ── Main sheet ────────────────────────────────────────────────────────────────

class ClientOrdersPosSheet extends StatefulWidget {
  const ClientOrdersPosSheet({super.key});

  @override
  State<ClientOrdersPosSheet> createState() => _ClientOrdersPosSheetState();
}

class _ClientOrdersPosSheetState extends State<ClientOrdersPosSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          SheetTitleRow(
            title: 'Commandes clients',
            icon: Icons.assignment_outlined,
            iconColor: kSheetBlue,
          ),
          const SheetDivider(),

          // ── TabBar ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: kSheetSlate50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kSheetSlate200, width: 1.5),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: kSheetBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: kSheetSlate500,
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                tabs: const [
                  Tab(text: 'Nouvelle commande'),
                  Tab(text: 'Mes commandes'),
                ],
              ),
            ),
          ),

          // ── TabBarView ───────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                SingleChildScrollView(
                  child: ClientOrderFormScreen(
                    isEmbedded: true,
                    onCreated: () => _tabController.animateTo(1),
                  ),
                ),
                const _MyOrdersList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Onglet "Mes commandes" ────────────────────────────────────────────────────

class _MyOrdersList extends ConsumerStatefulWidget {
  const _MyOrdersList();

  @override
  ConsumerState<_MyOrdersList> createState() => _MyOrdersListState();
}

class _MyOrdersListState extends ConsumerState<_MyOrdersList>
    with AutomaticKeepAliveClientMixin {
  Timer? _timer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) ref.invalidate(clientOrdersProvider);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final userId = ref.watch(userProfileProvider).valueOrNull?.id;
    final filter = ClientOrdersFilter(createdBy: userId);
    final ordersAsync = ref.watch(clientOrdersProvider(filter));

    return Column(
      children: [
        // Sub-header with refresh
        Row(
          children: [
            const Text('Mes commandes',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: kSheetSlate500)),
            const Spacer(),
            GestureDetector(
              onTap: () => ref.invalidate(clientOrdersProvider(filter)),
              child: const Icon(Icons.refresh_outlined,
                  size: 18, color: kSheetSlate500),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Expanded(
          child: ordersAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('Erreur : $e',
                  style: const TextStyle(color: kSheetSlate500)),
            ),
            data: (orders) {
              if (orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_outlined,
                          size: 48, color: kSheetSlate200),
                      const SizedBox(height: 12),
                      const Text('Aucune commande',
                          style: TextStyle(
                              color: kSheetSlate500, fontSize: 14)),
                      const SizedBox(height: 4),
                      const Text(
                        'Créez votre première commande\ndans l\'onglet "Nouvelle commande"',
                        style: TextStyle(
                            color: kSheetSlate500, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(clientOrdersProvider(filter)),
                child: ListView.separated(
                  itemCount: orders.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, i) =>
                      _OrderCard(order: orders[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Order card ────────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final ClientOrder order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusLabel) = _statusInfo(order.status);
    final isDraft = order.status == 'draft';
    final isReady = order.status == 'ready';

    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => _PosOrderDetailDialog(order: order),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isReady
                ? const Color(0xFF0D9488)
                : isDraft
                    ? kSheetAmber.withValues(alpha: 0.5)
                    : kSheetSlate200,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            // ── Status indicator ────────────────────────────────────────
            Container(
              width: 4,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),

            // ── Main info ───────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(order.orderNumber,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: kSheetSlate900)),
                      const SizedBox(width: 8),
                      _StatusBadge(
                          label: statusLabel, color: statusColor),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    order.customerName ?? 'Client inconnu',
                    style: const TextStyle(
                        fontSize: 12, color: kSheetSlate500),
                  ),
                  Text(
                    '${DateFormat('dd/MM/yyyy').format(order.createdAt)} · ${order.lines.length} article(s)',
                    style: const TextStyle(
                        fontSize: 11, color: kSheetSlate500),
                  ),
                  // Status hint
                  if (isDraft) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.hourglass_empty_outlined,
                            size: 11, color: kSheetAmber),
                        const SizedBox(width: 4),
                        Text('En attente de confirmation',
                            style: TextStyle(
                                fontSize: 10, color: kSheetAmber)),
                      ],
                    ),
                  ] else if (isReady) ...[
                    const SizedBox(height: 3),
                    const Row(
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 11,
                            color: Color(0xFF0D9488)),
                        SizedBox(width: 4),
                        Text('Prête — client peut récupérer',
                            style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF0D9488),
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // ── Amount + arrow ──────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _fcfa(order.totalAmount),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: kSheetSlate900),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right,
                    size: 16, color: kSheetSlate500),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Order detail dialog ───────────────────────────────────────────────────────

class _PosOrderDetailDialog extends ConsumerWidget {
  final ClientOrder order;
  const _PosOrderDetailDialog({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (statusColor, statusLabel) = _statusInfo(order.status);

    return Dialog(
      shape: kSheetDialogShape,
      child: SizedBox(
        width: 420,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: kSheetBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.assignment_outlined,
                        color: kSheetBlue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.orderNumber,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: kSheetSlate900)),
                        Text(
                            order.customerName ?? 'Client inconnu',
                            style: const TextStyle(
                                fontSize: 12, color: kSheetSlate500)),
                      ],
                    ),
                  ),
                  _StatusBadge(
                      label: statusLabel, color: statusColor),
                ],
              ),
              const SizedBox(height: 16),
              const SheetDivider(),
              const SizedBox(height: 12),

              // ── Meta ─────────────────────────────────────────────────────
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailRow('Date',
                          DateFormat('dd/MM/yyyy HH:mm')
                              .format(order.createdAt)),
                      if (order.notes != null &&
                          order.notes!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _DetailRow('Notes', order.notes!),
                      ],
                      const SizedBox(height: 10),

                      // ── Status banner ──────────────────────────────────
                      _StatusBanner(status: order.status),

                      const SizedBox(height: 12),
                      const SheetSectionLabel('Articles'),
                      const SizedBox(height: 8),

                      // ── Lines ──────────────────────────────────────────
                      ...order.lines.map((line) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  margin:
                                      const EdgeInsets.only(right: 8),
                                  decoration: const BoxDecoration(
                                    color: kSheetSlate200,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    line.itemName ??
                                        line.catalogItemId,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: kSheetSlate900),
                                  ),
                                ),
                                Text(
                                    '×${line.quantity.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: kSheetSlate500)),
                                const SizedBox(width: 10),
                                Text(
                                  _fcfa(line.quantity *
                                      line.unitPrice),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: kSheetSlate900),
                                ),
                              ],
                            ),
                          )),

                      const SheetDivider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TOTAL',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: kSheetSlate500)),
                          Text(
                            _fcfa(order.totalAmount),
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: kSheetSlate900),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Actions ──────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: sheetCancelButtonStyle(),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Fermer'),
                    ),
                  ),
                  if (order.status == 'delivered') ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        style: sheetPrimaryButtonStyle(
                            color: kSheetGreen),
                        icon: const Icon(Icons.payments_outlined,
                            size: 16),
                        label: const Text('Encaisser'),
                        onPressed: () {
                          Navigator.pop(context);
                          _showEncaissementDialog(context, ref);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEncaissementDialog(
      BuildContext context, WidgetRef ref) async {
    final enabledMethods =
        ref.read(enabledPaymentMethodsProvider).valueOrNull ??
            kDefaultPaymentMethods;
    final methods =
        enabledMethods.where((m) => m.code != 'SPLIT').toList();
    String paymentMethod =
        methods.any((m) => m.code == 'CASH') ? 'CASH' : methods.first.code;

    IconData methodIcon(String code) => switch (code) {
          'CASH' => Icons.payments_outlined,
          'MOBILE_MONEY' => Icons.phone_android_outlined,
          'CARD' => Icons.credit_card_outlined,
          'TRANSFER' => Icons.swap_horiz_outlined,
          _ => Icons.attach_money,
        };

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
                  title: 'Encaisser la commande',
                ),
                const SizedBox(height: 16),

                // Total banner
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
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total à encaisser',
                          style: TextStyle(
                              fontSize: 13, color: kSheetSlate500)),
                      Text(
                        _fcfa(order.totalAmount),
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
                  children: methods.map((m) {
                    final sel = m.code == paymentMethod;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => paymentMethod = m.code),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: sel ? kSheetBlue : Colors.white,
                          border: Border.all(
                            color: sel
                                ? kSheetBlue
                                : kSheetSlate200,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(methodIcon(m.code),
                                size: 14,
                                color: sel
                                    ? Colors.white
                                    : kSheetSlate500),
                            const SizedBox(width: 6),
                            Text(m.label,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: sel
                                        ? Colors.white
                                        : kSheetSlate500)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

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
      final repo = ref.read(clientOrderRepositoryProvider);
      await repo.payOrder(order.id,
          tenantId: tenantId, paymentMethod: paymentMethod);
      ref.invalidate(clientOrdersProvider);
      ref.invalidate(clientOrderKpisProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paiement enregistré ✓'),
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
}

// ── Status banner ─────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final String status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final config = switch (status) {
      'draft' => (
          kSheetAmber,
          Icons.hourglass_empty_outlined,
          'En attente de confirmation par le responsable',
        ),
      'confirmed' => (
          kSheetBlue,
          Icons.check_circle_outline,
          'Commande validée — en cours de préparation',
        ),
      'in-progress' => (
          kSheetAmber,
          Icons.pending_outlined,
          'En cours de préparation',
        ),
      'ready' => (
          const Color(0xFF0D9488),
          Icons.inventory_2_outlined,
          'Commande prête — le client peut venir récupérer',
        ),
      _ => null,
    };

    if (config == null) return const SizedBox.shrink();
    final (color, icon, text) = config;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

// ── Detail row ────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text(label,
                style: const TextStyle(
                    color: kSheetSlate500, fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: kSheetSlate900)),
          ),
        ],
      ),
    );
  }
}
