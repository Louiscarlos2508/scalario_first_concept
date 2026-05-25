# PRD Scalario v14 — SaaS ERP IA-Driven pour PME Africaines

**Version** : 14.0
**Date** : 2026-05-25
**Auteur** : Carlos Simporé (Scalario Labs)
**Source architecture** : `Scalario_Architecture_v14.pdf` (Mai 2026)
**Statut** : draft de refonte — supersede PRD v13

---

## 1. Vision

Scalario est un **moteur de livraison d'ERP sur mesure piloté par l'IA**.

- **Phase 1 (Mois 1-3)** — outil interne : Scalario Labs livre des ERP à des clients réels 10× plus vite qu'une agence classique. Le client reçoit un ERP fonctionnel **en quelques jours, pas en 6 mois**.
- **Phase 2 (Mois 4-6)** — semi self-service : Scalario Forge automatise la config, Labs supervise.
- **Phase 3 (Mois 7-12)** — SaaS complet : le client crée son compte sur `app.scalario.app`, configure via chat IA en 45 min, opère son ERP en self-service.
- **Phase 4 (vision long terme)** — Scalario Network : couche B2B inter-tenants (marketplace sectorielle, transactions natives).

**Positionnement** : "Shopify des ERP pour PME africaines" — tu héberges, le client accède via app universelle + abonnement mensuel.

---

## 2. Les 3 piliers techniques

### Pilier 1 — Backend-Driven UI (BDUI)
Le serveur génère dynamiquement la structure de l'interface selon le rôle, le contexte et les permissions. Flutter reçoit un JSON schema et rend les composants **sans aucun `if` métier dans le code**. Zéro mise à jour App Store pour changer l'UI — modifier la config suffit.

### Pilier 2 — Configuration par IA Conversationnelle
Le client remplit un **Business Profile** à son rythme. L'IA analyse, génère un résumé technique, pose 3 à 7 questions de précision ciblées. Un **Demo Space** multi-rôles permet de tester tous les workflows simultanément avant le go live. Résultat : ERP opérationnel en moins d'une journée, pas en 6 mois.

### Pilier 3 — RBAC + ABAC + Sécurité LLM
Chaque utilisateur a un rôle (RBAC) ET des attributs contextuels (ABAC : département, plafond, horaires). Le LLM ne reçoit **jamais** de données brutes — tout est filtré par ABAC avant d'atteindre le modèle. Row-Level Security PostgreSQL comme dernière ligne de défense.

---

## 3. Architecture — 7 engines + 12 services nommés

Tout est nommé pour parler sans ambiguïté technique. Voir `architecture-v14/README.md` pour la table complète.

```
Scalario Labs (la boite)
└── Scalario (la plateforme + client universel)
    │  Android · iOS · Web · Windows · macOS · Linux
    │
    ├── Scalario Forge      ← Config Agent IA (FastAPI + LangChain + Instructor)
    ├── Scalario Stage      ← Demo Space multi-rôles
    │
    ├── Scalario Flow       ← ActionEngine (orchestrateur des 6 engines)
    │   ├── Scalario Canvas ← ComponentRegistry + variantes + NavigationConfig
    │   ├── Scalario Form   ← FormEngine (saisie + validation + calculs live)
    │   ├── Scalario Calc   ← AlgoEngine (fonctions composables typées Zod/Dart)
    │   ├── Scalario Sense  ← CapabilityRegistry (hardware + Mobile Money)
    │   ├── Scalario Vault  ← DataSourceRegistry (Drift + PostgreSQL + SQL)
    │   └── Scalario Live   ← Realtime Engine (events serveur → app)
    │
    ├── Scalario Mind       ← LLM DeepSeek V4 hébergé sur cluster GPU
    │   ├── Scalario Memory ← Mem0 (mémoire utilisateur cross-sessions)
    │   └── Scalario Search ← RAG hybride (vecteur + BM25 + reranking)
    │
    ├── Scalario Kit        ← Catalogue modules JSON (commandes, stock, factures…)
    │   ├── Scalario Profile← UX Profiles + variantes par métier
    │   └── Scalario Pipe   ← Pipelines ActionEngine configurés par Scalario Forge
    │
    └── Scalario Shield     ← Sécurité RBAC/ABAC/RLS — 5 couches
        ├── Scalario Sync   ← CRDT offline (Phase 2 ; Phase 1 = timestamp+server_wins)
        └── Scalario Watch  ← Observabilité + Langfuse + audit logs
```

