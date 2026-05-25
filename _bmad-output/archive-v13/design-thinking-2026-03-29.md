# Design Thinking Session: Scalario PRD v7 — UX Architecture

**Date:** 2026-03-29
**Facilitator:** Carlos-simpore
**Design Challenge:** Comment architecturer l'UX de Scalario pour servir les personas actuels sans polluer le Core Standard, tout en anticipant l'architecture H2/H3 sans la développer.

---

## 🎯 Design Challenge

**Contexte :** Scalario, ERP SaaS mobile-first offline-first, entre en phase de closing commercial avec 3 personas simultanés — un client payant Premium (Blandine) et 2 testeurs gratuits Standard (boissons, cosmétique). Démo Blandine dans < 1 mois.

**Le défi :** Architecturer l'UX de Scalario PRD v7 en deux temps :

**Exercice 1 — Personas actuels :** Traduire l'empathie profonde avec les 3 personas actuels en décisions immédiates de priorisation PRD — sans sur-complexifier le Core Standard pour les cas simples, sans sous-estimer les besoins réels de Blandine.

**Exercice 2 — Personas futurs :** Identifier les décisions d'architecture UX qui doivent être prises MAINTENANT pour ne pas bloquer les horizons H2/H3 — sans les développer, sans dette technique.

**Règle de fer :** Le Core Standard (POS + Stock + Rôles + Caisse) ne sera jamais pollué par la complexité Premium. Les features Premium sont des extensions opt-in. Les décisions H2/H3 sont anticipées dans l'architecture, pas développées en V1.

**Hypothèse centrale à challenger :** Ce que les personas disent vouloir n'est pas forcément ce pour quoi ils paient. La démo doit montrer ce qui crée le "moment de vérité", pas ce qui impressionne.

---

## 👥 EMPATHIZE: Understanding Users

### User Insights

**Ce que les personas DISENT vs ce qu'ils VEULENT VRAIMENT vs ce qu'ils NE DISENT PAS**

| Persona | Ce qu'il dit | Ce qu'il veut vraiment | Ce qu'il ne dit pas |
|---|---|---|---|
| **Blandine** | "Contrôler mes stocks et mes employés" | "Pouvoir agir sur ma boutique depuis mon téléphone — valider, approuver, clôturer — et être alertée sur WhatsApp quand quelque chose mérite mon attention" | "J'ai peur que mes employés me volent mais je ne peux pas le prouver" |
| **Boissons** | "Un outil pour gérer mon stock" | "Savoir combien j'ai et combien j'ai fait en 30 secondes le soir" | "Je n'ai jamais la certitude que ma caisse est juste" |
| **Cosmétique** | "Gérer mes variantes" | "Arrêter de me tromper dans les commandes et de survendre des SKUs épuisés" | "Je ne sais pas combien vaut mon stock en ce moment" |

**Le job émotionnel dominant par persona :**

- **Blandine :** Contrôle actif à distance — "je peux agir sur ma boutique depuis mon téléphone, et WhatsApp me prévient quand je dois intervenir"
- **Boissons :** Certitude quotidienne sans effort — "je dors sans m'inquiéter de la caisse"
- **Cosmétique :** Confiance dans l'inventaire — "je commande ce qu'il faut, en bonne quantité, au bon moment"

**Les déclencheurs de paiement (ce qui fait signer, pas ce qui impressionne) :**
- Blandine paie pour résoudre une douleur existante qui lui coûte de l'argent MAINTENANT
- Boissons paie si l'outil lui fait gagner du temps ET lui donne une garantie qu'il n'avait pas
- Cosmétique paie si l'outil résout un problème qu'il ne peut pas résoudre seul avec un cahier

### Key Observations

1. **Le problème central n'est pas "pas d'outil" — c'est "pas de preuve".** Les 3 personas perdent de l'argent sans savoir exactement où, quand, à cause de qui. Scalario n'est pas un outil de gestion — c'est un système de preuve.

2. **L'absence physique du propriétaire est universelle.** Les 3 personas ne peuvent pas surveiller physiquement leur boutique à plein temps. Le contrôle à distance est le besoin réel, pas "la gestion des stocks".

3. **Le cahier et Excel ne résolvent pas la responsabilité.** Le vendeur boissons a un cahier. Le cosmétique a un Excel. Blandine a des WhatsApp. Aucun ne dit "qui a fait quoi quand avec quel impact".

4. **La douleur de l'arrêt de caisse est universelle mais d'intensité variable.** Pour Blandine (3 niveaux de confrontation), c'est un problème existentiel. Pour Boissons, c'est juste chronophage. Même solution, proposition de valeur différente par persona.

5. **La complexité de Blandine est réelle, pas perçue.** Les 8 phases correspondent au flux physique réel des produits frais. Le risque n'est pas de la sur-complexifier — c'est de simplifier là où la complexité est structurellement nécessaire.

6. **Challenge de l'hypothèse "testeur gratuit → conversion naturelle" :** Boissons et Cosmétique ne souffrent pas assez pour payer spontanément. La conversion en 3 mois ne se fera que si Scalario résout un problème qu'ils ne peuvent pas résoudre autrement. Pour Boissons : arrêt de caisse automatique. Pour Cosmétique : gestion des variantes. Si ces deux features ne sont pas démontrées dans les 3 mois, la conversion n'aura pas lieu.

### Empathy Maps — 3 Personas Actuels

---

### Empathy Map — PERSONA 1 : BLANDINE (Distribution Premium)

```
┌─────────────────────────────────────────────────────────────────────┐
│                         BLANDINE                                     │
│            Propriétaire, boutique gros & détail, Ouaga              │
├──────────────────────────┬──────────────────────────────────────────┤
│ 🗣️ DIT                   │ 🧠 PENSE                                 │
│                          │                                          │
│ "Je sais jamais si c'est │ "Est-ce que mes employés                │
│ du vol ou de la          │  me volent ?"                           │
│ déshydratation"          │                                          │
│                          │ "Je peux pas être partout               │
│ "Quand je suis pas là,   │  à la fois"                             │
│ je sais pas ce qui       │                                          │
│ se passe"                │ "Si ça marche pas, j'ai                 │
│                          │  perdu du temps ET de l'argent"         │
│ "Les arrêts de caisse,   │                                          │
│ c'est toujours le        │ "Un outil qui me permet de             │
│ bordel"                  │  contrôler sans être là —               │
│                          │  ça, je paierais"                       │
│ "Mon gestionnaire et mes │                                          │
│ commerciaux se rejettent │                                          │
│ la faute"                │                                          │
├──────────────────────────┼──────────────────────────────────────────┤
│ 👁️ VOIT                  │ 🏃 FAIT                                  │
│                          │                                          │
│ Pertes "inexpliquées"    │ Utilise l'app : valide les             │
│ chaque semaine           │ approbations réappro, consulte          │
│                          │ le dashboard, clôture sa               │
│ Conflits entre employés  │ caisse depuis son téléphone            │
│ sans preuve              │                                          │
│                          │ Fait des allers-retours boutique        │
│ Stock qui "disparaît"    │ quand l'app ne suffit pas               │
│ entre phases             │                                          │
│                          │ Reçoit résumé quotidien                 │
│ Concurrents qui n'ont    │ WhatsApp en complément                  │
│ pas ce problème (?)      │ (push + WA = double canal)              │
├──────────────────────────┼──────────────────────────────────────────┤
│ 😤 PAINS                 │ 🎯 GAINS ATTENDUS                        │
│                          │                                          │
│ • Taux de Frotte non     │ • Agir depuis l'app : valider,         │
│   distingué du vol       │   approuver, clôturer — sans           │
│ • Vrac→Sachet manuel     │   se déplacer                           │
│   (sac 50kg → sachets)   │                                          │
│ • Responsabilité non     │ • Recevoir les alertes sur             │
│   prouvable par phase    │   WhatsApp ET pouvoir agir             │
│ • Réconciliation caisse  │   dans l'app dans la foulée            │
│   manuelle et conflictuelle│                                       │
│ • Dépendance à sa        │ • Caisse réconciliée +                  │
│   présence physique      │   son sign-off propriétaire            │
│                          │   depuis n'importe où                   │
└──────────────────────────┴──────────────────────────────────────────┘
```

---

### Empathy Map — PERSONA 2 : VENDEUR BOISSONS/DIVERS (Retail Standard)

```
┌─────────────────────────────────────────────────────────────────────┐
│                    VENDEUR BOISSONS/DIVERS                           │
│              2-3 employés, stock simple, cahier+tél                  │
├──────────────────────────┬──────────────────────────────────────────┤
│ 🗣️ DIT                   │ 🧠 PENSE                                 │
│                          │                                          │
│ "Je sais jamais          │ "Si c'est compliqué, j'arrête"          │
│ exactement ce que j'ai   │                                          │
│ en stock"                │ "Je perds peut-être des ventes          │
│                          │  sans m'en rendre compte"               │
│ "On compte la caisse     │                                          │
│ à la main le soir"       │ "Mon employé me vole                    │
│                          │  peut-être un peu ?"                    │
│ "Des fois il manque      │                                          │
│ des trucs sans raison"   │ "Un truc gratuit, je vais               │
│                          │  essayer — si ça m'aide tant mieux"     │
│                          │                                          │
├──────────────────────────┼──────────────────────────────────────────┤
│ 👁️ VOIT                  │ 🏃 FAIT                                  │
│                          │                                          │
│ Son cahier de stock,     │ Tient un cahier de stock                │
│ toujours en retard       │ (irrégulièrement, souvent faux)         │
│                          │                                          │
│ Des ruptures de stock    │ Commande "à l'œil" quand                │
│ surprises                │ il voit que c'est presque vide          │
│                          │                                          │
│ Des voisins commerçants  │ Compte la caisse en fin de              │
│ qui utilisent Excel      │ journée à la main                       │
├──────────────────────────┼──────────────────────────────────────────┤
│ 😤 PAINS                 │ 🎯 GAINS ATTENDUS                        │
│                          │                                          │
│ • Ruptures de stock      │ • Voir son stock en temps réel          │
│   surprises (ventes perdues)│                                      │
│ • Caisse non réconciliée │ • Réconciliation caisse                 │
│   chroniquement          │   automatique en fin de journée         │
│ • Pas de visibilité sur  │                                          │
│   vol/erreur employé     │ • Alertes rupture avant                 │
│ • Comptage manuel        │   qu'elles arrivent                     │
│   chronophage            │                                          │
│                          │ • Historique ventes pour               │
│                          │   mieux commander                       │
└──────────────────────────┴──────────────────────────────────────────┘
```

---

### Empathy Map — PERSONA 3 : VENDEUR CHIMIQUE/COSMÉTIQUE (Retail Standard+)

