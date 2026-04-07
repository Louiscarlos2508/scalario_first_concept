# Scénario 11 — Blandine onboarde, jongle entre 2 boutiques et reçoit son rapport WhatsApp

**Persona :** Blandine ⭐ (PRIMARY)
**Priorité :** P1 (couvre 3 trous identifiés dans l'audit hub)
**Statut :** DRAFT 2026-04-07
**Trous comblés :**
1. Onboarding Blandine (Sc10 ne couvre que Yempabou côté gérant)
2. Gestion multi-boutique (driver "perte de contrôle quand absent" non visualisé)
3. Réception WhatsApp d'un rapport côté Blandine (Sc01.7 montre l'envoi, pas la réception)
4. Mode offline / sync (critique au Burkina)

---

## Contexte narratif

Dimanche soir, 21h. Blandine est à Dakar pour 10 jours. Avant de partir vendredi, elle a créé son compte Scalario depuis Ouaga et invité Yempabou comme gérant de "Boutique Tampouy". Lundi matin elle ouvre une seconde boutique "Boutique Zone 1" gérée par sa sœur. Ce dimanche, elle reçoit son rapport hebdo automatique sur WhatsApp pendant qu'elle est en réseau Edge dans le bus.

## Pages cibles (6)

| # | Page | Type | Réf code | Spec |
|---|------|------|----------|------|
| 11.1 | Onboarding Blandine (création compte patron) | CRÉER | — | [11.1](11.1-onboarding-patron/) |
| 11.2 | Création boutique #1 + invitation gérant | CRÉER | — | [11.2](11.2-creation-boutique/) |
| 11.3 | Switcher multi-boutique (drawer + bottomsheet) | CRÉER | — | [11.3](11.3-switcher-boutique/) |
| 11.4 | Vue consolidée multi-boutique (dashboard groupé) | CRÉER | — | [11.4](11.4-dashboard-consolide/) |
| 11.5 | Réception WhatsApp rapport hebdo (côté Blandine) | CRÉER (mockup chat) | — | [11.5](11.5-whatsapp-recu/) |
| 11.6 | Mode offline + bandeau sync reconnexion | RETOUCHE globale | tous écrans | [11.6](11.6-offline-sync/) |

**Delta :** 5 créations + 1 retouche transverse

## Drivers couverts

- ⭐ Perte de contrôle quand absente (Blandine) — multi-boutique
- ⭐ Visibilité temps réel — dashboard consolidé + WhatsApp push
- Réseau dégradé Burkina — offline/sync
- Onboarding patron — manquait à Sc10

## Lien aux scénarios existants

- **Sc01** envoie le rapport via WhatsApp ; **Sc11.5** montre le côté reçu (boucle UX complète)
- **Sc10** onboarde le gérant ; **Sc11.1-11.2** onboardent le patron en amont (chronologie réelle)
- **Sc06, 09** se rejouent par boutique sélectionnée via **Sc11.3** switcher

## Pages NON incluses (volontaire)

- Annulation/remboursement vente → Sc02 v2 (autre scénario)
- Profil utilisateur / changement PIN → Sc10 v2
- Recherche globale / scan hors POS → backlog Phase 2
