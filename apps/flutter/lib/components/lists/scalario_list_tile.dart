import 'package:flutter/material.dart';

import '../../core/design_system/tokens/tokens.dart';
import '../../core/theme/theme_extensions.dart';
import '../_internal/shimmer.dart';

/// Statut sémantique d'un `ScalarioListTile` — colore la bordure gauche.
///
/// Utilisé par les listes métier (mouvements, transferts, alertes) pour
/// indiquer visuellement l'état d'un item sans charge cognitive
/// supplémentaire.
enum ListTileStatus { primary, success, warning, danger }

/// Item de liste Scalario — wrappe `ListTile` Material 3 + bordure gauche
/// colorée optionnelle.
///
/// **Spec source :** `design-process/D-Design-System/components/06-lists.md`
/// (pattern liste générique).
///
/// **États supportés :** Normal, Tappable, Disabled, Loading, Empty (variante
/// centrée), Error, Avec leading/trailing.
///
/// **Différence avec `ListTile` Material 3 :**
/// - Bordure gauche colorée optionnelle via `status`.
/// - Factories `loading()` / `empty()` / `error()`.
/// - Typo et padding alignés sur les tokens Scalario.
class ScalarioListTile extends StatelessWidget {
  const ScalarioListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.status,
  })  : _variant = _TileVariant.normal,
        _emptyMessage = null,
        _errorMessage = null;

  const ScalarioListTile._loading()
      : leading = null,
        title = '',
        subtitle = null,
        trailing = null,
        onTap = null,
        enabled = false,
        status = null,
        _variant = _TileVariant.loading,
        _emptyMessage = null,
        _errorMessage = null;

  const ScalarioListTile._empty({required String message})
      : leading = null,
        title = '',
        subtitle = null,
        trailing = null,
        onTap = null,
        enabled = true,
        status = null,
        _variant = _TileVariant.empty,
        _emptyMessage = message,
        _errorMessage = null;

  const ScalarioListTile._error({required String message})
      : leading = null,
        title = '',
        subtitle = null,
        trailing = null,
        onTap = null,
        enabled = true,
        status = ListTileStatus.danger,
        _variant = _TileVariant.error,
        _emptyMessage = null,
        _errorMessage = message;

  /// Construit un `ScalarioListTile` depuis les props d'un `ComponentConfig` BDUI.
  ///
  /// Utilisé par le `ComponentRegistry` (STORY-005) sous les types
  /// `MouvementItem` et `ListTile`. Délègue à [fromJson].
  static Widget fromConfig(Map<String, dynamic> props, BuildContext ctx) {
    try {
      return ScalarioListTile.fromJson(props);
    } on FormatException {
      return ScalarioListTile(title: props['title'] as String? ?? '—');
    }
  }

  const factory ScalarioListTile.loading() = _LoadingTile;

  factory ScalarioListTile.empty(String message) =>
      ScalarioListTile._empty(message: message);

  factory ScalarioListTile.error(String message) =>
      ScalarioListTile._error(message: message);

  factory ScalarioListTile.fromJson(Map<String, dynamic> json) {
    final String? title = json['title'] as String?;
    if (title == null) {
      throw const FormatException("ScalarioListTile: 'title' requis");
    }
    return ScalarioListTile(
      title: title,
      subtitle: json['subtitle'] as String?,
      enabled: json['enabled'] as bool? ?? true,
      status: _parseStatus(json['status'] as String?),
    );
  }

  static ListTileStatus? _parseStatus(String? raw) {
    if (raw == null) return null;
    return ListTileStatus.values.firstWhere(
      (ListTileStatus s) => s.name == raw,
      orElse: () => ListTileStatus.primary,
    );
  }

  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final ListTileStatus? status;
  final _TileVariant _variant;
  final String? _emptyMessage;
  final String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    switch (_variant) {
      case _TileVariant.loading:
        return const _LoadingTile();
      case _TileVariant.empty:
        return _EmptyTile(message: _emptyMessage!);
      case _TileVariant.error:
        return _ErrorTile(message: _errorMessage!);
      case _TileVariant.normal:
        return _buildNormal(context);
    }
  }

  Widget _buildNormal(BuildContext context) {
    final Color titleColor = enabled
        ? ScalarioColors.textPrimary
        : ScalarioColors.textDisabled;
    final Color subtitleColor = enabled
        ? ScalarioColors.textSecondary
        : ScalarioColors.textDisabled;

    final Widget tile = ListTile(
      leading: leading,
      trailing: trailing,
      enabled: enabled,
      onTap: enabled ? onTap : null,
      title: Text(
        title,
        style: ScalarioTypography.fontListPrimary.copyWith(color: titleColor),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: ScalarioTypography.fontListSecondary
                  .copyWith(color: subtitleColor),
            )
          : null,
    );

    if (status == null) return tile;

    final Color borderColor = _statusColor(context, status!);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: borderColor, width: 3)),
      ),
      child: tile,
    );
  }

  static Color _statusColor(BuildContext context, ListTileStatus status) {
    final ScalarioColorsExtension ext =
        Theme.of(context).extension<ScalarioColorsExtension>()!;
    switch (status) {
      case ListTileStatus.primary:
        return ScalarioColors.primary500;
      case ListTileStatus.success:
        return ext.synced;
      case ListTileStatus.warning:
        return ScalarioColors.warning500;
      case ListTileStatus.danger:
        return ScalarioColors.danger500;
    }
  }
}

enum _TileVariant { normal, loading, empty, error }

class _LoadingTile extends ScalarioListTile {
  const _LoadingTile() : super._loading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ScalarioSpacing.space4,
        vertical: ScalarioSpacing.space3,
      ),
      child: ScalarioShimmer(
        child: Row(
          children: <Widget>[
            ScalarioShimmerBox(
              width: 40,
              height: 40,
              radius: ScalarioRadius.full,
            ),
            SizedBox(width: ScalarioSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ScalarioShimmerBox(width: 200, height: 14),
                  SizedBox(height: ScalarioSpacing.space2),
                  ScalarioShimmerBox(width: 120, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTile extends StatelessWidget {
  const _EmptyTile({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ScalarioSpacing.space6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            ScalarioIcons.inbox,
            size: ScalarioIconSize.lg,
            color: ScalarioColors.textDisabled,
          ),
          const SizedBox(height: ScalarioSpacing.space3),
          Text(
            message,
            textAlign: TextAlign.center,
            style: ScalarioTypography.body.copyWith(
              color: ScalarioColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorTile extends StatelessWidget {
  const _ErrorTile({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ScalarioSpacing.space4),
      child: Row(
        children: <Widget>[
          const Icon(
            ScalarioIcons.error,
            size: ScalarioIconSize.sm,
            color: ScalarioColors.danger500,
          ),
          const SizedBox(width: ScalarioSpacing.space3),
          Expanded(
            child: Text(
              message,
              style: ScalarioTypography.body.copyWith(
                color: ScalarioColors.danger700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
