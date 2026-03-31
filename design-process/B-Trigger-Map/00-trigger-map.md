# Trigger Map Scalario — Hub

**Phase 2 : Trigger Mapping | Document Principal**
**Généré :** 2026-03-31 | Mode Dream
**Version :** 1.0

---

## Vue d'ensemble

Le Trigger Map Scalario traduit la vision produit en forces motrices humaines concrètes. Il répond à la question fondamentale : **pourquoi des personnes réelles, dans des situations réelles, changeraient-elles leur comportement à cause de Scalario ?**

Cette carte est le pont entre la stratégie business (objectifs) et les décisions design (ce qu'on construit, dans quel ordre, avec quel message).

---

## Diagramme — Structure Complète

```mermaid
flowchart TD
    subgraph BG["🎯 Objectifs Business"]
        O1["O1 — Revenu Récurrent\nO1.1 Blandine < mi-avril 2026\nO1.2 10 clients ARR 3-4M FCFA\nO1.3 100 clients ARR 25-30M FCFA"]
        O2["O2 — Utilisateurs Non-Remplaçables\nO2.1 NRR > 100% à 12 mois\nO2.2 Sessions > 5/semaine à 3 mois\nO2.3 2 testeurs autonomes < 2 mois"]
        O3["O3 — Canal de Distribution Scalable\nO3.1 1er client via intégrateur\nO3.2 3 intégrateurs opérationnels\nO3.3 60% via intégrateurs"]
    end

    subgraph PROD["🚀 Scalario"]
        S["Plateforme de gestion universelle\npour organisations des marchés sous-servis\nUniversel par architecture · Local par exécution\nBeachhead UEMOA → Global"]
    end

    subgraph TG["👥 Groupes Cibles"]
        TG1["TG1 — Blandine la Boutiquière\nPremium Pro · 40 000 FCFA/mois\nBoutique gros & détail produits frais\n5 employés · 8 phases workflow\nClosing < mi-avril 2026"]
        TG2["TG2 — Bernard le Boutiquier\nStandard · 15 000–25 000 FCFA/mois\nBoutique boissons & divers\n2–3 employés · Cahier → digital\nTesteur actif · conversion < 3 mois"]
        TG3["TG3 — Cheick le Chimiste\nStandard+ · 20 000–30 000 FCFA/mois\nChimiques & cosmétiques · variantes\n3–5 employés · Excel + carnet + téléphone\nTesteur actif · variantes = test critique"]
        TG4["TG4 — Ibrahim l'Intégrateur\nPartenaire H2 · Commission 20% + 15%\nFormateur IT freelance · 20–30 clients PME\nActif à partir de Mois 6–12"]
    end

    subgraph DF["⚡ Forces Motrices"]
        subgraph DF1["Blandine"]
            B_P["✅ Contrôle à distance\n✅ Preuve par rôle\n✅ Distinguer Frotte / vol\n✅ Sign-off propriétaire\n✅ Alertes WhatsApp"]
            B_N["❌ Attribution impossible\n❌ Fausse certitude filtrée\n❌ Résistance adoption terrain\n❌ Conflit arrêt de caisse"]
        end
        subgraph DF2["Bernard"]
            Br_P["✅ Certitude CA quotidienne\n✅ Visibilité stock instantanée\n✅ Attribution transactions"]
            Br_N["❌ Friction adoption immédiate\n❌ Doute quotidien chronique\n❌ Vol invisible faible montant"]
        end
        subgraph DF3["Cheick"]
            C_P["✅ Inventaire SKU précis variantes\n✅ Solde crédit au moment vente\n✅ Alerte péremption proactive"]
            C_N["❌ Survente SKU épuisé\n❌ Créances non récupérées\n❌ Produits expirés non détectés"]
        end
        subgraph DF4["Ibrahim"]
            I_P["✅ Déploiement autonome < 1 jour\n✅ Argument différenciant monopole\n✅ Commission récurrente stable"]
            I_N["❌ Client n'adopte pas = réputation\n❌ Question sans réponse = incompétence\n❌ Mises à jour invalident formation"]
        end
    end

    BG --> PROD
    PROD --> TG
    TG1 --> DF1
    TG2 --> DF2
    TG3 --> DF3
    TG4 --> DF4
```

---

## Table de Priorité — Groupes Cibles

| Priorité | Persona | Tier | Horizon | Rôle Stratégique |
|---|---|---|---|---|
| 🥇 P1 | Blandine la Boutiquière | Premium Pro | H1 immédiat | Gate 1 — revenu + référence crédibilité |
| 🥈 P2 | Bernard le Boutiquier | Standard | H1 court | Gate 2 — validation modèle volume + archétype intégrateur |
| 🥉 P3 | Cheick le Chimiste | Standard+ | H1 moyen | Gate 2 — validation marché sophistiqué + NRR anchor |
| 4️⃣ P4 | Ibrahim l'Intégrateur | Partenaire | H2 | Gate 5 — canal distribution autonome |

---

## Focus Stratégique — La Tension Créative Centrale

> **"Scalario est universel par architecture, local par exécution."**

Chaque décision produit se joue entre ces deux pôles :

- **Architecture universelle** — offline-first, payment adapters, i18n, compliance pluggable, variants system, audit trail — tout doit fonctionner pour n'importe quel marché
- **Exécution locale** — Taux de Frotte, vrac→sachet, FCFA, OHADA, mobile money, WhatsApp — chaque feature locale est une instance d'un pattern universel

Le beachhead UEMOA n'est pas un compromis : c'est la preuve par l'extrême. Si Scalario fonctionne ici (offline quotidien, infrastructure variable, mixité technologique, commerce informel), il fonctionne partout.

---

## Documents du Trigger Map

| Document | Contenu |
|---|---|
| [01-Business-Goals.md](01-Business-Goals.md) | Objectifs 3×3 : O1 Revenu · O2 Rétention · O3 Distribution |
| [02-Blandine-Boutiquiere.md](02-Blandine-Boutiquiere.md) | Persona P1 — 5 forces positives + 4 négatives |
| [03-Bernard-Boutiquier.md](03-Bernard-Boutiquier.md) | Persona P2 — 3 forces positives + 3 négatives |
| [04-Cheick-Chimiste.md](04-Cheick-Chimiste.md) | Persona P3 — 3 forces positives + 3 négatives |
| [05-Ibrahim-Integrateur.md](05-Ibrahim-Integrateur.md) | Persona P4 — 3 forces positives + 3 négatives |
| [06-Key-Insights.md](06-Key-Insights.md) | 5 insights stratégiques + table priorités design |

---

## Décisions Produit Issues du Trigger Map

| Priorité | Force motrice | Implication |
|---|---|---|
| 🔴 P1 | Preuve de responsabilité par rôle | Audit trail visible = Core non-négociable |
| 🔴 P2 | Certitude quotidienne sur la caisse | Arrêt de caisse guidé < 5 min = Core non-négociable |
| 🔴 P3 | Friction d'adoption zéro | Onboarding Standard = produit à part entière |
| 🟡 P4 | Contrôle à distance propriétaire | Dashboard mobile + WhatsApp = Premium différenciant |
| 🟡 P5 | Distinguer perte naturelle de vol | Taux de Frotte = Premium opt-in |
| 🟡 P6 | Gestion variantes par SKU | Variantes = Core Standard+ |
| 🟢 P7 | Déploiement autonome intégrateur | AI Config Wizard = H2 prérequis |

---

*Source : Trigger Map Scalario v1 · WDS Phase 2 · 2026-03-31*
*Généré en Dream Mode par Saga — Whiteport Design Studio*
