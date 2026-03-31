# Insights Stratégiques Clés — Scalario Trigger Map

**Phase 2 : Trigger Mapping | Synthèse**
**Généré :** 2026-03-31

---

## Les 5 Insights qui guident toutes les décisions design

---

### Insight 1 — Le produit que Scalario vend n'est pas ce qu'il semble vendre

**Ce que Scalario semble vendre :** un outil de gestion (stock, caisse, POS)

**Ce que Scalario vend réellement :**
- À Blandine : **la preuve** — ne plus avoir à choisir entre faire confiance à ses employés et perdre de l'argent
- À Bernard : **la certitude du soir** — dormir sans doute sur sa caisse
- À Cheick : **l'unification** — un seul outil là où il en utilisait trois qui ne se parlaient pas
- À Ibrahim : **la crédibilité récurrente** — une solution qu'il peut défendre et qui lui rapporte tant qu'elle est utilisée

**Implication design :** Chaque écran doit délivrer sa promesse émotionnelle, pas seulement sa fonction logique. L'arrêt de caisse ne délivre pas "une réconciliation stock/CA" — il délivre "vous pouvez dormir".

---

### Insight 2 — La peur de l'attribution est universelle, d'intensité variable

Les 3 personas actifs (Blandine, Bernard, Cheick) partagent la même peur fondamentale : **quelque chose disparaît (argent, stock, créance) et je ne sais pas pourquoi ni à cause de qui.**

- Blandine : intensité maximale (perte chronique significative, 5 employés, 8 phases)
- Bernard : intensité modérée (doute récurrent, petit montant, 1 employé)
- Cheick : intensité spécialisée (créances et péremptions non suivies)

**Implication design :** L'audit trail et l'historique par utilisateur ne sont pas des fonctionnalités Premium — ce sont la fondation du Core Standard. Scalario = système de preuve d'abord, système de gestion ensuite.

---

### Insight 3 — La friction d'adoption est la menace existentielle pour le Standard track

Blandine signera parce qu'elle a une douleur aiguë qui justifie l'effort d'adoption. Bernard ne signera que si l'effort est **quasi nul**. Sa phrase — *"si c'est compliqué, j'arrête"* — définit l'exigence du Standard track.

Chaque feature Standard doit passer le test Bernard : **est-ce qu'un commerçant avec un cahier peut comprendre et utiliser cette feature en 3 minutes sans formation ?**

Si non → ce n'est pas du Standard.

**Implication design :** L'onboarding Standard doit être conçu comme un produit à part entière — pas une documentation, un chemin guidé qui mène à la première valeur perçue en < 10 minutes.

---

### Insight 4 — Les forces négatives sont plus puissantes que les forces positives pour déclencher l'action

Aucun des 4 personas ne "veut" adopter un nouveau logiciel. Ce qui les fait agir :
- Blandine : **peur d'une perte non attribuable qui continue à s'accumuler** → elle signe
- Bernard : **peur d'une journée de plus sans certitude** → il continue d'utiliser
- Cheick : **peur de perdre un client fidèle sur un SKU épuisé** → il configure ses variantes
- Ibrahim : **peur d'une mauvaise référence dans son réseau** → il déploie avec soin

**Implication design :** Les messages système et les empty states doivent activer les forces positives (certitude, contrôle) tout en désactivant les peurs (incertitude résolue, preuves visibles). Ne jamais laisser un utilisateur dans un état ambigu — l'ambiguïté réactive la peur.

---

### Insight 5 — "Universel par architecture, local par exécution" est la tension créative de toute décision produit

La vision de Scalario est globale. L'exécution est UEMOA Retail. Cette tension est productive si elle est assumée :
- Chaque feature locale (Taux de Frotte, vrac→sachet, FCFA, OHADA) doit être implémentée comme une **instance d'un pattern universel** — pas comme une exception
- Chaque décision architecturale (offline-first, payment adapters, i18n, compliance pluggable) doit tenir pour n'importe quel marché

**Implication design :** Quand une feature semble "trop africaine" ou "trop spécifique", la bonne question est : *"Quel est le pattern universel dont c'est une instance ?"* Le Taux de Frotte = instance de "perte naturelle configurable par type de produit". Ce pattern sert les boulangeries en France autant que Blandine à Ouaga.

---

## Priorités de Design Issues de ce Trigger Map

| Priorité | Force motrice | Persona(s) | Implication |
|---|---|---|---|
| 🔴 P1 | Preuve de responsabilité par rôle | Blandine, Bernard, Cheick | Audit trail visible = Core non-négociable |
| 🔴 P2 | Certitude quotidienne sur la caisse | Blandine, Bernard | Arrêt de caisse guidé < 5 minutes = Core non-négociable |
| 🔴 P3 | Friction d'adoption zéro | Bernard | Onboarding Standard = produit à part entière |
| 🟡 P4 | Contrôle à distance propriétaire | Blandine | Dashboard mobile + WhatsApp = Premium différenciant |
| 🟡 P5 | Distinguer perte naturelle de vol | Blandine | Taux de Frotte = Premium opt-in |
| 🟡 P6 | Gestion variantes par SKU | Cheick | Variantes = Core Standard+ |
| 🟢 P7 | Déploiement autonome intégrateur | Ibrahim | AI Config Wizard = H2 prérequis |

---

*Source : Trigger Map Scalario v1 · WDS Phase 2 · 2026-03-31*
