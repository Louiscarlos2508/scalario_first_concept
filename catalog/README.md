# `catalog/` — Catalogue Scalario v2 (BDUI)

**Mis à jour: 2026-06-02.** Le catalogue est le produit de Scalario — JSON config
pour les écrans, modules, navigation, dialogs et sheets, rendus côté Flutter via
le moteur BDUI v2.

## Structure

```
catalog/
├── README.md
├── CONTRIBUTING.md                    ← Contribution guidelines
├── schemas/                           ← Schémas JSON (contrat BDUI v2.0.0)
│   ├── screen-config.schema.json      ← Contrat strict ($ref, LayoutConfig, zones dynamiques)
│   ├── component-config.schema.json   ← Typed actions (12 types), slots, strict props
│   └── module-config.schema.json      ← Module contract v2.0.0
├── ux_profiles/                       ← UX profiles sectoriels (variants autorisés)
│   └── _base/
│       └── components.json
└── tenants/                           ← 1 dossier par tenant
    └── blandine/                      ← Tenant actif unique (Blandine Boutique)
        ├── module.json                ← Manifest tenant (modules, screens, RBAC, currency…)
        ├── navigation.json            ← Structure navigation (sidebar, top actions, responsive)
        ├── modules/                   ← Modules métier du tenant
        │   ├── ventes/module.json
        │   ├── stock/module.json
        │   ├── caisse/module.json
        │   ├── commandes/module.json
        │   ├── pertes/module.json
        │   ├── rapports/module.json
        │   ├── equipe/module.json
        │   ├── alertes/module.json
        │   └── configuration/module.json
        ├── screens/                   ← 17 écrans (format BDUI v2)
        ├── dialogs/                   ← 6 modaux (issus des scénarios UX)
        └── sheets/                    ← 4 panneaux latéraux
```

## Conventions

- **Fichiers JSON** : `snake_case`
- **Tenant** : dossier `tenants/<slug>/` avec `module.json` comme point d'entrée
- **Modules** : dossier `tenants/<slug>/modules/<id>/module.json`
- **Écrans** : **un dossier par écran** (pas de fichier JSON plat)
- **`$ref`** : tout sous-élément peut être externalisé via `{"$ref": "path.json"}`
- **Slots** : le layout définit l'ordre et le comportement des zones (`top`, `main`, `bottom`, `sidebar`)
- **RBAC** : chaque écran liste les rôles autorisés (`roles: ["OWNER", "MANAGER"]`)
- **Schémas** : validation stricte (`contrat` mode, pas `advisory`)
- **Navigation** : fichier `navigation.json` distinct du manifest tenant
- **Dialogs/Sheets** : même principe $ref que les écrans, dans des dossiers dédiés

## Navigation

`navigation.json` définit la structure complète de la navigation :

```
tenants/blandine/navigation.json
├── sidebar.groups[]          ← 9 groupes avec icônes, labels, écrans par rôle
│   ├── module                ← ID du module
│   ├── label                 ← Libellé affiché
│   ├── icon                  ← Icône Material
│   ├── screens[]             ← Écrans du groupe avec roles[]
│   └── badge                 ← Badge optionnel (endpoint API)
├── top_actions[]             ← Actions globales (search, sync, profil)
└── responsive                ← Breakpoint desktop, sidebar width, type mobile
```

## Structure d'un écran (BDUI v2)

```
screens/<screen_id>/
├── screen.json              ← Manifest (layout, zones, rules, states… tous en $ref)
├── appbar.json              ← AppBar : titre, back, actions (search, filtre, export…)
├── layout/layout.json       ← Définition des slots (positions, sticky, scroll, breakpoints)
├── rules/rules.json         ← Règles de visibilité (RBAC, conditions)
├── zones/                   ← Contenu des zones (1 fichier par zone)
│   ├── kpis.json
│   ├── main.json
│   └── actions.json
├── states/                  ← États alternatifs (loading, empty)
│   ├── loading.json
│   └── empty.json
├── data/sources.json        ← Sources de données / endpoints API
├── capabilities/            ← Capacités spécifiques (barcode, search)
├── components/              ← Composants réutilisables (scope écran)
├── i18n/fr.json             ← Traductions (clés texte)
└── ux/metadata.json         ← Métadonnées UX (layout, spacing, card style)
```

### `screen.json`

```json
{
  "screen": "dashboard_owner",
  "schema_version": "2.0.0",
  "layout": { "$ref": "layout/layout.json" },
  "zones": {
    "kpis":   { "$ref": "zones/kpis.json" },
    "main":   { "$ref": "zones/main.json" },
    "actions": { "$ref": "zones/actions.json" }
  },
  "rules": { "$ref": "rules/rules.json" },
  "states": {
    "loading": { "$ref": "states/loading.json" },
    "empty":   { "$ref": "states/empty.json" }
  },
  "i18n":  { "$ref": "i18n/fr.json" },
  "data":  { "$ref": "data/sources.json" }
}
```

### `layout/layout.json`

Les slots remplacent les layouts rigides (dashboard, list, form, detail). Chaque slot
référence une zone et définit sa position, son comportement de défilement et sa visibilité responsive.

```json
{
  "version": "2.0.0",
  "layout": "dashboard",
  "slots": {
    "kpis":   { "zone": "kpis",   "position": "top" },
    "main":   { "zone": "main",   "position": "main", "scroll": true },
    "actions": { "zone": "actions", "position": "bottom", "sticky": true }
  }
}
```

