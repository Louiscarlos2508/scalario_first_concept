---
project: scalario
scenario: "08"
slug: 08-blandines-offline-day
status: outlined
created: 2026-05-09
template: retail_fresh_produce.json
---

# 08: Blandine's Offline Day

**Project:** Scalario
**Created:** 2026-05-09
**Method:** Whiteport Design Studio (WDS)

---

## Transaction (Q1)

**What this scenario covers:**
L'utilisateur perd sa connexion réseau en cours de journée — continue à travailler normalement (vendre, consulter, valider) — l'app sync automatiquement au retour du réseau sans perte de données.

---

## Business Goal (Q2)

**Goal:** O1.1 — Usage quotidien garanti même sans réseau — connexion intermittente = réalité UEMOA
**Objective:** O2.2 — Churn <3% — si l'app bloque sans réseau, abandon certain sur le terrain

---

## User & Situation (Q3)

**Persona:** Blandine (OWNER) — applicable à tous : Commercial, Ibrahim
**Situation:** Au marché ou en déplacement. Connexion 4G coupée : zone sans couverture, réseau surchargé, ou coupure opérateur. L'app était ouverte et en cours d'utilisation.

---

## Driving Forces (Q4)

**Hope:** Continuer à travailler sans interruption — rien n'est perdu, le client ne voit rien.

**Worry:** Que l'app "bloque" ou affiche des erreurs devant le client — perdre une vente, perdre la face.

---

## Device & Starting Point (Q5 + Q6)

**Device:** Mobile Android mid-range — terrain UEMOA, réseau instable par nature
**Entry:** L'utilisateur est déjà dans l'app, en pleine action. Le réseau coupe. `SyncStatusBar` passe offline — l'app continue de fonctionner depuis Drift local.

---

## Best Outcome (Q7)

**User Success:**
Continue à travailler normalement — vente enregistrée, données consultables — message rassurant, pas d'alarme. Sync silencieuse automatique au retour réseau.

**Business Success:**
Zéro perte de données + zéro interruption = preuve offline-first = argument de vente terrain UEMOA + Gate 0 viable.

---

## Shortest Path (Q8)

1. **Réseau coupé — App continue** — `SyncStatusBar` passe offline, `AlertBanner` info discret "Hors ligne — tes données sont sauvegardées", workflow non interrompu
2. **Action hors ligne complétée** — Vente / clôture / livraison enregistrée dans Drift local — zéro blocage, zéro erreur visible
3. **Retour réseau — Sync automatique** — `SyncStatusBar` "Sync en cours" → "Synchronisé" — backend mis à jour silencieusement ✓

---

## Trigger Map Connections

**Persona:** Blandine (Primary) + tous rôles

**Driving Forces Addressed:**
- ✅ **Want:** "App disponible même sans réseau — terrain UEMOA" — Drift = source de vérité locale
- ❌ **Fear:** "App bloque devant le client — perte de face" — résolu par zéro interruption + message rassurant non-alarmiste

**Business Goal:** O1.1 + O2.2 — Usage quotidien garanti + rétention terrain

---

## Scenario Steps

| Step | Dossier | Purpose | Exit Action |
|------|---------|---------|-------------|
| 08.1 | `08.1-reseau-coupe-app-continue/` | Réseau coupé — SyncStatusBar offline — app continue | Utilisateur poursuit son action |
| 08.2 | `08.2-action-hors-ligne/` | Action complétée depuis Drift local — zéro blocage | Action enregistrée localement |
| 08.3 | `08.3-retour-reseau-sync/` | Retour réseau — sync silencieuse automatique | Backend synchronisé ✓ |
