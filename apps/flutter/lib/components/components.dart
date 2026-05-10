/// Barrel — point d'entrée unique pour les composants BDUI Scalario.
///
/// Spec source : STORY-003 (Composants BDUI Métier).
///
/// Les 7 composants ici sont les seuls enregistrés dans le `ComponentRegistry`
/// (STORY-005) au lancement de Sprint 1. Les autres composants du DS sont
/// implémentés en cascade — quand une story d'écran les exige.
library;

export 'actions/scalario_fab.dart';
export 'data_display/chart_bar.dart';
export 'data_display/kpi_card.dart';
export 'data_display/scalario_data_table.dart';
export 'feedback/alert_banner.dart';
export 'inputs/form_section.dart';
export 'lists/scalario_list_tile.dart';