---

## 4. Modèle SaaS — ce que tu fais vs ce que le client fait

| Ce que TU fais (Scalario Labs) | Ce que LE CLIENT fait |
|---|---|
| Héberger toute l'infrastructure | Créer son compte sur `app.scalario.app` |
| Publier l'APK universelle sur les stores | Télécharger l'APK (une fois) |
| Maintenir les serveurs | Remplir le Business Profile |
| Gérer le cluster GPU DeepSeek | Inviter ses utilisateurs par email |
| Déployer les mises à jour config | Se connecter → son ERP apparaît |
| Garantir uptime + sécurité | Payer l'abonnement mensuel |

**Pas de DSI, pas de consultant 3-6 mois, pas d'installation serveur côté client.**

---

## 5. Marché cible & pourquoi non adressé

| SAP / Oracle / Odoo | Ton ERP SaaS |
|---|---|
| Conçus pour DSI + grandes entreprises | Conçus pour PME africaines sans DSI |
| Config : consultant + 3-6 mois | Config : IA conversationnelle + 45 min |
| Prix : inaccessible pour PME | Abonnement mensuel accessible |
| Pas offline-first natif | Offline CRDT (Phase 2) — zones sans réseau |
| Pas localisés (XOF, Mobile Money) | Conçu pour marchés africains |
| Installation serveur requise | SaaS — zéro installation côté client |
| UI fixe imposée à tous | BDUI générée par rôle et contexte métier |

**Le marché** : centaines de millions de PME africaines qui gèrent encore avec Excel + cahiers. SAP regarde les multinationales. Odoo regarde les PME avec DSI. Toi tu cibles les PME sans DSI.

---

## 6. Stack technique — décisions clés

### 6.1 NestJS seul, pas Supabase

| Service | Technologie | Rôle |
|---|---|---|
| `nestjs:` | NestJS | API principal — auth, BDUI, modules, workflows, engines |
| `fastapi:` | FastAPI + LangChain | Microservice IA — RAG, streaming, Config Agent |
| `postgresql:` | PostgreSQL + pgvector | Données + RAG vectoriel + RLS + schema-per-tenant |
| `redis:` | Redis | Cache config, sessions, rate limiting LLM |
| `minio:` | MinIO (S3-compatible) | Storage fichiers — PDFs, ordonnances, images |
| `adminer:` | Adminer (dev only) | Dashboard visuel DB — remplace Supabase Studio |

**5 services Docker au lieu de 12+, contrôle total, stack cohérente.**

### 6.2 Stack complète

| Couche | Technologie | Rôle |
|---|---|---|
| App mobile | Flutter + Material 3 + Drift | BDUI renderer + offline-first + capabilities |
| App desktop | Flutter (Windows/macOS/Linux) | Managers, DG — écrans larges |
| App web admin | Flutter Web | Config chat, preview BDUI, back-office |
| Design System | Material 3 + ThemeData custom | Tokens, composants, layouts — natif Flutter |
| Maquettage | Widgetbook | Storybook vivant — composants × états |
| API principal | NestJS | Auth, RBAC/ABAC, tous les engines |
| Realtime | NestJS WebSocket Gateway | Streaming IA, notifications temps réel |
| Microservice IA | FastAPI + LangChain | RAG, Config Agent, streaming LLM |
| Base de données | PostgreSQL + pgvector | Données + RAG vectoriel + RLS |
| Cache | Redis | Sessions, config cache, rate limiting LLM |
| Storage | MinIO (S3-compatible) | PDFs, ordonnances, images — isolé par tenant |
| Mémoire IA | Mem0 | Contexte long terme par utilisateur |
| Parsing docs | Docling (IBM) | PDF, Excel, Word → chunks indexables |
| RAG | LlamaIndex + pgvector | Hybrid search données métier |
| Permissions | CASL + Casbin | ABAC complexe dans NestJS |
| LLM principal | DeepSeek V4-Flash (hébergé) | Sur ton cluster GPU — zéro coût par requête |
| LLM raisonnement | DeepSeek V4-Pro (hébergé) | Config Agent, tâches complexes |
| LLM fallback sensible | Claude API (Sonnet) | Données critiques — paie, finance, santé |
| Cluster GPU | 2-4× RTX 4090 ou A100 | DeepSeek V4 distillé — mutualisé tous tenants |

