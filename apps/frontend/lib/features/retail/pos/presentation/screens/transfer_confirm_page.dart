import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/shared/business_type/data/business_type_config_repository.dart';
import 'package:frontend/features/shared/business_type/presentation/providers/business_type_config_provider.dart';
import 'package:frontend/features/shared/inventory/presentation/widgets/transfer_pending_screen.dart';

class TransferConfirmPage extends ConsumerWidget {
  const TransferConfirmPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(inventoryRepositoryProvider);
    final config = ref.watch(businessTypeConfigProvider).valueOrNull
        ?? BusinessTypeConfig.fallback;
    return Scaffold(
      appBar: AppBar(title: Text(config.confirmAction)),
      body: TransferPendingScreen(repository: repo),
    );
  }
}
