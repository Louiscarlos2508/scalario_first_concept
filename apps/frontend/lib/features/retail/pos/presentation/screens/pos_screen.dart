import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/sdui/sdui_layout.dart';
import '../../../../../core/sdui/sdui_providers.dart';
import '../../../../../core/sdui/sdui_renderer.dart';
import '../widgets/cart_panel.dart';
import '../widgets/session_guard.dart';
import 'session_close_screen.dart';
import '../widgets/camera_scanner_dialog.dart';
import '../widgets/session_lock_wrapper.dart';
import '../providers/pos_providers.dart';
import '../../../../../core/auth/auth_state.dart';
import '../../../../../core/widgets/barcode_listener.dart';
import '../widgets/sync_status_indicator.dart';
import 'package:frontend/features/shared/catalog/data/models/product_variant.dart';
import 'package:frontend/features/shared/catalog/presentation/providers/catalog_providers.dart';
import 'package:frontend/features/shared/client_orders/presentation/screens/client_orders_commercial_screen.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/pos_reservations_sheet.dart';
import 'package:frontend/features/shared/business_type/presentation/providers/business_type_config_provider.dart';
import 'package:frontend/core/settings/settings_screen.dart';
import 'package:frontend/core/printing/printer_setup_sheet.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/profile_sheet.dart';
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
        .where((s) =>
            s != 'pos' &&
            s != 'backoffice' &&
            s != 'backoffice_restricted' &&
            s != 'client_orders')
        .isNotEmpty;
    final hasMenu = hasExtraScreens && !hasBackoffice;

    return Scaffold(
      appBar: _PosAppBar(
        sessionOpen: sessionOpen,
        hasBackoffice: hasBackoffice,
        hasMenu: hasMenu,
        isNarrow: MediaQuery.of(context).size.width < 500,
        statusBarHeight: MediaQuery.paddingOf(context).top,
        onScan: sessionOpen && _hasCameraScanner
            ? () => _openCameraScanner(context, ref)
            : null,
        onCloseSession: sessionOpen ? () => _showCloseSessionDialog(context, ref) : null,
        onMenu: hasMenu ? () => _showCommercialMenu(context, ref, screens) : null,
        onLogout: !hasBackoffice ? () => ref.read(authRepositoryProvider).signOut() : null,
      ),
      body: BarcodeScannerListener(
        onBarcodeScanned: (barcode) => _handleBarcodeScanned(ref, barcode, context),
        child: SessionGuard(
          child: SessionLockWrapper(
            child: _buildSduiBody(context, ref),
          ),
        ),
      ),
    );
  }

  Widget _buildSduiBody(BuildContext context, WidgetRef ref) {
    final layoutAsync = ref.watch(sduiLayoutProvider('pos'));
    final layout = layoutAsync.when(
      data: (l) => l,
      loading: () => SduiLayout.retailPosDefault(),
      error: (_, _) => SduiLayout.retailPosDefault(),
    );
    return SduiRenderer(
      layout: layout,
      onCartFabPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const _CartScreen()),
      ),
    );
  }

  /// True on Android/iOS where the device has a built-in camera for scanning.
  /// On desktop/web the USB HID scanner handles it automatically — no button needed.
  static bool get _hasCameraScanner {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  Future<void> _openCameraScanner(BuildContext context, WidgetRef ref) async {
    final barcode = await openCameraScanner(context);

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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('✓ ${product.name}${variant.attributes.isNotEmpty ? ' — ${variant.attributes.values.join(', ')}' : ''}'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.green.shade700,
          ));
          return;
        }
      }
    }

    // Fallback — local Isar lookup
    final repo = ref.read(productRepositoryProvider);
    final product = await repo.getProductByBarcode(barcode);
    if (!context.mounted) return;
    if (product != null) {
      ref.read(cartProvider.notifier).addProduct(product);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✓ ${product.name}'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.green.shade700,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Code-barres non trouvé : $barcode'),
            backgroundColor: Colors.orange),
      );
    }
  }

  void _showCloseSessionDialog(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SessionCloseScreen()),
    );
  }
}

// ── Commercial menu helpers ───────────────────────────────────────────────────