---

## 7. Catalogues — 3 types

### 7.1 Scalario Kit — modules génériques

6 moteurs codés une fois rendent n'importe quel module :

| Moteur | Rôle | Exemple |
|---|---|---|
| ModuleList | N'importe quelle liste d'entités | Commandes, Stock, Clients, Factures |
| ModuleForm | N'importe quel formulaire | Nouvelle commande, Fiche employé |
| ModuleDetail | N'importe quelle fiche détail | Détail commande, Profil client |
| ModuleReport | N'importe quel rapport/export | CA mensuel, Rapport paie |
| ModuleKanban | N'importe quel workflow en colonnes | Congés, Chantiers, Support |
| ModuleDashboard | KPIs de n'importe quelle source | Dashboard DG, Stats vendeur |

Catalogue standards :
```
catalog/modules/
├── gestion/
│   ├── commandes.json    (ModuleList + workflow approval)
│   ├── stock.json        (ModuleList + alertes seuils)
│   ├── clients.json      (ModuleList + fiche détail)
│   └── fournisseurs.json
├── finance/
│   ├── factures.json     (ModuleList + génération PDF)
│   ├── paiements.json    (ModuleList + réconciliation)
│   └── rapports_fin.json (ModuleDashboard + export)
├── rh/
│   ├── employes.json
│   ├── conges.json       (ModuleKanban + workflow)
│   └── paie.json         (ModuleReport + calculs)
└── operations/
    ├── livraisons.json
    ├── planning.json
    └── chantiers.json
```

Le tenant **hérite** d'un module standard, l'IA génère un **override** depuis la conversation. Zéro code par client.

### 7.2 Scalario Profile — UX par métier

```
catalog/ux_profiles/
├── pharmacie/
│   ├── layout_rules.json    ← règles spécifiques pharma
│   ├── screen_templates.json ← écrans types (caisse, stock)
│   └── ux_patterns.json     ← workflows validés
├── btp/
├── cabinet_medical/
├── commerce_general/
└── _base/                   ← règles communes à tous
```

L'IA ne crée pas de patterns UX. Elle **choisit** parmi des profiles validés par secteur. Cohérence métier garantie.

### 7.3 Scalario Pipe — pipelines ActionEngine

Les pipelines configurés par Scalario Forge depuis la conversation. Exemple :

```json
{
  "action": "reception_livraison",
  "trigger": "bouton_reception",
  "steps": [
    { "id": "scan", "registry": "capability", "fn": "scanner", "output": "qr" },
    { "id": "commande", "registry": "datasource", "source": "commandes", "where": { "qr_code": "$qr.raw" }, "output": "cmd" },
    { "id": "photo", "registry": "capability", "fn": "camera", "output": "photo" },
    { "id": "signature", "registry": "capability", "fn": "signature", "output": "sig" },
    { "id": "save", "registry": "datasource", "action": "update", "source": "livraisons", "data": { "...": "..." } },
    { "id": "alerte", "registry": "component", "fn": "AlertBanner", "props": { "...": "..." } },
    { "id": "print", "registry": "capability", "fn": "imprimante", "inputs": { "template": "bon_livraison" }, "on_error": { "hardware_unavailable": "skip" } }
  ]
}
```

---

## 8. Variantes de composants — système clé v14

### 8.1 Principe — 1 type, N variantes

Sans variantes : `KPICard`, `KPICardCompact`, `KPICardWithIcon`, `KPICardHero` → le catalogue explose.

Avec variantes : `KPICard` + `variant: 'compact'` → le registre reste propre, 1 entrée par composant.

`variant: 'auto'` → Flutter choisit selon la taille d'écran, le nombre d'éléments, le rôle de l'utilisateur.

L'IA choisit parmi les **variantes autorisées** dans Scalario Profile — elle n'en invente pas.

### 8.2 Catalogue composants × variantes (v14 §8.2)

