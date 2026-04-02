import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/core/theme/app_breakpoints.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/app_logos.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/sync_status_indicator.dart';
import 'package:frontend/features/retail/pos/presentation/screens/pos_screen.dart';
import 'package:frontend/features/shared/business_type/presentation/providers/business_type_config_provider.dart';
import 'package:frontend/features/shared/business_type/utils/access_utils.dart';

/// Navigation destination item.
/// [moduleCode] null = always visible; non-null = visible only when module is active.
class NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String? moduleCode;
  const NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.moduleCode,
  });
}

// Phone: max 5 items in BottomNavigationBar (AC3 — MVP overflow handling)
const int _maxBottomItems = 5;

class DashboardShell extends ConsumerStatefulWidget {
  final Widget child;
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final List<NavItem> items;

  const DashboardShell({
    super.key,
    required this.child,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
  });

  @override
  ConsumerState<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends ConsumerState<DashboardShell> {
  /// Returns an icon widget with an outbox badge for the Inventaire tab.
  Widget _navIcon(WidgetRef ref, String label, IconData icon) {
    if (label != 'Produits & Stock') return Icon(icon);
    final countAsync = ref.watch(inventoryOutboxCountProvider);
    final count = countAsync.when(
      data: (n) => n,
      loading: () => 0,
      error: (_, _) => 0,
    );
    if (count == 0) return Icon(icon);
    return Badge(
      label: Text('$count'),
      backgroundColor: AppColors.warning,
      child: Icon(icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= kCompact;
        return isWide
            ? _buildTabletLayout(context)
            : _buildPhoneLayout(context);
      },
    );
  }

  // ── Tablet layout (≥ 600dp) — custom dark sidebar ───────────────────────

  Widget _buildTabletLayout(BuildContext context) {
    final activeTenantId = ref.watch(activeTenantProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    final role = userProfileAsync.valueOrNull?.role ?? '';
    final config = ref.watch(businessTypeConfigProvider).valueOrNull;
    final canOpenPos = canAccessScreen(role, 'pos', config);
    final profile = userProfileAsync.valueOrNull;
    final activeMembership = profile?.memberships.firstWhere(
      (m) => m.tenantId == activeTenantId,
      orElse: () => profile.memberships.first,
    );
    final tenantName = activeMembership?.tenantName ?? 'Scalario';

    return Scaffold(
      body: Row(
        children: [
          _Sidebar(
            items: widget.items,
            selectedIndex: widget.selectedIndex,
            onDestinationSelected: widget.onDestinationSelected,
            tenantName: tenantName,
            profile: profile,
            activeTenantId: activeTenantId,
            canOpenPos: canOpenPos,
            navIconBuilder: (label, icon) => _navIcon(ref, label, icon),
            onOpenPos: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PosScreen()),
            ),
            onSignOut: () => ref.read(authRepositoryProvider).signOut(),
            onSwitchTenant: profile != null && profile.memberships.length > 1
                ? (id) =>
                    ref.read(activeTenantProvider.notifier).state = id
                : null,
          ),
          Expanded(child: SafeArea(child: widget.child)),
        ],
      ),
    );
  }

  // ── Phone layout (< 600dp) — BottomNavigationBar ─────────────────────────

