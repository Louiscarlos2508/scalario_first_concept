import 'package:flutter/material.dart';

import '../design_system/tokens/colors.dart';
import '../design_system/tokens/spacing.dart';

/// Couleurs sémantiques métier non couvertes par `ColorScheme`.
///
/// `ColorScheme` Material 3 expose primary/secondary/tertiary/error/surface,
/// mais Scalario a besoin de couleurs spécifiques pour :
///
/// - **Sync** (4 statuts barre de sync) : `synced`, `syncing`, `offline`,
///   `syncError`. Décision UX : `offline` n'est **jamais rouge** (P3) —
///   c'est un état neutre, pas un échec.
/// - **Conflicts** (Drift CRDT) : `conflict` = warning-700.
/// - **Stock** : `surplus`, `critical`, `rupture` (KPICard, AlertBanner).
/// - **Crédit** : `pendingCredit` (vente en attente de paiement).
///
/// Lecture runtime :
/// ```dart
/// final colors = Theme.of(context).extension<ScalarioColorsExtension>()!;
/// Container(color: colors.synced, ...);
/// ```
///
/// Spec STORY-002 AC-17, AC-20.
@immutable
class ScalarioColorsExtension extends ThemeExtension<ScalarioColorsExtension> {
  const ScalarioColorsExtension({
    required this.synced,
    required this.syncing,
    required this.offline,
    required this.syncError,
    required this.conflict,
    required this.surplus,
    required this.critical,
    required this.rupture,
    required this.pendingCredit,
  });

  /// Sync — 4 statuts SyncStatusBar
  final Color synced;
  final Color syncing;
  final Color offline;
  final Color syncError;

  /// Conflits Drift CRDT
  final Color conflict;

  /// Stock
  final Color surplus;
  final Color critical;
  final Color rupture;

  /// Vente en attente de paiement
  final Color pendingCredit;

  /// Light : palette par défaut.
  static const ScalarioColorsExtension light = ScalarioColorsExtension(
    synced: ScalarioColors.success500,
    syncing: ScalarioColors.primary500,
    offline: ScalarioColors.neutral500, // jamais rouge — décision P3
    syncError: ScalarioColors.warning500,
    conflict: ScalarioColors.warning700,
    surplus: ScalarioColors.primary500,
    critical: ScalarioColors.danger500,
    rupture: ScalarioColors.danger700,
    pendingCredit: ScalarioColors.warning700,
  );

  /// Dark : nuances ajustées pour fond sombre (primary500 → primary300 pour
  /// le contraste sur `bgCardDark`).
  static const ScalarioColorsExtension dark = ScalarioColorsExtension(
    synced: ScalarioColors.success500,
    syncing: ScalarioColors.primary300,
    offline: ScalarioColors.neutral500,
    syncError: ScalarioColors.warning500,
    conflict: ScalarioColors.warning700,
    surplus: ScalarioColors.primary300,
    critical: ScalarioColors.danger500,
    rupture: ScalarioColors.danger700,
    pendingCredit: ScalarioColors.warning700,
  );

  static ScalarioColorsExtension fromBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  @override
  ScalarioColorsExtension copyWith({
    Color? synced,
    Color? syncing,
    Color? offline,
    Color? syncError,
    Color? conflict,
    Color? surplus,
    Color? critical,
    Color? rupture,
    Color? pendingCredit,
  }) {
    return ScalarioColorsExtension(
      synced: synced ?? this.synced,
      syncing: syncing ?? this.syncing,
      offline: offline ?? this.offline,
      syncError: syncError ?? this.syncError,
      conflict: conflict ?? this.conflict,
      surplus: surplus ?? this.surplus,
      critical: critical ?? this.critical,
      rupture: rupture ?? this.rupture,
      pendingCredit: pendingCredit ?? this.pendingCredit,
    );
  }

  @override
  ScalarioColorsExtension lerp(
    covariant ThemeExtension<ScalarioColorsExtension>? other,
    double t,
  ) {
    if (other is! ScalarioColorsExtension) return this;
    return ScalarioColorsExtension(
      synced: Color.lerp(synced, other.synced, t)!,
      syncing: Color.lerp(syncing, other.syncing, t)!,
      offline: Color.lerp(offline, other.offline, t)!,
      syncError: Color.lerp(syncError, other.syncError, t)!,
      conflict: Color.lerp(conflict, other.conflict, t)!,
      surplus: Color.lerp(surplus, other.surplus, t)!,
      critical: Color.lerp(critical, other.critical, t)!,
      rupture: Color.lerp(rupture, other.rupture, t)!,
      pendingCredit: Color.lerp(pendingCredit, other.pendingCredit, t)!,
    );
  }
}

