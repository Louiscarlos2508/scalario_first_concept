# STORY-042 : Contraintes Global Scale — i18n FR/EN + PaymentAdapter

**Epic :** EPIC-007 — Premier Template `retail_fresh_produce.json` (Gate 0 Blandine)
**Priorité :** Must Have
**Story Points :** 3
**Status :** Defined
**Assigned To :** Unassigned
**Created :** 2026-05-10
**Sprint :** 4 (2026-06-23 → 2026-07-04)
**Dependencies :** STORY-012 (Flutter mobile + web), STORY-013 (NestJS setup), STORY-040 (modules consomment les `i18n_key` et le `payment_provider`)

---

## User Story

> **En tant que** dev / fondateur / futur intégrateur en Côte d'Ivoire ou Sénégal,
> **je veux** que les contraintes d'internationalisation et de paiement soient **posées dès le premier template** (FR primaire + EN préparé, `PaymentAdapter` interface en place avec Wave / Orange Money / MTN MoMo / cash / credit pluggables),
> **so that** l'expansion vers un 2ème pays au M3 (Gate 2) ne nécessite **aucun refactoring** — juste un nouveau provider implémenté et une nouvelle locale ajoutée. Et **so that** le template `retail_fresh_produce.json` est portable au-delà de Burkina Faso : aucune valeur métier (devise, locale, provider, fuseau) n'est hardcodée dans le catalogue ni dans Flutter.

---

## Description

### Background

Scalario est conçu **global-scale-by-default** (NFR-010). La tentation au Gate 0 est de tout cabler en `XOF`, `fr-BF`, `Wave` parce que Blandine est au Burkina. C'est exactement ce qui tue les boîtes africaines qui essaient de scaler — chaque nouveau pays = 6 mois de refactoring.

Cette story **pose les rails dès Phase 1** :
- **i18n Flutter** : `flutter_localizations` + `intl`, ARB files FR (primaire) + EN (préparé), 0 string visible hardcodée, lint qui le bloque en CI.
- **PaymentAdapter** : interface NestJS abstraite, registry par tenant, 3 implémentations Phase 1 (`CashAdapter`, `MobileMoneyAdapter` avec sub-providers Wave/OrangeMoney/MTN, `CreditAdapter`).
- **Tenant config** : devise, locale, fuseau, providers actifs — tout dans `tenant.config`, jamais en dur.
- **NestJS i18n** : codes d'erreur uniquement (`ERR_*`) — pas de strings traduites côté serveur (responsabilité Flutter).

C'est une story **rails + plomberie**. Elle n'a pas de feature visible "wow" pour Blandine, mais sans elle, le projet meurt à Gate 2.

### Scope

**In scope :**

**1. i18n Flutter**

- Configuration `flutter_localizations` + `intl` dans `apps/flutter/pubspec.yaml`.
- Création `apps/flutter/lib/l10n/app_fr.arb` (primaire, complet) et `app_en.arb` (préparé, ~80% de couverture).
- `l10n.yaml` config + génération `S` class via `flutter gen-l10n`.
- Toutes les `i18n_key` déclarées dans STORY-039, 040, 041 ont leur entrée FR.
- ~40-60% des `i18n_key` ont aussi une entrée EN (assez pour valider la mécanique ; complétude = post-Gate 0).
- Locale runtime : `tenant.config.locale` (défaut `fr-BF`) résout la `S.of(context)` via `LocaleProvider` Riverpod.
- Format monétaire dynamique : `intl.NumberFormat.currency(locale: tenant.locale, symbol: tenant.currency)` — utilisé dans tous les `KPICard`, `DataTable currency columns`, et form fields type `currency`.
- Format date : `intl.DateFormat.yMd(tenant.locale)`.
- Format nombre (Roboto Mono) : préserver l'espace insécable (`12 500`) en FR, virgule en EN (`12,500`).
- RTL préparé : `MaterialApp.localizationsDelegates` inclut `GlobalCupertinoLocalizations` ; un test golden charge en `ar` (vide à 100%, mais la mécanique RTL flip est testée).
- **Lint custom `no_hardcoded_strings_in_widgets`** : règle dans `analysis_options.yaml` qui détecte `Text("Hello")` dans `lib/features/` et `lib/screens/` et fait échouer `flutter analyze`. Whitelist : `lib/core/`, fichiers `*.g.dart`, et exceptions explicites annotées `// i18n-ignore: <reason>`.