```
┌─────────────────────────────────────────────────────────────────────┐
│               VENDEUR CHIMIQUE / COSMÉTIQUE                          │
│       3-5 employés, variantes, clients réguliers avec crédit         │
├──────────────────────────┬──────────────────────────────────────────┤
│ 🗣️ DIT                   │ 🧠 PENSE                                 │
│                          │                                          │
│ "Un seul produit peut    │ "Gérer les variantes c'est              │
│ avoir 10 références      │  mon plus gros problème"                │
│ différentes"             │                                          │
│                          │ "Le crédit client que je                │
│ "Je sais pas combien     │  donne me coûte de l'argent"            │
│ j'ai de chaque taille"   │                                          │
│                          │ "Si l'outil comprend                    │
│ "Certains clients        │  mes variantes, ça vaut le coup"        │
│ paient pas tout de suite"│                                          │
│                          │                                          │
│ "J'ai des produits qui   │ "Je dois regarder les dates             │
│ expirent bientôt"        │  de péremption pour pas jeter"          │
├──────────────────────────┼──────────────────────────────────────────┤
│ 👁️ VOIT                  │ 🏃 FAIT                                  │
│                          │                                          │
│ Des erreurs de SKU       │ Utilise Excel ou cahier                 │
│ (survente d'une variante │ pour le stock (avec erreurs)            │
│ épuisée)                 │                                          │
│                          │ Gère le crédit dans un carnet           │
│ Des clients qui          │ par client                              │
│ disparaissent après      │                                          │
│ avoir pris crédit        │ Regarde manuellement les dates          │
│                          │ de péremption (souvent trop tard)       │
├──────────────────────────┼──────────────────────────────────────────┤
│ 😤 PAINS                 │ 🎯 GAINS ATTENDUS                        │
│                          │                                          │
│ • Gestion des variantes  │ • Gestion variantes par                 │
│   impossible au cahier   │   taille/couleur/parfum                 │
│   (10 réf. même produit) │                                          │
│ • Dates péremption       │ • Alertes péremption                    │
│   non suivies            │   paramétrables                         │
│ • Crédit client non      │                                          │
│   suivi (pertes réelles) │ • Solde crédit client                   │
│ • Valeur stock inconnue  │   visible au moment de la vente         │
│                          │                                          │
│                          │ • Valorisation stock automatique        │
└──────────────────────────┴──────────────────────────────────────────┘
```

---

## 🎨 DEFINE: Frame the Problem

### Jobs COMMUNS aux 3 Personas → Core Standard Non-Négociable

Ces jobs sont présents chez les 3 personas avec la même intensité. Ils constituent le **Core Standard non-négociable** — toute feature du Core qui ne sert pas ces jobs est hors-scope Standard.

| # | Job | Traduction feature Core | Pourquoi c'est universel |
|---|-----|------------------------|--------------------------|
| 1 | **"Savoir ce que j'ai en stock maintenant"** | Stock en temps réel par produit (quantité + valorisation basique) | Les 3 personas perdent des ventes ou de l'argent faute de cette visibilité |
| 2 | **"Fermer ma journée proprement"** | Arrêt de caisse guidé avec réconciliation automatique stock/CA | Les 3 passent du temps inutile à compter, recompter, et débattre |
| 3 | **"Voir ce que mes employés ont vendu"** | Historique des ventes par employé/session | La peur du vol est universelle dans ce marché — la preuve est le produit |
| 4 | **"Commander avant la rupture"** | Alertes stock d'alerte configurables par produit | Les ruptures surprises coûtent des ventes manquées à tous |
| 5 | **"Contrôler même quand je suis absent"** | Dashboard propriétaire mobile : CA jour, écarts, alertes critiques | Les 3 propriétaires sont régulièrement hors boutique |
| 6 | **"Que chacun fasse son travail sans accéder à tout"** | Rôles et permissions : propriétaire / employé (au minimum) | Donner accès à tout = risque de manipulation |
| 7 | **"Pas perdre de données si internet coupe"** | Mode offline fiable avec sync silencieux au retour de connexion | UEMOA : coupures internet quotidiennes, non-négociable |
| 8 | **"Savoir ce qui s'est passé et qui l'a fait"** | Audit trail complet : qui a fait quoi, quand, depuis quel appareil — sur toute l'application. Ce n'est pas une feature Premium — c'est la fondation de la traçabilité Core. | Universel : sans audit trail, aucune des 3 features "preuve" ne tient |

> **Règle de fer :** Ces 8 jobs constituent le périmètre minimum du Core Standard. Aucune feature qui ne sert pas ces jobs ne doit y entrer. Aucune feature qui sert ces jobs ne doit être conditionnée à un module Premium.

### Jobs SPÉCIFIQUES Blandine → Premium Opt-In

Ces jobs sont **exclusifs à Blandine** ou à une minorité de cas complexes. Ils justifient le tier Premium et le pricing 40K FCFA/mois. Ils ne doivent **jamais** être des prérequis au Core Standard.

| # | Job | Traduction feature Premium | Pourquoi c'est Blandine-spécifique |
|---|-----|---------------------------|-------------------------------------|
| 1 | **"Distinguer perte naturelle de vol"** | Taux de Frotte paramétrable par variété (% perte attendue par jour/semaine) + rapport pertes catégorisées | Uniquement pertinent pour les produits frais périssables — inutile pour boissons ou cosmétiques |
| 2 | **"Transformer mes conditionnements sans perte"** | Conversion Vrac→Sachet : "split" d'une unité mère en N sous-unités, stock recalculé automatiquement | Propre au commerce vrac épices/céréales. Pas un besoin universel. |
| 3 | **"Prioriser la vente avant que ça pourrisse"** | Code couleur fraîcheur J0/J+1/J+2 par catégorie produit, visible au POS | Produits frais uniquement. Boissons et cosmétiques ont des durées de vie trop longues pour que ça change la vente quotidienne. |
| 4 | **"Responsabiliser chaque employé sur sa phase"** | Sign-off numérique à chaque étape du workflow (réception, mise en rayon, appro) — qui a validé quoi quand | Blandine a 8 phases avec 3 rôles distincts. Boissons n'a pas de workflow multi-phases. |
| 5 | **"Commander en interne sans chaos WhatsApp"** | Circuit de réappro interne : commercial → gestionnaire → Blandine avec statuts et traçabilité | Uniquement pertinent quand il y a des niveaux hiérarchiques distincts + volume suffisant pour justifier la formalisation |
| 6 | **"Recevoir mon rapport sans demander"** | Résumé quotidien push/WhatsApp automatique à heure fixe (CA, pertes, produits à commander) | Blandine est souvent absente. Boissons est présent — il voit sa caisse en direct. |
| 7 | **"Valider la réception avant de mettre en stock"** | Phase QC gestionnaire : réception confirmée avec quantité + qualité avant entrée en stock rayon | Produits frais : une palette de tomates peut être reçue en mauvais état. Pour boissons, la réception est binaire (ça arrive ou pas). |

> **Règle d'architecture :** Chacun de ces jobs est un **module opt-in activable dans la config tenant**. L'activation n'est pas conditionnée au plan tarifaire dans le code — c'est une règle commerciale, pas une règle technique. Ça permet de faire évoluer le packaging sans toucher au code.

### Point of View Statements (x3)

**Format :** [Utilisateur] a besoin de [besoin réel] parce que [insight profond]

---

**POV 1 — Blandine (Distribution Premium)**

> Blandine, propriétaire d'une boutique gros & détail de produits frais avec 5 employés répartis sur 8 phases de workflow, **a besoin de savoir en temps réel qui a fait quoi dans chaque étape — avec preuve** — parce que ses pertes financières sont actuellement ni chiffrables ni attribuables, et qu'elle gère sa boutique dans l'anxiété permanente de ne pas savoir si c'est du vol, de la négligence, ou une perte naturelle inévitable.

**Le vrai insight :** Blandine ne paie pas pour "gérer son stock". Elle paie pour **ne plus avoir à choisir entre faire confiance à ses employés et perdre de l'argent**. Ce que Scalario lui vend, c'est la capacité de faire les deux.

---

**POV 2 — Vendeur Boissons/Divers (Retail Standard)**

> Le vendeur boissons avec 2-3 employés et un stock simple **a besoin d'une clôture de journée en moins de 5 minutes qui lui donne une certitude sur son CA et ses écarts** — parce que son problème n'est pas l'absence d'outil, c'est l'absence de certitude quotidienne : il finit chaque journée sans vraiment savoir s'il a bien fait, mal fait, ou s'est fait voler.

**Le vrai insight :** Son cahier ne lui manque pas fonctionnellement. Ce qui lui manque, c'est **la confiance dans le chiffre du soir**. Scalario ne lui vend pas un outil — il lui vend la fin du doute quotidien.

---

**POV 3 — Vendeur Chimique/Cosmétique (Retail Standard+)**

> Le vendeur de produits chimiques et cosmétiques avec 3-5 employés et un catalogue à variantes multiples (taille/couleur/parfum) **a besoin de suivre simultanément ses stocks par SKU, ses créances clients actives, et ses dates de péremption à risque** — parce qu'il jongle actuellement avec trois carnets parallèles pour un problème qui, non résolu, lui coûte des surventes, des pertes sur produits expirés, et des créances jamais récupérées.

**Le vrai insight :** Sa douleur n'est pas "je n'ai pas d'outil". C'est **"j'ai un outil différent pour chaque problème et aucun ne parle aux autres"**. Scalario lui vend l'unification, pas la gestion.

### How Might We Questions → FRs PRD v7

Chaque HMW est tagué avec sa **cible PRD** : `[CORE]` = Core Standard non-négociable / `[PREMIUM]` = module opt-in Blandine / `[STD+]` = extension Standard pour cosmétique.

#### Groupe A — Arrêt de caisse & réconciliation

- `[CORE]` HMW faire un arrêt de caisse en < 5 minutes qui réconcilie automatiquement stock théorique et CA réel, sans que le propriétaire ait besoin de compter ?
- `[CORE]` HMW rendre l'écart de caisse immédiatement visible avec le montant exact et l'heure à laquelle il s'est produit ?
- `[CORE]` HMW permettre au propriétaire de valider la clôture depuis son téléphone à distance, avec une seule action ?
- `[PREMIUM]` HMW présenter l'arrêt de caisse Blandine en 3 niveaux (commercial / gestionnaire / propriétaire) sans que ça ressemble à 3 étapes séparées ?

#### Groupe B — Traçabilité & responsabilité par rôle