| Composant | Variantes | `variant: auto` choisit selon |
|---|---|---|
| KPICard | default · compact · with-icon · hero · with-chart | Taille écran + nb KPIs + rôle |
| DataTable | default · compact · card-list · timeline | Mobile → card-list, desktop → default |
| ListTile | default · with-avatar · with-badge · dense | Densité données + type entité |
| AlertBanner | info · success · warning · danger · dismissible | Statut de la donnée source |
| ChartBar | default · stacked · horizontal · mini | Espace disponible + nb séries |
| ChartPie | default · donut · mini-legend | Nb catégories + espace |
| Button | primary · secondary · ghost · danger · icon-only | Contexte action + espace |
| FAB | default · extended · mini | Mobile → mini, desktop → extended |
| FormField | text · number · date · select · search · scan | Type de donnée déclaré |
| StatCard | default · trend-up · trend-down · flat | Variation vs période précédente |
| SyncStatusBar | syncing · synced · conflict · offline | Widget permanent — état Scalario Sync |
| DocumentPreview | inline · card · fullscreen · thumbnail | Preview PDF/facture avant impression |

---

## 9. Onboarding client — Business Profile + Anti-procrastination

### 9.1 Flux complet — du Business Profile au Go Live

```
Jour 1 (30 min, à son rythme)
  → Client remplit le Business Profile
  → Sauvegarde auto, peut revenir le lendemain

Jour 1 (2 min après envoi)
  → L'IA analyse + génère résumé technique
  → 3 à 7 questions de précision (choix multiples)
  → Config générée + validée (Instructor + Dry Run)

Jour 1 (1-2 heures — Demo Space)
  → Données fictives réalistes générées
  → Mode Réalisateur — tous rôles visibles
  → Scénarios guidés par l'IA
  → Ajustements via chat intégré

Jour 2-7 (optionnel — affinage)
  → Teams internes testent le Demo Space
  → Mode Formation pour les futurs utilisateurs

Jour 7 — Go Live
  → Import données existantes (Excel/CSV)
  → Config validée → déployée
  → Rollback possible 30 jours
```

### 9.2 Anti-procrastination — 3 règles

- Jamais plus de 7 questions de précision — jamais de texte libre dans les questions de précision.
- Toujours des choix multiples — le client clique, il ne rédige pas.
- Si une info peut être corrigée facilement après → ne pas la demander maintenant.

Objectif : configuration en moins de 3 minutes (après le Business Profile).

### 9.3 Anti-hallucination — 6 couches de protection

| Couche | Mécanisme | Ce qu'elle détecte |
|---|---|---|
| 1 — Structure | Instructor + Zod | Fonctions inexistantes, JSON invalide — rejeté au déploiement |
| 2 — Logique | ConfigValidator NestJS | Types incohérents, refs manquantes, cycles DAG |
| 3 — Exécution | Dry Run données fictives | Bugs runtime avant production |
| 4 — Métier | Résumé langage naturel | Mauvaise compréhension — le client valide en français |
| 5 — Test réel | Demo Space sandbox | Le client teste lui-même avec données réalistes |
| 6 — Filet | Rollback 30 jours | Tout bug passé en production — retour en 1 clic |

---

## 10. Demo Space — Test multi-rôles simultané

Avant le go live, le client entre dans un espace sandbox avec des données fictives réalistes et peut voir tous les rôles simultanément — le **mode Réalisateur**.

### 10.1 Les 3 modes

| Mode | Description |
|---|---|
| 🎮 Joueur | Le client joue UN rôle. Les autres sont simulés par l'IA automatiquement. |
| 🎬 Réalisateur | Tous les rôles visibles simultanément. Interactions possibles avec chacun. |
| 🎓 Formation | Guidé étape par étape. Idéal pour former les futurs utilisateurs. |

### 10.2 Ajustements en temps réel

```
Client dans le Demo Space :
  "Le seuil de validation devrait être 200k, pas 500k"
→ L'IA modifie la config en temps réel
→ Le scénario se rejoue avec la nouvelle règle
→ Le client voit la différence immédiatement
→ L'ajustement est sauvegardé dans la config finale
```

Chaque correction est mémorisée. La config finale intègre tous les ajustements du Demo Space.

---

