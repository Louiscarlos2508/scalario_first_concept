import 'package:flutter/material.dart';

import '../../canvas_registry/component_config.dart';
import '../../../core/design_system/tokens/tokens.dart';

class CanvasInput extends StatefulWidget {
  final ComponentConfig config;
  final BuildContext ctx;

  const CanvasInput({super.key, required this.config, required this.ctx});

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    return CanvasInput(config: config, ctx: ctx);
  }

  @override
  State<CanvasInput> createState() => _CanvasInputState();
}

class _CanvasInputState extends State<CanvasInput> {
  late TextEditingController _controller;
  bool _obscured = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.config.props['value'] as String? ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant CanvasInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newValue = widget.config.props['value'] as String?;
    if (newValue != null && newValue != _controller.text) {
      _controller.text = newValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.config.props['label'] as String? ?? widget.config.props['text'] as String? ?? '';
    final hint = widget.config.props['hint'] as String?;
    final inputType = widget.config.props['type'] as String? ?? 'text';
    final required = widget.config.props['required'] as bool? ?? false;
    final prefix = widget.config.props['prefix'] as String?;
    final suffix = widget.config.props['suffix'] as String?;
    final readOnly = widget.config.props['readonly'] as bool? ?? false;

    final isPassword = inputType == 'password';
    final isNumber = inputType == 'number' || inputType == 'numeric';
    final isMoney = inputType == 'money';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: ScalarioSpacing.space1),
            child: Row(
              children: [
                Text(label, style: ScalarioTypography.fontKpiLabel),
                if (required)
                  const Text(' *', style: TextStyle(color: ScalarioColors.danger500)),
              ],
            ),
          ),
        TextField(
          controller: _controller,
          readOnly: readOnly,
          obscureText: isPassword ? !_obscured : false,
          keyboardType: isNumber || isMoney ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: ScalarioSpacing.space3,
              vertical: ScalarioSpacing.space3,
            ),
            prefixText: isMoney ? 'FCFA ' : prefix,
            suffixText: isMoney ? null : suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ScalarioRadius.sm),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ScalarioRadius.sm),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ScalarioRadius.sm),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(_obscured ? Icons.visibility : Icons.visibility_off, size: 18),
                    onPressed: () => setState(() => _obscured = !_obscured),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
