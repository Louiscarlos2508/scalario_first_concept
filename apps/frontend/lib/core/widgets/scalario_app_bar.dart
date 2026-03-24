import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/shared/notifications/presentation/widgets/notification_bell.dart';
import '../theme/app_logos.dart';

/// App bar Scalario (Material 3, hauteur 56 dp + bottom optionnel).
///
/// Leading : monogramme `scalario-monogram-dark.svg` 24×24 dp (ou [leadingOverride]).
/// Titre   : [title] centré en texte.
/// Thème   : fond et couleurs adaptés à la luminosité courante.
///
/// Pour les rôles owner et manager, la cloche de notifications est automatiquement
/// ajoutée en dernière action.
class ScalarioAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const ScalarioAppBar({
    super.key,
    required this.title,
    this.actions,
    this.bottom,
    this.leadingOverride,
  });

  /// Titre textuel affiché au centre de la barre.
  final String title;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF2B2B2B) : const Color(0xFFFFFFFF);
    final iconColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    final role = ref.watch(userProfileProvider).valueOrNull?.role;
    final showBell = role == 'owner' || role == 'manager';

    final List<Widget> allActions = [
      ...(actions ?? const <Widget>[]),
      if (showBell) const NotificationBell(),
    ];

    return AppBar(
      backgroundColor: bgColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 56,
      iconTheme: IconThemeData(color: iconColor),
      actionsIconTheme: IconThemeData(color: iconColor),
      leading: leadingOverride ??
          (Navigator.canPop(context)
              ? BackButton(color: iconColor)
              : Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: SvgPicture.asset(
                    AppLogos.monogramPath(context),
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                  ),
                )),
      leadingWidth: 56,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: iconColor,
          height: 1.2,
        ),
      ),
      centerTitle: true,
      actions: allActions.isEmpty ? null : allActions,
      bottom: bottom,
    );
  }
}