- `[PREMIUM]` HMW aider Blandine à prouver qu'une perte est naturelle (Frotte) et non un vol, sans confrontation avec ses employés ?
- `[PREMIUM]` HMW rendre visible la chaîne de responsabilité d'un produit depuis sa réception jusqu'à sa vente, en un seul écran ?
- `[CORE]` HMW donner au propriétaire un historique de qui a vendu quoi, quand, filtrable par employé en moins de 3 taps ?
- `[PREMIUM]` HMW permettre à chaque employé de "signer" numériquement sa phase du workflow sans que ça alourde son usage quotidien ?

#### Groupe C — Stock & alertes

- `[CORE]` HMW alerter le bon employé (pas juste le propriétaire) quand un produit atteint son seuil minimum ?
- `[CORE]` HMW permettre à un non-technicien de configurer un seuil d'alerte par produit en moins de 30 secondes ?
- `[PREMIUM]` HMW transformer la conversion Vrac→Sachet en une opération en 1 tap, avec recalcul automatique du stock ?
- `[PREMIUM]` HMW rendre le code couleur fraîcheur visible directement dans le POS au moment de la vente, sans navigation supplémentaire ?
- `[STD+]` HMW alerter sur les produits dont la date de péremption est dans les 30 jours, depuis un tableau de bord — sans que l'utilisateur ait à chercher ?

#### Groupe D — Dashboard propriétaire & contrôle à distance

- `[CORE]` HMW donner au propriétaire une vue synthétique de sa journée (CA, stock critique, clôture) accessible en < 10 secondes depuis la notification ?
- `[CORE]` HMW envoyer automatiquement un résumé quotidien au propriétaire sans qu'il ait à ouvrir l'application ?
- `[PREMIUM]` HMW présenter le circuit de réappro interne (commercial → gestionnaire → Blandine) comme une liste de tâches simple, pas un workflow complexe ?

#### Groupe E — Catalogue & variantes

- `[STD+]` HMW gérer 10 variantes d'un même produit (taille/couleur/parfum) avec un seul stock par SKU, sans multiplier les fiches produit ?
- `[STD+]` HMW afficher le solde de crédit d'un client régulier automatiquement au moment où il passe en caisse ?
- `[STD+]` HMW valoriser le stock total en temps réel sans que l'utilisateur ait à demander un rapport ?

#### Groupe F — Offline & onboarding

- `[CORE]` HMW garantir qu'aucune donnée n'est perdue lors d'une coupure internet, avec une synchronisation silencieuse au retour de connexion ?
- `[CORE]` HMW réduire la configuration initiale (produits, rôles, alertes) à moins de 30 minutes pour un non-technicien, seul, sans Carlos ?

### Key Insights

1. **L'arrêt de caisse est le Point de Vérité quotidien.** C'est le moment où la valeur de Scalario est la plus immédiatement perceptible pour les 3 personas. C'est l'écran à designer en priorité absolue — il doit être parfait avant la démo Blandine.

2. **La responsabilité par rôle est l'innovation clé, pas le stock.** Gérer un stock, n'importe quelle caisse enregistreuse le fait. Lier chaque mouvement de stock à un rôle, une heure, un contexte — c'est ce qui transforme "je pense qu'on me vole" en "voici exactement qui, quand, combien". C'est le vrai différenciateur.

3. **L'offline-first n'est pas une feature de différenciation — c'est la condition de confiance.** Si l'app plante ou perd des données à chaque coupure d'internet, aucun des 3 personas ne lui confiera sa caisse réelle. Le offline n'est pas dans le marketing deck — c'est la fondation sur laquelle tout le reste repose.

4. **Les 3 personas ont des déclencheurs de paiement distincts :**
   - **Blandine :** résolution d'une douleur existante qui lui coûte de l'argent aujourd'hui — elle paie pour stopper une hémorragie
   - **Boissons :** commodité + certitude — il paie pour dormir sans s'inquiéter de sa caisse
   - **Cosmétique :** précision + unification — il paie parce que ses 3 carnets ne parlent pas entre eux

5. **L'onboarding est un produit à part entière.** Ces 3 personas n'ont pas de département IT. Scalario ne peut pas supposer qu'ils savent configurer des rôles, des produits, des alertes. Si l'onboarding prend plus de 30 minutes sans Carlos présent, la rétention sera faible — même si le produit est excellent.

6. **Les écrans Core sont purs et prévisibles. L'AI a son espace dédié.** Principe UX structurant découlant du pattern GenUI (D11) : un utilisateur qui ouvre l'écran POS, Stock, ou Caisse voit exactement le même écran qu'il soit connecté ou non, que l'AI soit disponible ou non. Les écrans Core ne contiennent aucun élément UI conditionnel à la disponibilité d'un service externe. L'AI — et tout ce qu'elle génère dynamiquement — vit dans un panel/command bar dédié que l'utilisateur ouvre intentionnellement. Cette séparation n'est pas une contrainte technique : c'est ce qui garantit la confiance offline-first et évite la dette UX de l'IR-9.

7. **Un module Core = N secteurs déverrouillés. Ce principe change la priorisation du backlog.** La logique Flywheel : Carlos construit des modules génériques, les intégrateurs configurent des templates sectoriels dessus. Exemple : un module "Gestion Documentaire" générique → templates pour avocats, notaires, hôpitaux, administration, RH avancé — sans aucun développement sectoriel. Conséquence directe sur la sélection du Core Standard : la question n'est pas "quelle feature veut Blandine ?" mais "quel module déverrouille le plus grand nombre de secteurs adressables ?". Les deux critères ne sont pas toujours contradictoires, mais quand ils le sont, le Flywheel prime sur les demandes individuelles. Blandine reste le beachhead ; les modules qui la servent doivent aussi servir 10 autres secteurs.

---

## 💡 IDEATE: Prioritization & Feature Decisions

### Feature Justification — "La Feature qui Justifie SEULE le Paiement"

**La question :** Si un persona ne devait retenir qu'une seule raison de payer, laquelle serait-elle ? Cette feature doit être dans la démo. Tout le reste est secondaire.

---

**Blandine — 40 000 FCFA/mois**

> **La feature : Taux de Frotte + Responsabilité par Phase**

Challenge de l'hypothèse intuitive : on pourrait croire que c'est "l'arrêt de caisse automatique". Faux. L'arrêt de caisse automatique, n'importe quelle caisse enregistreuse à 5 000 FCFA le fait approximativement. Ce que Blandine ne peut résoudre avec aucun outil existant, c'est **prouver que la disparition de 2kg de tomates est de la déshydratation et non du vol**. Ce conflit lui coûte de l'énergie managériale quotidienne, détériore ses relations employés, et représente des pertes non quantifiées depuis des années.

Le Taux de Frotte paramétrable par variété avec sign-off de responsabilité par phase — **aucun outil en UEMOA ne fait ça**. C'est le seul argument que Blandine ne peut pas entendre ailleurs. Tout le reste (arrêt de caisse, dashboard) est du confort. Ça, c'est de la survie économique.

---

**Vendeur Boissons — ~15 000-20 000 FCFA/mois**

> **La feature : Arrêt de Caisse Automatique avec détection d'écart**

Challenge de l'hypothèse : on pourrait croire que c'est "les alertes de stock". Mais les alertes de stock, il les simule avec un coup d'œil quotidien — son stock est simple et visible. Ce qu'il ne peut pas faire : **réconcilier sa caisse en fin de journée sans 45 minutes de comptage et recomptage, et savoir si l'écart vient d'une erreur ou d'un vol**. C'est la douleur qu'il refoule chaque soir. Scalario lui donne la preuve, pas une impression.

---

**Vendeur Cosmétique — ~20 000-25 000 FCFA/mois**

> **La feature : Gestion des variantes avec stock individuel par SKU**

C'est le problème qu'aucun cahier, aucun Excel simple ne résout correctement : **1 produit × 5 tailles × 3 couleurs = 15 SKUs distincts qui se vendent à des rythmes différents**. La confusion entre variantes lui coûte des surventes (promettre une taille qu'il n'a plus), des surstocks (acheter une taille dont il a déjà trop), et une image de commerçant peu fiable auprès de ses clients réguliers. C'est le problème quotidien que son Excel ne résout pas et que Scalario résout nativement.

### Blandine Démo V1 (< 30j) vs Post-Signature vs Reportable

> **Challenge critique :** Carlos pense probablement que Blandine paie pour les features complexes (Taux de Frotte, Vrac→Sachet). L'hypothèse à challenger : **elle paie pour la paix d'esprit, pas pour la feature**. Le Taux de Frotte est un moyen. La fin, c'est "je sais ce qui se passe dans ma boutique quand je ne suis pas là". Si la démo montre ça clairement, elle signe. Le Taux de Frotte peut être amélioré post-signature sans risquer le closing.

---

#### DÉMO V1 — DOIT FONCTIONNER PARFAITEMENT (< 30 jours)

Ces features créent le "moment de vérité" de la démo. Sans elles, pas de signature.

| Feature | Pourquoi c'est bloquant pour la démo |
|---------|--------------------------------------|
| POS multi-rôle (gestionnaire / commercial / Blandine) | Blandine doit se voir dans le système avec ses propres permissions |
| Arrêt de caisse journalier — réconciliation 3 niveaux | C'est le pain point #1 — doit être démontré, pas décrit |
| Circuit de réappro interne (commercial → gestionnaire → Blandine) | Elle doit voir son workflow existant digitalisé, pas un workflow générique |
| Dashboard propriétaire mobile — synthèse du jour | Elle doit se projeter en train de recevoir ça sur son téléphone quand elle est absente |
| Taux de Frotte — au moins la configuration | Montrer qu'on peut paramétrer son taux de déshydratation par produit — même si le calcul n'est pas 100% automatisé |

#### POST-SIGNATURE — LIVRABLE DANS LES 30 PREMIERS JOURS D'UTILISATION

Ces features doivent être prêtes avant que Blandine commence à utiliser le système en production. Elles ne sont pas bloquantes pour signer, mais leur absence pendant l'utilisation réelle = risque de churn.

| Feature | Justification |
|---------|--------------|
| Vrac→Sachet configuré sur ses produits réels | Elle en a besoin dès le premier jour de vraie utilisation. Si H2-5b (NLP produit) est disponible à ce moment, la création se fait en langage naturel — sinon, via formulaire de split. |
| Alertes stock d'alerte par variété | Sans ça, elle revient au WhatsApp pour les réappros urgentes |
| Rapport de pertes catégorisées (Frotte / mévente / vol déclaré) | C'est la promesse implicite du Taux de Frotte — sans le rapport, la feature est incomplète |
| Résumé quotidien push notification | Peut être push d'abord, WhatsApp après — mais doit exister J+7 maximum |

#### REPORTABLE SANS RISQUE — 3 À 6 MOIS

Ces features ont de la valeur mais leur absence n'impacte pas la rétention à court terme. Blandine peut vivre sans elles pendant 3-6 mois si le reste fonctionne.

