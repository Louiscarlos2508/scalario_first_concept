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
import 'package:frontend/features/shared/client_orders/presentation/screens/client_order_form_screen.dart';
import 'package:frontend/features/shared/business_type/presentation/providers/business_type_config_provider.dart';
import 'package:frontend/core/settings/settings_screen.dart';
import 'loss_declaration_page.dart';
import 'transfer_confirm_page.dart';
import 'stock_view_page.dart';
import 'package:frontend/features/shared/reports/presentation/screens/sales_history_screen.dart';

class PosScreen extends ConsumerWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).valueOrNull;
    final sessionOpen = session != null && session.status == 'OPEN';
    final role = ref.watch(userProfileProvider).valueOrNull?.role ?? '';
    final config = ref.watch(businessTypeConfigProvider).valueOrNull;
    final screens = config != null
        ? config.screensForRole(role)
        : _fallbackScreensForRole(role);
    final hasBackoffice = screens.contains('backoffice') ||
        screens.contains('backoffice_restricted');
    final hasExtraScreens = screens
        .where((s) => s != 'pos' && s != 'backoffice' && s != 'backoffice_restricted')
        .isNotEmpty;
    final hasMenu = hasExtraScreens && !hasBackoffice;

    ref.listen<AsyncValue<ScanEvent>>(scanEventsProvider, (_, next) {
      next.whenData((event) {
        final messenger = ScaffoldMessenger.of(context);
        if (event.found) {
          messenger.showSnackBar(SnackBar(
            content: Text('✓ ${event.productName ?? event.barcode}'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.green.shade700,
          ));
        } else {
          messenger.showSnackBar(SnackBar(
            content: Text('Code-barres non trouvé : ${event.barcode}'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red.shade700,
          ));
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scalario POS'),
        centerTitle: false,
        actions: [
          if (sessionOpen) ...[
            IconButton(
              icon: const Icon(Icons.assignment_add),
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => const ClientOrderFormScreen(),
              ),
              tooltip: 'Commande client',
            ),
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
          if (hasMenu)
            IconButton(
              icon: const Icon(Icons.menu),
              tooltip: 'Mon espace',
              onPressed: () => _showCommercialMenu(context, ref, screens),
            ),
          // Commercial / Cashier → le POS est leur écran principal → déconnexion
          // Owner → le bouton retour natif de l'AppBar suffit (Navigator.pop)
          if (!hasBackoffice)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Déconnexion',
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
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
              content: Text('Code-barres non trouvé : $barcode'),
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

// ── Commercial menu helpers ───────────────────────────────────────────────────

List<String> _fallbackScreensForRole(String role) {
  switch (role) {
    case 'owner':
      return ['pos'];
    case 'manager':
      return ['backoffice_restricted'];
    case 'commercial':
      return ['pos', 'losses', 'transfers', 'stock_view', 'daily_sales'];
    default:
      return ['pos'];
  }
}

void _showCommercialMenu(
  BuildContext context,
  WidgetRef ref,
  List<String> screens,
) {
  void go(Widget page) {
    Navigator.pop(context);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          if (screens.contains('losses'))
            ListTile(
              leading: const Icon(Icons.remove_circle_outline),
              title: const Text('Déclarer une perte'),
              onTap: () => go(const LossDeclarationPage()),
            ),
          if (screens.contains('transfers'))
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Confirmer un transfert'),
              onTap: () => go(const TransferConfirmPage()),
            ),
          if (screens.contains('stock_view'))
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Mon stock'),
              onTap: () => go(const StockViewPage()),
            ),
          if (screens.contains('client_orders'))
            ListTile(
              leading: const Icon(Icons.shopping_cart_outlined),
              title: const Text('Commandes clients'),
              onTap: () => go(const _PlaceholderPage('Commandes clients')),
            ),
          if (screens.contains('deliveries'))
            ListTile(
              leading: const Icon(Icons.local_shipping_outlined),
              title: const Text('Livraisons'),
              onTap: () => go(const _PlaceholderPage('Livraisons')),
            ),
          if (screens.contains('daily_sales'))
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Mes ventes du jour'),
              onTap: () {
                final userId =
                    ref.read(userProfileProvider).valueOrNull?.id;
                go(SalesHistoryScreen(
                  fixedUserId: userId,
                  initialPeriod: 'today',
                ));
              },
            ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Paramètres'),
            onTap: () => go(const SettingsScreen()),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage(this.title);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          'Bientôt disponible',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

/// Fullscreen cart view — used by the FAB in compact (phone) layout.
class _CartScreen extends StatelessWidget {
  const _CartScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panier')),
      body: const CartPanel(),
    );
  }
}
