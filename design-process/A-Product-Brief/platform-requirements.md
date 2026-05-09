---
stepsCompleted: ['step-27-platform-init', 'step-28-tech-stack', 'step-29-integrations', 'step-30-contact-strategy', 'step-31-multilingual', 'step-32-create-platform-document']
project: scalario
lastUpdated: 2026-05-09
status: complete
---

# Platform Requirements: Scalario

> Technical Boundaries & Platform Decisions

**Created:** 2026-05-09
**Author:** Carlos Simporé
**Related:** [Product Brief](./project-brief.md) | [Visual Direction](./visual-direction.md) | [Content & Language](./content-language.md)

---

## Summary

```
Tech Stack:      Flutter + NestJS + FastAPI + PostgreSQL + Redis + MinIO
Styling:         Material Design 3 flat, dark-first, dual dark/light mode
Languages:       FR (primaire) + EN (secondaire) · flutter_localizations + intl
Contact:         WhatsApp direct Phase 1 → WhatsApp Business API Phase 2
SEO:             Hors scope app (landing page géré séparément)
Key Constraint:  Offline-first natif · 60fps Snapdragon 680 · BDUI JSON-driven
Maintenance:     Carlos seul jusqu'à M8 minimum
```

---

## Technology Stack

### Core Platform

**Approche :** Mobile-first cross-platform (Flutter) + Modular monolith backend (NestJS)

Le principe structurant : zéro logique métier dans le code. Tout est déclaré en JSON. Le BDUI Engine Flutter rend l'UI depuis des schémas JSON — nouveau secteur = nouveau fichier JSON, zéro ligne de code.

### Stack complète

| Couche | Technologie | Rationale |
|--------|-------------|-----------|
| **App client** | Flutter (Material Design 3) | Codebase unique Android/iOS/Web · BDUI Engine · Material 3 natif |
| **Local DB (offline)** | Drift / Isar | Source de vérité offline-first — backend = service de sync, pas source primaire |
| **i18n** | flutter_localizations + intl | Zéro string hardcodée dès le jour 1 · FR + EN · RTL-ready pour Phase 3+ |
| **Backend API** | NestJS (TypeScript) | Modular monolith · 2 endpoints génériques servent tous les modules |
| **IA / ML** | FastAPI (Python) | Écosystème Python pour AI · séparé du core NestJS |
| **Base de données** | PostgreSQL | Multi-tenant shared schema · Row Level Security |
| **Cache / Queues** | Redis | Sync queue pour events offline · pub/sub temps réel · sessions |
| **Stockage fichiers** | MinIO | S3-compatible self-hosted · zéro vendor lock-in |
| **Infra** | Docker Compose (5 services) | VPS léger · déployable solo · évolutif vers Kubernetes Phase 3 |

### Package stack Flutter (principaux)

| Package | Usage | Statut |
|---------|-------|--------|
| `flutter_localizations` + `intl` | i18n FR/EN | Phase 1 |
| `drift` | Local DB offline-first | Phase 1 |
| `firebase_messaging` | Push notifications (FCM) | Phase 1 |
| `go_router` | Navigation déclarative | Phase 1 |
| `riverpod` | State management | Phase 1 |
| `dio` | HTTP client + interceptors | Phase 1 |
| `claude_api` (Anthropic) | Config Agent IA | Phase 2 |

---

## Integrations

### Phase 1 — Requises maintenant

| Intégration | Usage | Propriétaire |
|-------------|-------|--------------|
| **FCM (Firebase Cloud Messaging)** | Push notifications — résumé soir Blandine + alertes critiques | Carlos |
| **Claude API (Anthropic)** | Config Agent IA — architecture anticipée, implémentée Phase 2 | Carlos |
| **Email transactionnel** (Resend / Sendgrid) | Onboarding, factures intégrateurs | Carlos |

### Phase 2 — M6

| Intégration | Usage |
|-------------|-------|
| **Wave / Orange Money** | Paiement mobile UEMOA — abonnements clients |
| **WhatsApp Business API** | Support in-app Blandine → intégrateur + reporting |
| **Config IA conversationnelle** | Déploiement 45 min via conversation — cœur de la Phase 2 |

### Phase 3 — Horizon

| Intégration | Usage |
|-------------|-------|
| **BDAPI** | Open API pour apps tierces (livraison, credit scoring, supply chain) |
| **Orange / MTN Telco** | Distribution à l'échelle via réseau telco |
| **Ecobank / Coris Bank** | Bundle compte pro + Scalario 3 mois offerts |

### Analytics

