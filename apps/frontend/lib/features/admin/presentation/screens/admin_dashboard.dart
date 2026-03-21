import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/theme/app_breakpoints.dart';
import 'admin_tenants_screen.dart';
import 'admin_modules_screen.dart';
import 'admin_monitoring_screen.dart';
import 'admin_billing_screen.dart';
import 'business_types_screen.dart';

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

const List<_NavItem> _adminNavItems = [
  _NavItem(icon: Icons.business, label: 'Tenants'),
  _NavItem(icon: Icons.extension, label: 'Modules'),
  _NavItem(icon: Icons.monitor_heart, label: 'Monitoring'),
  _NavItem(icon: Icons.store, label: 'Types métier'),
  _NavItem(icon: Icons.receipt_long, label: 'Facturation'),
];

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    AdminTenantsScreen(),
    AdminModulesScreen(),
    AdminMonitoringScreen(),
    BusinessTypesScreen(),
    AdminBillingScreen(),
  ];

  void _signOut() => ref.read(authRepositoryProvider).signOut();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= kMedium) {
          return _buildTabletLayout();
        }
        return _buildMobileLayout();
      },
    );
  }

  Widget _buildTabletLayout() {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) =>
                setState(() => _selectedIndex = index),
            labelType: NavigationRailLabelType.all,
            destinations: _adminNavItems
                .map((item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      label: Text(item.label),
                    ))
                .toList(),
            trailing: Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: 'Déconnexion',
                    onPressed: _signOut,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: SafeArea(
              child: IndexedStack(
                index: _selectedIndex,
                children: _screens,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        title: Text(_adminNavItems[_selectedIndex].label),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: _signOut,
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: _adminNavItems
            .map((item) => NavigationDestination(
                  icon: Icon(item.icon),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }
}
