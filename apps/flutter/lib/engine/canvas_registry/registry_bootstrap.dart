import '../../components/actions/scalario_fab.dart';
import '../../components/data_display/chart_bar.dart';
import '../../components/data_display/kpi_card.dart';
import '../../components/data_display/scalario_data_table.dart';
import '../../components/feedback/alert_banner.dart';
import '../../components/inputs/form_section.dart';
import '../../components/lists/scalario_list_tile.dart';
import 'scalario_canvas_registry.dart';

/// Enregistre les composants DS Phase 1 dans [registry].
///
/// Appelé depuis `main()` avant `runApp()` — synchrone, < 1ms.
///
/// **Convention d'extension :** pour ajouter un composant en Sprint 2+,
/// ajouter **une seule ligne** ici. Ne jamais modifier [ScalarioCanvasRegistry]
/// lui-même pour ajouter un type (AC-18 — zéro logique métier dans engine).
///
/// **Aliases :** certains types JSON historiques (FAB, FormSection, ChartBar)
/// pointent vers le même builder DS que leur équivalent canonique.
abstract final class RegistryBootstrap {
  static void registerPhase1(ScalarioCanvasRegistry r) {
    // 02 — Data Display
    r.register('KPICard', (c, ctx) => KPICard.fromConfig(c.props, ctx));
    r.register(
        'DataTable', (c, ctx) => ScalarioDataTable.fromConfig(c.props, ctx));
    r.register('ChartWidget', (c, ctx) => ChartBar.fromConfig(c.props, ctx));
    // alias ChartBar → ChartWidget (PRD §FR-001 vs DS naming)
    r.register('ChartBar', (c, ctx) => ChartBar.fromConfig(c.props, ctx));

    // 01 — Feedback
    r.register(
        'AlertBanner', (c, ctx) => AlertBanner.fromConfig(c.props, ctx));

    // 06 — Actions
    r.register(
        'ActionButton', (c, ctx) => ScalarioFAB.fromConfig(c.props, ctx));
    // alias FAB → ActionButton (PRD FAB ↔ DS ActionButton variant=floating)
    r.register('FAB', (c, ctx) => ScalarioFAB.fromConfig(c.props, ctx));

    // 03 — Inputs
    r.register(
        'FormWidget', (c, ctx) => FormSection.fromConfig(c.props, ctx));
    // alias FormSection → FormWidget
    r.register(
        'FormSection', (c, ctx) => FormSection.fromConfig(c.props, ctx));

    // 06 — Lists métier (substitut "ListTile" générique — cf. STORY-005 spec)
    r.register(
        'MouvementItem', (c, ctx) => ScalarioListTile.fromConfig(c.props, ctx));

    // Alias supplémentaire ReceiptPreview → préparation STORY-003 ultérieure.
    // En Sprint 1, pointe sur ScalarioListTile avec props.type='ticket'.
    r.register('TicketPreview',
        (c, ctx) => ScalarioListTile.fromConfig(c.props, ctx));
  }
}
