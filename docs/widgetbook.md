# Scalario Widgetbook

**Story**: STORY-V14-010
**Acces**: `flutter run -d chrome --target lib/widgetbook.dart`

## Quickstart

```bash
cd apps/flutter
flutter pub get
flutter run -d chrome --target lib/widgetbook.dart
```

## Structure

- `lib/widgetbook.dart` — Entry point Widgetbook avec navigation hierarchique
- 5 dossiers : Data Display, Feedback, Actions, Inputs, Lists
- 12 composants documentes avec ~40 UseCase
- Add-ons : Light/Dark theme, TextScale (0.85x → 1.3x)

## Ajouter un UseCase

1. Ouvrir `lib/widgetbook.dart`
2. Trouver le composant dans la section appropriee
3. Ajouter un `WidgetbookUseCase` dans la liste `useCases` :

```dart
WidgetbookUseCase(
  name: 'Nouvelle variante',
  builder: (ctx) => MonComposant(variant: 'nouvelle'),
),
```

## Golden tests

```bash
flutter test --update-goldens test/widgetbook/golden_test.dart
```

Les goldens sont generes dans `test/goldens/`.

## Composants documentes

| Composant | Variantes |
|---|---|
| KPICard | default, warning, critical, loading, empty, error |
| DataTable | default (3 colonnes) |
| ChartBar | default (5 points) |
| ChartPie | default, donut, mini-legend |
| StatCard | default, trend-up, trend-down, flat |
| DocumentPreview | inline, card, thumbnail |
| AlertBanner | info, success, warning, critical |
| SyncStatusBar | synced, syncing, conflict, offline |
| Button | primary, secondary, ghost, danger, icon-only |
| FAB | default, mini, extended |
| FormField | FormSection demo |
| ListTile | default, with-avatar, with-badge, dense |
