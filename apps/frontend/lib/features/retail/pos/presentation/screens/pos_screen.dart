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
import '../../../../../core/widgets/barcode_listener.dart';
import '../widgets/sync_status_indicator.dart';

class PosScreen extends ConsumerWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scalario POS'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => _openCameraScanner(context, ref),
            tooltip: 'Camera Scanner',
          ),
          const SyncStatusIndicator(),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              _showCloseSessionDialog(context, ref);
            },
            tooltip: 'Close Session',
          ),
          const SizedBox(width: 16),
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
        title: const Text('Close Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please count the physical cash in the drawer.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Physical Amount',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text) ?? 0;
              Navigator.pop(context, val);
            },
            child: const Text('Next'),
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
        await ref.read(sessionProvider.notifier).closeSession(physicalAmount);
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
