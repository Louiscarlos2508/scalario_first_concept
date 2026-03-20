import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/sdui/sdui_layout.dart';
import '../../../../../core/sdui/sdui_providers.dart';
import '../../../../../core/sdui/sdui_renderer.dart';
import '../widgets/cart_panel.dart';
import '../widgets/session_guard.dart';
import '../widgets/session_report_dialog.dart';
import '../widgets/camera_scanner_dialog.dart';
import '../providers/pos_providers.dart';
import '../../../../../core/auth/auth_state.dart';
import '../../../../../core/widgets/barcode_listener.dart';
import '../widgets/sync_status_indicator.dart';
import 'package:frontend/features/shared/catalog/data/models/product_variant.dart';
import 'package:frontend/features/shared/catalog/presentation/providers/catalog_providers.dart';

class PosScreen extends ConsumerWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).valueOrNull;
    final sessionOpen = session != null && session.status == 'OPEN';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scalario POS'),
        centerTitle: false,
        actions: [
          if (sessionOpen) ...[
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () => _openCameraScanner(context, ref),
              tooltip: 'Scanner',
            ),
            const SyncStatusIndicator(),
            IconButton(
              icon: const Icon(Icons.lock_outline),
              onPressed: () => _showCloseSessionDialog(context, ref),
              tooltip: 'Fermer la caisse',
            ),
          ],
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            tooltip: 'Déconnexion',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BarcodeScannerListener(
        onBarcodeScanned: (barcode) => _handleBarcodeScanned(ref, barcode, context),
        child: SessionGuard(
          child: _buildSduiBody(context, ref),
        ),
      ),
    );
  }

  Widget _buildSduiBody(BuildContext context, WidgetRef ref) {
    final layoutAsync = ref.watch(sduiLayoutProvider('pos'));
    final layout = layoutAsync.when(
      data: (l) => l,
      loading: () => SduiLayout.retailPosDefault(),
      error: (_, __) => SduiLayout.retailPosDefault(),
    );
    return SduiRenderer(
      layout: layout,
      onCartFabPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const _CartScreen()),
      ),
    );
  }

  Future<void> _openCameraScanner(BuildContext context, WidgetRef ref) async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const CameraScannerDialog()),
    );

    if (barcode != null && context.mounted) {
      _handleBarcodeScanned(ref, barcode, context);
    }
  }

  void _handleBarcodeScanned(WidgetRef ref, String barcode, BuildContext context) async {
    // AC3 (Story 25-3) — Try catalog API barcode lookup first (handles variant barcodes)
    final tenantId = ref.read(activeTenantProvider);
    if (tenantId != null) {
      final catalogResult = await ref.read(catalogRepositoryProvider).getByBarcode(
        barcode: barcode,
        tenantId: tenantId,
      );
      if (catalogResult != null && catalogResult.containsKey('matchedVariant')) {
        // Variant barcode — add directly without selector
        final productRepo = ref.read(productRepositoryProvider);
        final product = await productRepo.getProductByBarcode(barcode) ??
            await productRepo.getProductByBarcode(catalogResult['barcode']?.toString() ?? barcode);
        if (product != null && context.mounted) {
          final variantData = catalogResult['matchedVariant'] as Map<String, dynamic>;
          final variant = ProductVariant.fromJson(variantData);
          ref.read(cartProvider.notifier).addProductWithVariant(product, variant);
          return;
        }
      }
    }

    // Fallback — local Isar lookup
    final repo = ref.read(productRepositoryProvider);
    final product = await repo.getProductByBarcode(barcode);
    if (product != null) {
      ref.read(cartProvider.notifier).addProduct(product);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Product not found: $barcode'),
              backgroundColor: Colors.orange),
        );
      }
    }
  }

  Future<void> _showCloseSessionDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    
    // 1. Get Physical Count
    final physicalAmount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clôturer la session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Veuillez compter le cash physique dans le tiroir.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Montant physique',
                suffixText: 'FCFA',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text) ?? 0;
              Navigator.pop(context, val);
            },
            child: const Text('Suivant'),
          ),
        ],
      ),
    );

    if (physicalAmount == null) return;

    // 2. Calculate Summary
    final summary = await ref.read(sessionProvider.notifier).calculateSessionSummary();

    // 3. Show Reconciliation Report
    if (context.mounted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => SessionReportDialog(
          summary: summary,
          physicalCount: physicalAmount,
        ),
      );

      if (confirmed == true) {
        final theoretical = (summary['theoreticalCash'] as double?) ?? 0.0;
        await ref.read(sessionProvider.notifier).closeSession(physicalAmount, theoretical);
      }
    }
  }
}

/// Fullscreen cart view — used by the FAB in compact (phone) layout.
class _CartScreen extends StatelessWidget {
  const _CartScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: const CartPanel(),
    );
  }
}
