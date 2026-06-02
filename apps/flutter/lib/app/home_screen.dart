import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../engine/canvas/scalario_canvas.dart';
import '../engine/canvas_layout/screen_config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.token,
    required this.tenantSlug,
  });

  final String token;
  final String tenantSlug;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _NavModule {
  _NavModule({required this.id, required this.name, required this.icon, required this.screens});
  final String id;
  final String name;
  final String icon;
  final List<_NavScreen> screens;
}

class _NavScreen {
  _NavScreen({required this.id, required this.title});
  final String id;
  final String title;
}

class _HomeScreenState extends State<HomeScreen> {
  final _dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));

  List<_NavModule>? _modules;
  var _loadingNav = true;
  String? _navError;

  var _loadingScreen = false;
  ScreenConfig? _screenConfig;
  String? _screenError;
  String? _currentScreenId;

  @override
  void initState() {
    super.initState();
    _fetchNavigation();
  }

  @override
  void dispose() {
    _dio.close();
    super.dispose();
  }

  Future<void> _fetchNavigation() async {
    setState(() {
      _loadingNav = true;
      _navError = null;
    });
    try {
      final resp = await _dio.get(
        '/api/v1/${widget.tenantSlug}/navigation',
        options: Options(headers: {'Authorization': 'Bearer ${widget.token}'}),
      );
      final data = resp.data as Map<String, dynamic>;
      final modulesJson = data['modules'] as List<dynamic>;
      final modules = modulesJson.map((m) {
        final map = m as Map<String, dynamic>;
        final screens = (map['screens'] as List<dynamic>).map((s) {
          final sm = s as Map<String, dynamic>;
          return _NavScreen(id: sm['id'] as String, title: sm['title'] as String? ?? sm['id'] as String);
        }).toList();
        return _NavModule(
          id: map['id'] as String,
          name: map['name'] as String? ?? map['id'] as String,
          icon: map['icon'] as String? ?? 'apps',
          screens: screens,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _modules = modules;
        _loadingNav = false;
      });

      if (modules.isNotEmpty && modules.first.screens.isNotEmpty) {
        _selectScreen(modules.first.screens.first.id);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _navError = e.toString();
        _loadingNav = false;
      });
    }
  }

  Future<void> _selectScreen(String screenId) async {
    setState(() {
      _currentScreenId = screenId;
      _loadingScreen = true;
      _screenError = null;
    });

    try {
      final resp = await _dio.get(
        '/api/v1/${widget.tenantSlug}/layout/$screenId',
        options: Options(headers: {'Authorization': 'Bearer ${widget.token}'}),
      );
      final config = ScreenConfig.fromJson(resp.data as Map<String, dynamic>);
      if (!mounted) return;
      setState(() {
        _screenConfig = config;
        _loadingScreen = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _screenError = e.toString();
        _loadingScreen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = GetIt.I<ScalarioCanvas>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return Scaffold(
          appBar: wide ? null : AppBar(title: Text(_currentScreenId ?? 'Scalario')),
          drawer: wide ? null : Drawer(child: _buildNavContent(onClose: Navigator.of(context).pop)),
          body: Row(
            children: [
              if (wide) _buildSidebar(),
              Expanded(child: _buildBody(engine)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavContent({VoidCallback? onClose}) {
    if (_loadingNav) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_navError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Erreur: $_navError'),
        ),
      );
    }
    return ListView(
      children: [
        DrawerHeader(
          child: Text(
            widget.tenantSlug,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        if (_modules != null)
          for (final module in _modules!)
            ExpansionTile(
              leading: Icon(_iconFromString(module.icon)),
              title: Text(module.name),
              initiallyExpanded: true,
              children: module.screens.map((screen) {
                return ListTile(
                  title: Text(screen.title),
                  selected: screen.id == _currentScreenId,
                  onTap: () {
                    _selectScreen(screen.id);
                    onClose?.call();
                  },
                );
              }).toList(),
            ),
      ],
    );
  }

  Widget _buildSidebar() {
    return SizedBox(
      width: 280,
      child: Material(
        elevation: 1,
        child: _buildNavContent(),
      ),
    );
  }

  Widget _buildBody(ScalarioCanvas engine) {
    if (_loadingScreen) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_screenError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Erreur: $_screenError'),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => _selectScreen(_currentScreenId ?? ''), child: const Text('Réessayer')),
          ],
        ),
      );
    }
    if (_screenConfig == null) {
      return const Center(child: Text('Sélectionnez un écran'));
    }

    return engine.render(_screenConfig!, context);
  }

  IconData _iconFromString(String name) {
    return switch (name) {
      'point_of_sale' => Icons.point_of_sale,
      'inventory_2' => Icons.inventory_2,
      'notifications' => Icons.notifications,
      'shopping_cart' => Icons.shopping_cart,
      'receipt' => Icons.receipt,
      'people' => Icons.people,
      'bar_chart' => Icons.bar_chart,
      'warning' => Icons.warning,
      _ => Icons.apps,
    };
  }
}