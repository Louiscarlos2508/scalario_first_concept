import 'package:flutter/material.dart';

class AppbarActionDescriptor {
  final String type;
  final String? cmd;
  final String? sheet;

  const AppbarActionDescriptor({
    required this.type,
    this.cmd,
    this.sheet,
  });

  factory AppbarActionDescriptor.fromJson(Map<String, dynamic> json) {
    return AppbarActionDescriptor(
      type: json['type'] as String? ?? 'local',
      cmd: json['cmd'] as String?,
      sheet: json['sheet'] as String?,
    );
  }
}

class AppbarAction {
  final String icon;
  final String? badge;
  final AppbarActionDescriptor action;

  const AppbarAction({
    required this.icon,
    this.badge,
    required this.action,
  });

  factory AppbarAction.fromJson(Map<String, dynamic> json) {
    return AppbarAction(
      icon: json['icon'] as String? ?? '',
      badge: json['badge'] as String?,
      action: AppbarActionDescriptor.fromJson(
        json['action'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class AppbarConfig {
  final String title;
  final bool showBack;
  final List<AppbarAction> actions;

  const AppbarConfig({
    required this.title,
    this.showBack = false,
    this.actions = const [],
  });

  factory AppbarConfig.fromJson(Map<String, dynamic> json) {
    final actionsJson = json['actions'] as List<dynamic>? ?? [];
    return AppbarConfig(
      title: json['title'] as String? ?? '',
      showBack: json['show_back'] as bool? ?? false,
      actions: actionsJson
          .map((e) => AppbarAction.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static AppbarConfig? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return AppbarConfig.fromJson(json);
  }
}

IconData iconFromString(String name) {
  return switch (name) {
    'notifications' => Icons.notifications_outlined,
    'search' => Icons.search,
    'receipt_long' => Icons.receipt_long,
    'calendar_month' => Icons.calendar_month,
    'file_download' => Icons.file_download,
    'shopping_cart' => Icons.shopping_cart,
    'add' => Icons.add,
    'close' => Icons.close,
    'arrow_back' => Icons.arrow_back,
    'more_vert' => Icons.more_vert,
    'menu' => Icons.menu,
    _ => Icons.circle_outlined,
  };
}