**2. PaymentAdapter (NestJS)**

- Interface `PaymentAdapter` dans `services/nestjs/src/payment/`.
- 3 implémentations Phase 1 :
  - `CashAdapter` : no-op (cash = pas d'API à appeler ; juste log audit).
  - `MobileMoneyAdapter` : strategy interne par sub-provider (`wave`, `orange_money`, `mtn_momo`). Phase 1 = **stubs** (méthodes existent, retournent `{ status: "phase_2_stub", session_id: "stub_xxx" }`). Branchement réel = post-Gate 0.
  - `CreditAdapter` : crédit interne au tenant (créance commercial). Pas de provider externe.
- Registry `PaymentAdapterRegistry` qui résout `(tenant, payment_method, payment_provider)` → adapter instance.
- Configuration dans `tenant.config.payment_methods_enabled[]` (cf STORY-039 `tenant_defaults`).
- Endpoint `POST /api/v1/:tenant/payment/initiate` qui prend `{ amount, currency, method, provider, meta }` et délègue à l'adapter.
- Endpoint `POST /api/v1/:tenant/payment/verify` qui vérifie une session.
- Webhook NestJS prêt (route protégée HMAC) `POST /api/v1/webhooks/payment/:provider` — implémentation Phase 2, mais squelette + signature verification en place.

**3. Tenant config — Global Scale defaults**

- Le `tenant_defaults` du `retail_fresh_produce.json` (STORY-039) est étendu avec :
  - `locale: "fr-BF"` (résolu via i18n).
  - `currency: "XOF"`.
  - `timezone: "Africa/Ouagadougou"`.
  - `payment_methods_enabled: ["cash", "mobile_money", "credit"]`.
  - `payment_providers_default: { "mobile_money": ["wave", "orange_money", "mtn_momo"] }`.
- Override possible par tenant via UI admin (Phase 2) ou via seed (Phase 1).

**4. Audit "no hardcoded business value"**

- Script `scripts/audit-business-values.ts` qui grep dans `apps/flutter/lib/`, `services/nestjs/src/`, et `catalog/` pour patterns suspects :
  - `XOF`, `FCFA`, `EUR`, `USD` hors zones autorisées.
  - `Burkina`, `Ouagadougou`, `Africa/`.
  - `wave.com`, `orange-money`, `mtn-momo` URLs en dur.
- Échec CI si match hors whitelist. Whitelist explicite et minimale.

**Out of scope :**

- Implémentation **réelle** des intégrations Wave / Orange Money / MTN MoMo (signature, webhook, polling) — Phase 2. Phase 1 = stubs fonctionnels qui retournent un état "OK simulé".
- Compliance OHADA / fiscalité par pays — Phase 3 (`OHADAPlugin implements CompliancePlugin`).
- ARB EN à 100% complet — 40-60% suffit pour valider la mécanique. Complétude post-Gate 0.
- Locale `ar` (Arabe) RTL réelle — juste mécanique testée. Strings = post-Phase 2.
- Format de papier facture (A4 vs Letter) — Phase 2.

### User Flow

**Dev sur Scalario (Carlos, futur intégrateur) :**
1. Ajoute un nouveau widget. Tape `Text("Bienvenue")`.
2. `flutter analyze` → **Erreur** : "hardcoded string in widget — use S.of(context).welcome".
3. Ajoute la clé dans `app_fr.arb` : `"welcome": "Bienvenue"`. Et dans `app_en.arb` : `"welcome": "Welcome"`.
4. Code devient `Text(S.of(context).welcome)`. Lint passe.

**Tenant dans un autre pays (Côte d'Ivoire) :**
1. Provisioning crée tenant avec `tenant.config = { locale: "fr-CI", currency: "XOF", timezone: "Africa/Abidjan", payment_methods_enabled: ["cash", "mobile_money"], payment_providers_default: { "mobile_money": ["wave", "orange_money_ci", "moov_money"] } }`.
2. Le template `retail_fresh_produce.json` est rechargé **sans modification**.
3. L'app Flutter rend les écrans avec `12 500 FCFA` formatés en `fr-CI` (même rendu textuel ici, car XOF UEMOA, mais la mécanique passerait pour XAF, EUR, USD).
4. Quand un commercial fait une vente Mobile Money, le form propose `wave / orange_money_ci / moov_money` (lus depuis `tenant.config`), pas les providers BF.
5. Le `MobileMoneyAdapter` route vers le sub-adapter `moov_money` (stub Phase 1, réel Phase 2). 0 ligne de code modifiée pour ouvrir la Côte d'Ivoire.

---

## Acceptance Criteria

### i18n Flutter — setup

- [ ] AC-01 — `pubspec.yaml` déclare `flutter_localizations` (SDK), `intl: ^0.19+`. `flutter_gen-l10n` configuré dans `l10n.yaml`.
- [ ] AC-02 — `apps/flutter/lib/l10n/app_fr.arb` contient **toutes** les `i18n_key` référencées dans `catalog/domains/retail_fresh_produce.json`, `catalog/modules/*.json`, `catalog/workflows/*.json` (extraites par `scripts/extract-i18n-keys.ts`). Couverture FR = 100%.
- [ ] AC-03 — `apps/flutter/lib/l10n/app_en.arb` contient au minimum **40%** des clés (au moins toutes les clés de navigation, rôles, modules names, screens titles). Le reste a un fallback FR documenté en runtime.
- [ ] AC-04 — `MaterialApp` configurée avec `localizationsDelegates`, `supportedLocales: [Locale('fr', 'BF'), Locale('en', 'US'), Locale('ar')]`. RTL géré par `Directionality` natif.
- [ ] AC-05 — `LocaleProvider` Riverpod résout la locale depuis `tenant.config.locale` au login (défaut `fr-BF`). Le user peut override en réglages (UI minimal Phase 1).

### i18n Flutter — usage

- [ ] AC-06 — Dans `apps/flutter/lib/features/` et `lib/screens/`, **0 string visible hardcodée**. Toute string passe par `S.of(context).<key>` ou `context.l10n.<key>`.
- [ ] AC-07 — Lint custom `no_hardcoded_strings_in_widgets` actif dans `analysis_options.yaml` : pattern `Text\(['"][^$].*['"]\)` dans `lib/features/` ou `lib/screens/` → erreur `flutter analyze`. Whitelist explicite `// i18n-ignore: <reason>`.
- [ ] AC-08 — Format monétaire : helper `Currency.format(amount, tenant)` retourne `intl.NumberFormat.currency(locale: tenant.locale, symbol: _, decimalDigits: _).format(amount)`. Symbol résolu depuis `tenant.config.currency` (XOF → `FCFA`, EUR → `€`, etc.). Test : `Currency.format(12500, blandineTenant) == "12 500 FCFA"`.
- [ ] AC-09 — Format date : helper `DateFmt.yMd(date, tenant.locale)` ; format heure `DateFmt.Hm(date, tenant.locale)`. Tests sur `fr-BF` (`10/05/2026`) et `en-US` (`5/10/2026`).
- [ ] AC-10 — Espace insécable préservé en FR (`12 500 FCFA`) — vérifié dans test golden Roboto Mono.

### NestJS — codes d'erreur uniquement

- [ ] AC-11 — Tous les `throw new HttpException()` côté NestJS utilisent un code d'erreur (`ERR_UNAUTHORIZED`, `ERR_TENANT_NOT_FOUND`, etc.) — **jamais** une string traduite. Test : grep `'.*[a-z]'` dans les exceptions, whitelist `ERR_*`.
- [ ] AC-12 — Codes d'erreur documentés dans `services/nestjs/src/errors/error-codes.ts` (enum + i18n_key associée). Flutter mappe `ERR_*` → `S.of(context).err_*`.

### PaymentAdapter — interface + registry

- [ ] AC-13 — Interface `PaymentAdapter` définie :
  ```typescript
  interface PaymentAdapter {
    readonly id: string;
    readonly supportedMethods: PaymentMethod[];
    initiate(input: { amount: number; currency: string; meta: PaymentMeta }): Promise<PaymentSession>;
    verify(sessionId: string): Promise<PaymentResult>;
    refund?(sessionId: string, amount: number): Promise<PaymentResult>;
  }
  ```
- [ ] AC-14 — `CashAdapter` implémenté : `initiate` retourne `{ status: "completed", session_id: uuid }` immédiatement. `verify` retourne `{ status: "completed" }`. Audit log écrit.
- [ ] AC-15 — `MobileMoneyAdapter` implémenté avec strategy interne (`wave`, `orange_money`, `mtn_momo`). `initiate` retourne `{ status: "phase_2_stub", session_id: "stub_xxx", message: "Phase 2 — real provider integration pending" }`. `verify` retourne `{ status: "completed_simulated" }`.
- [ ] AC-16 — `CreditAdapter` implémenté : `initiate` crée une entrée `entity { type: "credit_line", debtor_user_id, amount }`. `verify` retourne le solde restant.
- [ ] AC-17 — `PaymentAdapterRegistry` : `getAdapter(tenant_id, payment_method, payment_provider)` résout l'adapter. Throw `ERR_PAYMENT_ADAPTER_NOT_FOUND` si combinaison non supportée.
- [ ] AC-18 — Endpoint `POST /api/v1/:tenant/payment/initiate` validé Zod, RBAC `COMMERCIAL or OWNER`, retourne `PaymentSession`.
- [ ] AC-19 — Endpoint `POST /api/v1/:tenant/payment/verify` validé Zod, retourne `PaymentResult`.
- [ ] AC-20 — Webhook squelette `POST /api/v1/webhooks/payment/:provider` : signature HMAC SHA-256 vérifiée (Phase 1 = stub `verify-only`, pas d'action ; Phase 2 = délégation à l'adapter).

### Tenant config

- [ ] AC-21 — `tenant_defaults` dans `retail_fresh_produce.json` étendu avec `payment_methods_enabled` et `payment_providers_default` (cf scope). Validation Zod OK.
- [ ] AC-22 — Au provisioning d'un tenant, `tenant.config` hérite de `tenant_defaults` du domaine + override seed. Test : 2 tenants, 1 BF + 1 CI, configs distinctes.

### Audit "no hardcoded business value"

- [ ] AC-23 — Script `scripts/audit-business-values.ts` exécutable :
  - Cherche `XOF`, `FCFA`, `EUR`, `USD`, `Burkina`, `Ouaga`, `Africa/`, URLs `wave\.com|orange-money|mtn`.
  - Cherche dans `apps/flutter/lib/`, `services/nestjs/src/`, `catalog/`.
  - Whitelist : `tenant_defaults` blocs dans catalogue, `tests/`, `__mocks__/`, `error-codes.ts` strings allowlist.
  - Échec si match hors whitelist.
- [ ] AC-24 — Hook CI : `scripts/audit-business-values.ts` exécuté dans `.github/workflows/ci.yml`. Échec → PR bloquée.

### RTL préparé

- [ ] AC-25 — Test golden : 1 écran simple chargé en `Locale('ar')`. La direction est RTL (`Directionality.of(context) == TextDirection.rtl`). L'arrangement des composants est miroir (Sidebar à droite, etc.). Pas besoin de strings traduites.

---

## Technical Notes

### Composants concernés

- **Flutter :**
  - `apps/flutter/lib/l10n/app_fr.arb`, `app_en.arb`, `l10n.yaml` (nouveaux).
  - `apps/flutter/lib/core/i18n/locale_provider.dart`, `currency_format.dart`, `date_format.dart`.
  - `apps/flutter/analysis_options.yaml` — règle `no_hardcoded_strings_in_widgets`.
- **NestJS :**
  - `services/nestjs/src/payment/` — `payment-adapter.interface.ts`, `cash.adapter.ts`, `mobile-money.adapter.ts`, `credit.adapter.ts`, `payment-adapter.registry.ts`, `payment.controller.ts`, `payment.service.ts`.
  - `services/nestjs/src/errors/error-codes.ts`.
- **Catalogue :** `catalog/domains/retail_fresh_produce.json` — extension `tenant_defaults`.
- **Scripts :** `scripts/extract-i18n-keys.ts`, `scripts/audit-business-values.ts`.

### Pattern PaymentAdapter (extrait)

```typescript
// payment-adapter.interface.ts
export interface PaymentMeta {
  saleId?: string;
  customerId?: string;
  description?: string;
  [k: string]: unknown;
}

export interface PaymentSession {
  sessionId: string;
  status: 'pending' | 'completed' | 'completed_simulated' | 'phase_2_stub' | 'failed';
  redirectUrl?: string;
  expiresAt?: string;
  message?: string;
}

export interface PaymentResult {
  sessionId: string;
  status: 'completed' | 'completed_simulated' | 'failed' | 'pending';
  amount?: number;
  currency?: string;
  providerRef?: string;
}

export interface PaymentAdapter {
  readonly id: string;
  readonly supportedMethods: ('cash' | 'mobile_money' | 'credit')[];
  initiate(input: { amount: number; currency: string; meta: PaymentMeta }): Promise<PaymentSession>;
  verify(sessionId: string): Promise<PaymentResult>;
  refund?(sessionId: string, amount: number): Promise<PaymentResult>;
}
```

```typescript
// mobile-money.adapter.ts (Phase 1 stub)
@Injectable()
export class MobileMoneyAdapter implements PaymentAdapter {
  readonly id = 'mobile_money';
  readonly supportedMethods = ['mobile_money'] as const;

  constructor(private readonly logger: Logger) {}

  async initiate({ amount, currency, meta }) {
    const provider = (meta as any).provider as 'wave' | 'orange_money' | 'mtn_momo';
    if (!provider) throw new BadRequestException('ERR_PAYMENT_PROVIDER_REQUIRED');
    this.logger.log({ event: 'payment_initiate_stub', provider, amount, currency });
    return {
      sessionId: `stub_${randomUUID()}`,
      status: 'phase_2_stub' as const,
      message: `Phase 2 — ${provider} integration pending`,
    };
  }

  async verify(sessionId: string) {
    return { sessionId, status: 'completed_simulated' as const };
  }
}
```

### Pattern lint custom `no_hardcoded_strings_in_widgets`

```yaml
# analysis_options.yaml (extrait)
analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
  errors:
    todo: ignore
  plugins:
    - custom_lint

custom_lint:
  rules:
    - no_hardcoded_strings_in_widgets:
        paths:
          - "lib/features/**"
          - "lib/screens/**"
        whitelist_comment: "i18n-ignore"
```

(Si `custom_lint` n'est pas en place — c'est probable Phase 1 — fallback : script `scripts/check-no-hardcoded-strings.dart` exécuté en CI qui grep les `Text\(['"]` dans les paths cibles. Documenté.)

### Conflits de spec — résolutions

- **PRD §FR-023 mentionne `Wave = 1 implémentation future`** (= Phase 2 réelle). Cette story livre **3 sub-providers stubbés** (Wave + Orange Money + MTN MoMo) sous le même `MobileMoneyAdapter`. **Décision plus large que le PRD** : Burkina Faso a 3 mobile money dominants ; ne lister que Wave créerait un faux signal d'orientation OEMUA-only. Documenter dans le doc-release post-merge.
- **Architecture §1306-1314** spécifie `WaveAdapter implements PaymentAdapter` et `OrangeMoneyAdapter implements PaymentAdapter` comme **classes séparées**. Cette story regroupe sous **un seul** `MobileMoneyAdapter` avec strategy interne (sub-providers). Raison : le 90% de la logique est commune (HMAC, polling, webhook), seules les URLs/secrets diffèrent. **Décision :** strategy pattern. Si un futur provider a une logique radicalement différente (ex: Stripe), on dérivera. Documenter en archi-update post-merge.
- **NFR-010 mentionne `OHADAPlugin implements CompliancePlugin`** : **out of scope** Phase 1. Mentionné en Notes pour traçabilité.
- **Sprint plan AC-04 dit `Wave = 1 implémentation future (interface only Phase 1)`** : **résolu** — interface ✅, registry ✅, 3 sub-stubs ✅, intégrations réelles Phase 2.
- **DS source de vérité format monétaire** : DS `tokens/typography.md` impose Roboto Mono pour valeurs FCFA. Cette story consomme — elle ne redéfinit pas de tokens. PRD vs DS : DS gagne sur la typo (déjà résolu STORY-001).

### Edge cases

- **Locale absente** (user ouvre app avec `Locale('zh')` non supporté) : fallback chain `zh → fr-BF → fr → en` (`MaterialApp.localeResolutionCallback`).
- **Devise non standard** : si un tenant a `currency: "BTC"` (rigolo mais possible), `intl.NumberFormat.currency` ne connaît pas — fallback : `<amount> <currency_code>` brut. Pas de crash.
- **Timezone DST** : `Africa/Ouagadougou` n'a pas de DST. Test sur `Europe/Paris` (a DST) couvert dans `DateFmt` test.
- **Webhook replay** : le webhook squelette vérifie `signature + timestamp < 5min` pour éviter les replays. Phase 1 = juste vérification, pas d'action. Phase 2 = action.
- **Adapter non trouvé** : si `tenant.config.payment_methods_enabled = ["mobile_money"]` mais le commercial tente `cash`, le `Registry` throw `ERR_PAYMENT_METHOD_NOT_ENABLED`. UI doit cacher l'option (`module_ventes` form `visible_if`).

### Sécurité

- **Webhook HMAC** : signature SHA-256 du body avec secret par provider, stocké dans `services/nestjs/.env` Phase 1, puis Vault Phase 2. Header `X-Scalario-Signature: sha256=<hex>`. Replay window 5 min.
- **Aucun secret dans le catalogue** : les secrets adapters sont dans env vars / vault, jamais dans `tenant.config` (qui est en JSONB lisible).
- **i18n keys ≠ code execution** : les strings ARB sont des données. Flutter ne fait jamais `eval` dessus. XSS impossible (Flutter ne rend pas de HTML).
- **Audit log paiement** : chaque `initiate / verify / webhook` écrit dans `audit_logs`.

---

## Dependencies

**Prérequis (techniques) :**
- STORY-012 — Flutter setup mobile + web (consommateur des delegates).
- STORY-013 — NestJS setup (module structure, Logger, ConfigModule).
- STORY-039 — Squelette domaine (étendu ici avec `tenant_defaults.payment_*`).
- STORY-040 — Modules Phase 1 JSON (consomment les `i18n_key` d'ici, et le `payment_provider` enum).

**Stories bloquées par celle-ci :**
- STORY-043 — Validation E2E Gate 0 (test final, doit voir Blandine en `fr-BF` + un test secondaire en `en` + paiement Mobile Money simulé).

**Externes :**
- `flutter_localizations`, `intl` Flutter packages — disponibles SDK.
- `@nestjs/config`, `class-validator`, `zod` — déjà dans STORY-013.
- Pas d'API externe Phase 1 (les providers sont stubbés).

---

## Definition of Done

- [ ] Code commité sur branche `feat/story-042-i18n-payment-adapter`.
- [ ] ARB files FR (100%) + EN (≥ 40%) présents et validés (`flutter gen-l10n` produit `S` class sans erreur).
- [ ] `flutter analyze` vert (lint custom passé sur tous les widgets).
- [ ] `npm run lint` (NestJS) vert.
- [ ] Tests verts :
  - 3 PaymentAdapter (cash + MobileMoney + credit) ont leurs tests unitaires.
  - Registry test : combinaisons valides + invalides (`ERR_PAYMENT_ADAPTER_NOT_FOUND`).
  - Endpoint `/payment/initiate` test integration (RBAC + Zod + adapter delegation).
  - Webhook signature HMAC test.
  - Currency format test (XOF / EUR / USD / fallback).
  - Date format test (fr-BF / en-US).
  - RTL golden test sur `Locale('ar')`.
- [ ] `scripts/audit-business-values.ts` exécuté en CI, échoue si match hors whitelist (test négatif inclus).
- [ ] Aucune string visible hardcodée détectée (manuel grep + lint).
- [ ] Code review : `/codex review` + auto-review Carlos.
- [ ] PR mergée sur `main`.
- [ ] `_bmad-output/implementation-artifacts/sprint-status.yaml` mis à jour : STORY-042 status `completed`, sprint 4 `completed_points += 3`.

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| Setup `flutter_localizations` + `l10n.yaml` + ARB FR (100% des keys) | 0.5 | Mécanique mais volumineux — extraire toutes les keys du catalogue. |
| ARB EN (~40-60% couverture) | 0.25 | Tradeoff : assez pour valider la mécanique, complétude post-Gate 0. |
| `LocaleProvider` + `currency_format.dart` + `date_format.dart` + tests | 0.5 | Helpers + tests sur 3-4 locales. |
| Lint custom `no_hardcoded_strings_in_widgets` (custom_lint plugin OU script grep CI) | 0.5 | Important — sans ce filet, on dérive en sprint 5. |
| `PaymentAdapter` interface + 3 implémentations (cash + mobile_money stub + credit) | 0.5 | Stub bien fait, pas du throwaway. Strategy interne mobile_money. |
| `PaymentAdapterRegistry` + endpoints `/initiate` `/verify` + webhook squelette HMAC | 0.5 | Tests RBAC + signature. |
| Audit script `audit-business-values.ts` + intégration CI | 0.25 | Réutilise patterns de STORY-039/040 lint. |
| **Total** | **3** | Fibonacci 3 — moderate, mais c'est de la rails. |

**Rationale :** Pas de complexité algorithmique (les adapters sont stubs). La valeur est dans les **rails posés** : interface stable, registry, lint actif, audit CI. Si un seul de ces 4 manque, la dette technique au M3 explose. Les 3 points couvrent la rigueur d'enforcement plus que le volume de code.

---

## Notes additionnelles

- **Compliance OHADA** : intentionnellement reportée Phase 3. Mentionnée ici pour traçabilité de la dette future. Pattern attendu : `OHADAPlugin implements CompliancePlugin` injecté comme module NestJS optionnel — déjà préparé par l'archi modulaire.
- **Locale `ar`** : test golden uniquement. Strings réelles Phase 3+ quand un client arabophone arrive.
- **Mobile money réel (Wave / OM / MTN)** : Phase 2. Effort estimé : 1 sprint (Wave d'abord, plus simple ; OM 2ème ; MTN 3ème). Sandbox de test disponible chez chaque provider.
- **Référence DS :** Roboto Mono (STORY-001) pour les valeurs monétaires. Cette story consomme — elle ne touche pas aux tokens.
- **Lien Blandine ↔ AC :** Blandine bénéficie directement de :
  - AC-08 (`12 500 FCFA` formaté correctement avec espace insécable).
  - AC-15 (paiement Mobile Money simulé fonctionnel — elle peut faire des sales en demo Phase 1, le vrai branchement provider arrive Phase 2 sans qu'elle s'en rende compte).
- **Logo Scalario :** non concerné.
- **Tone serveur :** la décision "codes d'erreur uniquement, pas de strings" côté NestJS est **non-négociable**. Si un dev pousse `throw new Error("Compte introuvable")`, code review refuse. Le filet : le test AC-11 grep les exceptions.

---

## Progress Tracking

**Status History :**
- 2026-05-10 : Created (Carlos / Scrum Master via `/bmad:create-story`)

**Actual Effort :** TBD

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
