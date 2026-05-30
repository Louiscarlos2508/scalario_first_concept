import 'package:flutter/material.dart';

import '../../canvas_registry/component_config.dart';
import '../../../core/design_system/tokens/tokens.dart';

class CanvasDropdown extends StatefulWidget {
  final ComponentConfig config;
  final BuildContext ctx;

  const CanvasDropdown({super.key, required this.config, required this.ctx});

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    return CanvasDropdown(config: config, ctx: ctx);
  }

  @override
  State<CanvasDropdown> createState() => _CanvasDropdownState();
}

class _CanvasDropdownState extends State<CanvasDropdown> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.config.props['value'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.config.props['label'] as String? ?? widget.config.props['text'] as String? ?? '';
    final hint = widget.config.props['hint'] as String? ?? 'Sélectionner...';
    final items = (widget.config.props['options'] as List?)?.map((e) {
      if (e is Map) return MapEntry(e['value'] as String? ?? '', e['label'] as String? ?? '');
      return MapEntry(e.toString(), e.toString());
    }).toList() ?? <MapEntry<String, String>>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: ScalarioSpacing.space1),
            child: Text(label, style: ScalarioTypography.fontKpiLabel),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: ScalarioSpacing.space3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ScalarioRadius.sm),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selected != null && items.any((e) => e.key == _selected) ? _selected : null,
              hint: Text(hint, style: ScalarioTypography.bodyMedium),
              isExpanded: true,
              isDense: true,
              items: items.map((e) => DropdownMenuItem(
                value: e.key,
                child: Text(e.value, style: ScalarioTypography.bodyMedium),
              )).toList(),
              onChanged: (v) => setState(() => _selected = v),
            ),
          ),
        ),
      ],
    );
  }
}
