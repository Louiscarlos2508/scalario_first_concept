import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/shared/inventory/presentation/widgets/loss_declaration_form.dart';

class LossDeclarationPage extends ConsumerWidget {
  const LossDeclarationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(inventoryRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Déclarer une perte')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: LossDeclarationForm(repository: repo),
      ),
    );
  }
}
