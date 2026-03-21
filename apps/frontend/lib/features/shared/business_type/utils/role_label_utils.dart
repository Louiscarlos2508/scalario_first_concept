const _ownerLabel = 'Propriétaire';

/// Returns a human-readable label for a given [roleCode].
///
/// - `owner` always returns `"Propriétaire"` (non-overridable).
/// - Other codes look up [roleLabels]; if found and non-empty, that label is used.
/// - Fallback: capitalises the first character of [roleCode].
String getRoleLabel(String roleCode, Map<String, dynamic> roleLabels) {
  if (roleCode == 'owner') return _ownerLabel;
  final label = roleLabels[roleCode];
  if (label != null && label is String && label.isNotEmpty) return label;
  return roleCode.isEmpty
      ? roleCode
      : '${roleCode[0].toUpperCase()}${roleCode.substring(1)}';
}