Interne uniquement — métriques usage dans la DB Scalario :
- Fréquence ouverture app Blandine (leading indicator #1)
- Nombre validations croisées exécutées par semaine
- Temps d'onboarding client N vs N-1
- Modifications JSON demandées (moins = mieux)

Pas de Google Analytics — application native, pas un site web.

---

## Contact Strategy

| Canal | Phase | Usage |
|-------|-------|-------|
| **WhatsApp direct Carlos** | Phase 1 | Support intégrateur = Carlos, canal informel direct |
| **Push notifications (FCM)** | Phase 1 | Communication proactive vers Blandine — résumé soir |
| **Email transactionnel** | Phase 1 | Onboarding intégrateur, factures |
| **WhatsApp Business API** | Phase 2 | Support in-app natif Blandine → intégrateur certifié |
| **Config IA conversationnelle** | Phase 2 | "Contact" = conversation pour configurer et déployer |

**UX implications :**
- Bouton support in-app → deeplink WhatsApp Phase 1 (simple, direct)
- Pas de formulaire de contact classique dans l'app
- Notifications push = canal sortant principal → design des états de notification critique

---

## UX Constraints

Contraintes qui définissent ce qui est possible en Phase 3 (UX Scenarios) et Phase 4 (Design) :

- **Offline-first** → UI fonctionne sans réseau · zéro blocking states · données depuis Drift immédiatement disponibles
- **BDUI Engine** → zéro logique métier hardcodée dans Flutter · tout composant doit être composable/paramétrable par JSON
- **Android mid-range** (Snapdragon 680, 4GB RAM) → 60fps constant · zéro shader lourd · BackdropFilter minimal ou absent
- **Touch targets** → minimum 48×48dp (Material accessibility guidelines)
- **Dual theme** → tokens sémantiques uniquement (`surface`, `onSurface`, `primary`...) · pas de couleurs hardcodées
- **Multilingue FR/EN** → labels UI absorbent la variabilité de longueur · EN souvent plus court que FR
- **WCAG AA** → contraste minimum 4.5:1 texte, 3:1 composants UI
- **Pas de hover patterns** → mobile tactile uniquement, pas de desktop-first adapté après

### Performance Targets

| Métrique | Cible | Rationale |
|----------|-------|-----------|
| Démarrage à froid | < 2 secondes | Snapdragon 680, usage terrain |
| Frame rate | 60 fps constant | Fluidité mid-range |
| Sync offline → backend | < 5 secondes | Data du jour, connexion intermittente UEMOA |
| Push notification delivery | < 30 secondes | Résumé soir Blandine |
| Taille APK | < 50 MB | Stockage limité mid-range + téléchargement 4G |

---

## Multilingual Requirements

**Langues :**

| Langue | Priorité | Couverture | Implémentation |
|--------|----------|------------|----------------|
| **Français** | Primaire | 100% UI + marketing | `flutter_localizations` + `intl` |
| **Anglais** | Secondaire | UI + pages marketing clés | Carlos + IA review après FR validé |
| Dioula / Mooré / Wolof | Phase 3 | Interface vocale uniquement | Après 50+ clients, marché rural |

**Règle absolue :** Zéro string hardcodée. Toutes les chaînes passent par le système `intl` dès le premier écran.

**Workflow traduction :**
1. Contenu créé en français
2. Traduction anglaise : Carlos + révision IA (pas de traducteur pro Phase 1)
3. Strings locales = `.arb` files dans `/l10n/`

**Localisation :**
- Devise : FCFA par défaut, configurable par tenant
- Date : `DD/MM/YYYY`, heure locale UEMOA
- Téléphone : format UEMOA (`+226`, `+225`, etc.)

**RTL readiness :** Architecture i18n prête pour marchés arabophones Phase 3+ — pas de hard-coded `left`/`right`, utiliser `start`/`end` Flutter.

---

## SEO Requirements

**Hors scope application native.**

- Landing page : gérée séparément, hors scope WDS
- App Store SEO (Google Play / App Store) : Phase 2 lors de la publication
- In-app : pas de SEO — application native

---

## Maintenance & Ownership

| Aspect | Responsable | Notes |
|--------|-------------|-------|
| **Contenu UI (FR)** | Carlos | À chaque nouvelle feature |
| **Contenu UI (EN)** | Carlos + IA review | Après FR validé |
| **Infrastructure / DevOps** | Carlos | VPS + Docker Compose solo |
| **Mises à jour dépendances** | Carlos | Revue manuelle — pas d'update automatique |
| **Support client Phase 1** | Carlos (via WhatsApp) | Intégrateur = Carlos Phase 1 |
| **Support client Phase 2+** | Intégrateurs certifiés | Carlos garde le core, intégrateurs prennent le terrain |

---

## Development Handoff Notes

**Environment Setup :**
- Docker Compose : 5 services (`nestjs`, `fastapi`, `postgresql`, `redis`, `minio`)
- Flutter : Android SDK + VSCode / Android Studio
- Env variables : `.env` template fourni, secrets gérés manuellement Phase 1

**Deployment :**
- VPS unique (Hetzner ou OVH) Phase 1
- CI/CD : GitHub Actions → build → deploy via SSH Phase 2
- Mobile : distribution manuelle APK Phase 1 → Google Play Phase 2

**Considérations clés :**
- Zéro logique métier dans Flutter — tout passe par le BDUI Engine
- Les 2 endpoints génériques NestJS servent tous les modules — ne pas créer d'endpoints domaine-spécifiques
- Offline sync = source de bugs les plus subtils — tester systématiquement en mode avion
- Multi-tenant shared schema → Row Level Security PostgreSQL critique pour l'isolation

---

## Next Steps

- [ ] **Phase 2 : Trigger Mapping** — Connecter la plateforme à la psychologie utilisateur
- [ ] **Phase 3 : UX Scenarios** — Designer les flows dans ces contraintes techniques
- [ ] **Phase 4 : Design System** — Construire les tokens depuis la direction visuelle

---

_Platform Requirements v1.0 — Carlos Simporé — 2026-05-09_
