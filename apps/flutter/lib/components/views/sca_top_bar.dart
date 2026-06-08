// ============================================================
// sca_top_bar.dart
// AppBar universelle Scalario — portée de TopBar + NavigationDrawerHeader de Twenty
// Features:
//  - Breadcrumbs cliquables (avec séparateur "/")
//  - Zone de gauche (breadcrumbs + titre de la vue)
//  - Zone de droite (actions + avatar profil + menus)
//  - Barre de filtres inférieure (slot "bottom")
//  - Hauteur fixe 39px (identique à Twenty)
//  - Séparateur de bas (border-bottom 1px)
// ============================================================
import 'package:flutter/material.dart';
import '../../engine/canvas_registry/component_config.dart';
import '../../theme/sca_tokens.dart';
import '../_internal/sca_focus_wrapper.dart';
import '../data_display/sca_avatar.dart';

class ScaTopBar extends StatelessWidget {
  final ComponentConfig config;

  const ScaTopBar({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final title = config.props['title'] as String? ?? 'Vue';
    final breadcrumbs = (config.props['breadcrumbs'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final showSearch = config.props['show_search'] as bool? ?? false;
    final showProfile = config.props['show_profile'] as bool? ?? true;
    final profileName = config.props['profile_name'] as String? ?? 'U';
    final profileImageUrl = config.props['profile_image_url'] as String?;
    final actions = (config.props['actions'] as List<dynamic>?) ?? [];

    return Container(
      decoration: const BoxDecoration(
        color: ScaColors.bgPrimary,
        border: Border(
          bottom: BorderSide(color: ScaColors.borderLight, width: 1),
        ),
      ),
      padding: const EdgeInsets.only(
        left: ScaSpacing.s3,
        right: ScaSpacing.s2,
      ),
      height: 39,
      child: Row(
        children: [
          // Zone gauche : breadcrumbs + titre vue courante
          _LeftSection(title: title, breadcrumbs: breadcrumbs),
          const Spacer(),
          // Zone droite : search + actions + profil
          _RightSection(
            showSearch: showSearch,
            showProfile: showProfile,
            profileName: profileName,
            profileImageUrl: profileImageUrl,
            actions: actions,
          ),
        ],
      ),
    );
  }
}

// ---- Left: Breadcrumbs + Title ----

class _LeftSection extends StatelessWidget {
  final String title;
  final List<String> breadcrumbs;

  const _LeftSection({required this.title, required this.breadcrumbs});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < breadcrumbs.length; i++) ...[
          ScaFocusWrapper(
            padding: const EdgeInsets.symmetric(
              horizontal: ScaSpacing.s1,
              vertical: 2,
            ),
            borderRadius: BorderRadius.circular(ScaRadius.sm),
            child: Text(
              breadcrumbs[i],
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: ScaColors.fontTertiary,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              '/',
              style: TextStyle(
                fontSize: 13,
                color: ScaColors.fontLight,
              ),
            ),
          ),
        ],
        // Titre de la vue active (toujours affiché en primary)
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: ScaColors.fontPrimary,
          ),
        ),
      ],
    );
  }
}

// ---- Right: Actions, Search, Profile ----

class _RightSection extends StatelessWidget {
  final bool showSearch;
  final bool showProfile;
  final String profileName;
  final String? profileImageUrl;
  final List<dynamic> actions;

  const _RightSection({
    required this.showSearch,
    required this.showProfile,
    required this.profileName,
    required this.actions,
    this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Actions contextuelles
        for (final action in actions)
          _TopBarActionButton(action: action as Map<String, dynamic>),

        if (actions.isNotEmpty)
          const SizedBox(width: ScaSpacing.s2),

        // Bouton recherche
        if (showSearch) ...[
          _ScaTopBarIconButton(
            icon: Icons.search_rounded,
            tooltip: 'Recherche',
            onTap: () {},
          ),
          const SizedBox(width: ScaSpacing.s1),
        ],

        // Avatar profil utilisateur
        if (showProfile)
          _ProfileAvatar(
            name: profileName,
            imageUrl: profileImageUrl,
          ),
      ],
    );
  }
}

class _TopBarActionButton extends StatelessWidget {
  final Map<String, dynamic> action;

  const _TopBarActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    final label = action['label'] as String? ?? '';
    final icon = action['icon'] as String?;
    final isPrimary = action['primary'] as bool? ?? false;

    return Padding(
      padding: const EdgeInsets.only(left: ScaSpacing.s1),
      child: ScaFocusWrapper(
        onTap: () {},
        padding: const EdgeInsets.symmetric(
          horizontal: ScaSpacing.s2,
          vertical: ScaSpacing.s1,
        ),
        borderRadius: BorderRadius.circular(ScaRadius.sm),
        child: Container(
          decoration: isPrimary
              ? BoxDecoration(
                  color: ScaColors.focusRing,
                  borderRadius: BorderRadius.circular(ScaRadius.sm),
                )
              : null,
          padding: isPrimary
              ? const EdgeInsets.symmetric(
                  horizontal: ScaSpacing.s2,
                  vertical: ScaSpacing.s1,
                )
              : null,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isPrimary ? Colors.white : ScaColors.fontSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScaTopBarIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ScaTopBarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: ScaFocusWrapper(
        onTap: onTap,
        padding: const EdgeInsets.all(ScaSpacing.s1),
        borderRadius: BorderRadius.circular(ScaRadius.sm),
        child: Icon(icon, size: 18, color: ScaColors.fontSecondary),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;

  const _ProfileAvatar({required this.name, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty
        ? name.split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : 'U';

    return Tooltip(
      message: name,
      child: ScaFocusWrapper(
        onTap: () {},
        padding: const EdgeInsets.all(2),
        borderRadius: BorderRadius.circular(ScaRadius.full),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ScaColors.focusRing,
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
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
