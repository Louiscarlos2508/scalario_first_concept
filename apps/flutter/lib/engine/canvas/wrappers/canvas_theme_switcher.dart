import 'package:flutter/material.dart';

class CanvasThemeSwitcher extends StatelessWidget {
  final String mode;
  final Map<String, dynamic>? colors;
  final Widget child;

  const CanvasThemeSwitcher({super.key, this.mode = 'system', this.colors, required this.child});

  static Widget fromConfig(dynamic config, BuildContext ctx, Widget child) {
    final mode = (config is Map) ? config['mode'] as String? ?? 'system' : 'system';
    final colors = (config is Map) ? config['colors'] as Map<String, dynamic>? : null;
    return CanvasThemeSwitcher(mode: mode, colors: colors, child: child);
  }

  static ThemeData applyColors(ThemeData base, Map<String, dynamic>? colors) {
    if (colors == null) return base;
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: _parseColor(colors['primary'] as String?) ?? base.colorScheme.primary,
        error: _parseColor(colors['danger'] as String?) ?? base.colorScheme.error,
      ),
    );
  }

  static Color? _parseColor(String? hex) {
    if (hex == null || !hex.startsWith('#')) return null;
    return Color(int.parse(hex.substring(1), radix: 16) | 0xFF000000);
  }

  @override
  Widget build(BuildContext context) => child;
}
