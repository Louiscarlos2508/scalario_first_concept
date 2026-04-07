# Trigger Map — Scalario Retail Phase 1

> Reference strategique unique : Business Goals -> Target Groups -> Driving Forces -> Prioritisation

**Document:** Trigger Map - Hub
**Created:** 2026-04-06
**Status:** COMPLETE

---

## Transformation

**De :** Proprietaires de boutiques retail en Afrique de l'Ouest qui dependent d'appels telephoniques, de cahiers et d'Excel pour savoir ce qui se passe dans leur boutique quand ils ne sont pas la.

**Vers :** Proprietaires qui gerent avec confiance a distance — chaque mouvement est trace, chaque decision est validee, chaque perte est detectable.

---

## Vision

**Chaque petit commercant d'Afrique de l'Ouest gere sa boutique avec confiance — sans cahier, sans Excel, qu'il soit la ou pas.**

---

## Flywheel (moteur strategique)

**THE ENGINE (Priorite #1) :** 3 testeurs actifs (Blandine + Yempabou + Vivien) qui utilisent l'app quotidiennement d'ici fin avril 2026. Ces premiers utilisateurs valident le produit et deviennent les references pour l'acquisition future.

**Acquisition (Priorite #2) :** 50-100 clients payants dans la premiere annee. Portes par le bouche-a-oreille des testeurs et un produit objectivement superieur a Gescom (offline, factures, CRM, credit, impression thermique).

**Retention (Priorite #3) :** Abandon complet du cahier/Excel en moins de 2 semaines. Le client ne revient jamais a l'ancien outil. Pricing adapte : Solo 5K, Boutique 7.5K, Pro 15K FCFA/mois.

---

## Diagramme Trigger Map

```mermaid
%%{init: {'theme':'base', 'themeVariables': { 'fontFamily':'Inter, system-ui, sans-serif', 'fontSize':'14px'}}}%%
flowchart LR
    %% Business Goals
    BG0["<br/>🌟 VISION<br/><br/>Chaque petit commercant<br/>gere sa boutique avec confiance<br/>sans cahier, sans Excel<br/>qu'il soit la ou pas<br/><br/>"]
    BG1["<br/>📊 OBJECTIFS<br/><br/>3 testeurs actifs fin avril<br/>50-100 clients en 1 an<br/>5K-15K FCFA/mois<br/>0 perte donnees sync<br/><br/>"]

    %% Platform
    PLATFORM["<br/>📱 SCALARIO RETAIL<br/><br/>Gestion de boutique<br/>offline-first<br/><br/>Remplace le cahier et Excel<br/>par un outil de controle<br/>a distance en temps reel<br/><br/>"]

    %% Target Groups
    TG0["<br/>🎯 BLANDINE<br/>PRIMARY TARGET<br/><br/>Boss lointaine (Senegal→Ouaga)<br/>3 roles, workflow 8 phases<br/>Frais perissables, complexe<br/>Palier Pro (cloud)<br/><br/>"]
    TG1["<br/>💼 YEMPABOU<br/>SECONDARY TARGET<br/><br/>Patron pragmatique, 150 produits<br/>Ex-Gescom, gestion familiale<br/>Veut factures + alertes stock<br/>Palier Boutique → Pro<br/><br/>"]
    TG2["<br/>🛒 VIVIEN<br/>SECONDARY TARGET<br/><br/>Commercant connecte, 60 produits<br/>1 vendeuse, cahier uniquement<br/>Veut impression thermique<br/>Palier Pro (2 devices)<br/><br/>"]

    %% Driving Forces
    DF0["<br/>🎯 DRIVERS BLANDINE<br/><br/>WANTS<br/>✅ Maitrise totale a distance<br/>✅ Visibilite permanente<br/>✅ Chaine de confiance validee<br/><br/>FEARS<br/>❌ Perte de controle<br/>❌ Decisions prises sans elle<br/>❌ Etre dans le flou<br/><br/>"]

    DF1["<br/>💼 DRIVERS YEMPABOU<br/><br/>WANTS<br/>✅ Vue d'ensemble immediate<br/>✅ Preuves tangibles (factures)<br/>✅ Mieux que Gescom<br/><br/>FEARS<br/>❌ Vol et pertes non prouvables<br/>❌ Dependance a l'appel<br/>❌ Limites outil actuel<br/><br/>"]

    DF2["<br/>🛒 DRIVERS VIVIEN<br/><br/>WANTS<br/>✅ Supervision bienveillante<br/>✅ Ventes en temps reel<br/>✅ Professionnalisation<br/><br/>FEARS<br/>❌ L'angle mort (rien quand absent)<br/>❌ Cahier insuffisant<br/>❌ Pas de facture = pas pro<br/><br/>"]

    %% Connections
    BG0 --> PLATFORM
    BG1 --> PLATFORM
    PLATFORM --> TG0
    PLATFORM --> TG1
    PLATFORM --> TG2
    TG0 --> DF0
    TG1 --> DF1
    TG2 --> DF2

    %% Styling
    classDef businessGoal fill:#f3f4f6,color:#1f2937,stroke:#d1d5db,stroke-width:2px
    classDef platform fill:#e5e7eb,color:#111827,stroke:#9ca3af,stroke-width:3px
    classDef targetGroup fill:#f9fafb,color:#1f2937,stroke:#d1d5db,stroke-width:2px
    classDef drivingForces fill:#f3f4f6,color:#1f2937,stroke:#d1d5db,stroke-width:2px

    class BG0,BG1 businessGoal
    class PLATFORM platform
    class TG0,TG1,TG2 targetGroup
    class DF0,DF1,DF2 drivingForces
```

---

## Focus Statement

**Scalario Phase 1 cible en priorite les proprietaires de boutique retail qui ne sont pas toujours sur place.** Le produit doit eliminer l'angle mort (ne pas savoir ce qui se passe quand on est absent) en offrant une visibilite en temps reel, un circuit de validation qui empeche les decisions non autorisees, et des preuves tangibles (factures, inventaires, arrets de caisse) qui rendent les pertes et le vol detectables. Si un patron au Senegal peut piloter sa boutique a Ouaga avec confiance, alors tout proprietaire qui s'absente quelques heures peut le faire aussi.

---

## Driver #1 : Perte de controle quand absent

C'est LE pattern commun aux 3 testeurs. Tout le UX doit repondre a cette question : **"Qu'est-ce qui s'est passe pendant que je n'etais pas la ?"**

---

## Comment lire cette Trigger Map

1. **Gauche → Droite** : Des objectifs business aux motivations psychologiques
2. **Business Goals** : Ce que Scalario doit atteindre (metrics)
3. **Platform** : Ce que Scalario est (produit)
4. **Target Groups** : Qui va atteindre ces objectifs par leur usage
5. **Driving Forces** : Pourquoi ils utilisent le produit (positif) et pourquoi ils ne pourraient PAS l'utiliser (negatif)

---

## Documents lies

- **[01-Business-Goals.md](01-Business-Goals.md)** - Objectifs et metriques
- **[02-Blandine.md](personas/02-Blandine.md)** - Persona primaire
- **[03-Yempabou.md](personas/03-Yempabou.md)** - Persona secondaire
- **[04-Vivien.md](personas/04-Vivien.md)** - Persona secondaire
- **[05-Key-Insights.md](05-Key-Insights.md)** - Implications strategiques

---

_Cree avec la methode WDS — Phase 2 (Trigger Mapping)_
