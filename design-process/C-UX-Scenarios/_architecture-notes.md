---
project: scalario
created: 2026-05-09
type: architecture-clarification
---

# Architecture Notes — UX Scenarios

> Décisions clarifiées pendant la Phase 3 — applicables à tous les scénarios

---

## Identité & Authentification

**Login = username (ou numéro téléphone) + mot de passe — unique par user.**

Aucun user ne partage le même identifiant. Après auth réussie, le système charge un **profil complet** depuis le backend :

| Donnée | Source | Usage |
|--------|--------|-------|
| Tenant (entreprise) | Config Kofi | Isolation multi-tenant (RLS PostgreSQL) |
| Département | Config Kofi (si applicable) | Filtrage modules et données |
| Rôle | Config Kofi | Dashboard JSON + permissions |
| Permissions d'accès | Config Kofi | Actions autorisées par module |
| Dashboard layout JSON | Config tenant | BDUI Engine — rendu immédiat |

Ce profil est mis en cache Drift → disponible offline après le premier login.

**KYC / Vérification :**
- **Niveau tenant** : vérification entreprise lors du onboarding par Kofi (intégrateur certifié)
- **Niveau user** : identité vérifiée à la création du compte par Kofi — pas à chaque login
- Le login quotidien = authentification uniquement, pas de re-vérification

**Re-auth rapide (sessions suivantes) :**
Après le premier login complet (username + mot de passe), les ouvertures suivantes utilisent un unlock rapide :
- PIN app (4-6 chiffres)
- Empreinte digitale (fingerprint)
- Face ID
Disponibilité selon l'appareil + configuration tenant (Kofi peut activer/désactiver par JSON). Le user ne re-saisit pas ses credentials complets à chaque ouverture.

**Multi-device :**
Un même user peut être connecté simultanément sur mobile (Android) ET ordinateur (Flutter Web PWA). Profil identique sur les deux. Données synchronisées via backend. Le BDUI Engine adapte le layout au facteur de forme — même composants, rendu différent selon l'écran.

**Conséquence UX :**
L'app ne demande jamais "qui es-tu ?" ou "quel est ton département ?" — elle le sait. Le BDUI Engine rend le bon dashboard avec les bonnes actions pour ce user spécifique, dès le premier frame après unlock. Blandine qui ouvre l'app le matin → fingerprint → dashboard immédiat.

---

## POS — Deux niveaux de configuration

### Niveau 1 — `pos_layout` (paramètre business/template)

Définit **quel type d'interface POS** est utilisé pour tout le tenant. Configuré dans le JSON template au niveau tenant.

| pos_layout | Interface | Usage type |
|------------|-----------|------------|
| `grid` | Grille de cartes produits — tap pour ajouter | Marché frais, épicerie (Blandine) |
| `list` | Liste avec recherche par nom ou référence | Quincaillerie, grande référence |
| `scanner` | Saisie code-barres + liste | Supermarché, dépôt |
| `menu` | Catégories → sous-catégories → article | Restaurant, snack |

**Gate 0 :** `retail_fresh_produce.json` utilise `pos_layout: grid` — grille de cartes 2 colonnes mobile, 3 colonnes web.

### Niveau 2 — `input_type` (paramètre par produit)

Définit **comment la quantité est saisie** pour chaque produit dans le POS. Configuré dans le catalogue produit.

| input_type | Saisie | Calcul |
|------------|--------|--------|
| `vrac` | Poids en kg (bottom sheet) — décimal | Poids × prix/kg |
| `unit` | Compteur entier +/− inline sur la carte | Quantité × prix unitaire |
| `service` | Ajout direct (forfait fixe, pas de quantité) | Prix forfait |
| `mixed` | Articles + modifiers (ex: taille + quantité) | Somme composants |

Un même tenant peut avoir des produits avec `input_type` différents : tomates = `vrac`, sachets = `unit`, livraison = `service`.

**Note :** Dans les scénarios précédents, ce champ était nommé `pos_type`. Le nom correct est `input_type` au niveau produit, `pos_layout` au niveau business.

