import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../canvas_registry/component_schema.dart';
import '../canvas_registry/scalario_canvas_registry.dart';

/// Overlay de debug draggable qui affiche les erreurs de validation
/// des schémas de composants pour l'écran courant.
///
/// Ne fait rien si [ScalarioCanvasRegistry.instance] est null.
/// Ne s'affiche qu'en `kDebugMode`.
class SchemaDebugOverlay extends StatefulWidget {
  final String screenId;
  final Widget child;

  const SchemaDebugOverlay({
    super.key,
    required this.screenId,
    required this.child,
  });

  @override
  State<SchemaDebugOverlay> createState() => _SchemaDebugOverlayState();
}

class _SchemaDebugOverlayState extends State<SchemaDebugOverlay> {
  Offset _position = const Offset(16, 200);
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_expanded) _buildBackdrop(),
        Positioned(
          left: _position.dx,
          top: _position.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() => _position += details.delta);
            },
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: _expanded
                  ? const Color(0xF0282838)
                  : const Color(0xE0282838),
              child: _expanded ? _buildExpanded() : _buildCollapsed(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackdrop() {
    return GestureDetector(
      onTap: () => setState(() => _expanded = false),
      child: Container(color: Colors.black26),
    );
  }

  Widget _buildCollapsed() {
    final errors = _currentErrors;
    final count = errors.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: count > 0 ? Colors.orangeAccent : Colors.green,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            count > 0 ? Icons.warning_amber_rounded : Icons.check_circle,
            color: count > 0 ? Colors.orangeAccent : Colors.green,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            'Schema: $count error(s)',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Colors.white54, size: 16),
        ],
      ),
    );
  }

  Widget _buildExpanded() {
    final errors = _currentErrors;
    return Container(
      width: 340,
      constraints: const BoxConstraints(maxHeight: 400),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                errors.isEmpty ? Icons.check_circle : Icons.warning_amber_rounded,
                color: errors.isEmpty ? Colors.green : Colors.orangeAccent,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Schema — ${widget.screenId}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _expanded = false),
                child: const Icon(Icons.close, color: Colors.white54, size: 18),
              ),
            ],
          ),
          const Divider(color: Colors.white24),
          if (errors.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No validation errors',
                style: TextStyle(color: Colors.green, fontSize: 12),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: errors.length,
                separatorBuilder: (_, _) => const Divider(height: 1, color: Colors.white12),
                itemBuilder: (_, i) => _buildErrorTile(errors[i]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorTile(SchemaValidationError error) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '<${error.type}>${error.componentId.isNotEmpty ? '#${error.componentId}' : ''}',
            style: const TextStyle(
              color: Colors.orangeAccent,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            error.message,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  List<SchemaValidationError> get _currentErrors {
    final reg = ScalarioCanvasRegistry.instance;
    if (reg == null) return const [];
    try {
      return reg.lastValidationErrors(widget.screenId);
    } catch (e, st) {
      developer.log(
        'SchemaDebugOverlay error: $e',
        name: 'BDUI.Debug',
        level: 900,
        error: e,
        stackTrace: st,
      );
      return const [];
    }
  }
}
