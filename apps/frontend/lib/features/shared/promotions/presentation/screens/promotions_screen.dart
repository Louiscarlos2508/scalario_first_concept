import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';
import 'package:frontend/features/shared/promotions/data/models/promotion.dart';
import 'package:frontend/features/shared/promotions/presentation/providers/promotions_providers.dart';
import 'package:frontend/features/shared/promotions/presentation/widgets/create_promotion_sheet.dart';

class PromotionsScreen extends ConsumerStatefulWidget {
  const PromotionsScreen({super.key});

  @override
  ConsumerState<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends ConsumerState<PromotionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    (label: 'Actives', status: 'active'),
    (label: 'Planifiées', status: 'planned'),
    (label: 'Expirées', status: 'inactive'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ScalarioAppBar(
        title: 'Promotions',
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((t) => Tab(text: t.label)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs
            .map((t) => _PromotionsList(status: t.status))
            .toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateSheet(),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle promotion'),
      ),
    );
  }

  void _openCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CreatePromotionSheet(),
    ).then((_) {
      // Refresh all tabs
      ref.invalidate(promotionsProvider);
    });
  }
}

// ── Promotions list for a given status tab ────────────────────────────────────

class _PromotionsList extends ConsumerWidget {
  final String status;
  const _PromotionsList({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 'planned' is not a backend status — we fetch all and filter client-side
    final fetchStatus = status == 'planned' ? null : status;
    final async = ref.watch(promotionsProvider(fetchStatus));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur : $e')),
      data: (all) {
        final now = DateTime.now();
        final promos = status == 'planned'
            ? all.where((p) {
                try {
                  return DateTime.parse(p.startDate).isAfter(now);
                } catch (_) {
                  return false;
                }
              }).toList()
            : all;

        if (promos.isEmpty) {
          return const Center(child: Text('Aucune promotion.'));
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(promotionsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: promos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, i) =>
                _PromoCard(promo: promos[i]),
          ),
        );
      },
    );
  }
}

// ── Single promotion card ─────────────────────────────────────────────────────

class _PromoCard extends ConsumerWidget {
  final Promotion promo;
  const _PromoCard({required this.promo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = promo.status == 'active';
    final tenantId = ref.watch(activeTenantProvider);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive
              ? Colors.green.shade100
              : Colors.grey.shade200,
          child: Icon(
            _typeIcon(promo.type),
            color: isActive ? Colors.green : Colors.grey,
            size: 20,
          ),
        ),
        title: Text(promo.typeLabel,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scope : ${promo.scope}${promo.scopeId != null ? ' · ${promo.scopeId}' : ''}',
                style: const TextStyle(fontSize: 11)),
            Text(
              '${_fmtDate(promo.startDate)} → ${_fmtDate(promo.endDate)}',
              style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusBadge(isActive: isActive),
            if (tenantId != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                tooltip: 'Désactiver',
                onPressed: () => _delete(context, ref, tenantId),
              ),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'PERCENT':
        return Icons.percent;
      case 'BUY_N_GET_M':
        return Icons.card_giftcard;
      case 'CROSSED_PRICE':
        return Icons.price_change_outlined;
      default:
        return Icons.local_offer_outlined;
    }
  }

  String _fmtDate(String iso) {
    try {
      return DateFormat('dd/MM/yy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, String tenantId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Désactiver la promotion ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(promotionsRepositoryProvider)
          .deletePromotion(tenantId, promo.id);
      ref.invalidate(promotionsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade100 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isActive ? Colors.green.shade800 : Colors.grey.shade600,
        ),
      ),
    );
  }
}
