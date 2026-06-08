// ============================================================
// sca_avatar.dart - REFONTE COMPLÈTE (Phase 7)
// AvatarGroup + Tooltips + Variants (circle/square) + tailles
// Inspiré du design system Twenty
// ============================================================
import 'package:flutter/material.dart';
import '../../engine/canvas_registry/component_config.dart';
import '../../theme/sca_tokens.dart';

enum ScaAvatarShape { circle, square }

enum ScaAvatarSize { xs, sm, md, lg, xl }

// ---- Single Avatar ----

class ScaAvatar extends StatelessWidget {
  final ComponentConfig config;

  const ScaAvatar({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final name = config.props['name'] as String? ?? '?';
    final imageUrl = config.props['image_url'] as String?;
    final sizeStr = config.props['size'] as String? ?? 'md';
    final shapeStr = config.props['shape'] as String? ?? 'circle';
    final showTooltip = config.props['show_tooltip'] as bool? ?? true;
    final group = (config.props['group'] as List<dynamic>?)
        ?.map((e) => e as Map<String, dynamic>)
        .toList();

    final size = _resolveSize(sizeStr);
    final shape = shapeStr == 'square'
        ? ScaAvatarShape.square
        : ScaAvatarShape.circle;

    // AvatarGroup mode
    if (group != null && group.isNotEmpty) {
      return _ScaAvatarGroup(
        members: group,
        size: size,
        shape: shape,
      );
    }

    final widget = _ScaAvatarSingle(
      name: name,
      imageUrl: imageUrl,
      size: size,
      shape: shape,
    );

    if (showTooltip && name.isNotEmpty && name != '?') {
      return Tooltip(
        message: name,
        child: widget,
      );
    }

    return widget;
  }

  double _resolveSize(String s) {
    switch (s) {
      case 'xs':
        return 20;
      case 'sm':
        return 24;
      case 'md':
        return 32;
      case 'lg':
        return 40;
      case 'xl':
        return 48;
      default:
        return 32;
    }
  }
}

// ---- Single Avatar Widget ----

class _ScaAvatarSingle extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;
  final ScaAvatarShape shape;
  final double? borderWidth;
  final Color? borderColor;

  const _ScaAvatarSingle({
    required this.name,
    required this.size,
    required this.shape,
    this.imageUrl,
    this.borderWidth,
    this.borderColor,
  });

  Color _generateColor(String name) {
    final colors = [
      const Color(0xFFE3F2FD),
      const Color(0xFFF3E5F5),
      const Color(0xFFE8F5E9),
      const Color(0xFFFFF8E1),
      const Color(0xFFFBE9E7),
      const Color(0xFFECEFF1),
    ];
    final idx = name.codeUnitAt(0) % colors.length;
    return colors[idx];
  }

  Color _generateFgColor(String name) {
    final colors = [
      const Color(0xFF1565C0),
      const Color(0xFF6A1B9A),
      const Color(0xFF2E7D32),
      const Color(0xFFF57F17),
      const Color(0xFFBF360C),
      const Color(0xFF37474F),
    ];
    final idx = name.codeUnitAt(0) % colors.length;
    return colors[idx];
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final bg = _generateColor(name);
    final fg = _generateFgColor(name);
    final radius = shape == ScaAvatarShape.circle
        ? BorderRadius.circular(ScaRadius.full)
        : BorderRadius.circular(ScaRadius.md);
    final fontSize = size * 0.36;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: imageUrl == null ? bg : null,
        borderRadius: radius,
        border: borderWidth != null
            ? Border.all(
                color: borderColor ?? ScaColors.bgPrimary,
                width: borderWidth!,
              )
            : null,
        image: imageUrl != null
            ? DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: imageUrl == null
          ? Text(
              _initials(name),
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w700,
                fontSize: fontSize,
                height: 1,
              ),
            )
          : null,
    );
  }
}

// ---- Avatar Group (multiple assignees) ----

class _ScaAvatarGroup extends StatelessWidget {
  final List<Map<String, dynamic>> members;
  final double size;
  final ScaAvatarShape shape;
  static const int maxVisible = 3;
  static const double overlapFactor = 0.3;

  const _ScaAvatarGroup({
    required this.members,
    required this.size,
    required this.shape,
  });

  @override
  Widget build(BuildContext context) {
    final visible = members.take(maxVisible).toList();
    final remaining = members.length - maxVisible;
    final overlap = size * overlapFactor;

    return SizedBox(
      width: size + (visible.length - 1) * (size - overlap) +
          (remaining > 0 ? size - overlap : 0),
      height: size,
      child: Stack(
        children: [
          for (int i = 0; i < visible.length; i++)
            Positioned(
              left: i * (size - overlap),
              child: Tooltip(
                message: visible[i]['name'] as String? ?? '',
                child: _ScaAvatarSingle(
                  name: visible[i]['name'] as String? ?? '?',
                  imageUrl: visible[i]['image_url'] as String?,
                  size: size,
                  shape: shape,
                  borderWidth: 2,
                  borderColor: ScaColors.bgPrimary,
                ),
              ),
            ),
          if (remaining > 0)
            Positioned(
              left: visible.length * (size - overlap),
              child: Tooltip(
                message: '+$remaining autres',
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: ScaColors.neutralBg,
                    borderRadius: shape == ScaAvatarShape.circle
                        ? BorderRadius.circular(ScaRadius.full)
                        : BorderRadius.circular(ScaRadius.md),
                    border: Border.all(
                      color: ScaColors.bgPrimary,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '+$remaining',
                    style: TextStyle(
                      fontSize: size * 0.3,
                      fontWeight: FontWeight.w700,
                      color: ScaColors.fontSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