### Paramètres produit spécifiques au template `retail_fresh_produce.json`

- `fraicheur_jours` — durée de vie en jours (0 = illimité)
- `taux_perte_pct` — % de perte normale intégré dans le pricing
- `seuil_alerte_stock` — quantité minimum avant déclenchement `AlertBanner`
- `unite_vente` — kg / pièce / botte / sac / caisse / autre
- `input_type` — vrac / unit / service / mixed

---

## BDUI — Pas d'écrans codés en dur

Tous les dashboards, formulaires et layouts sont rendus par le BDUI Engine depuis la config JSON. Les scénarios documentent des **flows** (séquences d'actions) et des **composants dans des états**, pas des écrans fixes.

---

## Offline-First

Drift/Isar = source de vérité locale. Le backend = service de sync. Après le premier login :
- Profil user en cache
- Données métier en cache
- L'app fonctionne sans réseau — sync silencieuse au retour

---

## Backend-Down vs Mode Offline — Distinction critique

Deux états distincts, deux UX distincts :

| État | Condition | UX |
|------|-----------|-----|
| **Mode offline** | Réseau indisponible, Drift peuplé | `SyncStatusBar` ambre — app 100% fonctionnelle |
| **ErrorState backend** | Backend 5XX + retry épuisé, Drift peuplé | Bannière rouge "Sync impossible" — lecture OK, écriture mise en queue |
| **ErrorState bloquant** | Drift vide + pas de réseau (premier login jamais complété) | Plein écran `ErrorState` — "Connexion requise pour le premier lancement" |
| **Session expirée** | Token expiré + impossible de refresh | Plein écran `ErrorState` — "Session expirée — reconnectez-vous" |

### Règles d'application

**Mode offline (cas normal) :**
- Toutes les actions continuent (vente, inventaire, perte)
- Transactions en queue locale Drift
- `SyncStatusBar` ambre avec compteur "X action(s) en attente"
- Sync automatique silencieuse au retour réseau
- Pas d'interruption utilisateur

**Backend 5XX (cas exceptionnel) :**
- Même comportement que mode offline pour l'utilisateur
- Logs d'erreur côté serveur — monitoring admin A05
- Retry automatique exponentiel (30s → 2min → 10min)
- Après 3 retry échoués : `AlertBanner` rouge "Serveur temporairement indisponible — vos données sont sauvegardées"

**Drift vide + premier launch :**
- `ErrorState` plein écran bloquant — aucune fonctionnalité accessible
- Message : "Connexion internet requise pour le premier lancement"
- `ActionButton` "Réessayer"
- Contact intégrateur visible (Kofi)

**Session expirée :**
- Détectée au refresh token — redirection automatique vers écran de re-login
- `ErrorState` avec bouton "Se reconnecter" → retour S07 (login)
- Données Drift conservées intactes — pas de perte

---

## FCM — Notifications Push (Android 13+)

### Permission initiale

Android 13+ exige une permission explicite `POST_NOTIFICATIONS` avant l'envoi de FCM.

**Déclencheur :** La demande de permission est faite lors du setup re-auth (S24.1), pas au premier lancement. Raison : l'utilisateur comprend déjà la valeur de l'app à ce stade.

### Flow de permission

```
S24.1 (PIN Setup) →
  AlertBanner info : "Scalario vous envoie des alertes stock
                      et confirmations de caisse en temps réel"
  ActionButton "Activer les notifications" → dialog Android natif
  ↓
  [Autoriser]  →  FCM token enregistré → notifications actives
  [Refuser]    →  AlertBanner ambre "Notifications désactivées —
                   vous pouvez les activer dans les paramètres Android"
                   App continue normalement (dégradé)
```

### Types de notifications Gate 0

| Type | Déclencheur | Destinataire |
|------|-------------|-------------|
| Alerte stock critique | Stock < seuil_alerte_stock | Blandine (OWNER) |
| Ouverture caisse | S26 — session ouverte | Blandine (OWNER) |
| Fermeture caisse | S03 — session clôturée | Blandine (OWNER) |
| Vente à crédit | S15 — crédit enregistré | Blandine (OWNER) |
| Perte déclarée | S06 — perte validée | Blandine (OWNER) |

### Silence nocturne

Configurable dans S13.2 (Config Alerte) — `Toggle` silence nocturne + `TimePicker` heures début/fin.
Par défaut : silence entre 22:00 et 07:00.
Géré côté backend : FCM envoyé uniquement dans la plage horaire autorisée.

---

## Template Update Flow — Mise à jour du template JSON

### Problème

Le template `retail_fresh_produce.json` évolue (nouvelles fonctionnalités, corrections). Les tenants déployés doivent recevoir les mises à jour sans interruption de service.

### Architecture de mise à jour

```
Scalario backend
  │
  ├── template_version: "1.2.0"  (dans le profil tenant)
  │
  └── Au login ou sync :
        1. App compare version locale vs version backend
        2. Si mismatch → télécharge delta JSON en background
        3. Drift mis à jour silencieusement
        4. Nouveau layout appliqué au prochain écran (pas de force-restart)
```

### Règles

- **Backward compatible obligatoire** — les champs supprimés sont ignorés par le renderer, pas d'erreur
- **Nouveaux composants** — ignorés si version Flutter app ne les connaît pas (graceful degradation)
- **Breaking changes** — nécessitent une mise à jour de l'app Flutter (Play Store) — version minimum définie dans le template JSON (`min_app_version`)
- **Rollback** — Kofi peut forcer une version template depuis A02 (admin tenant)

### UX pendant la mise à jour

- Transparente pour l'utilisateur — `SyncStatusBar` vert clignotant quelques secondes
- Pas de splash screen "Mise à jour en cours"
- Si mise à jour échoue → ancienne version conservée, retry au prochain sync

---

## Session Caisse — Ouverture & Fermeture

### Concept

Une **session caisse** est distincte d'une **session auth** :
- Session auth = login/logout utilisateur (S07, S25)
- Session caisse = période d'activité commerciale avec fond de caisse

### Lifecycle

```
Matin : S26 Ouverture caisse
  → Fond de caisse déclaré (montant cash initial)
  → Session horodatée (heure, utilisateur)
  → Notification Blandine

Journée : Ventes (S02, S15), Pertes (S06), Livraisons (S05)
  → Toutes les transactions liées à la session active

Soir : S03 Fermeture caisse
  → Comptage cash final
  → Réconciliation : fond + ventes cash - monnaie rendue = caisse finale attendue
  → Écart constaté signalé (alerte si > seuil)
  → Notification Blandine
```

### Multi-caisse (Gate 0 : non)

Gate 0 = une seule caisse par tenant. La structure de données supporte plusieurs caisses (champ `caisse_id`) mais l'UI n'expose qu'une seule pour Gate 0.

---

## Documents Commerciaux — Ticket, Facture, Rapport

### Génération

Tous les documents sont générés côté backend (PDF server-side) ou côté client (Dart PDF library) selon la connectivité :

| Document | Génération | Offline ? |
|----------|------------|-----------|
| Ticket de caisse | Client (Dart PDF) | ✅ Oui |
| Facture PDF | Client (Dart PDF) ou backend | ✅ Oui (client) |
| Rapport PDF | Backend (données complètes) | ⚠️ Partiel si données offline |
| Export CSV | Client (données Drift) | ✅ Oui |

### Branding

Chaque document porte le branding du tenant (logo, nom, adresse, téléphone) depuis la config JSON. Le footer mentionne "Propulsé par Scalario" — configurable (`hide_scalario_branding: true` pour les tenants premium).

### Numérotation factures

Séquentielle par tenant : `AAAA-NNNN` (année + numéro auto-incrémenté). Côté client en offline : numéro temporaire `TMP-NNNN`, remplacé par le numéro définitif au sync.
