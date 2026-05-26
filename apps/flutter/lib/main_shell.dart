import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'features/modules/catalog_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  Map<String, dynamic>? _module;
  final _screens = <String>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadModule();
  }

  Future<void> _loadModule() async {
    try {
      final raw = await rootBundle.loadString('assets/catalog/tenants/blandine/module.json');
      setState(() {
        _module = jsonDecode(raw) as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _module == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final screenRefs = (_module!['screens'] as List?)?.cast<String>() ?? [];
    if (screenRefs.isEmpty) return const Scaffold(body: Center(child: Text('No screens')));

    // Limit tabs to first 5 screens for BottomNav
    final tabCount = screenRefs.length > 5 ? 5 : screenRefs.length;
    final idx = _currentIndex.clamp(0, screenRefs.length - 1);

    final tabIcons = [
      Icons.home, Icons.inventory_2, Icons.warning, Icons.local_shipping, Icons.bar_chart,
    ];

    return Scaffold(
      body: CatalogScreen(jsonAssetPath: 'assets/catalog/tenants/blandine/module.json', screenIndex: _currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: idx.clamp(0, tabCount - 1),
        onTap: (i) => setState(() => _currentIndex = i),
        items: List.generate(tabCount, (i) {
          final name = screenRefs[i].replaceAll('screens/', '').replaceAll('.json', '').replaceAll('_', ' ');
          return BottomNavigationBarItem(icon: Icon(tabIcons[i % tabIcons.length]), label: name.length > 8 ? name.substring(0, 7) : name);
        }),
      ),
    );
  }
}
