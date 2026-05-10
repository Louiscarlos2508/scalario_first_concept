/// Contrat d'entrée du ComponentRegistry — value object immutable.
///
/// Mappé sur le champ `ComponentConfig` du JSON Schema partagé
/// (STORY-023). La sérialisation manuelle ci-dessous sera regénérée
/// par quicktype quand le schema sera figé.
///
/// AC-01: POJO immutable, fromJson/toJson, champs optionnels nullable.
/// AC-02: copyWith disponible.
class ComponentConfig {
  const ComponentConfig({
    required this.type,
    this.id,
    this.props = const <String, dynamic>{},
    this.visibleIf,
    this.source,
    this.validation,
    this.i18nKey,
  });

  /// Construit depuis un map JSON brut.
  ///
  /// Si `type` est absent ou vide, retourne un config avec `type == ""` —
  /// le registry le traitera comme un type inconnu (UnknownComponent).
  factory ComponentConfig.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> toStringMap(dynamic raw) {
      if (raw == null) return <String, dynamic>{};
      if (raw is Map<String, dynamic>) return raw;
      return (raw as Map<dynamic, dynamic>).cast<String, dynamic>();
    }

    return ComponentConfig(
      type: json['type'] as String? ?? '',
      id: json['id'] as String?,
      props: toStringMap(json['props']),
      visibleIf: json['visible_if'] == null
          ? null
          : toStringMap(json['visible_if']),
      source: json['source'] == null ? null : toStringMap(json['source']),
      validation: (json['validation'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>(),
      i18nKey: json['i18n_key'] as String?,
    );
  }

  /// Type string résolu par le ComponentRegistry (`"KPICard"`, `"DataTable"`, …).
  final String type;

  /// Identifiant stable du composant dans le screen — utile pour les
  /// animations de transition et l'audit log.
  final String? id;

  /// Props métier passées au builder DS — contenu dépend du `type`.
  final Map<String, dynamic> props;

  /// Règle de visibilité évaluée par RuleEvaluator (STORY-006).
  /// `null` = composant toujours visible.
  final Map<String, dynamic>? visibleIf;

  /// Source de données résolue par le BDUIEngine (STORY-008).
  final Map<String, dynamic>? source;

  /// Règles de validation — utilisées par FormWidget (STORY-011).
  final List<Map<String, dynamic>>? validation;

  /// Clé i18n pour la localisation (STORY-042).
  final String? i18nKey;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        if (id != null) 'id': id,
        if (props.isNotEmpty) 'props': props,
        if (visibleIf != null) 'visible_if': visibleIf,
        if (source != null) 'source': source,
        if (validation != null) 'validation': validation,
        if (i18nKey != null) 'i18n_key': i18nKey,
      };

  ComponentConfig copyWith({
    String? type,
    String? id,
    Map<String, dynamic>? props,
    Map<String, dynamic>? visibleIf,
    Map<String, dynamic>? source,
    List<Map<String, dynamic>>? validation,
    String? i18nKey,
  }) {
    return ComponentConfig(
      type: type ?? this.type,
      id: id ?? this.id,
      props: props ?? this.props,
      visibleIf: visibleIf ?? this.visibleIf,
      source: source ?? this.source,
      validation: validation ?? this.validation,
      i18nKey: i18nKey ?? this.i18nKey,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComponentConfig &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          id == other.id;

  @override
  int get hashCode => Object.hash(type, id);

  @override
  String toString() => 'ComponentConfig(type: $type, id: $id)';
}
