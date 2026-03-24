import 'package:frontend/features/shared/business_type/data/business_type_config_repository.dart';

/// Returns true if [role] can access [screen].
///
/// Uses [config] when available; falls back to the built-in defaults inside
/// [BusinessTypeConfig.fallback] (which delegates to `_kDefaultScreens`).
bool canAccessScreen(
  String role,
  String screen,
  BusinessTypeConfig? config,
) {
  return (config ?? BusinessTypeConfig.fallback).canAccess(role, screen);
}