3 layouts disponibles : `dashboard`, `pos` (sidebar panier + main catalogue), `form`.

### Zones

Chaque fichier `zones/<name>.json` contient un tableau de `ComponentConfig` :

```json
[
  {
    "type": "kpi_card",
    "props": {
      "title": "Chiffre d'affaires",
      "value": "2 450 000 FCFA",
      "trend": "+12%",
      "trend_direction": "up",
      "icon": "trending_up"
    }
  }
]
```

### Typed props (28 types)

Le moteur Flutter résout chaque `type` vers une classe Props typée :

| Type | Props | Widget |
|------|-------|--------|
| `kpi_card` | `KPICardProps` | Carte KPI avec tendance |
| `action_button` | `ActionButtonProps` | Bouton d'action |
| `data_table` | `DataTableProps` | Tableau de données |
| `chart_bar` | `ChartBarProps` | Graphique à barres |
| `form_widget` | `FormWidgetProps` | Champ de formulaire |
| `search_bar` | `SearchBarProps` | Barre de recherche |
| `product_grid` | `ProductGridProps` | Grille produits |
| `cart_summary` | `CartSummaryProps` | Résumé panier |
| `text` | `TextProps` | Texte simple |
| `ranking_list` | `RankingListProps` | Classement |
| … | … | … |

### Typed actions (12 types)

```json
{
  "action": {
    "type": "navigate",
    "screen": "pos_caisse",
    "params": { "mode": "vente" }
  }
}
```

Types : `navigate`, `dialog`, `sheet`, `confirm`, `api_call`, `local`, `toast`,
`show_alert`, `add_to_cart`, `remove_from_cart`, `update_cart_item`.

## Dialogs

Modaux de confirmation, issus des étapes `ConfirmationDialog` des scénarios UX.
Chaque dialog a son propre dossier avec `dialog.json` + `zones/`.

```
dialogs/<dialog_id>/
├── dialog.json              ← Manifest : titre, taille (sm/md/lg), actions, zones ref
└── zones/main.json          ← Contenu du dialog (KPICard, Text, DataTable…)
```

| Dialog | Scénario | Usage |
|--------|----------|-------|
| `validation_closure` | S03.3 | Blandine valide clôture (montant saisi vs système + écart) |
| `confirmation_reception` | S05.3 | Ibrahim valide réception (attendu/reçu/écart par article) |
| `confirmation_perte` | S06.3 | Ibrahim confirme perte (valeur estimée) |
| `confirmation_produit` | S09.3 | Blandine confirme produit (tous paramètres + aperçu POS) |
| `confirmation_credentials` | S10.3 | Credentials employé (username, mdp temporaire, WhatsApp) |
| `confirmation_annulation` | S14.3 | Commercial confirme annulation vente |

## Sheets

Panneaux latéraux/bottom sheets pour la sélection et la saisie contextuelle.

```
sheets/<sheet_id>/
├── sheet.json              ← Manifest : titre, snap points, search config
└── zones/main.json         ← Contenu du sheet
```

| Sheet | Scénario | Usage |
|-------|----------|-------|
| `client_select` | S15.2 | Sélection client pour vente crédit |
| `product_picker` | S02.2 | Sélection articles POS (scan + recherche) |
| `payment_method` | S15.2 | Mode paiement (espèces, Wave, Orange Money, crédit partiel) |
| `period_picker` | S12.1 | Sélection période pour rapports |

## Tenant Manifest

`tenants/blandine/module.json` définit :

- **`modules[]`** : liste des modules activés (id, name, icon)
- **`screens{}`** : dictionnaire des écrans avec module, title, roles, layout, order
- **`rbac_roles[]`** : rôles disponibles (OWNER, MANAGER, COMMERCIAL)
- **`currency`, `locale`, `timezone`** : locale tenant

## Navigation

`GET /api/v1/:tenant/navigation` → lit `tenants/{slug}/navigation.json` et retourne
la structure complète de navigation (sidebar groups, top actions, responsive config)
filtrée par rôle utilisateur.

## Layout

`GET /api/v1/:tenant/layout/:screenId` → `CatalogueLoaderService` assemble l'écran :
1. Lit `screens/{screenId}/screen.json`
2. Résout récursivement tous les `$ref`
3. Retourne le `ScreenConfig` complet (zones, layout, rules, states, data, i18n)

## Validation

- **NestJS bootstrap** : `CatalogueValidatorService` rejette le catalogue invalide
- **Zod schemas** : validation des `module.json` et `screen.json` au démarrage
- **Flutter** : `ScalarioCanvas.registry.build()` valide en mode `strict` à l'exécution
- **RBAC** : `RbacComponentFilter` filtre les zones selon le rôle utilisateur côté serveur

## État actuel

- **Tenant unique** : `blandine` (Boutique, Burkina Faso, XOF)
- **Modules** : 9
- **Écrans** : 17
- **Dialogs** : 6 (validation_closure, confirmation_reception, confirmation_perte, confirmation_produit, confirmation_credentials, confirmation_annulation)
- **Sheets** : 4 (client_select, product_picker, payment_method, period_picker)
- **Auth** : gérée côté Flutter (login native, pas dans le catalogue)
