import 'package:flutter/material.dart';
import '../../canvas_registry/component_config.dart';
import '../../canvas_registry/scalario_canvas_registry.dart';
import '../../../core/design_system/tokens/spacing_resolver.dart';

class CanvasSlots extends StatelessWidget {
  final ComponentConfig config;
  final BuildContext ctx;
  const CanvasSlots({super.key, required this.config, required this.ctx});

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    return CanvasSlots(config: config, ctx: ctx);
  }

  @override
  Widget build(BuildContext context) {
    final slots = config.props['slots'] as Map<String, dynamic>? ?? {};
    final r = ScalarioCanvasRegistry.instance;
    if (r == null) return const SizedBox.shrink();

    final mainSlot = slots['main'];
    final asideSlot = slots['aside'];
    final hasAside = asideSlot != null;
    bool hideAsideMobile = false;
    if (asideSlot is Map) {
      hideAsideMobile = (asideSlot['hide_on_mobile'] as bool?) ?? false;
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (slots['banner'] != null)
        _render(r, slots['banner'], context),
      Expanded(child: hasAside ? LayoutBuilder(builder: (context, constraints) {
        final showAside = !hideAsideMobile || constraints.maxWidth >= 600;
    int flex = 1;
    if (mainSlot is Map && mainSlot.containsKey('flex')) {
      flex = mainSlot['flex'] as int;
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex: flex, child: _render(r, mainSlot, context)),
          if (showAside) SizedBox(width: resolveGap(asideSlot?['width'] ?? 320), child: _render(r, asideSlot, context)),
        ]);
      }) : _render(r, mainSlot ?? slots['main'], context)),
      if (slots['bottom'] != null)
        _render(r, slots['bottom'], context),
      if (slots['fab'] != null)
        Positioned(bottom: resolveGap('lg'), right: resolveGap('lg'), child: _render(r, slots['fab'], context)),
    ]);
  }

  Widget _render(ScalarioCanvasRegistry r, dynamic slot, BuildContext ctx) {
    if (slot == null || slot is! Map) return const SizedBox.shrink();
    final cc = ComponentConfig.fromJson(slot as Map<String, dynamic>);
    return r.build(cc, ctx);
  }
}