| Feature | Pourquoi c'est différable |
|---------|--------------------------|
| WhatsApp Business API (résumé quotidien) | Push notification remplace le besoin immédiat — WhatsApp est un upgrade, pas une condition |
| Historique analytique par employé sur 3-6 mois | Pas de données historiques au démarrage de toute façon |
| Code couleur fraîcheur au POS | Valeur réelle mais non-urgente — Blandine gère déjà ça à l'œil |
| Inventaire comparatif automatisé | L'inventaire hebdomadaire peut être semi-manuel les premiers mois |
| Prédiction de commande basée sur l'historique | Nécessite des données — pas applicable avant 3 mois d'utilisation réelle |

#### HORS SCOPE V1 — NE PAS PROMETTRE

| Feature | Raison |
|---------|--------|
| Intégration Wave/Orange Money | Haute valeur mais complexité technique — ne pas promettre avant d'avoir validé l'API |
| Module analytique avancé | H3 — aucune donnée suffisante avant 6-12 mois |
| Multi-boutiques | H3 — Blandine n'a qu'une boutique |

### Generated Ideas

26 idées générées, toutes issues des HMW questions :

**Caisse & réconciliation**
1. Arrêt de caisse guidé en wizard 3 étapes : clore session POS → confronter stock → valider et signer
2. Confrontation automatique stock théorique vs CA déclaré avec affichage écart en FCFA
3. Validation propriétaire distance — 1 tap depuis la notification push
4. Arrêt de caisse 3 niveaux Blandine : chaque rôle valide sa couche avant le suivant
5. Historique des clôtures avec comparatif semaine sur semaine

**Traçabilité & responsabilité**
6. Sign-off numérique par phase : chaque employé confirme sa phase avec timestamp et nom
7. Rapport de pertes catégorisées : Frotte automatique / mévente déclarée / vol déclaré / erreur
8. Timeline produit : de la réception à la vente, chaque mouvement horodaté et attribué
9. Vue responsabilité par employé : total mouvements, total ventes, total pertes déclarées sur période

**Stock & alertes**
10. Seuil d'alerte par produit configurable en 1 tap depuis la fiche produit
11. Alerte push ciblée : le bon employé reçoit l'alerte, pas tout le monde
12. Taux de Frotte paramétrable par variété : % perte attendue/jour configurable
13. Conversion Vrac→Sachet : "split" d'une unité mère en N sous-unités, stock recalculé
14. Code couleur fraîcheur au POS : J0 vert / J+1 orange / J+2 rouge, visible sans navigation
15. Alerte péremption paramétrable J-30/J-7/J-1 par catégorie produit

**Dashboard & contrôle à distance**
16. Dashboard propriétaire "1 écran" : CA jour, écarts, alertes critiques, statut clôture
17. Push notification quotidienne automatique à heure fixe (configurable)
18. WhatsApp Business API : même contenu que push, pour les propriétaires qui préfèrent WhatsApp
19. Vue "boutique en direct" : qui est connecté, quelle session est ouverte, dernière vente

**Catalogue & clients**
20. Arbre produit parent/variantes : 1 fiche parent, N variantes enfants avec stock individuel
21. Crédit client : solde visible au moment de la vente, déductible ou à reporter
22. Valorisation stock temps réel : valeur totale du stock en FCFA, toujours à jour
23. Import produits en masse depuis Excel/CSV pour l'onboarding initial

**Circuit de commande interne**
24. Circuit réappro interne : commercial soumet → gestionnaire valide → Blandine approuve
25. Formulaire de demande de réappro simplifié : le commercial demande sans accéder au stock global

**Onboarding & autonomie**
26. Wizard onboarding guidé : type d'activité → configuration produits → création rôles → première vente test

### Top Concepts → PRD v7 Decisions

Trois concepts émergent du clustering des 26 idées. Chaque concept est un ensemble cohérent de features qui adresse un job dominant.

---

**Concept 1 — "Certitude Quotidienne"** → Core Standard

Idées : #1, #2, #3, #10, #11, #16, #17, #22
Le concept central du Standard : à la fin de chaque journée, le propriétaire sait exactement où il en est. Stock, caisse, écarts — en 5 minutes, depuis son téléphone. C'est ce qui justifie le passage du cahier à Scalario pour Boissons et Cosmétique.

Features constitutives : arrêt de caisse guidé, confrontation automatique, dashboard 1 écran, push quotidien, alertes stock, historique ventes par employé.

---

**Concept 2 — "Traçabilité par Rôle"** → Module Premium Blandine

Idées : #4, #6, #7, #8, #12, #13, #14, #24, #25
Le concept Premium : chaque centime qui disparaît est attribuable. Chaque employé sait qu'il est responsable de sa phase. Les pertes naturelles ne sont plus des accusations implicites. C'est ce qui justifie le pricing Blandine à 40K FCFA/mois.

Features constitutives : sign-off par phase, Taux de Frotte, Vrac→Sachet, circuit réappro interne, code couleur fraîcheur, rapport pertes catégorisées.

---

**Concept 3 — "Catalogue Précis"** → Extension Standard+ Cosmétique

Idées : #15, #20, #21, #22
Le concept Standard+ : le catalogue reflète exactement la réalité du commerce — variantes, crédit client, péremptions. Pas de surventes, pas de créances oubliées, pas de produits expirés jetés sans alerte.

Features constitutives : arbre produit parent/variantes, crédit client avec solde POS, alertes péremption, valorisation stock temps réel.

---

**Décision de développement PRD v7 :**

| Concept | Sprint PRD v7 | Critère de "done" |
|---------|--------------|-------------------|
| Certitude Quotidienne | Priorité absolue — avant démo Blandine | Arrêt de caisse + dashboard propriétaire fonctionnels sur données réelles |
| Traçabilité par Rôle | Parallèle — livrable démo Blandine (au moins configurable) | Circuit réappro + Taux de Frotte paramétrable démontrables |
| Catalogue Précis | Post-signature Blandine — avant conversion testeurs | Variantes + crédit client fonctionnels pour démo cosmétique |

---

## 🔭 EXERCISE 2 — Future Personas Architecture Foresight

### Persona 4 — Restaurateur/Maquis (H2, 12-18 mois)

**Contexte :** Production + vente sur place. Menu du jour. Tables ou comptoir. Gestion ingrédients → plats. H2, 12-18 mois.

#### Questions UX critiques à anticiper

1. **Comment le POS distingue-t-il un "produit fabriqué" d'un produit acheté-revendu ?**
   Un plat de riz sauce n'est pas un article en stock — c'est le résultat de la consommation de riz + sauce + légumes. L'architecture POS actuelle (vente = décrément d'un SKU) ne peut pas gérer ça sans une couche d'abstraction entre "ce qui est vendu" et "ce qui est prélevé en stock".

2. **Comment le POS gère-t-il une commande "table 5" avec des articles ouverts dans le temps ?**
   La vente en restauration est une commande OUVERTE (le client commande, puis reccommande, puis paie à la fin). Ce n'est pas une transaction instantanée comme au POS retail. L'état "session ouverte par table" n'existe pas dans le modèle actuel.

3. **Comment les ingrédients sont-ils décrémentés automatiquement à la fabrication ou à la vente d'un plat ?**
   Si "1 riz sauce" = 200g riz + 50cl sauce + 2 tomates, alors vendre 10 riz sauce doit décrémenter 2kg de riz, 5L de sauce, 20 tomates — pas "10 unités de riz sauce".

#### Ce qui doit être prévu dans l'architecture SANS être développé

- **`productType` enum dans le modèle Produit :** `SIMPLE | COMPOSED | RECIPE_BASED` — une seule colonne nullable aujourd'hui. Sans elle, ajouter la restauration = migration breaking sur toute la table produits.
- **`OrderSession` avec état :** `OPEN | CLOSED | PAID` — distinct de la session POS actuelle. Le concept de "commande de table ouverte" doit avoir une entité propre, même vide, pour ne pas confluer avec la logique de vente directe.
- **Ne pas hardcoder "vente = décrément direct du SKU vendu"** — la couche qui relie une ligne de vente à un mouvement de stock doit être paramétrable (pour les produits composés, le décrément sera sur les ingrédients, pas sur le produit fini).

#### Décisions irréversibles à éviter

- ❌ **Hardcoder `saleItemId === stockItemId`** dans la logique de décrément — c'est la décision la plus destructrice pour la restauration H2.
- ❌ **Nommer le concept de "session POS" et "session de table" avec la même entité** — une session POS ferme à la clôture de caisse ; une session de table ferme quand le client paye. Ce ne sont pas le même objet.

### Persona 5 — Grossiste Distributeur (H2, 12-24 mois)

**Contexte :** Gère un dépôt. Livre des retailers (dont Blandine). Multi-clients, multi-tournées, facturation différée. H2, 12-24 mois.

#### Questions UX critiques à anticiper

1. **Comment gérer des commandes B2B entre deux clients Scalario ?**
   Si Blandine (retailer sur Scalario) commande à son distributeur (aussi sur Scalario), qui initie la commande ? Comment le distributeur voit-il toutes ses commandes entrantes de tous ses clients retailers ? L'architecture actuelle ne prévoit pas de cross-tenant reference dans les orders.

2. **Comment la livraison est-elle confirmée par le retailer ?**
   Le distributeur dit "livré" — mais le retailer doit confirmer la réception (quantité, qualité). Sans confirmation côté retailer, le distributeur n'a pas de preuve. Quelle est l'UX de la confirmation de livraison sur le téléphone du retailer ?

3. **Comment les factures différées et paiements en plusieurs fois sont-ils trackés sans polluer la caisse journalière du distributeur ?**
   Le distributeur livre aujourd'hui et facture à J+30. Sa caisse du jour ne reflète pas ces flux. Il a besoin d'une vue "créances clients B2B" distincte de sa caisse quotidienne.

#### Ce qui doit être prévu dans l'architecture SANS être développé

- **`clientType` enum sur l'entité Client :** `INDIVIDUAL | BUSINESS` — une colonne nullable aujourd'hui. Sans elle, distinguer un client particulier d'un client entreprise (avec SIRET, adresse livraison, conditions paiement) nécessite une refonte du modèle Client.
- **`deliveryStatus` sur les orders :** `PENDING | DISPATCHED | DELIVERED | CONFIRMED_BY_RECEIVER` — même si aujourd'hui l'app n'utilise que PENDING/COMPLETED, prévoir les états intermédiaires évite d'avoir à migrer le champ quand la livraison devient un vrai workflow.
- **Séparation naming "commande interne" vs "commande B2B" :** Le circuit de réappro de Blandine (H1) et la commande inter-tenants (H3) utilisent le même concept logique mais ne sont PAS la même entité. Le nommer clairement dans le code (`InternalRequisition` vs `B2BOrder`) évite la confusion future.

