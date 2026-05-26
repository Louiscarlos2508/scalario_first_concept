enum ScalarioBreakpoint { compact, medium, expanded }

ScalarioBreakpoint resolveBreakpoint(double width) {
  if (width < 600) return ScalarioBreakpoint.compact;
  if (width < 1200) return ScalarioBreakpoint.medium;
  return ScalarioBreakpoint.expanded;
}

Map<String, dynamic>? resolveResponsiveConfig(
  Map<String, dynamic>? responsive,
  double width,
) {
  if (responsive == null) return null;
  final bp = resolveBreakpoint(width);
  return switch (bp) {
    ScalarioBreakpoint.compact => responsive['compact'] as Map<String, dynamic>?,
    ScalarioBreakpoint.medium => responsive['medium'] as Map<String, dynamic>?,
    ScalarioBreakpoint.expanded => responsive['expanded'] as Map<String, dynamic>?,
  };
}
