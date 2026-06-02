import 'package:flutter/material.dart';

class SlotDefinition {
  final String zone;
  final String position;
  final bool sticky;
  final bool scroll;
  final List<String>? visibleOn;

  const SlotDefinition({
    required this.zone,
    required this.position,
    this.sticky = false,
    this.scroll = false,
    this.visibleOn,
  });

  static SlotDefinition fromJson(Map<String, dynamic> json) {
    return SlotDefinition(
      zone: json['zone'] as String? ?? '',
      position: json['position'] as String? ?? 'main',
      sticky: json['sticky'] as bool? ?? false,
      scroll: json['scroll'] as bool? ?? false,
      visibleOn: (json['visible_on'] as List<dynamic>?)?.cast<String>(),
    );
  }
}

class ScreenLayout {
  final String layout;
  final Map<String, SlotDefinition> slots;
  final Map<String, dynamic> responsive;
  final Map<String, dynamic> fallback;
  final String? breakpoint;
  final String? cartVisibility;

  const ScreenLayout({
    required this.layout,
    required this.slots,
    this.responsive = const {},
    this.fallback = const {},
    this.breakpoint,
    this.cartVisibility,
  });

  static ScreenLayout fromJson(Map<String, dynamic> json) {
    final slotsRaw = json['slots'] as Map<String, dynamic>? ?? {};
    final slots = slotsRaw.map((k, v) => MapEntry(k, SlotDefinition.fromJson(v as Map<String, dynamic>)));

    return ScreenLayout(
      layout: json['layout'] as String? ?? 'dashboard',
      slots: slots,
      responsive: json['responsive'] as Map<String, dynamic>? ?? {},
      fallback: json['fallback'] as Map<String, dynamic>? ?? {},
    );
  }

  List<String> zoneOrder({bool isWide = false}) {
    final wide = isWide;
    final order = {'header': 0, 'kpis': 1, 'main': 2, 'sidebar': 3, 'cart': 4, 'product_grid': 5, 'filters': 6, 'list': 7, 'form': 8, 'content': 9, 'actions': 10, 'sheet': 11};

    final visible = <MapEntry<String, SlotDefinition>>[];
    for (final e in slots.entries) {
      final vis = e.value.visibleOn;
      if (vis == null || vis.isEmpty) {
        visible.add(e);
      } else if (wide && vis.any((v) => v == 'desktop' || v == 'tablet')) {
        visible.add(e);
      } else if (!wide && vis.any((v) => v == 'mobile')) {
        visible.add(e);
      }
    }

    visible.sort((a, b) => (order[a.value.zone] ?? 99).compareTo(order[b.value.zone] ?? 99));
    return visible.map((e) => e.key).toList();
  }
}