## 11. Sécurité — 5 couches (Scalario Shield)

```
Requête utilisateur
  ↓ Layer 1 : JWT Guard (NestJS) — authentification
  ↓ Layer 2 : RBAC Guard — le rôle a-t-il accès à cette route ?
  ↓ Layer 3 : ABAC CASL — les attributs autorisent-ils cet objet ?
  ↓ Layer 4 : pgvector filter — RAG filtrée par dept/rôle (AVANT le LLM)
  ↓ Layer 5 : PostgreSQL RLS — sécurité au niveau base de données
  → Données retournées (déjà filtrées — le LLM ne voit jamais de données brutes)
```

**Règle critique** : le LLM ne décide jamais des permissions.

- ❌ FAUX : envoyer toutes les données au LLM et dire "montre seulement ce que l'user peut voir".
- ✅ CORRECT : filtrer les données AVANT d'appeler le LLM — le modèle reçoit uniquement les données autorisées.

Le LLM est un moteur de traitement, pas un garde de sécurité.

---

## 12. Algorithmes différenciants (v14 §22)

Ce qui prend des années à construire — et encore plus à maîtriser :

| Algorithme | Niveau | Application dans l'ERP |
|---|---|---|
| DAG + Topological Sort | Intermédiaire-Avancé | Validation workflows générés par l'IA |
| CRDT (Vector Clocks) | Avancé | Sync offline sans conflit ni perte (Phase 2) |
| Rete Algorithm | Avancé | ABAC O(1) pour milliers d'utilisateurs (Phase 3) |
| FSM (XState) | Intermédiaire | États ERP — transitions illégales impossibles |
| Hybrid RAG + Cross-Encoder Reranking | Avancé | +30-40% pertinence vs RAG basique |
| Reciprocal Rank Fusion | Intermédiaire | Fusion vecteur + BM25 pour RAG hybride |
| Property-based testing | Intermédiaire | Tests AlgoEngine (fast_check, glados) |

La plupart des ERP IA s'arrêtent au RAG basique. Scalario fait ces 7 algorithmes — c'est l'avantage technique défendable.

---

## 13. Feuille de route — 3 phases produit

### Phase 1 — Fondations Scalario (Mois 1-3)

**Objectif** : livrer les premiers ERP à des clients réels. Scalario Labs opère Scalario Forge manuellement.

- JSON Schema BDUI avec `variant` — contrat TypeScript/Dart validé (Scalario Canvas)
- NestJS : auth JWT, RBAC Guards, structure multi-tenant + **@nestjs/swagger** (Scalario Shield)
- Flutter : Scalario Canvas + variantes + SyncStatusBar + NavigationConfig + Widgetbook
- **i18n** : ARB files FR/EN + lint `no_hardcoded_strings` dès le premier commit
- PostgreSQL : schema-per-tenant, RLS, pgvector, tenant_configs (Scalario Vault)
- Redis : sessions, cache config
- CASL : ABAC basique — Scalario Shield opérationnel
- Scalario Calc : ~30 fonctions atomiques, typage Zod strict
- DAG : validation des workflows — Scalario Flow de base
- Scalario Live : WebSocket in-app + FCM/APN enregistrement
- Login flow : Scalario → login → config chargée → UI rendue selon rôle

### Phase 2 — Engines & IA (Mois 4-6)

**Objectif** : automatiser la config avec Scalario Forge. Premiers clients configurés en self-service supervisé.

- Scalario Form : validation, calculs temps réel, capabilities dans champs
- Scalario Sense : scanner, camera, signature, imprimante, GPS
- Mobile Money : Wave + Orange Money + MTN MoMo + webhooks NestJS (Scalario Sense)
- Scalario Live : FCM/APN push réel + ConflictReviewScreen + SyncStatusBar actif
- **Scalario Sync** : CRDT Vector Clocks — résolution auto + ConflictReviewScreen
- Scalario Flow complet : pipelines JSON, variables, on_error strategies
- Scalario Vault niveau 3 : catalogue SQL par métier
- Scalario Mind : DeepSeek V4 hébergé, RAG hybride, SSE, Mem0, Docling
- **Scalario Forge** : Business Profile → Instructor → ERPConfig automatique
- **Scalario Stage** : sandbox multi-rôles, données fictives, ajustements live
- i18n Phase 2 : ARB Bambara, Wolof, Dioula — langues africaines

