// ============================================================
// sca_focus_wrapper.dart
// Wrapper universel de Focus Ring + Hover State
// Inspiré de l'architecture de NavigationDrawerItem de Twenty:
//   &:hover { background: transparent.light; }
//   border: 1px solid ${color.blue} (when focused)
// ============================================================
import 'package:flutter/material.dart';
import '../../theme/sca_tokens.dart';

enum ScaFocusVariant {
  /// Fond transparent avec arrondi au survol (ex: item de navigation)
  subtle,
  /// Bordure bleue pleine (ex: input, champ de formulaire)
  outlined,
  /// Sans effet visible (désactivé)
  none,
}

/// Widget générique pour ajouter les comportements Hover + Focus
/// conformes au design system de Twenty/Scalario.
/// Remplace les InkWell/Material ripples par défaut de Flutter.
class ScaFocusWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final ScaFocusVariant variant;
  final BorderRadius borderRadius;
  final bool isSelected;
  final bool isDisabled;
  final EdgeInsets? padding;

  const ScaFocusWrapper({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.variant = ScaFocusVariant.subtle,
    this.borderRadius = const BorderRadius.all(Radius.circular(ScaRadius.sm)),
    this.isSelected = false,
    this.isDisabled = false,
    this.padding,
  });

  @override
  State<ScaFocusWrapper> createState() => _ScaFocusWrapperState();
}

class _ScaFocusWrapperState extends State<ScaFocusWrapper> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  Color _getBackgroundColor() {
    if (widget.isDisabled) return Colors.transparent;
    if (widget.variant == ScaFocusVariant.none) return Colors.transparent;

    if (_isPressed) return ScaColors.transparentMedium;
    if (widget.isSelected) return ScaColors.transparentLight;
    if (_isHovered) return ScaColors.transparentLight;
    return Colors.transparent;
  }

  Border? _getBorder() {
    if (widget.isDisabled) return Border.all(color: Colors.transparent);

    if (widget.variant == ScaFocusVariant.outlined) {
      if (_isFocused) {
        return Border.all(color: ScaColors.focusRing, width: 1.5);
      }
      if (widget.isSelected) {
        return Border.all(color: ScaColors.focusRing, width: 1.0);
      }
      return Border.all(color: ScaColors.borderLight, width: 1.0);
    }

    if (widget.variant == ScaFocusVariant.subtle) {
      if (widget.isSelected) {
        return Border.all(color: ScaColors.focusRing, width: 1.0);
      }
    }

    return Border.all(color: Colors.transparent, width: 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.isDisabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      onEnter: (_) {
        if (!widget.isDisabled) setState(() => _isHovered = true);
      },
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.isDisabled ? null : widget.onTap,
        onLongPress: widget.isDisabled ? null : widget.onLongPress,
        onTapDown: (_) {
          if (!widget.isDisabled) setState(() => _isPressed = true);
        },
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: Focus(
          onFocusChange: (focused) => setState(() => _isFocused = focused),
          child: AnimatedContainer(
            duration: ScaAnimation.fast,
            curve: ScaAnimation.easeOut,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              borderRadius: widget.borderRadius,
              border: _getBorder(),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