  Widget _buildPhoneLayout(BuildContext context) {
    final visibleBottom = widget.items.take(_maxBottomItems).toList();
    final bottomIndex = widget.selectedIndex.clamp(0, visibleBottom.length - 1);

    return Scaffold(
      body: SafeArea(bottom: false, child: widget.child),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: bottomIndex,
        onTap: widget.onDestinationSelected,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        items: visibleBottom
            .asMap()
            .entries
            .map(
              (e) => BottomNavigationBarItem(
                icon: _navIcon(ref, e.value.label, e.value.icon),
                activeIcon: _navIcon(ref, e.value.label, e.value.selectedIcon),
                label: e.value.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

// ── Dark sidebar ──────────────────────────────────────────────────────────────

const _kSidebarBg = Color(0xFF0F172A);      // slate-900
const _kSidebarWidth = 220.0;

class _Sidebar extends ConsumerWidget {
  final List<NavItem> items;
  final int selectedIndex;
  final void Function(int) onDestinationSelected;
  final String tenantName;
  final dynamic profile;
  final String? activeTenantId;
  final bool canOpenPos;
  final Widget Function(String label, IconData icon) navIconBuilder;
  final VoidCallback onOpenPos;
  final VoidCallback onSignOut;
  final void Function(String tenantId)? onSwitchTenant;

  const _Sidebar({
    required this.items,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.tenantName,
    required this.profile,
    required this.activeTenantId,
    required this.canOpenPos,
    required this.navIconBuilder,
    required this.onOpenPos,
    required this.onSignOut,
    this.onSwitchTenant,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: _kSidebarWidth,
      color: _kSidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Logo ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: SvgPicture.asset(
              AppLogos.wordmarkDark,
              height: 22,
              fit: BoxFit.contain,
              alignment: Alignment.centerLeft,
            ),
          ),

          // ── Boutique ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: _TenantChip(
              tenantName: tenantName,
              activeTenantId: activeTenantId,
              memberships: profile?.memberships ?? [],
              onSwitch: onSwitchTenant,
            ),
          ),

          const SizedBox(height: 8),

          // ── Nav items ──────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                final isSelected = i == selectedIndex;
                return _NavTile(
                  icon: navIconBuilder(
                    item.label,
                    isSelected ? item.selectedIcon : item.icon,
                  ),
                  label: item.label,
                  isSelected: isSelected,
                  onTap: () => onDestinationSelected(i),
                );
              },
            ),
          ),

          // ── Bottom actions ─────────────────────────────────────────────
          const Divider(color: Colors.white12, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              children: [
                if (canOpenPos)
                  _NavTile(
                    icon: const Icon(Icons.point_of_sale_outlined,
                        size: 18, color: Colors.white60),
                    label: 'Ouvrir la caisse',
                    isSelected: false,
                    onTap: onOpenPos,
                  ),
                _NavTile(
                  icon: const Icon(Icons.logout,
                      size: 18, color: Colors.white60),
                  label: 'Déconnexion',
                  isSelected: false,
                  onTap: onSignOut,
                ),
              ],
            ),
          ),

          // ── User info ──────────────────────────────────────────────────
          const Divider(color: Colors.white12, height: 1),
          _UserFooter(profile: profile),
        ],
      ),
    );
  }
}

// ── Sidebar nav tile ──────────────────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.18)
                : Colors.transparent,
            border: isSelected
                ? Border.all(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            children: [
              IconTheme(
                data: IconThemeData(
                  size: 18,
                  color: isSelected
                      ? const Color(0xFF93C5FD) // blue-300
                      : Colors.white54,
                ),
                child: icon,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF93C5FD)
                        : Colors.white60,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tenant chip ───────────────────────────────────────────────────────────────

class _TenantChip extends StatelessWidget {
  final String tenantName;
  final String? activeTenantId;
  final List<dynamic> memberships;
  final void Function(String)? onSwitch;

  const _TenantChip({
    required this.tenantName,
    required this.activeTenantId,
    required this.memberships,
    this.onSwitch,
  });

  @override
  Widget build(BuildContext context) {
    final hasMultiple = memberships.length > 1;

    Widget chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          const Icon(Icons.storefront_outlined,
              size: 14, color: Colors.white54),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tenantName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasMultiple)
            const Icon(Icons.unfold_more, size: 14, color: Colors.white38),
        ],
      ),
    );

    if (hasMultiple && onSwitch != null) {
      chip = PopupMenuButton<String>(
        initialValue: activeTenantId,
        onSelected: onSwitch,
        tooltip: 'Changer de boutique',
        color: const Color(0xFF1E293B),
        itemBuilder: (_) => memberships
            .map((m) => PopupMenuItem<String>(
                  value: m.tenantId as String,
                  child: Text(
                    m.tenantName as String? ?? 'Branche',
                    style: TextStyle(
                      color: m.tenantId == activeTenantId
                          ? const Color(0xFF93C5FD)
                          : Colors.white70,
                      fontWeight: m.tenantId == activeTenantId
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ))
            .toList(),
        child: chip,
      );
    }

    return chip;
  }
}

// ── User footer ───────────────────────────────────────────────────────────────

class _UserFooter extends StatelessWidget {
  final dynamic profile;

  const _UserFooter({required this.profile});

  @override
  Widget build(BuildContext context) {
    final name = profile?.fullName ?? profile?.email ?? 'Utilisateur';
    final role = profile?.role ?? '';
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').take(2).map((w) => w[0]).join().toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withValues(alpha: 0.8),
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (role.isNotEmpty)
                  Text(
                    _roleLabel(role),
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 10),
                  ),
              ],
            ),
          ),
          const SyncStatusIndicator(),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'owner':
        return 'Propriétaire';
      case 'manager':
        return 'Gérant';
      case 'cashier':
        return 'Caissier';
      case 'commercial':
        return 'Commercial';
      default:
        return role;
    }
  }
}
