import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/shared/notifications/presentation/widgets/notification_bell.dart';
import '../theme/app_logos.dart';

const _kBg = Color(0xFF0F172A);
const _kFg = Colors.white;

/// App bar Scalario — fond sombre `#0F172A`, texte et icônes blancs.
/// Cohérent avec le POS AppBar sur toute l'application.
///
/// Leading : monogramme SVG (ou [leadingOverride] / bouton retour auto).
/// Titre   : [title] (String) ou [titleWidget] (Widget) si besoin d'un widget custom.
/// Pour les rôles owner et manager, la cloche de notifications est automatiquement
/// ajoutée en dernière action.
class ScalarioAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const ScalarioAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.bottom,
    this.leadingOverride,
  }) : assert(title != null || titleWidget != null,
            'Provide title or titleWidget');

  /// Titre textuel (usage standard).
  final String? title;

  /// Titre widget — pour les cas avec Chip, Row, etc.
  final Widget? titleWidget;

  /// Actions affichées à droite.
  final List<Widget>? actions;

  /// Widget affiché sous la barre (ex. `TabBar`).
  final PreferredSizeWidget? bottom;

  /// Remplace le monogramme en leading (ex. bouton retour custom).
  final Widget? leadingOverride;

  @override
  Size get preferredSize => Size.fromHeight(
        56 + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userProfileProvider).valueOrNull?.role;
    final showBell = role == 'owner' || role == 'manager';

    final List<Widget> allActions = [
      ...(actions ?? const <Widget>[]),
      if (showBell) const NotificationBell(),
    ];

    return AppBar(
      backgroundColor: _kBg,
      foregroundColor: _kFg,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 56,
      iconTheme: const IconThemeData(color: _kFg),
      actionsIconTheme: const IconThemeData(color: _kFg),
      leading: leadingOverride ??
          (Navigator.canPop(context)
              ? const BackButton(color: _kFg)
              : Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: SvgPicture.asset(
                    AppLogos.monogramDark,
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                  ),
                )),
      leadingWidth: 56,
      title: titleWidget ??
          Text(
            title!,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _kFg,
              height: 1.2,
            ),
          ),
      centerTitle: true,
      actions: allActions.isEmpty ? null : allActions,
      bottom: bottom,
    );
  }
}
