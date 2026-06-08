import 'package:flutter/material.dart';
import '../canvas_registry/screen_layout.dart';
import '../canvas_registry/component_config.dart';
import '../canvas_registry/scalario_canvas_registry.dart';

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

          Widget content = _buildZone(context, components, slot, wide);

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
            child: _buildScrollView(main.toList(), wide),
          ),
          SizedBox(
            width: 320,
            child: _buildScrollView(side.toList(), wide, isSidebar: true),
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
          Expanded(child: _buildScrollView(scrollable, wide)),
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: stickyBottom.map((e) => e.value).toList(),
            ),
          ),
        ],
      );
    }

    return _buildScrollView(zoneWidgets, wide);
  }

  Widget _buildScrollView(List<MapEntry<String, Widget>> entries, bool wide, {bool isSidebar = false}) {
    Widget content = ListView(
      padding: isSidebar
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
          : (wide
              ? const EdgeInsets.symmetric(horizontal: 24, vertical: 20)
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
      children: entries.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: e.value,
      )).toList(),
    );

    if (wide && !isSidebar) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: content,
        ),
      );
    }
    return content;
  }

  Widget _buildZone(BuildContext context, List<ComponentConfig> components, SlotDefinition slot, bool wide) {
    final children = components
        .map((c) => registry.build(c, context, slot.zone))
        .toList();

    if (children.isEmpty) return const SizedBox.shrink();

    if (slot.zone == 'kpis') {
      if (wide) {
        final List<Widget> rowChildren = children
            .map<Widget>((w) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: w,
                  ),
                ))
            .toList();
        if (rowChildren.isNotEmpty) {
          rowChildren[rowChildren.length - 1] = Expanded(child: children.last);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rowChildren,
        );
      } else {
        final List<Widget> colChildren = children
            .map<Widget>((w) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: w,
                ))
            .toList();
        if (colChildren.isNotEmpty) {
          colChildren[colChildren.length - 1] = children.last;
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: colChildren,
        );
      }
    }

    if (slot.zone == 'actions') {
      if (wide) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: children
              .map((w) => Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: w,
                  ))
              .toList(),
        );
      } else {
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.spaceEvenly,
          children: children,
        );
      }
    }

    final List<Widget> defaultChildren = children
        .map<Widget>((w) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: w,
            ))
        .toList();
    if (defaultChildren.isNotEmpty) {
      defaultChildren[defaultChildren.length - 1] = children.last;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: defaultChildren,
    );
  }
}