### Phase 3 — Robustesse & Scale (Mois 7-12)

**Objectif** : moteur stable, scalable, prêt pour Phase 2 business (semi self-service).

- Scalario Shield : Rete Algorithm — règles ABAC O(1) pour milliers d'utilisateurs
- FSM XState : états ERP générés automatiquement par Scalario Forge
- Scalario Watch : Langfuse + anti-hallucination 6 couches opérationnelles
- Scalario Mind : upgrade cluster GPU DeepSeek V4 selon volume clients
- Performance : memoization Scalario Calc, vues matérialisées PostgreSQL
- i18n Phase 3 : Haoussa, Arabe — extension Maghreb + Sahel
- Multi-région : réplication DB pour clients dans plusieurs pays africains
- **Swagger public** : documentation API pour intégrateurs Phase 3
- Préparation Phase 2 business : portail client, billing Mobile Money, self-service partiel

### Phase 4 — Scalario Network (vision long terme)

**Objectif** : transformer Scalario d'un outil de gestion interne en un réseau d'échanges B2B natif entre entreprises.

- Scalario Network : identité publique + catalogue réseau + découverte de partenaires
- Scalario Trade : moteur de transaction cross-tenant (commandes, devis, factures B2B)
- Scalario Market : marketplace sectorielle par verticale (pharma, BTP, restauration…)
- API inter-tenant avec permissions granulaires
- KYC entreprises + notation + historique + contrats numériques
- Mobile Money cross-tenant — règlement automatique entre 2 entreprises

**Décisions prises maintenant pour ne pas devoir tout reconstruire en Phase 4** :
- `tenant_handle` : identité unique sur le réseau — à ajouter dès Phase 1
- `schema-per-tenant` : isolation parfaite — données cross-tenant passent par une API dédiée
- Scalario Shield : RBAC/ABAC s'étend naturellement aux permissions inter-tenant
- Mobile Money dans Scalario Sense : déjà là — le règlement cross-tenant s'appuie dessus
- Scalario Live : les events cross-tenant (commande reçue d'un autre tenant) passent par le même mécanisme

---

## 14. Différentiation finale

| SAP / Odoo / ERP classique | Ton ERP SaaS IA-Driven |
|---|---|
| Conçu pour grandes entreprises avec DSI | Conçu pour PME africaines sans DSI |
| Config : consultant + 3-6 mois | Config : Business Profile + IA + 45 min |
| Installation serveur côté client | SaaS — tu héberges, le client accède |
| APK différente par client ou absente | 1 Scalario universel — login → UI générée |
| UI fixe imposée à tous | BDUI — UI selon tenant + rôle + contexte + variantes |
| RBAC simple | RBAC + ABAC + RLS — 5 couches |
| Offline basique ou inexistant | Offline CRDT — sync intelligente par diff (Phase 2) |
| RAG absent ou basique | Hybrid RAG + DeepSeek V4 hébergé |
| Modules codés en dur | 7 engines + JSON — zéro code par client |
| Prix inaccessible pour PME | Abonnement mensuel accessible |
| Pas localisé pour l'Afrique | XOF, Mobile Money, langues africaines, zones sans réseau |
| Chaque entreprise isolée | Scalario Network — B2B natif entre tenants en Phase 4 |

---

## 15. Principes directeurs

1. Scalario Labs livre d'abord. Scalario scale ensuite. Scalario Network connecte enfin.
2. Scalario Forge configure en 45 min ce qui prenait 6 mois.
3. 7 engines communicants — Canvas, Form, Calc, Sense, Vault, Live orchestrés par Flow.
4. Scalario Live est le seul engine déclenché par le serveur — notifications, refresh, badges en temps réel.
5. Scalario Mind (DeepSeek V4 hébergé) + Scalario Shield (RBAC/ABAC/RLS) = moteur sécurisé.
6. 1 Scalario universel. Login → config chargée → UI générée selon rôle.
7. Phase 4 : Scalario Network transforme chaque tenant en nœud d'un réseau B2B africain natif.

C'est l'intégration cohérente de tout ça qui est défendable — pas une technologie seule.
