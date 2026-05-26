import 'package:flutter/material.dart';

import '../../../components/actions/scalario_button.dart';
import '../../../components/inputs/form_section.dart';
import '../../../engine/canvas_registry/component_config.dart';
import '../../../l10n/s.dart';

class ModuleFormScreen extends StatefulWidget {
  const ModuleFormScreen({super.key, required this.config});
  final Map<String, dynamic> config;

  @override
  State<ModuleFormScreen> createState() => _ModuleFormScreenState();
}

class _ModuleFormScreenState extends State<ModuleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _values = <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    for (final field in (widget.config['fields'] as List?) ?? []) {
      _values[field['key'] as String] = field['default'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.config['title'] as String? ?? S.of(context).moduleVentes;
    final fields = (widget.config['fields'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Form(
        key: _formKey,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: fields.length + 1,
          itemBuilder: (context, index) {
            if (index == fields.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 24),
                child: ScalarioButton.fromConfig(
                  ComponentConfig(type: 'ScalarioButton', variant: 'primary', props: {'label': S.of(context).btnSave}),
                  context,
                ),
              );
            }
            final field = fields[index];
            final key = field['key'] as String;
            final label = field['label'] as String? ?? key;
            final required = field['required'] as bool? ?? false;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: label,
                  hintText: field['hint'] as String?,
                ),
                initialValue: _values[key]?.toString(),
                validator: required ? (v) => v == null || v.isEmpty ? S.of(context).formRequired : null : null,
                onSaved: (v) => _values[key] = v,
              ),
            );
          },
        ),
      ),
    );
  }
}
