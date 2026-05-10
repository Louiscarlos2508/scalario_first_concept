# Scalario — Showcases Guide

Outils dev pour visualiser les composants DS sans démarrer l'app complète.
Pattern : **Santera** (projet `recherchelivraisonmedicament`).

---

## Lancer une preview IDE

```bash
# Dans le dossier apps/flutter :
flutter widget-preview start
# Puis ouvrir un fichier _<feature>_showcase.dart dans VSCode/Cursor.
# L'IDE affiche les variantes côte à côte et recharge à chaque sauvegarde.
```

## Lancer un showcase standalone

```bash
flutter run --target=lib/components/data_display/_kpi_card_showcase.dart -d chrome
flutter run --target=lib/components/data_display/_data_table_showcase.dart -d <device>
flutter run --target=lib/components/data_display/_chart_bar_showcase.dart -d <device>
flutter run --target=lib/components/feedback/_alert_banner_showcase.dart -d <device>
flutter run --target=lib/components/actions/_scalario_fab_showcase.dart -d <device>
flutter run --target=lib/components/lists/_scalario_list_tile_showcase.dart -d <device>
flutter run --target=lib/components/inputs/_form_section_showcase.dart -d <device>

# Compositions
flutter run --target=lib/showcases/_dashboard_owner_showcase.dart -d <device>
flutter run --target=lib/showcases/_pos_commercial_showcase.dart -d <device>
```

L'AppBar de chaque standalone contient un **toggle dark/light** (icône soleil/lune).

---

## Convention de nommage

| Élément | Convention | Exemple |
|---|---|---|
| Fichier showcase composant | `lib/components/<group>/_<name>_showcase.dart` | `_kpi_card_showcase.dart` |
| Fichier showcase composition | `lib/showcases/_<name>_showcase.dart` | `_dashboard_owner_showcase.dart` |
| Fonction thème | `scalario<X>Themes()` | `scalarioKPICardThemes()` |
| Fonction wrapper | `scalario<X>Wrap(child)` | `scalarioKPICardWrap` |

Le préfixe `_` est une **convention** dev-only — les showcases ne sont pas
ré-exportés dans le barrel `components.dart`. Ne jamais les importer depuis
le code app prod.

---

## Données mockées

Toutes les données dans les showcases sont **fictives** : noms génériques
(`Boutique Kouamé`, `Tenant Démo`, `Acme SARL`). Jamais de vraies données
Blandine ou d'un tenant beta.

---

## Widgetbook (Sprint 2+)

Le dossier `widgetbook/` contient un stub minimal. La galerie complète avec
knobs, viewport, et snapshot tests visuels sera ajoutée en Sprint 2.
