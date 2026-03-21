import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/shared/inventory/presentation/widgets/transfer_pending_screen.dart';

class TransferConfirmPage extends ConsumerWidget {
  const TransferConfirmPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(inventoryRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmer un transfert')),
      body: TransferPendingScreen(repository: repo),
    );
  }
}
