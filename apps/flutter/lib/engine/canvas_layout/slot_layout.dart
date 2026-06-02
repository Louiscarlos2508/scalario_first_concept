import 'package:flutter/material.dart';
import '../canvas_registry/screen_layout.dart';
import '../canvas_registry/component_config.dart';
import '../canvas_registry/scalario_canvas_registry.dart';
import '../canvas/screen_cache.dart';

class SlotLayout extends StatelessWidget {
  final ScreenLayout layout;
  final Map<String, List<ComponentConfig>> zones;
  final ScalarioCanvasRegistry registry;

  const SlotLayout({
    super.key,
    required this.layout,
    required this.zones,
    required this.registry,
  });

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;
    final zoneOrder = layout.zoneOrder(isWide: wide);

    final zoneWidgets = zoneOrder
        .map((slotKey) {
          final slot = layout.slots[slotKey];
          if (slot == null) return null;
          if (slot.visibleOn != null && !wide && slot.visibleOn!.contains('desktop')) return null;
          final components = zones[slot.zone] ?? [];
          if (components.isEmpty) return null;

          Widget content = _buildZone(context, components, slot);

          if (slot.sticky && slot.position != 'bottom') {
            content = Column(
              children: [
                content,
                const Divider(height: 1),
              ],
            );
          }

          return MapEntry(slotKey, content);
        })
        .whereType<MapEntry<String, Widget>>()
        .toList();

    if (zoneWidgets.isEmpty) {
      return const Center(child: Text('Sélectionnez un écran'));
    }

    final hasSidebar = zoneWidgets.any((e) =>
        layout.slots[e.key]?.position == 'right' ||
        layout.slots[e.key]?.position == 'sidebar');

    if (hasSidebar && wide) {
      final main = zoneWidgets.where((e) =>
          layout.slots[e.key]?.position != 'right' &&
          layout.slots[e.key]?.position != 'sidebar');
      final side = zoneWidgets.where((e) =>
          layout.slots[e.key]?.position == 'right' ||
          layout.slots[e.key]?.position == 'sidebar');

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: _buildScrollView(main.toList()),
          ),
          SizedBox(
            width: 320,
            child: _buildScrollView(side.toList()),
          ),
        ],
      );
    }

    final stickyBottom = zoneWidgets
        .where((e) => layout.slots[e.key]?.sticky == true && layout.slots[e.key]?.position == 'bottom')
        .toList();
    final scrollable = zoneWidgets
        .where((e) => !(layout.slots[e.key]?.sticky == true && layout.slots[e.key]?.position == 'bottom'))
        .toList();

    if (stickyBottom.isNotEmpty) {
      return Column(
        children: [
          Expanded(child: _buildScrollView(scrollable)),
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: stickyBottom.map((e) => e.value).toList(),
            ),
          ),
        ],
      );
    }

    return _buildScrollView(zoneWidgets);
  }

  Widget _buildScrollView(List<MapEntry<String, Widget>> entries) {
    return ListView(
      padding: EdgeInsets.zero,
      children: entries.map((e) => e.value).toList(),
    );
  }

  Widget _buildZone(BuildContext context, List<ComponentConfig> components, covariant dynamic slot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: components
          .map((c) => registry.build(c, context, slot is SlotDefinition ? slot.zone : ''))
          .toList(),
    );
  }
}