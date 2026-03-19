import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';
import 'package:frontend/features/shared/stock_alerts/presentation/providers/stock_alerts_provider.dart';
import 'package:frontend/features/shared/purchase_orders/presentation/widgets/create_purchase_order_sheet.dart';

class StockAlertsScreen extends ConsumerWidget {
  const StockAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(stockAlertsProvider);

    return Scaffold(
      appBar: ScalarioAppBar(
        title: 'Alertes stock bas',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(stockAlertsProvider),
          ),
        ],
      ),
      body: alertsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Erreur : $err', style: const TextStyle(color: AppColors.error)),
        ),
        data: (alerts) {
          if (alerts.isEmpty) {
            return const Center(
              key: Key('stock_alerts_empty'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
                  SizedBox(height: 16),
                  Text(
                    'Aucun stock critique',
                    style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(stockAlertsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert = alerts[index];
                final name = alert['itemName']?.toString() ?? '';
                final stock = (alert['stockQuantity'] as num?)?.toDouble() ?? 0;
                final threshold = (alert['minStockLevel'] as num?)?.toDouble() ?? 0;
                final deficit = (alert['deficit'] as num?)?.toDouble() ?? 0;
                final catalogItemId = alert['catalogItemId']?.toString();

                return Card(
                  key: Key('alert_$catalogItemId'),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                      size: 32,
                    ),
                    title: Text(name, style: AppTextStyles.bodyMedium),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Stock : $stock  |  Seuil : $threshold'),
                        Text(
                          'Déficit : $deficit',
                          style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: TextButton.icon(
                      key: Key('reappro_$catalogItemId'),
                      icon: const Icon(Icons.add_shopping_cart, size: 16),
                      label: const Text('Réapprovisionner'),
                      onPressed: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => const CreatePurchaseOrderSheet(),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
