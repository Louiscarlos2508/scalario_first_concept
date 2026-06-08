import 'package:flutter/material.dart';
import 'screen_appbar.dart';

class AppbarRenderer extends StatelessWidget {
  const AppbarRenderer({super.key, required this.appbar});

  final AppbarConfig? appbar;

  @override
  Widget build(BuildContext context) {
    if (appbar == null) return const SizedBox.shrink();
    final otherActions = appbar!.actions.where((a) => a.icon != 'search').toList();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (appbar!.actions.any((a) => a.icon == 'search'))
          SizedBox(
            width: 180,
            height: 36,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        for (final a in otherActions) _ActionButton(action: a),
      ],
    );
  }
}

class PlatformAppbar extends StatelessWidget implements PreferredSizeWidget {
  const PlatformAppbar({super.key, required this.appbar, this.leading, this.actions});

  final AppbarConfig? appbar;
  final Widget? leading;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final hasSearch = appbar?.actions.any((a) => a.icon == 'search') ?? false;
    final otherActions = appbar?.actions.where((a) => a.icon != 'search').toList() ?? [];

    return Container(
      height: kToolbarHeight,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 8)],
          if (hasSearch)
            Expanded(child: _searchField(context))
          else
            const Spacer(),
          if (actions != null) ...actions!,
          for (final a in otherActions) _ActionButton(action: a),
        ],
      ),
    );
  }

  Widget _searchField(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 36,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Rechercher...',
          prefixIcon: const Icon(Icons.search, size: 20),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action});

  final AppbarAction action;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(iconFromString(action.icon)),
          tooltip: action.badge ?? action.action.cmd ?? action.action.type,
          onPressed: () {},
        ),
        if (action.badge != null)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}


