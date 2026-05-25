# STORY-V14-010 : Widgetbook setup — 12 composants × variantes × états (Light + Dark)

**Epic :** EPIC-V14-002 — Scalario Canvas
**Priorité :** Must Have
**Story Points :** 5
**Status :** defined
**Sprint :** v14-2 (2026-06-09 → 2026-06-22)
**Dépendances :** V14-003 (Dispatch par variante), V14-004 (Catalogue variantes)

---

## User Story

> **En tant que** dev Scalario + futur intégrateur,
> **je veux** un Widgetbook accessible en local (`flutter run -d chrome --target lib/widgetbook.dart`) qui affiche chaque composant × chaque variante × chaque état (Light + Dark) en cas d'usage réaliste,
> **so that** ajouter une variante ou modifier le DS se voit immédiatement, sans devoir lancer un écran ERP complet pour tester.

---

## Description

### Background

PRD v14 §8.6 : "Widgetbook — ton Figma vivant : chaque composant × chaque variante × chaque état". Remplace l'approche v13 `_<feature>_showcase.dart` (STORY-004) qui était valide mais isolée. Widgetbook permet la navigation hiérarchique + add-ons (theme, device, locale, text scale).

### Scope

**In scope :**
- Installation `widgetbook` + `widgetbook_annotation` + `widgetbook_generator`
- `lib/widgetbook.dart` : entry point avec navigation hiérarchique
- 12 composants × ~50 UseCase (default, compact, with-icon, hero, with-chart, error states, loading states, RTL si applicable)
- Add-ons : theme (Light/Dark), device (mobile/tablet/desktop), locale (fr-BF, en-US), text scale (0.85, 1.0, 1.3)
- Golden tests : ≥ 1 golden par variante × theme (Light + Dark)
- README `docs/widgetbook.md` expliquant comment ajouter une UseCase

**Out of scope :**
- Widgetbook hosted (web public) — Phase 3 (V14-036)
- Code Connect Figma → Widgetbook — Phase 2+

---

## Acceptance Criteria

### Setup

- [ ] **AC-01** — `pubspec.yaml` ajoute `widgetbook: ^3.x` + `widgetbook_annotation` + `widgetbook_generator` (dev_dependencies).
- [ ] **AC-02** — `lib/widgetbook.dart` configuré avec `Widgetbook.material()` + add-ons (MaterialThemeAddon, DeviceFrameAddon, LocalizationAddon, TextScaleAddon).
- [ ] **AC-03** — Lancement `flutter run -d chrome --target lib/widgetbook.dart` → UI Widgetbook accessible.

### UseCase par composant (12 composants)

- [ ] **AC-04** — `KPICard` : default normal, default warning, compact mobile 4-KPIs, with-icon danger, hero desktop, with-chart, auto (3 sub-scenarios).
- [ ] **AC-05** — `DataTable` : default (5 colonnes), compact (haute densité), card-list (mobile), timeline (Phase 2 placeholder).
- [ ] **AC-06** — `ListTile` : default, with-avatar, with-badge, dense.
- [ ] **AC-07** — `AlertBanner` : info, success, warning, danger, dismissible.
- [ ] **AC-08** — `ChartBar` : default, stacked, horizontal, mini.
- [ ] **AC-09** — `ChartPie` : default, donut, mini-legend.
- [ ] **AC-10** — `Button` : primary, secondary, ghost, danger, icon-only.
- [ ] **AC-11** — `FAB` : default, extended, mini.
- [ ] **AC-12** — `FormField` : text, number, date, select, search, scan.
- [ ] **AC-13** — `StatCard` : default, trend-up, trend-down, flat.
- [ ] **AC-14** — `SyncStatusBar` : syncing, synced, conflict, offline.
- [ ] **AC-15** — `DocumentPreview` : inline, card, fullscreen, thumbnail.

### Golden tests

- [ ] **AC-16** — `test/widgetbook/<component>_golden_test.dart` pour chaque composant.
- [ ] **AC-17** — ≥ 2 goldens par composant (Light + Dark) → ~24 goldens minimum.
- [ ] **AC-18** — `flutter test --update-goldens` génère les PNG dans `test/goldens/`.

### Docs

- [ ] **AC-19** — `docs/widgetbook.md` : comment ajouter une UseCase, comment regénérer goldens, comment exporter une variante en preview.

---

## Technical Notes

### Structure `lib/widgetbook.dart`

```dart
@App()
class WidgetbookApp {}

void main() {
  runApp(const HotReload());
}

@app.App()
class HotReload extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      directories: [
        WidgetbookCategory(
          name: 'Feedback',
          children: [
            WidgetbookComponent(
              name: 'KPICard',
              useCases: [
                WidgetbookUseCase(
                  name: 'Default — normal',
                  builder: (_) => KPICard(variant: 'default', value: '142', label: 'Commandes'),
                ),
                WidgetbookUseCase(
                  name: 'Compact — mobile 4 KPIs',
                  builder: (_) => KPICard(variant: 'compact', value: '142', label: 'Ventes'),
                ),
                // ... 5 autres UseCase
              ],
            ),
            // ... 11 autres composants
          ],
        ),
      ],
      addons: [
        MaterialThemeAddon(themes: [
          WidgetbookTheme(name: 'Light', data: ScalarioTheme.light),
          WidgetbookTheme(name: 'Dark', data: ScalarioTheme.dark),
        ]),
        DeviceFrameAddon(devices: [Devices.android.samsungGalaxyS20, Devices.ios.iPad, ...]),
        LocalizationAddon(locales: [Locale('fr','BF'), Locale('en','US')]),
        TextScaleAddon(scales: [0.85, 1.0, 1.3]),
      ],
    );
  }
}
```

### Edge cases

- Composants qui dépendent de Riverpod state (`SyncStatusBar` → `ScalarioSyncProvider`) → wrapper `ProviderScope(overrides: [...])` dans la UseCase
- Composants qui dépendent de `MediaQuery` (`KPICard variant: 'auto'`) → utiliser `DeviceFrameAddon` pour simuler taille
- Locale `ar` (RTL) → ajouté comme add-on même si ARB Arabe Phase 3 (V14-034) — la mécanique RTL doit marcher dès Phase 1

---

## Dependencies

- **Prérequis :** V14-003 (dispatch par variante — chaque composant a ses sous-types), V14-004 (catalogue variantes — savoir lesquelles documenter)
- **Stories bloquées :** V14-019 (Scalario Forge utilise Widgetbook pour preview), V14-036 (Widgetbook public Phase 3)

---

## Definition of Done

- [ ] Widgetbook lancable en local
- [ ] 12 composants documentés avec ~50 UseCase
- [ ] ≥ 24 goldens (12 composants × 2 themes)
- [ ] `docs/widgetbook.md` rédigé
- [ ] sprint-status.yaml V14-010 = completed

---

## Story Points Breakdown

| Tâche | Points |
|---|---|
| Setup widgetbook + add-ons | 1.0 |
| 12 composants × ~4-5 UseCase = 50 UseCase | 2.0 |
| Golden tests (24+ goldens) | 1.0 |
| Docs `widgetbook.md` | 0.5 |
| Tests + revue | 0.5 |
| **Total** | **5** |

---

## Progress Tracking

- 2026-05-25 : Created (Carlos via `/bmad:create-story`)

**Actual Effort :** TBD
