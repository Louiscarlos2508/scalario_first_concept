const spacingTokens = {
  'none': 0.0,
  'xs': 4.0,
  'sm': 8.0,
  'md': 16.0,
  'lg': 24.0,
  'xl': 32.0,
  'xxl': 48.0,
};

double resolveGap(dynamic gap) {
  if (gap is num) return gap.toDouble();
  if (gap is String) return spacingTokens[gap] ?? 8.0;
  return 8.0;
}

double resolvePadding(dynamic padding) {
  return resolveGap(padding);
}
