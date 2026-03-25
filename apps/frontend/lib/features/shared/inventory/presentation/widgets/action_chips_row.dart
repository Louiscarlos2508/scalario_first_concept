import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/shared/business_type/data/business_type_config_repository.dart';
import 'package:frontend/features/shared/business_type/presentation/providers/business_type_config_provider.dart';
import 'package:frontend/features/shared/business_type/utils/access_utils.dart';
import 'package:frontend/features/shared/freshness/presentation/screens/freshness_screen.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/shared/inventory/presentation/widgets/adjustment_form.dart';
import 'package:frontend/features/shared/inventory/presentation/widgets/delivery_form.dart';
import 'package:frontend/features/shared/inventory/presentation/widgets/loss_declaration_form.dart';
import 'package:frontend/features/shared/inventory/presentation/widgets/transfer_out_form.dart';
import 'package:frontend/features/shared/inventory/presentation/widgets/transfer_pending_screen.dart';
import 'package:frontend/features/shared/inventory/presentation/screens/inventory_count_screen.dart';
import 'package:frontend/features/shared/inventory/presentation/screens/internal_requests_screen.dart';
import 'package:frontend/features/shared/inventory/presentation/providers/internal_requests_provider.dart';

void openFreshnessSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.90,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Fraîcheur',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const Expanded(child: FreshnessScreen()),
        ],
      ),
    ),
  );
}

class StockActionChipsRow extends ConsumerWidget {
  const StockActionChipsRow({super.key});

  void _openSheet(BuildContext context, Widget child) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.92,
        child: SingleChildScrollView(child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(inventoryRepositoryProvider);
    final config = ref.watch(businessTypeConfigProvider).valueOrNull ??
        BusinessTypeConfig.fallback;
    final role =
        ref.watch(userProfileProvider).valueOrNull?.role ?? '';
    final visibleSections = config.visibleSections;

    final canDelivery = canAccessScreen(role, 'deliveries', config) ||
        canAccessScreen(role, 'backoffice_restricted', config);
    final canLoss = canAccessScreen(role, 'losses', config);
    final canCount =
        canAccessScreen(role, 'backoffice_restricted', config);
    final canAdjust =
        canAccessScreen(role, 'backoffice_restricted', config);
    final showFreshness = visibleSections.isEmpty ||
        visibleSections.contains('freshness') ||
        visibleSections.contains('expiry');

    // FR88 — visible pour tous les rôles : commercial, manager, owner
    final canReappro =
        role == 'commercial' || role == 'manager' || role == 'owner';
    // Badge : nombre de demandes en attente d'action selon le rôle
    final pendingCountAsync = canReappro
        ? ref.watch(internalRequestsPendingCountProvider(role))
        : const AsyncData(0);

    final chips = <Widget>[];

    if (canDelivery) {
      chips.add(ActionChip(
        avatar: const Icon(Icons.download_outlined, size: 16),
        label: const Text('Réception'),
        onPressed: () => _openSheet(context, DeliveryForm(repository: repo)),
      ));
    }

    if (config.hasTransfers) {
      chips.add(ActionChip(
        avatar: const Icon(Icons.swap_horiz, size: 16),
        label: Text(config.sendAction),
        onPressed: () => _openSheet(
          context,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TransferOutForm(repository: repo, config: config),
              const SizedBox(height: 16),
              TransferPendingScreen(
                repository: repo,
                mode: TransferPendingMode.cancel,
              ),
            ],
          ),
        ),
      ));
    }

    if (canLoss) {
      chips.add(ActionChip(
        avatar: const Icon(Icons.remove_circle_outline, size: 16),
        label: const Text('Perte'),
        onPressed: () =>
            _openSheet(context, LossDeclarationForm(repository: repo)),
      ));
    }

    if (canCount) {
      chips.add(ActionChip(
        avatar: const Icon(Icons.fact_check_outlined, size: 16),
        label: const Text('Comptage'),
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          showDragHandle: true,
          builder: (_) => FractionallySizedBox(
            heightFactor: 0.95,
            child: InventoryCountScreen(
              repository: repo,
              embedded: true,
            ),
          ),
        ),
      ));
    }

    if (showFreshness) {
      chips.add(ActionChip(
        avatar: const Icon(Icons.eco_outlined, size: 16),
        label: const Text('Fraîcheur'),
        onPressed: () => openFreshnessSheet(context),
      ));
    }

    if (canAdjust) {
      chips.add(ActionChip(
        avatar: const Icon(Icons.tune, size: 16),
        label: const Text('Ajustement'),
        onPressed: () =>
            _openSheet(context, AdjustmentForm(repository: repo)),
      ));
    }

    if (canReappro) {
      final pendingCount = pendingCountAsync.valueOrNull ?? 0;
      chips.add(ActionChip(
        avatar: const Icon(Icons.move_down_outlined, size: 16),
        label: pendingCount > 0
            ? Badge.count(
                count: pendingCount,
                child: const Text('Réappro.'),
              )
            : const Text('Réappro.'),
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          showDragHandle: true,
          builder: (_) => const FractionallySizedBox(
            heightFactor: 0.95,
            child: InternalRequestsScreen(),
          ),
        ),
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: chips
            .expand((chip) => [chip, const SizedBox(width: 8)])
            .toList()
          ..removeLast(),
      ),
    );
  }
}
