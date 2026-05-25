import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/design_system/tokens/tokens.dart';

/// Type sémantique d'un `AlertBanner`.
///
/// Hiérarchie d'attention : `critical` > `warning` > `success` > `info`.
/// Une seule banner visible à la fois (règle DS, garantie par l'écran appelant).
enum AlertType { critical, warning, success, info }

/// Banner d'alerte affiché en haut de vue, sous l'AppBar.
///
/// **Spec source :** `design-process/D-Design-System/components/01-feedback.md`
/// (lignes 14-68).
///
/// **États supportés :** `critical`, `warning`, `success`, `info`, absent
/// (= widget non rendu par le parent).
///
/// **Règles métier :**
/// - `critical` ne s'auto-dismiss **jamais** — `autoDismissMs` ignoré pour ce type.
/// - `critical` ne se swipe pas — l'utilisateur doit cliquer sur l'action.
/// - `success` typique : 2000 ms d'auto-dismiss.
class AlertBanner extends StatefulWidget {
  const AlertBanner({
    super.key,
    required this.type,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.autoDismissMs,
    this.onDismiss,
  });

  /// Construit un `AlertBanner` depuis les props d'un `ComponentConfig` BDUI.
  ///
  /// Utilisé par le `ScalarioCanvasRegistry` (STORY-005). Délègue à [fromJson].
  static Widget fromConfig(Map<String, dynamic> props, BuildContext ctx) {
    try {
      return AlertBanner.fromJson(props);
    } on FormatException {
      return const AlertBanner(type: AlertType.warning, message: 'Alerte indisponible');
    }
  }

  factory AlertBanner.fromJson(Map<String, dynamic> json) {
    final String? message = json['message'] as String?;
    if (message == null) {
      throw const FormatException("AlertBanner: 'message' requis");
    }
    return AlertBanner(
      type: _parseType(json['type'] as String?),
      message: message,
      actionLabel: json['action_label'] as String?,
      autoDismissMs: json['auto_dismiss_ms'] as int?,
    );
  }

  static AlertType _parseType(String? raw) {
    if (raw == null) return AlertType.info;
    return AlertType.values.firstWhere(
      (AlertType t) => t.name == raw,
      orElse: () => AlertType.info,
    );
  }

  final AlertType type;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Auto-dismiss en ms. Ignoré si `type == critical`.
  final int? autoDismissMs;

  /// Appelé quand le banner est dismiss (auto ou swipe).
  final VoidCallback? onDismiss;

  @override
  State<AlertBanner> createState() => _AlertBannerState();
}

class _AlertBannerState extends State<AlertBanner> {
  Timer? _dismissTimer;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _scheduleAutoDismiss();
  }

  @override
  void didUpdateWidget(AlertBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.autoDismissMs != widget.autoDismissMs ||
        oldWidget.type != widget.type) {
      _dismissTimer?.cancel();
      _scheduleAutoDismiss();
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _scheduleAutoDismiss() {
    if (widget.type == AlertType.critical) return;
    final int? ms = widget.autoDismissMs;
    if (ms == null) return;
    _dismissTimer = Timer(Duration(milliseconds: ms), _dismiss);
  }

  void _dismiss() {
    if (_dismissed || !mounted) return;
    setState(() => _dismissed = true);
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final _BannerPalette palette = _paletteFor(widget.type);
    final Widget banner = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ScalarioSpacing.space4,
        vertical: ScalarioSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: palette.background,
        border: Border(
          left: BorderSide(color: palette.border, width: 3),
        ),
        borderRadius: BorderRadius.circular(ScalarioRadius.sm),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            palette.icon,
            size: ScalarioIconSize.sm,
            color: palette.text,
          ),
          const SizedBox(width: ScalarioSpacing.space3),
          Expanded(
            child: Text(
              widget.message,
              style: ScalarioTypography.fontBannerText.copyWith(
                color: palette.text,
              ),
            ),
          ),
          if (widget.actionLabel != null) ...<Widget>[
            const SizedBox(width: ScalarioSpacing.space2),
            // GestureDetector + Padding + Text plutôt que TextButton :
            // TextButton dans un Row avec un Expanded déclenche une
            // assertion "BoxConstraints forces an infinite width" pendant
            // la mesure intrinsèque du Flex — incompatibilité connue entre
            // _RenderInputPadding du bouton et le passe Flex initial.
            // Le visuel "ghost button" demandé par AC-19 est conservé.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onAction,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ScalarioSpacing.space3,
                  vertical: ScalarioSpacing.space2,
                ),
                child: Text(
                  widget.actionLabel!,
                  style: ScalarioTypography.fontButton.copyWith(
                    color: palette.text,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (widget.type == AlertType.critical) {
      return banner;
    }

    // AC-18 — swipe horizontal pour dismiss (sauf critical). On utilise un
    // GestureDetector simple plutôt que `Dismissible` : Dismissible exige des
    // contraintes de largeur que les boutons d'action (TextButton interne)
    // peinent à respecter quand l'AlertBanner est en haut d'un Scaffold sans
    // appbar. Le résultat fonctionnel est identique pour Sprint 1.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (DragEndDetails details) {
        // Seuil de vélocité minimum pour éviter les dismiss accidentels.
        if (details.primaryVelocity == null) return;
        if (details.primaryVelocity!.abs() > 200) {
          _dismiss();
        }
      },
      child: banner,
    );
  }

  static _BannerPalette _paletteFor(AlertType type) {
    switch (type) {
      case AlertType.critical:
        return const _BannerPalette(
          background: ScalarioColors.danger100,
          text: ScalarioColors.danger700,
          border: ScalarioColors.danger500,
          icon: ScalarioIcons.alert,
        );
      case AlertType.warning:
        return const _BannerPalette(
          background: ScalarioColors.warning100,
          text: ScalarioColors.warning700,
          border: ScalarioColors.warning500,
          icon: ScalarioIcons.warning,
        );
      case AlertType.success:
        return const _BannerPalette(
          background: ScalarioColors.success100,
          text: ScalarioColors.success700,
          border: ScalarioColors.success500,
          icon: ScalarioIcons.check,
        );
      case AlertType.info:
        return const _BannerPalette(
          background: ScalarioColors.info100,
          text: ScalarioColors.info500,
          border: ScalarioColors.info500,
          icon: ScalarioIcons.info,
        );
    }
  }
}

class _BannerPalette {
  const _BannerPalette({
    required this.background,
    required this.text,
    required this.border,
    required this.icon,
  });

  final Color background;
  final Color text;
  final Color border;
  final IconData icon;
}
