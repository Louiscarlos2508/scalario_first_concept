# Scalario Client — Flutter BDUI Runtime Engine

Ce dossier contient le client **Flutter (Web & Desktop)** de Scalario, un moteur de rendu d'interface utilisateur piloté par le backend (Backend-Driven UI ou BDUI).

---

## Architecture du Code source (`lib/`)

```
lib/
├── app/                      # Applications & Écrans de base (Login, Home)
├── assets/                   # Assets (JSON BDUI schemas, Images, Icons)
├── components/               # Librairie de composants & primitives visuelles
│   ├── actions/              # Boutons, FAB, boutons à chargement dynamique
│   ├── data_display/         # KPICard, ChartBar, RankingList, ScalarioDataTable
│   ├── views/                # Macro-composants UX (ScaDataGrid, ScaKanbanBoard, ScaFilterBuilder...)
│   └── _internal/            # Wrappers internes de focus et états système
├── core/                     # Logic de bas niveau (Authentification, websocket, Live client)
└── engine/                   # Moteur BDUI principal
    ├── canvas_layout/        # Layout sémantique (SlotLayout, ScaPageBody, ScaPageHeader, ScaRightDrawer)
    ├── canvas_registry/      # Registre de composants (ScalarioCanvasRegistry)
    └── actions/              # Moteur d'actions séquentielles (ScalarioActionEngine)
```

---

## 1. Moteur de Layout Premium (`canvas_layout`)

Inspiré par le design de **Twenty CRM**, le layout de Scalario est strict et centré sur l'utilisateur :
- **`SlotLayout`** : Aligne automatiquement les composants selon leurs zones (`kpis`, `main`, `aside`, `actions`). Gère le rendu responsive horizontal (Row/Wrap) sur desktop et vertical sur mobile.
- **`ScaPageBody`** : Contraint la zone principale à `1200px` max-width et la centre élégamment sur les écrans larges pour éviter tout étirement disgracieux.
- **`ScaRightDrawer`** : Tiroir latéral contextuel pour l'édition d'enregistrements en ligne.

---

## 2. Librairie de Composants & Atomes Visuels

Tous les composants respectent la palette de design Slate/Zinc moderne et sémantique :
- **`KPICard`** : Cartes à indicateurs clés avec bordures fines, ombres douces (`ScalarioElevation.e1`) et états dynamiques.
- **`ChartBar`** : Graphiques à barres encapsulés dans un conteneur de carte stylisé premium.
- **`RankingList`** : Liste ordonnée de classements avec badges de rang et alignement des valeurs.
- **`ScaAvatar` & `ScaChip`** : Atomes stylisés pour le rendu de statuts, priorités et portraits d'utilisateurs.
- **`ScaTypography`** : Échelle typographique sémantique (`h1`, `h2`, `body`, `caption`).

---

## 3. Macro-Composants UX (`components/views`)

- **`ScaDataGrid`** : Tableau de données hyper-dynamique supportant l'édition rapide en ligne, le tri, et les actions groupées (Bulk).
- **`ScaKanbanBoard`** : Tableau Kanban générique piloté par le backend pour le drag-and-drop de cartes et de pipelines métiers.
- **`ScaRecordSplitView`** : Vue divisée universelle avec détails de l'objet à gauche et fil d'activité/timeline à droite.
- **`ScaFilterBuilder`** : Générateur de filtres avancés générant des requêtes structurées pour le backend.

---

## 4. Moteur d'Actions (`ScalarioActionEngine`)

Gère l'exécution séquentielle d'actions et la résolution de promesses réseau côté client :
- **`api_call`** : Requête backend sécurisée.
- **`navigate`** : Navigation dynamique inter-écrans.
- **Indicateurs de chargement** : Les boutons (`ScalarioButton`) affichent automatiquement un état `loading` (loader circulaire) durant l'attente du retour d'une action réseau.

---

## Commandes Utiles

### Lancer en mode Sandbox (Développement hors ligne)
Le mode Sandbox utilise des fixtures JSON locales pour tester les maquettes visuelles et les rôles utilisateurs sans connexion API.
```bash
flutter run -d chrome --dart-define=APP_MODE=sandbox
```

### Lancer en mode Application (Connecté au backend NestJS)
```bash
flutter run -d chrome --dart-define=APP_MODE=app --web-port 8090
```

### Lancer les Tests d'analyse
```bash
flutter analyze
```