#### Décisions irréversibles à éviter

- ❌ **Orders sans référence à un `tenantId` externe optionnel** — si chaque order est strictement fermé à un seul tenant, le B2B inter-tenants nécessite une architecture parallèle au lieu d'une extension.
- ❌ **Assumer que "un client = un utilisateur final de l'app"** — pour le B2B, "le client" est une entreprise avec plusieurs contacts, une adresse de livraison, des conditions de paiement spécifiques. Le modèle Client doit pouvoir représenter les deux.

### Persona 6 — Intégrateur Local (H2, 6-12 mois)

**Contexte :** Informaticien ou formateur qui installe Scalario chez les clients. Gère plusieurs clients en parallèle. **H2, 6-12 mois — le persona futur le plus urgent à anticiper.**

#### Questions UX à anticiper

1. **Comment l'intégrateur configure-t-il un nouveau tenant sans accès au backend Scalario ?**
   Aujourd'hui Carlos crée les tenants manuellement. Quand le premier intégrateur arrive, il a besoin d'un panneau de provisioning autonome — créer un tenant, configurer ses modules, définir ses rôles, charger ses produits — sans appeler Carlos. C'est la condition sine qua non du canal intégrateur.

2. **Comment l'intégrateur surveille-t-il l'état de santé de tous ses clients en même temps ?**
   Un intégrateur avec 10 clients actifs doit savoir, depuis une seule vue : qui a eu une erreur de sync hier, qui n'a pas fait d'arrêt de caisse depuis 3 jours, qui a des sessions bloquées. Sans ça, le support client est réactif (le client appelle quand ça plante) au lieu de proactif.

