---
stepsCompleted: ['step-13-content-init', 'step-14-personality', 'step-15-tone', 'step-16-languages', 'step-17-seo-keywords', 'step-17a-content-structure', 'step-18-create-content-document']
project: scalario
lastUpdated: 2026-05-09
status: complete
---

# Content & Language Strategy: Scalario

**Status:** Complete
**Phase:** 1 — Product Brief
**Next Phase:** Visual Direction (Phase 1 — step-19+)

---

## Brand Personality

5 attributs qui définissent comment Scalario se comporte en tant que marque :

| Attribut | Ce que ça veut dire | Comment ça s'exprime |
|---|---|---|
| **Terrain** | Ancré dans la réalité africaine. Connaît le commerce de Ouaga, pas juste les slides PowerPoint. | Exemples concrets, langage du commerçant, jamais de jargon SAP |
| **Direct** | Va droit au but. La preuve vient des données, pas des discours. | Phrases courtes, chiffres visibles, zéro euphémisme |
| **Fiable** | Toujours disponible — même sans connexion. Promesses tenues, gates respectés. | Offline-first comme identité, pas comme feature |
| **Ambitieux** | Pense UEMOA → Afrique de l'Ouest, pas juste Ouagadougou. Construit pour l'échelle dès le premier jour. | Vision 5 ans assumée, architecture qui anticipe |
| **Expert discret** | La technologie est puissante mais invisible à l'utilisateur final. Blandine ne voit pas le JSON — elle voit son business. | L'UI cache la complexité. L'intégrateur sent la puissance. |

**Comment Blandine devrait se sentir :** en confiance, en contrôle, jamais perdue. Comme si elle avait un associé compétent qui gère les chiffres pendant qu'elle gère son business.

---

## Tone of Voice

### Spectres

| Spectre | Position | Note |
|---|---|---|
| Formalité (Formel ↔ Casual) | **3/5** | Associé — ni corporate ni familier |
| Humeur (Sérieux ↔ Joueur) | **2/5** | Sérieux mais pas lourd — c'est l'argent de Blandine |
| Complexité (Technique ↔ Simple) | **4/5** | Simple pour l'utilisateur, puissance sous le capot |
| Énergie (Réservé ↔ Enthousiaste) | **3/5** | Confiant et assumé, pas de hype |

### We Say / We Don't Say

| Contexte | ✅ We Say | ❌ We Don't Say |
|---|---|---|
| Accueil | "Bonjour Carlos, voici ton tableau de bord" | "Cher utilisateur estimé..." |
| Erreur | "Quelque chose s'est mal passé — réessaie" | "Erreur 503 : service indisponible" |
| Succès | "Caisse clôturée ✓" | "Votre requête a été traitée avec succès" |
| Offline | "Mode hors ligne — tes données sont sauvegardées" | "Connexion internet requise" |
| État vide | "Aucune vente pour aujourd'hui" | "Aucun enregistrement trouvé" |
| Action | "Valider la livraison" | "Soumettre" |
| Sync | "Tout est à jour" | "Synchronisation complète à 100%" |
| Champ erreur | "Vérifie ce champ" | "Invalid input" |

---

## Language Strategy

| Langue | Priorité | Couverture | Rôle |
|---|---|---|---|
| **Français** | Primaire | 100% — UI, marketing, docs | Langue source, UEMOA francophone |
| **Anglais** | Secondaire | UI + pages marketing clés | Expansion anglophone + intégrateurs internationaux |
| Dioula / Mooré / Wolof | Phase 3 | Interface vocale uniquement | Après 50+ clients, marché rural |

**Approche traduction :**
- Contenu créé d'abord en français
- Traduction anglaise : Carlos + IA review (pas de traducteur pro Phase 1)
- Zéro string hardcodée — `flutter_localizations` + `intl` dès le jour 1

**Localisations :**
- Devise : FCFA par défaut, configurable par tenant
- Date/heure : format africain francophone (`DD/MM/YYYY`, heure locale)
- Téléphone : format UEMOA (`+226`, `+225`, etc.)
- Compliance : OHADA = plugin, pas dépendance core

**Ton multilingue :** Même personnalité dans les deux langues — direct, terrain, expert discret.

---

## Content Guidelines par Type

### UI Microcopy (boutons, labels, erreurs)
- Phrases courtes — max 4 mots pour les labels
- Voix active — "Valider" pas "Validation"
- Spécifique sur l'action — "Valider la livraison" pas "OK"
- Erreurs humaines — expliquer sans code technique
- Zéro jargon ERP dans l'UI visible par Blandine

### Marketing (TikTok/Facebook)
- Bénéfice d'abord, preuve par les données
- Ton fondateur authentique sur compte Carlos (build in public)
- Ton produit sur compte Scalario (démos, cas d'usage, témoignages)
- Exemples concrets > promesses abstraites

### Onboarding intégrateur
- Direct et professionnel — l'intégrateur est un partenaire, pas un client
- Technique quand nécessaire — il comprend le JSON
- Revenue focus — toujours lier les actions au revenu récurrent

---

## SEO

Hors scope — landing page gérée séparément.

---

## Content Structure

Hors scope WDS — structure 100% data-driven depuis les templates JSON du BDUI Engine. Chaque rôle voit une structure différente selon `visible_if`. Géré par le catalogue Scalario.

---

## Content Ownership

| Type de contenu | Responsable | Fréquence |
|---|---|---|
| UI microcopy (FR) | Carlos | À chaque nouvelle feature |
| UI microcopy (EN) | Carlos + IA review | Après FR validé |
| Marketing TikTok/Facebook | Carlos | Continu (build in public) |
| Docs intégrateur | Carlos | Phase 2 |
| Templates JSON sectoriels | Carlos + intégrateurs (Phase 3) | Par nouveau secteur |

---

## Writing Checklist

- [ ] Ton correspond aux 5 attributs de personnalité (Terrain, Direct, Fiable, Ambitieux, Expert discret)
- [ ] Zéro jargon ERP dans l'UI visible par Blandine
- [ ] Versions française ET anglaise à jour
- [ ] Voix active, labels < 4 mots
- [ ] Erreurs expliquées en langage humain (pas de codes techniques)
- [ ] Offline states couverts dans tous les écrans

---

_Content & Language Strategy v1.0 — Carlos Simporé — 2026-05-09_