List<String> _fallbackScreensForRole(String role) {
  switch (role) {
    case 'owner':
      return ['backoffice', 'pos'];
    case 'manager':
      return ['backoffice_restricted'];
    case 'commercial':
      return ['pos', 'client_orders', 'reservations', 'losses', 'transfers', 'stock_view', 'daily_sales'];
    case 'cashier':
      return ['pos', 'client_orders'];
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
              title: Text(
                ref.read(businessTypeConfigProvider).valueOrNull?.confirmAction
                    ?? 'Réception de stock interne',
              ),
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
              leading: const Icon(Icons.assignment_outlined, color: Colors.indigo),
              title: const Text('Commandes clients'),
              subtitle: const Text('Créer et suivre vos commandes'),
              onTap: () => go(const ClientOrdersCommercialScreen()),
            ),
          if (screens.contains('reservations'))
            ListTile(
              leading: const Icon(Icons.bookmark_outline, color: Colors.orange),
              title: const Text('Réservations'),
              subtitle: const Text('Gérer les réservations en cours'),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => const PosReservationsSheet(),
                );
              },
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

// ── POS Top bar ───────────────────────────────────────────────────────────────

enum _AppBarAction { scan, printer, profile, closeSession, menu, logout }

class _PosAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final bool sessionOpen;
  final bool hasBackoffice;
  final bool hasMenu;
  final bool isNarrow;
  final double statusBarHeight;
  final VoidCallback? onScan;
  final VoidCallback? onCloseSession;
  final VoidCallback? onMenu;
  final VoidCallback? onLogout;

  const _PosAppBar({
    required this.sessionOpen,
    required this.hasBackoffice,
    required this.hasMenu,
    required this.isNarrow,
    required this.statusBarHeight,
    this.onScan,
    this.onCloseSession,
    this.onMenu,
    this.onLogout,
  });

  // 2-row toolbar on narrow screens (mobile), 1-row on wide (desktop/tablet)
  @override
  Size get preferredSize =>
      Size.fromHeight((isNarrow ? 78 : 56) + statusBarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).valueOrNull;
    final employee = ref.watch(selectedEmployeeProvider);
    final userProfile = ref.watch(userProfileProvider).valueOrNull;
    final isLocked = ref.watch(sessionLockedProvider);
    final displayName = employee?.name ??
        userProfile?.fullName ??
        userProfile?.email ??
        'Utilisateur';

    // ── Session pill ────────────────────────────────────────────────────────
    final sessionPill = sessionOpen
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF34A853), shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 110),
                  child: Text(
                    displayName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
                if (session?.openedAt != null) ...[
                  const SizedBox(width: 5),
                  Text(
                    DateFormat('HH:mm').format(session!.openedAt),
                    style: TextStyle(
                        fontSize: 11, color: Colors.white.withValues(alpha: 0.45)),
                  ),
                ],
              ],
            ),
          )
        : null;

    // ── Menu ⋮ ──────────────────────────────────────────────────────────────
    final menuBtn = PopupMenuButton<_AppBarAction>(
      enabled: !isLocked,
      icon: Icon(Icons.more_vert,
          color: isLocked ? Colors.white24 : Colors.white70, size: 20),
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      tooltip: 'Menu',
      onSelected: (action) {
        switch (action) {
          case _AppBarAction.scan:    onScan?.call();
          case _AppBarAction.printer: showPrinterSetupSheet(context);
          case _AppBarAction.profile: showProfileSheet(context);
          case _AppBarAction.closeSession: onCloseSession?.call();
          case _AppBarAction.menu:    onMenu?.call();
          case _AppBarAction.logout:  onLogout?.call();
        }
      },
      itemBuilder: (_) => [
        if (onScan != null)
          _menuItem(_AppBarAction.scan, Icons.qr_code_scanner, 'Scanner'),
        _menuItem(_AppBarAction.printer, Icons.print_outlined, 'Imprimante'),
        const PopupMenuDivider(),
        _menuItem(_AppBarAction.profile, Icons.person_outline, 'Mon profil'),
        if (sessionOpen) ...[
          const PopupMenuDivider(),
          _menuItem(_AppBarAction.closeSession, Icons.lock_outline, 'Fermer la caisse'),
        ],
        if (hasMenu) ...[
          const PopupMenuDivider(),
          _menuItem(_AppBarAction.menu, Icons.grid_view_outlined, 'Mon espace'),
        ],
        if (!hasBackoffice) ...[
          const PopupMenuDivider(),
          _menuItem(_AppBarAction.logout, Icons.logout, 'Déconnexion',
              color: const Color(0xFFEF4444)),
        ],
      ],
    );

    // ── Logo ────────────────────────────────────────────────────────────────
    final logo = SizedBox(
      width: 22, height: 33,
      child: CustomPaint(painter: _LogoSTopBarPainter()),
    );
    const wordmark = Text('CALARIO',
        style: TextStyle(
            fontFamily: 'Impact', fontSize: 22, fontWeight: FontWeight.w900,
            letterSpacing: 2, color: Colors.white, height: 1.0));
    const subtitle = Text('Point de vente',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white38));

    // ── Compact menu button (no 48px tap target padding) ────────────────────
    final compactMenuBtn = Theme(
      data: Theme.of(context).copyWith(
        iconButtonTheme: const IconButtonThemeData(
          style: ButtonStyle(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            minimumSize: WidgetStatePropertyAll(Size(32, 32)),
            padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 4)),
          ),
        ),
      ),
      child: menuBtn,
    );

    // ── Layout ──────────────────────────────────────────────────────────────
    // AnnotatedRegion → white icons in Android status bar (dark background).
    // SafeArea → content below status bar, no overlap.
    // isNarrow → 2-row (mobile); wide → single row (desktop/tablet).
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: ColoredBox(
        color: const Color(0xFF0F172A),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: isNarrow
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Row 1 — branding
                      Row(children: [
                        logo,
                        const SizedBox(width: 8),
                        wordmark,
                        const SizedBox(width: 10),
                        Container(width: 1, height: 16, color: Colors.white12),
                        const SizedBox(width: 10),
                        subtitle,
                      ]),
                      const SizedBox(height: 2),
                      // Row 2 — session + actions (height capped to avoid tap-target overflow)
                      SizedBox(
                        height: 38,
                        child: Row(children: [
                          if (sessionPill != null) ...[sessionPill, const SizedBox(width: 6)],
                          const Spacer(),
                          if (sessionOpen) ...[const SyncStatusIndicator(), const SizedBox(width: 2)],
                          compactMenuBtn,
                        ]),
                      ),
                    ],
                  )
                : SizedBox(
                    height: 56,
                    child: Row(children: [
                      logo,
                      const SizedBox(width: 8),
                      wordmark,
                      const SizedBox(width: 12),
                      Container(width: 1, height: 20, color: Colors.white12),
                      const SizedBox(width: 12),
                      subtitle,
                      const Spacer(),
                      if (sessionPill != null) ...[sessionPill, const SizedBox(width: 6)],
                      if (sessionOpen) ...[const SyncStatusIndicator(), const SizedBox(width: 2)],
                      menuBtn,
                    ]),
                  ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<_AppBarAction> _menuItem(
    _AppBarAction value,
    IconData icon,
    String label, {
    Color color = Colors.white,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color.withValues(alpha: 0.7)),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Static S logo painter (topbar) ────────────────────────────────────────────

class _LogoSTopBarPainter extends CustomPainter {
  static const double _vbX = 32, _vbY = 20, _vbW = 64, _vbH = 90;

  static final Path _p1 = Path()..moveTo(64, 24)..cubicTo(48, 24, 36, 34, 36, 48);
  static final Path _p2 = Path()..moveTo(36, 48)..cubicTo(36, 60, 48, 66, 64, 66);
  static final Path _p3 = Path()..moveTo(64, 66)..cubicTo(78, 66, 90, 72, 90, 86);
  static final Path _p4 = Path()..moveTo(90, 86)..cubicTo(90, 98, 78, 106, 64, 106);

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / _vbW;
    final sy = size.height / _vbH;
    canvas.save();
    canvas.translate(-_vbX * sx, -_vbY * sy);
    canvas.scale(sx, sy);
    _arc(canvas, _p1, const Color(0xFFFFCC00));
    _arc(canvas, _p2, const Color(0xFF1A73E8));
    _arc(canvas, _p3, const Color(0xFF34A853));
    _arc(canvas, _p4, const Color(0xFFEA4335));
    canvas.restore();
  }

  static void _arc(Canvas canvas, Path path, Color color) {
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_LogoSTopBarPainter _) => false;
}
