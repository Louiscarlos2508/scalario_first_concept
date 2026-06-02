import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

class _NavGroup {
  _NavGroup({required this.label, required this.icon, required this.screens});
  final String label;
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

  List<_NavGroup>? _groups;
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
      final resp = await _dio.get<Map<String, dynamic>>(
        '/api/v1/${widget.tenantSlug}/navigation',
        options: Options(headers: {'Authorization': 'Bearer ${widget.token}'}),
      );
      final data = resp.data!;
      final sidebar = data['sidebar'] as Map<String, dynamic>?;
      final groupsJson = (sidebar?['groups'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>() ?? [];

      final groups = groupsJson.map((g) {
        final screens = (g['screens'] as List<dynamic>?)?.map((s) {
          final sm = s as Map<String, dynamic>;
          return _NavScreen(
            id: sm['screen'] as String? ?? sm['id'] as String,
            title: sm['label'] as String? ?? sm['title'] as String? ?? sm['screen'] as String,
          );
        }).toList() ?? [];
        return _NavGroup(
          label: g['label'] as String? ?? g['name'] as String? ?? g['module'] as String ?? '',
          icon: g['icon'] as String? ?? 'apps',
          screens: screens,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _groups = groups;
        _loadingNav = false;
      });

      if (groups.isNotEmpty && groups.first.screens.isNotEmpty) {
        _selectScreen(groups.first.screens.first.id);
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
      final resp = await _dio.get<Map<String, dynamic>>(
        '/api/v1/${widget.tenantSlug}/layout/$screenId',
        options: Options(headers: {'Authorization': 'Bearer ${widget.token}'}),
      );
      final config = ScreenConfig.fromJson(resp.data!);
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
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return Scaffold(
          appBar: wide
              ? null
              : AppBar(
                  title: SvgPicture.asset(
                    'assets/images/scalario-wordmark-light.svg',
                    height: 28,
                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
                ),
          drawer: wide ? null : Drawer(child: _buildNavContent(theme, onClose: Navigator.of(context).pop)),
          body: Row(
            children: [
              if (wide) _buildSidebar(theme),
              Expanded(child: _buildBody(engine)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavContent(ThemeData theme, {VoidCallback? onClose}) {
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
      padding: EdgeInsets.zero,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          color: theme.colorScheme.primary,
          child: SvgPicture.asset(
            'assets/images/scalario-wordmark-light.svg',
            height: 32,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ),
        if (_groups != null)
          for (final group in _groups!) ...[
            if (group.label.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  group.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ...group.screens.map((screen) {
              final selected = screen.id == _currentScreenId;
              return ListTile(
                dense: true,
                leading: Icon(
                  _iconFromString(group.icon),
                  size: 20,
                  color: selected ? theme.colorScheme.primary : null,
                ),
                title: Text(
                  screen.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    color: selected ? theme.colorScheme.primary : null,
                  ),
                ),
                selected: selected,
                selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onTap: () {
                  _selectScreen(screen.id);
                  onClose?.call();
                },
              );
            }),
          ],
      ],
    );
  }

  Widget _buildSidebar(ThemeData theme) {
    return SizedBox(
      width: 280,
      child: Material(
        elevation: 2,
        shadowColor: Colors.black26,
        child: _buildNavContent(theme),
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