3. **L'AI est maintenant en 3 niveaux distincts avec des utilisateurs cibles différents — comment les distinguer architecturalement ?**
   La stratégie a précisé une séquence AI en 3 paliers :
   - **H2-5a (Mois 3-6, PRIORITÉ #1 AI) :** Import Excel/CSV → catalogue produits configuré automatiquement. Utilisateur cible : **le client lui-même** (ou l'intégrateur qui l'onboard). Réduit l'onboarding catalogue de 3h à 10 min.
   - **H2-5b (Mois 3-6) :** Création produit en langage naturel — "j'achète du piment en sac 5kg à 3000 FCFA, je vends en sachets 50g à 150 FCFA". Résout nativement le cas Vrac→Sachet sans formulaire complexe. Utilisateur cible : **client ET intégrateur**.
   - **H2-5c (Mois 6-12) :** Config Wizard entreprise complet — rôles, modules, workflows, permissions en langage naturel. Utilisateur cible : **l'intégrateur d'abord**, pour déployer chez son client en 30 min au lieu de 4-8h.

   La question architecturale n'est plus "wizard pour qui ?" mais "ces 3 niveaux partagent-ils une infrastructure commune ou sont-ils 3 features indépendantes ?" La réponse : ils partagent la même couche LLM + structured output, mais opèrent sur des domaines différents (catalogue / workflow / entreprise). Ne pas les coupler.

#### Architecture à anticiper SANS développer

- **`IntegratorRole` dans le RBAC :** un niveau d'accès au-dessus du "propriétaire tenant" mais en dessous de l'admin Scalario. Peut voir et configurer plusieurs tenants, ne peut pas modifier la plateforme. Une ligne dans le système de permissions — à poser maintenant pour ne pas refactoriser tout le RBAC en H2.
- **Tenant provisioning programmatique :** même si Carlos crée les tenants manuellement aujourd'hui, l'action de provisioning doit être une fonction isolée (pas du SQL ad hoc), de sorte qu'elle soit exposable via une interface intégrateur sans toucher à la logique core.
- **`TenantHealthMetrics` comme concept :** une table ou vue qui expose — dernier sync, dernière transaction, erreurs actives, nb users actifs sur 7j. Les données sont déjà dans le système ; c'est juste une question d'exposition. Le schéma de données doit pouvoir répondre à cette requête sans calcul complexe.
- **Couche LLM + structured output isolée :** H2-5a, H2-5b et H2-5c partagent tous la même mécanique (prompt → LLM → JSON structuré → action dans Scalario). Cette couche doit être un service indépendant, pas du code inline dans chaque feature. Un `AIService` réutilisable qui prend un contexte et retourne un objet métier. Ne pas refaire cette plomberie 3 fois.
- **Format d'import catalogue standardisé :** pour que H2-5a fonctionne sur n'importe quel Excel client, il faut que le modèle produit Scalario soit documenté comme un schema d'import (colonnes attendues, variantes, unités). Ce schema doit être défini avant que l'AI soit développée — l'AI mappe vers ce schema, pas vers une structure ad hoc.

#### Décisions irréversibles à éviter

- ❌ **H2-5c (Config Wizard entreprise) designé pour le client final non-technicien en priorité.** H2-5a et H2-5b sont légitimement des outils clients (import Excel, description NLP d'un produit — tout le monde peut faire ça). Mais H2-5c configure les rôles, les workflows, les permissions d'une entreprise entière — c'est l'intégrateur qui doit être au volant, pas le client. Confondre les deux personas pour ce niveau = produit inutilisable pour les deux.
- ❌ **RBAC sans slot intégrateur** dès V1 — ajouter un niveau d'autorisation entre propriétaire et super-admin après coup nécessite de revoir toutes les vérifications de permissions existantes.
- ❌ **H2-5a/b développés comme features monolithiques** liées à un écran spécifique — si l'import Excel et le NLP produit sont couplés à l'UI d'un seul écran, l'intégrateur ne peut pas les réutiliser dans son propre workflow de déploiement. Ce doit être des actions appelables depuis plusieurs contextes (onboarding wizard, fiche produit, panneau intégrateur).

### Persona 7 — Commerçant Abidjan/Dakar (H2, 18-24 mois)

**Contexte :** Même profil que les personas 1-3 mais à Abidjan ou Dakar — pouvoir d'achat plus élevé, plus tech-savvy, attentes UX plus élevées. Contexte réglementaire OHADA identique. H2, 18-24 mois.

#### Questions UX à anticiper

1. **Qu'est-ce qui change réellement dans l'interface pour CI/SN ?**
   La réponse intuitive est "la langue" — mais l'application est déjà en français. La vraie question est : les commerçants Abidjan/Dakar ont des attentes UX plus proches d'applications comme Wave ou Moov — animations fluides, design soigné, zéro friction. L'interface qui satisfait Blandine à Ouaga (fonctionnelle, directe) peut sembler grossière à un commerçant d'Abidjan habitué à des apps fintech bien designées.

2. **La localisation va-t-elle au-delà de la langue ?**
   Oui. Taux de TVA différents (CI : 18%, BF : 18% — similaires en OHADA, mais les règles de facturation peuvent diverger). Devises identiques (XOF), mais les formats d'affichage des montants peuvent varier. Surtout : les intégrateurs locaux CI/SN ne connaîtront pas le contexte Burkinabè — l'app doit être configurable par `countryCode` sans toucher au code.

3. **Le persona Abidjan est-il prêt à payer plus pour une meilleure UX ?**
   Probablement oui. Ce qui justifie une réflexion sur le pricing CI/SN — pas forcément des features différentes, mais un positionnement premium possible avec des attentes UX plus élevées comme argument.

#### Architecture à anticiper SANS développer

- **`countryCode` dans la config tenant :** un champ qui drive les règles fiscales, le formatage des montants, les labels légaux (reçu OHADA vs reçu local). Une colonne aujourd'hui = expansion multi-pays sans toucher au code plus tard.
- **Toutes les strings UI dans des fichiers i18n dès maintenant :** le coût de refactoriser les strings hardcodées après 12 mois de dev est 10× plus élevé qu'un i18n propre dès le départ. Même si l'app reste en français, la structure doit permettre `fr-BF`, `fr-CI`, `fr-SN` comme variantes.
- **Règles fiscales dans la configuration tenant, jamais dans le code :** `taxRate`, `taxLabel`, `invoiceFooterText` — tous configurables par tenant. Une règle fiscale hardcodée est une dette technique garantie.

#### Décisions irréversibles à éviter

- ❌ **Strings hardcodées dans le code Flutter/NestJS** — toute string visible par l'utilisateur doit passer par un système de localisation. C'est le seul point technique de cette section qui crée une dette irréversible si ignoré maintenant.
- ❌ **Règles fiscales en dur dans la logique de calcul** — `if (country === 'BF') taxRate = 0.18` dans le code est un anti-pattern. La règle doit venir de la config tenant.

### Persona 8 — Propriétaire Multi-Boutiques (H3, 24-36 mois)

**Contexte :** 3-5 boutiques dans différents quartiers ou villes. Vue consolidée de tout son empire. H3, 24-36 mois.

#### Questions UX à anticiper

1. **Comment consolider POS + Stock de 5 boutiques dans un seul dashboard sans noyer le propriétaire ?**
   La tentation technique est d'agréger toutes les données dans un seul tableau de bord. Le vrai défi UX : le propriétaire multi-boutiques ne veut pas voir 5× plus de données — il veut voir les **exceptions** (quelle boutique a un écart de caisse, laquelle est en rupture). La vue consolidée doit être une vue d'alertes, pas une vue de données brutes.

2. **Comment les transferts inter-boutiques fonctionnent-ils dans le modèle de données ?**
   Un transfert de stock de la boutique A vers la boutique B est à la fois une **sortie** du stock A et une **entrée** dans le stock B, liées par un même document de transfert. Ce n'est ni une vente ni un achat. Le modèle de mouvement de stock doit avoir un type `TRANSFER` avec une référence à l'entité source et destination.

3. **Une "boutique" est-elle une entité juridique séparée ou un point de vente d'une même entité ?**
   Décision structurelle critique. Si chaque boutique est une entité comptable séparée, la consolidation est comptable (fusion de bilans). Si c'est un point de vente d'une même entité, c'est juste une vue agrégée. Le modèle de données est radicalement différent. Cette décision doit être prise avant H3.

#### Architecture à anticiper SANS développer

- **`locationId` / `storeId` nullable sur TOUTES les transactions dès maintenant** — c'est la décision la plus critique et la moins coûteuse de cette liste. Un champ `storeId UUID nullable` sur chaque transaction = multi-boutiques activable par configuration plus tard. Sans ce champ, multi-boutiques = migration massive de toute la base.
- **`StockMovement.type` enum extensible :** `SALE | PURCHASE | ADJUSTMENT | TRANSFER | LOSS` — prévoir `TRANSFER` maintenant même s'il n'est pas utilisé. Les transferts inter-boutiques ne sont pas une vente et ne doivent pas apparaître dans le CA.
- **Vue "parent" dans la navigation :** même si elle est vide en V1, prévoir le slot dans l'arborescence UX pour une vue "multi-boutiques" évite de devoir restructurer la navigation en H3.
- **3 modèles de stock multi-boutiques — tous configurations, aucun développement custom :**
  - **Modèle A** — Stock indépendant par boutique + transferts inter-boutiques tracés avec approbation optionnelle. Usage : propriétaires multi-points de vente géographiquement séparés.
  - **Modèle B** — Dépôt central, boutiques consomment depuis le pool. Boutiques ne "possèdent" pas de stock. Usage : grossiste avec antennes, chaîne restauration cuisine centrale.
  - **Modèle C** — Hybride multi-niveaux (Dépôt National → Dépôt Régional → Boutique). Usage : distribution nationale, coopératives.

  Ces 3 modèles reposent sur l'architecture multi-entité existante + workflows inter-entités + `storeId` (D2). Les définir maintenant dans le data model évite de découvrir en H3 que l'architecture ne supporte que le Modèle A.

#### Décisions irréversibles à éviter

- ❌ **Transactions sans `storeId`** — c'est la dette technique la plus coûteuse de toute la roadmap H3. Un champ nullable aujourd'hui = zéro coût. Une migration de millions de transactions plus tard = semaines de travail et risque de perte de données.
- ❌ **Décider que "1 tenant = 1 boutique"** comme invariant dans la logique core — si cette hypothèse est hardcodée dans des règles métier, le multi-boutiques devient une refonte de l'architecture tenant entière.

### Persona 9 — PME Multi-Département (H3, 36+ mois)

**Contexte :** Entreprise avec RH + Comptabilité + Production + Stock. Chaque département a ses propres utilisateurs et workflows. H3, 36+ mois.

#### Questions UX à anticiper

1. **Comment les modules RH et Comptabilité s'intègrent-ils avec le POS actuel ?**
   Un module RH n'a pas de raison de connaître l'implémentation du POS. Mais une vente génère du CA qui impacte la comptabilité. Une dépense RH (paie) impacte la trésorerie. L'intégration ne doit pas être des dépendances directes entre modules — elle doit passer par des **events** : "sale.completed → comptabilité enregistre l'entrée", "payroll.processed → trésorerie enregistre la sortie".

2. **Comment l'approbation cross-département fonctionne-t-elle ?**
   Exemple : une dépense demandée par la production, validée par le comptable, approuvée par la direction. C'est exactement le circuit de réappro interne de Blandine — généralisé à N étapes, N rôles, N seuils de montant. La structure de Blandine en H1 **est** le cas particulier de ce workflow général. Si elle est hardcodée "3 rôles fixes", H3 est bloqué.

3. **Comment les droits d'accès cross-département sont-ils gérés ?**
   Un employé RH ne doit pas voir les données POS. Un comptable peut voir les totaux de vente mais pas les détails client. Un responsable production voit le stock matières premières mais pas la caisse. Le RBAC actuel (propriétaire/employé/gestionnaire) est insuffisant pour ce niveau de granularité.

#### Architecture à anticiper SANS développer

- **Architecture événementielle interne (event bus)** : chaque action significative (vente complétée, dépense validée, stock reçu) émet un event interne que d'autres modules peuvent consommer sans couplage direct. Même si en V1 il n'y a qu'un seul module, ne pas créer d'appels directs entre domaines — passer par des callbacks ou des hooks qui pourront devenir un vrai event bus en H3.
- **Workflow d'approbation générique dès le circuit Blandine :** construire la Phase 6 (circuit réappro commercial→gestionnaire→Blandine) comme un `ApprovalWorkflow` configurable avec `steps[]`, `approverRole[]`, `escalationRule` — même si en V1 les valeurs sont fixes. L'abstraction coûte 2h de design supplémentaire aujourd'hui et évite une refonte complète en H3.
- **`departmentId` nullable sur les utilisateurs et transactions :** même concept que `storeId` pour le multi-boutiques. Un champ nullable aujourd'hui = segmentation par département activable en H3 sans migration.

#### Décisions irréversibles à éviter

- ❌ **Circuit de commande interne Blandine hardcodé "3 rôles fixes"** — c'est la décision H1 qui a le plus d'impact sur H3. Si `steps = ['commercial', 'gestionnaire', 'owner']` est hardcodé dans la logique, tout workflow d'approbation H3 doit être réécrit de zéro. La structure doit être `steps: ApprovalStep[]` dès maintenant.
- ❌ **Modules qui s'appellent directement** (`posService.getSales()` depuis `accountingService`) — tout appel inter-module direct est une dépendance qui bloque la modularisation H3. Les modules doivent communiquer par interfaces ou events, jamais par import direct.

---

### Persona 10 — Expert-Comptable / Cabinet Comptable (H2 mid, 18-24 mois)

**Contexte :** Un cabinet comptable UEMOA gère 15 à 30 PME clientes. Ces entreprises sont obligées d'avoir un expert-comptable agréé (OHADA). Le comptable a besoin d'accéder aux données financières de ses clients pour établir les bilans, déclarations TVA, liasses SYSCOHADA. Avec Scalario, le programme H2-1b vise à faire du cabinet un canal d'acquisition (modèle Xero NZ) : le comptable recommande Scalario à ses clients ET utilise Scalario pour sa propre gestion.

**Pourquoi distinct du P6 Intégrateur :** L'intégrateur configure des tenants (write access sur la config). Le comptable lit des données financières de PLUSIEURS tenants clients (read-only, scoped au module comptabilité/finance). Ce sont deux modèles d'autorisation radicalement différents. Un intégrateur ne peut pas voir le CA d'un client (sécurité). Un comptable ne peut pas modifier les rôles d'un client (inapproprié). Les confondre dans le RBAC = faille de sécurité ou blocage fonctionnel.

#### Questions UX à anticiper

1. **Comment le comptable accède-t-il aux données financières d'un client sans avoir le login du client ?**
   La délégation d'accès doit être initiée PAR le client (il autorise son comptable), pas par le comptable (qui ne peut pas s'auto-attribuer l'accès). L'UX du côté client : "Autoriser mon comptable [email] à accéder à mes données financières". L'UX du côté comptable : son tableau de bord Scalario agrège toutes les autorisations actives.

2. **Comment le comptable distingue-t-il rapidement lequel de ses 20 clients a ses arrêts de caisse à jour, lequel a des incohérences stock/ventes, lequel est en retard ?**
   Le dashboard multi-clients du comptable n'est pas un simple listing. C'est un outil de priorisation : couleur rouge = anomalie à résoudre, vert = données propres. Sans ce signal visuel, le comptable passe 1h à vérifier chaque client au lieu d'intervenir sur les 2 qui ont vraiment un problème.

3. **Quelle est la granularité de l'accès délégué — le comptable voit-il TOUT ou seulement le module comptabilité ?**
   Un propriétaire de boutique ne veut probablement pas que son comptable voie ses données RH ou ses conversations avec les clients. L'accès délégué doit être scopé par module. Cette décision de design (scopes granulaires vs accès complet) affecte l'UX de la délégation côté client ET l'architecture du système d'autorisation.

#### Architecture à anticiper SANS développer

- **`DelegatedAccess` pattern dans le RBAC :** un tiers externe (comptable, auditeur, partenaire IMF futur) peut se voir déléguer un accès READ-ONLY scopé à des modules spécifiques d'UN tenant. L'autorisation est créée par le propriétaire du tenant, a une durée de vie et peut être révoquée. Mécanisme technique : token d'accès scopé (`tenantId + allowedModules[]`), distinct du JWT utilisateur standard. À ne pas confondre avec `IntegratorRole` (accès write config, multi-tenant, permanent via admin Scalario).
- **`ExternalPartnerPortal` comme surface distincte :** le comptable n'utilise pas l'app Flutter mobile du commerçant — il utilise une interface web (Next.js / web dashboard déjà prévu dans la stack). Cette surface existe déjà dans la feuille de route technique ; il faut juste que le contrat de données `tenant → finance module → read-only export` soit défini maintenant.
- **Audit trail sur les accès délégués :** chaque lecture par un partenaire externe doit être loggée (qui a accédé, quand, quel module). Non optionnel — c'est une obligation de confidentialité vis-à-vis du propriétaire du tenant.

#### Décisions irréversibles à éviter

- ❌ **RBAC conçu avec 2 types d'acteurs externes seulement (IntegratorRole + SuperAdmin)** sans prévoir un slot `DelegatedPartner`. Ajouter une 3e catégorie d'accès externe après coup = refactoring complet de toutes les vérifications de permissions. C'est le même IR que IR-6, appliqué à un acteur différent.
- ❌ **Module Comptabilité conçu comme un module "read-only de la caisse"** sans modèle de données propre. Si la comptabilité est une vue SQL sur les ventes, elle ne peut pas être scopée pour une délégation d'accès sécurisée. Le module Comptabilité doit avoir son propre espace de données (écritures, journaux, états) même si en V2 il ne fait que répliquer les données du POS.

---

## 🗺️ SYNTHÈSE: Carte des Décisions UX

### Décisions à Prendre MAINTENANT

Ces décisions doivent être prises **avant de finaliser le PRD v7** et **avant la démo Blandine**. Elles ont un coût nul ou très faible maintenant et un coût exponentiel si différées.

| # | Décision | Impact si différée | Persona débloqué |
|---|----------|--------------------|-----------------|
| **D1** | `productType` enum (`SIMPLE \| COMPOSED \| RECIPE_BASED`) dans le modèle Produit | Migration breaking sur toute la table produits en H2 | P4 Restauration |
| **D2** | `storeId UUID nullable` sur TOUTES les transactions (ventes, stocks, dépenses) | Migration massive de millions de lignes en H3 | P8 Multi-boutiques |
| **D3** | `countryCode` dans la config tenant, règles fiscales dans la config (jamais dans le code) | Refactoring complet de la logique fiscale pour CI/SN | P7 Abidjan/Dakar |
| **D4** | Toutes les strings UI dans des fichiers i18n (`fr-BF`, `fr-CI`, `fr-SN`) | Coût de localisation ×10 après 12 mois de dev | P7 Abidjan/Dakar |
| **D5** | `clientType` enum (`INDIVIDUAL \| BUSINESS`) sur l'entité Client | Refonte du modèle Client pour supporter les entreprises B2B | P5 Grossiste |
| **D6** | `deliveryStatus` sur les orders (`PENDING \| DISPATCHED \| DELIVERED \| CONFIRMED`) | Architecture order B2B impossible à étendre | P5 Grossiste |
| **D7** | Circuit de réappro Blandine = `ApprovalWorkflow` générique avec `steps: ApprovalStep[]` | Workflow multi-département H3 à réécrire de zéro | P9 Multi-département |
| **D8** | `IntegratorRole` prévu dans le RBAC (slot, même vide) | Refactoring complet des vérifications de permissions | P6 Intégrateur |
| **D9** | **AI = 3 niveaux distincts : H2-5a/b (client-facing, mois 3-6) ≠ H2-5c (intégrateur-first, mois 6-12). Couche LLM isolée en `AIService` partagé. H2-5c = intégrateur d'abord.** | Features AI couplées qui se bloquent mutuellement + H2-5c rate son vrai utilisateur | P6 Intégrateur + tous |
| **D10** | Modules qui communiquent par interfaces/events, jamais par import direct | Couplage fort qui bloque la modularisation H3 | P9 Multi-département |
| **D11** | **PRINCIPE ARCHITECTURAL AI + PATTERN GenUI : chaque module expose ses actions comme AI-invocables. L'AI vit dans un panel/command bar dédié — jamais injectée sur les écrans existants.** Dans ce panel, l'AI génère dynamiquement des boutons, listes, cards (GenUI) qui appellent ces actions. Les écrans Core restent purs et prévisibles. Pattern : Notion AI panel / Linear Cmd+K. L'assistant est offline-unavailable — acceptable, les écrans Core fonctionnent normalement sans lui. | Panel AI couplé aux écrans = UX impossible à défaire une fois que les utilisateurs s'y habituent. Modules sans actions exposées = GenUI ne peut rien générer d'actionnable. | Tous H2+ |
| **D12** | **Config tenant sérialisable en JSON exportable/importable** — rôles, modules activés, workflows, alertes, seuils. La config d'un tenant doit pouvoir être exportée comme un fichier et réimportée sur un autre tenant. Condition pour H3-3 (Template Marketplace). | Templates sectoriels impossibles sans config sérialisable — H3-3 nécessite une refonte complète du modèle de config | P6 Intégrateur + H3-3 Marketplace |
| **D13** | **REST API versionnée `/api/v1/` dès V1, zéro endpoint non versionné exposé.** Condition pour le TypeScript SDK intégrateurs et le Marketplace H3-3. Un changement d'API non versionné en production avec clients actifs = breaking change pour tous les intégrateurs. | SDK et Marketplace impossibles à construire proprement sur une API non versionnée | P6 Intégrateur + H3-3 |
| **D14** | **Couche AI = Python/FastAPI microservice séparé de NestJS.** NestJS appelle ce service via HTTP interne — les deux coexistent. Ne pas forcer le LLM, le parsing Excel et le ML dans NestJS. Architecturer la séparation dès H2-5a, pas retrofiter. | AI layer monolithique dans NestJS = refactoring complet pour ajouter ML, Python libs, async processing | H2-5a/b/c/d |
| **D15** | **Wave = payment adapter, pas intégration directe.** Interface `PaymentAdapter` avec une implémentation Wave. Demain : Orange Money, Moov Money, virement — chacun = un adapter. Si Wave est hardcodé dans la logique de caisse, chaque nouveau moyen de paiement = refactoring du core. | Multi-payment UEMOA impossible sans adapter pattern | P5 Grossiste + tous |
| **D16** | **Compliance OHADA = plugin/configuration, pas logique core.** `ComplianceAdapter` par pays (règles TVA, SYSCOHADA, formats déclaratifs). Sinon le core est pollué par des règles fiscales qui diffèrent entre BF, CI, SN — et H3-4 (Conformité Fiscale Automatique) est inatteignable. | Expansion multi-pays = réécriture de la logique fiscale core | P7 CI/SN + H3-4 |
| **D17** | **`DelegatedAccess` pattern dans le RBAC — slot pour partenaires externes à accès scopé read-only.** Distinct de `IntegratorRole` (config write) et des rôles employés (opérations). Un `DelegatedAccess` = `{ tenantId, partnerId, allowedModules[], expiresAt }`. Couvre l'expert-comptable (module finance), l'auditeur, le partenaire IMF futur. Sans ce slot maintenant, le Programme Cabinets Comptables H2-1b = 3e refactoring RBAC en production. | RBAC avec seulement 2 types d'acteurs externes (intégrateur + super-admin) = refactoring complet pour chaque nouveau type de partenaire | P10 Expert-Comptable + H2-1b |
| **D18** | **Extension Module layer = champs custom + règles de validation + automations sectorielles stockés comme configuration (JSONB/metadata), pas comme migrations SQL.** Le Template Builder (H3-3) repose sur deux niveaux : (a) Template = labels, navigation, workflows, rôles, données par défaut — configuration pure ; (b) Extension Module = champs custom, calculs auto, règles métier sectorielles — doit être metadata-driven, pas du code. Si les champs custom sont des colonnes SQL ajoutées au cas par cas, chaque vertical sectoriel nécessite une migration. Avec un modèle `custom_fields: JSONB` ou une table `FieldDefinition`, les intégrateurs étendent sans SDK. Coût de la décision maintenant : définir le modèle `FieldDefinition` avant d'ajouter les premiers champs Blandine. | Chaque customisation sectorielle = migration SQL + déploiement = Template Builder impossible sans SDK | P6 Intégrateur + H3-3 Template Builder |
| **D19** | **Structure organisationnelle dynamique — `RoleDefinition` en base par tenant, jamais d'enum TypeScript hardcodé.** Les noms de rôles (`OWNER`, `EMPLOYEE`, `MANAGER`...) ne sont pas des constantes dans le code — ce sont des entrées dans une table `RoleDefinition` configurée par tenant. H1 peut avoir des rôles de départ préconfigurés dans la seed (ex : Propriétaire, Employé, Gestionnaire), mais l'architecture doit accepter la création de rôles custom dès V1. Raison : l'AI Config Wizard crée les rôles selon la description du client ("j'ai un responsable magasin qui voit le stock mais pas les finances"), et les templates sectoriels incluent des jeux de rôles par défaut (Cabinet Juridique → Associé, Collaborateur, Secrétaire juridique). Si les noms de rôles sont des enums hardcodés, aucune des deux fonctionnalités n'est possible sans déploiement de code. | Templates sectoriels avec rôles custom impossibles ; AI Config Wizard ne peut pas créer de rôles dynamiquement ; chaque nouveau type d'organisation nécessite un changement de code | P6 Intégrateur + H2-5c + H3-3 Templates |

> **Règle :** D1 à D19 sont des décisions d'architecture **de données, de design et de stack**, pas des features à développer. La plupart se règlent en ajoutant une colonne nullable, un adapter pattern ou en nommant correctement un concept. Coût total estimé : 3-4 jours de design préventif. D11 est la décision la plus structurante de toute la roadmap AI.

### Décisions Différables Sans Dette Technique

Ces décisions peuvent attendre sans créer de dette technique, à condition que les décisions D1-D10 ci-dessus soient prises.

**Dashboard multi-boutiques consolidé (P8)**
La vue agrégée n'a pas besoin d'exister avant que le premier client multi-boutiques arrive. Condition : `storeId` (D2) est déjà dans toutes les transactions. Quand le besoin arrive, c'est une requête SQL agrégée sur un champ existant, pas une refonte.

**B2B inter-tenants (P5 / H3)**
Le canal de commande entre deux clients Scalario peut attendre. Condition : `clientType` (D5) et `deliveryStatus` (D6) sont en place. Quand le besoin arrive, c'est une extension du modèle Order existant, pas une nouvelle entité.

**Modules RH et Comptabilité (P9)**
Ces modules n'ont aucune urgence avant que Scalario ait 20+ clients actifs avec des besoins comptables formels. Condition : l'architecture événementielle (D10) et le workflow générique (D7) sont en place. Sans ces conditions, différer ces modules crée de la dette. Avec elles, les modules s'ajoutent comme des consumers d'events existants.

**Freemium Starter (H2)**
Décision business pure, pas technique. Peut attendre la validation product-market fit avec les testeurs actuels. Aucune décision d'architecture n'est conditionnée à ce choix.

**Expansion CI/SN (P7)**
Différable jusqu'à 10+ clients actifs à Ouagadougou. Condition : i18n (D4) et `countryCode` (D3) sont en place. L'expansion elle-même est alors une configuration, pas un développement.

**WhatsApp Business API**
Push notification couvre le besoin immédiat. WhatsApp est un upgrade qui peut attendre la signature Blandine et validation de l'usage réel. Ne pas le promettre comme feature démo V1.

**AI H2-5a — Import Excel/CSV catalogue (PRIORITÉ #1 AI, mois 3-6)**
Ne pas développer avant signature Blandine + au moins 1 testeur gratuit actif, mais à planifier dès maintenant. C'est la feature la plus directement rentable sur le coût d'onboarding : chaque client a un Excel quelque part. Condition préalable : schema d'import catalogue défini + `AIService` isolé (D9). Impact direct sur le taux de conversion des testeurs — si l'onboarding catalogue prend 10 min au lieu de 3h, la barrière à l'adoption s'effondre.

**AI H2-5b — Création produit en langage naturel (mois 3-6)**
Différable jusqu'après signature Blandine mais à prioriser en post-signature. Résout le cas Vrac→Sachet par une voie différente : au lieu d'un formulaire "split", l'utilisateur décrit son produit en langage naturel et Scalario crée automatiquement l'unité mère et les sous-unités avec la conversion. Impact direct sur la qualité de l'onboarding pour les produits frais/vrac.

**AI H2-5c — Config Wizard entreprise complet (intégrateur-first, mois 6-12)**
Différable jusqu'à 3 clients réels actifs ET premier intégrateur identifié. Condition préalable : `IntegratorRole` (D8) + provisioning programmatique + H2-5a/b opérationnels (infrastructure LLM déjà en place). Ne pas développer avant d'avoir un intégrateur réel qui peut valider les flows.

**AI H2-5d — Diagnostic & Support (mois 6-12)**
Différable jusqu'à H2-5a/b opérationnels et base de clients réels pour entraîner les patterns de diagnostic. Fonctionnement : l'utilisateur décrit un problème en langage naturel ("pourquoi mon stock d'huile est négatif ?") → l'AI interroge les modules via function calling, analyse les transactions, et explique ou corrige. Condition préalable : D11 (modules AI-invocables) — sans actions exposées, l'AI ne peut pas interroger les données.

**AI H4-1 — Multi-Langue Locale (Mooré, Dioula, Wolof, Haoussa)**
Horizon 4, très différable. À anticiper néanmoins dès maintenant dans la couche LLM : ne pas hardcoder des prompts système en français uniquement. Utiliser des variables de langue dans les prompts (`{language}`) pour pouvoir ajouter des langues locales sans réécrire toute l'infrastructure AI.

**Analytique prédictive AI (H3)**
Aucune donnée suffisante avant 6-12 mois d'utilisation réelle. Différable sans impact. Les transactions sont capturées dès maintenant — les données s'accumulent passivement.

**Extraction NestJS en microservices (hors Python/AI)**
Le service Python/FastAPI AI est déjà le premier microservice naturel (D14). L'extraction des autres domaines NestJS (Reporting, Notifications, Sync Engine) est différable jusqu'à signal de bottleneck réel prouvé par les données ET équipe backend 3+ devs. Ne pas découper le monolithe par anticipation. Un fondateur solo ne peut pas gérer 5 microservices en production — la complexité opérationnelle tuerait la vélocité produit avant le scaling problem.

**Extension Module / Template Builder (H3-3)**
Le concept est clairement défini (2 niveaux : Template = labels/workflows/rôles, Extension Module = champs custom + règles de validation + automations sectorielles), mais son développement est différable jusqu'à 10+ clients et 2+ intégrateurs actifs. La condition préalable est D18 (modèle de données extension) et D12 (config sérialisable) — ces deux décisions se prennent maintenant, l'outil se construit après.

### Décisions Irréversibles à Éviter

Ces décisions, si prises dans le mauvais sens, créent une dette technique qui ne peut pas être corrigée sans casser des données existantes ou réécrire des pans entiers du système.

**IR-1 — `saleItemId === stockItemId` hardcodé dans le décrément de stock**
Si la logique "vendre X = décrémenter X du stock" est une invariante dans le code, la restauration (produits composés) est impossible sans refonte. Coût si irréversible : réécriture complète de la logique de mouvement de stock.

**IR-2 — Transactions sans `storeId`**
La décision la plus coûteuse de la roadmap. Un champ nullable aujourd'hui = zéro travail. Une migration de 100K+ lignes de transactions en production = risque élevé de perte de données et de downtime.

**IR-3 — Strings UI hardcodées hors i18n**
Un refactoring d'internationalisation sur une codebase Flutter de cette taille après 12 mois de développement actif représente plusieurs semaines de travail avec un risque élevé de régression. C'est la seule décision technique de cette liste dont le coût croît de façon exponentielle avec le temps.

**IR-4 — Circuit de réappro Blandine hardcodé avec 3 rôles fixes**
Si `steps = [COMMERCIAL, GESTIONNAIRE, OWNER]` est une constante dans le code et non une configuration, tout workflow d'approbation H3 (multi-département, multi-niveau, seuils variables) doit être réécrit de zéro — en parallèle d'un système existant, avec risque de conflits.

**IR-5 — AI Config Wizard designé "client final autonome" en priorité**
Cette décision est irréversible non pas techniquement mais stratégiquement. Une UX conçue pour un propriétaire de boutique non-technicien qui configure seul son ERP est incompatible avec une UX pour un intégrateur qui configure 5 tenants clients en parallèle. Les deux ont des flows, des permissions, et des besoins radicalement différents. Choisir le mauvais utilisateur cible dès le design initial crée un produit qui ne sert bien ni l'un ni l'autre.

**IR-6 — RBAC sans slot intégrateur**
Ajouter un niveau d'autorisation entre "propriétaire" et "super-admin" après coup nécessite de revisiter chaque `guard`, chaque `permission check`, et chaque endpoint de l'API. Sur une API NestJS déjà en production avec des clients actifs, c'est un risque de régression majeur.

**IR-7 — Modules construits sans contrat d'actions AI-invocables**
Le PRINCIPE ARCHITECTURAL AI (D11) — "tout ce qui est faisable via l'UI doit être faisable via l'AI" — est impossible à retro-appliquer sur des modules existants sans les réécrire. Si chaque module encapsule sa logique dans des services fermés sans interface d'actions exposée, l'AI universelle (H2-5c, H2-5d, et toute la couche AI long-terme) devient un projet de refactoring de la codebase entière. La décision se prend maintenant : définir un contrat d'actions par module (`ModuleActions` interface) avant de construire les prochains modules, ou accepter que l'AI ne sera jamais vraiment universelle.

**IR-8 — Config tenant non-sérialisable**
Si la configuration d'un tenant (modules actifs, rôles, workflows, alertes, seuils) est stockée de façon fragmentée dans plusieurs tables sans format exportable, le Template Marketplace (H3-3) — qui repose sur des bundles de config importables — est architecturalement impossible. Une config non-sérialisable, c'est aussi un onboarding intégrateur qui reste manuel indéfiniment : impossible de cloner la config d'un client réussi pour l'appliquer à un nouveau.

**IR-9 — Injecter des boutons AI sur les écrans Core existants**
Le pattern GenUI (D11) repose sur une séparation nette : les écrans Core sont purs et prévisibles, l'AI a son espace dédié (panel/command bar). Si dès V1 des boutons "Ask AI", des suggestions inline, ou des widgets AI sont injectés directement sur les écrans POS, Stock, ou Caisse, deux problèmes irréversibles apparaissent : (1) les utilisateurs s'habituent à l'AI *dans* les écrans et refusent le modèle panel-séparé — UX impossible à défaire sans friction massive ; (2) l'écran Core devient dépendant de la disponibilité de l'AI, cassant la promesse offline-first. Une fois que l'AI est dans l'écran, elle ne peut plus en être retirée proprement. La règle est simple et binaire : les écrans Core n'ont aucun élément UI conditionnel à la disponibilité de l'AI. Tout AI se déclenche depuis le panel dédié.

---

## 🚀 Next Steps

### Refinements Needed

**Sur la démo Blandine :** Le risque actuel est de sur-promettre sur des features complexes (Taux de Frotte complet, Vrac→Sachet automatique, WhatsApp) avant d'avoir sécurisé la signature. Recentrer la démo sur le "moment de vérité" : montrer que la boutique de Blandine tourne sans elle, avec preuve. Tout le reste est post-signature.

**Sur les testeurs gratuits :** La conversion en 3 mois ne se fera pas "naturellement". Il faut identifier la feature déclencheuse pour chaque testeur (arrêt de caisse automatique pour Boissons, variantes pour Cosmétique) et s'assurer qu'elle est parfaitement fonctionnelle avant la fin du mois 2.

**Sur l'architecture :** Les décisions D1-D10 ne sont pas des features — elles sont des choix de design de données qui se font en 1-2 jours. Les intégrer dans le backlog PRD v7 comme des tâches techniques bloquantes, pas comme des stories optionnelles.

**Sur le naming :** Plusieurs concepts qui semblent identiques sont architecturalement distincts et doivent être nommés différemment dès maintenant : `InternalRequisition` vs `B2BOrder`, `POSSession` vs `TableSession`, `ApprovalStep` vs `WorkflowState`. Le naming flou aujourd'hui = confusion garantie en H2.

**Sur la tension vision universelle vs beachhead :** La vision stratégique est maintenant explicitement "plateforme de gestion universelle pour toute organisation dans le monde". C'est une ambition légitime et les décisions architecturales D1-D12 sont cohérentes avec elle. Le seul risque concret : que cette vision influence les décisions de *développement immédiat* au détriment de la démo Blandine dans < 30 jours. Règle de discipline : l'architecture peut être universelle dès maintenant (coût faible), mais le développement reste 100% focalisé sur les 3 personas actuels jusqu'à la première conversion payante. L'Horizon 4 (IoT, Haoussa, Pay-per-transaction) ne doit pas apparaître dans le PRD v7.

### Action Items → PRD v7

**Immédiat — avant démo Blandine (< 30 jours)**

1. **Finaliser l'arrêt de caisse guidé** avec réconciliation 3 niveaux — c'est l'écran pivot de la démo
2. **Construire le circuit de réappro interne** comme `ApprovalWorkflow` générique avec `steps: ApprovalStep[]` (D7 + valeur démo)
3. **Ajouter `storeId UUID nullable`** sur les tables transactions, ventes, dépenses, mouvements de stock (D2 — 2h de migration)
4. **Ajouter `productType` enum** sur le modèle Produit (D1 — 30 min)
5. **Ajouter `IntegratorRole` slot** dans le RBAC, même vide (D8 — 1h)
6. **Mettre toutes les strings UI** dans des fichiers i18n (D4 — à planifier, bloquer du temps)
7. **Préparer la config Taux de Frotte** pour la démo — même si le calcul n'est pas 100% automatisé, montrer la configuration paramétrable

**Post-signature Blandine (< J+30 d'utilisation)**

8. **Vrac→Sachet** configuré sur les vrais produits Blandine
9. **Alertes stock d'alerte** par variété activées
10. **Push notification quotidienne** à 21h — résumé CA + écarts + alertes critiques

**PRD v7 — Décisions à documenter**

11. **Documenter la décision D9** (AI Config Wizard = intégrateur first) comme principe produit dans le PRD — pas une feature, une philosophie de design
12. **Documenter la règle de fer** Core Standard vs Premium comme contrainte architecturale, pas juste commerciale
13. **Créer les 3 user stories** pour les testeurs : "Boissons convertit parce que l'arrêt de caisse lui a fait gagner X min/jour" et "Cosmétique convertit parce que ses variantes sont enfin gérées"

### Success Metrics

**Métriques démo Blandine (< 30 jours)**
- Blandine complète une simulation d'arrêt de caisse sans aide externe en < 5 minutes
- Blandine identifie correctement quel employé est responsable d'une phase sans qu'on lui explique
- Blandine dit spontanément "je pourrais voir ça sur mon téléphone quand je suis absente" — signal de projection réussi
- Blandine signe et paie le setup fee : 0 ou 1, la seule métrique qui compte

**Métriques conversion testeurs (< 90 jours)**
- Vendeur Boissons : temps de clôture de caisse divisé par 3 (de ~45 min à < 15 min)
- Vendeur Boissons : 0 rupture de stock surprise sur les 30 premiers jours d'utilisation active
- Vendeur Cosmétique : 0 survente d'une variante épuisée sur les 30 premiers jours
- Taux de conversion testeur → payant : objectif 1/2 minimum sur les 2 testeurs actifs

**Métriques architecture (vérification PRD v7)**
- `storeId` présent sur 100% des tables de transactions avant mise en production client
- 0 string UI hardcodée hors fichiers i18n dans la codebase Flutter + NestJS
- Circuit de réappro Blandine implémenté avec `ApprovalStep[]` configurable, pas de rôles hardcodés
- `productType` enum présent dans le modèle Produit avant démo Blandine

**Métrique stratégique H2 (6-12 mois)**
- L'AI Config Wizard (quand développé) permet à un intégrateur de configurer un nouveau tenant client en < 30 minutes — mesuré sur les 3 premiers intégrateurs réels

---

*Generated using BMAD Creative Intelligence Suite - Design Thinking Workflow*