/// Spacing tokens exposés runtime.
///
/// Utile pour les widgets BDUI qui veulent piocher dans le thème plutôt que
/// d'importer `ScalarioSpacing` directement (préférence Flutter idiomatique).
///
/// Spec STORY-002 AC-18.
@immutable
class ScalarioSpacingExtension extends ThemeExtension<ScalarioSpacingExtension> {
  const ScalarioSpacingExtension({
    required this.space1,
    required this.space2,
    required this.space3,
    required this.space4,
    required this.space5,
    required this.space6,
    required this.space8,
    required this.space10,
    required this.space12,
    required this.space16,
  });

  final double space1;
  final double space2;
  final double space3;
  final double space4;
  final double space5;
  final double space6;
  final double space8;
  final double space10;
  final double space12;
  final double space16;

  static const ScalarioSpacingExtension standard = ScalarioSpacingExtension(
    space1: ScalarioSpacing.space1,
    space2: ScalarioSpacing.space2,
    space3: ScalarioSpacing.space3,
    space4: ScalarioSpacing.space4,
    space5: ScalarioSpacing.space5,
    space6: ScalarioSpacing.space6,
    space8: ScalarioSpacing.space8,
    space10: ScalarioSpacing.space10,
    space12: ScalarioSpacing.space12,
    space16: ScalarioSpacing.space16,
  );

  @override
  ScalarioSpacingExtension copyWith({
    double? space1,
    double? space2,
    double? space3,
    double? space4,
    double? space5,
    double? space6,
    double? space8,
    double? space10,
    double? space12,
    double? space16,
  }) {
    return ScalarioSpacingExtension(
      space1: space1 ?? this.space1,
      space2: space2 ?? this.space2,
      space3: space3 ?? this.space3,
      space4: space4 ?? this.space4,
      space5: space5 ?? this.space5,
      space6: space6 ?? this.space6,
      space8: space8 ?? this.space8,
      space10: space10 ?? this.space10,
      space12: space12 ?? this.space12,
      space16: space16 ?? this.space16,
    );
  }

  @override
  ScalarioSpacingExtension lerp(
    covariant ThemeExtension<ScalarioSpacingExtension>? other,
    double t,
  ) {
    if (other is! ScalarioSpacingExtension) return this;
    return ScalarioSpacingExtension(
      space1: lerpDouble(space1, other.space1, t),
      space2: lerpDouble(space2, other.space2, t),
      space3: lerpDouble(space3, other.space3, t),
      space4: lerpDouble(space4, other.space4, t),
      space5: lerpDouble(space5, other.space5, t),
      space6: lerpDouble(space6, other.space6, t),
      space8: lerpDouble(space8, other.space8, t),
      space10: lerpDouble(space10, other.space10, t),
      space12: lerpDouble(space12, other.space12, t),
      space16: lerpDouble(space16, other.space16, t),
    );
  }

  static double lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

/// Élévations exposées runtime — wraps `ScalarioElevation.e0..e4` en
/// `List<BoxShadow>`.
///
/// Spec STORY-002 AC-19. `lerp` interpole les ombres en restant en discrete
/// (Flutter ne sait pas mélanger des `BoxShadow` de manière utile en
/// transition de thème — on snap au target à `t >= 0.5`).
@immutable
class ScalarioElevationExtension
    extends ThemeExtension<ScalarioElevationExtension> {
  const ScalarioElevationExtension({
    required this.e0,
    required this.e1,
    required this.e2,
    required this.e3,
    required this.e4,
  });

  final List<BoxShadow> e0;
  final List<BoxShadow> e1;
  final List<BoxShadow> e2;
  final List<BoxShadow> e3;
  final List<BoxShadow> e4;

  static const ScalarioElevationExtension standard = ScalarioElevationExtension(
    e0: ScalarioElevation.e0,
    e1: ScalarioElevation.e1,
    e2: ScalarioElevation.e2,
    e3: ScalarioElevation.e3,
    e4: ScalarioElevation.e4,
  );

  /// Dark — ombres atténuées (sur fond sombre, la profondeur passe par la
  /// surface tinting plus que par l'ombre projetée).
  static const ScalarioElevationExtension dark = ScalarioElevationExtension(
    e0: ScalarioElevation.e0,
    e1: ScalarioElevation.e1,
    e2: ScalarioElevation.e2,
    e3: ScalarioElevation.e3,
    e4: ScalarioElevation.e4,
  );

  static ScalarioElevationExtension fromBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : standard;

  @override
  ScalarioElevationExtension copyWith({
    List<BoxShadow>? e0,
    List<BoxShadow>? e1,
    List<BoxShadow>? e2,
    List<BoxShadow>? e3,
    List<BoxShadow>? e4,
  }) {
    return ScalarioElevationExtension(
      e0: e0 ?? this.e0,
      e1: e1 ?? this.e1,
      e2: e2 ?? this.e2,
      e3: e3 ?? this.e3,
      e4: e4 ?? this.e4,
    );
  }

  @override
  ScalarioElevationExtension lerp(
    covariant ThemeExtension<ScalarioElevationExtension>? other,
    double t,
  ) {
    if (other is! ScalarioElevationExtension) return this;
    return t < 0.5 ? this : other;
  }
}
