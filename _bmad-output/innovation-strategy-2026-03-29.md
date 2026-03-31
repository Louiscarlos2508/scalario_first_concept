# Innovation Strategy: Scalario

**Date:** 2026-03-29
**Strategist:** Carlos-simpore
**Strategic Focus:** Devenir la plateforme de gestion universelle pour toute organisation dans le monde — commerce, industrie, éducation, santé, hôtellerie, mines, agriculture, ONG, coopératives, services et tout type d'organisation — via une architecture Core + Modules + Templates Sectoriels + AI Configuration universelle. Offline-first, mobile-first, configurable sans code, accessible à tout intégrateur local via une couche AI qui remplace les consultants SAP/Odoo à 500€/jour. Beachhead : UEMOA Retail (marché le plus difficile = validation universelle). Expansion progressive : tous secteurs, tous continents.

---

## 🎯 Strategic Context

### Current Situation

Carlos Simporé, fondateur solo, a construit en pré-revenu une plateforme ERP SaaS multi-verticale (Retail, Distribution, Restauration, Services) avec des modules opérationnels couvrant POS, Stock, Réservations, Commandes clients, Inventaire, Dépenses, Rapports et Notifications. Architecture offline-first robuste (Flutter + NestJS + Supabase + Isar), 14 business types restructurés en 4 verticales, config sans code par businessType.

Premier client identifié : Blandine, boutique fruits/légumes/épices (commerce de produits frais périssables), 5 utilisateurs (propriétaire + gestionnaire + commerciaux), 8 phases de workflow opérationnel. Une proposition formelle a été remise engageant des features spécifiques aux produits frais : Taux de Frotte (déshydratation naturelle), conversion Vrac→Sachet, code couleur fraîcheur, circuit de commande interne, arrêt de caisse quotidien, résumé WhatsApp/notification propriétaire. Démo dans moins d'1 mois. Revenu = 0. Pricing Blandine : 40 000 FCFA/mois ou 400 000 FCFA/an (déjà communiqué).

Deux testeurs gratuits actifs dans la même période (< 1 mois) : (1) vendeur de boissons et produits divers — Retail standard, complexité faible, archétype du mass market réplicable ; (2) vendeur de produits chimiques et cosmétiques — Retail spécialisé, complexité moyenne, variants taille/couleur/parfum. Ces 3 cas simultanés couvrent trois profils distincts et fourniront des données réelles pour décider du beachhead en moins d'1 mois. Règle : testeurs gratuits 3 mois maximum puis conversion commerciale. Blandine reste la priorité bandwidth.


### Strategic Challenge

**Le vrai concurrent n'est pas Odoo — c'est l'absence de gouvernance interne et la fragmentation des outils.** En UEMOA, la PME multi-activités gère sa production sur Excel, ses ventes sur un autre outil, ses employés sur WhatsApp, et sa comptabilité dans la tête du propriétaire. Scalario est le premier système qui unifie toutes ces entités et flux dans une seule plateforme modulaire : production, retail, distribution, RH — avec des workflows inter-entités définis, des accès contrôlés par rôle, des modules activables sans code selon la configuration de l'entreprise — le tout offline-first sur mobile, configurable par AI, et déployable par un intégrateur local sans expertise SAP.

**Tensions stratégiques non résolues :**
1. **Scope** : 4 verticales × 14 business types pour un fondateur solo = risque de mort par complexité. Un seul vertical doit être priorisé pour les 12 premiers mois.
2. **Beachhead** : Blandine (distribution complexe, 5 users, 8 workflows) est-elle l'archétype du client idéal ou une exception qui distrait du marché retail de masse ?
3. **Pricing** : Le mécanisme de paiement récurrent SaaS n'est pas établi dans la cible. La question n'est pas "quel montant" mais "quel modèle de paiement crée le moins de friction" (annuel prepaid, mobile money, etc.).
4. **AI-driven** : Vision séduisante mais distraction mortelle pré-revenu. Doit être explicitement réservée à Horizon 3.
5. **Canal intégrateur** : Hypothèse non testée. La densité et la qualité des intégrateurs ERP en UEMOA est très limitée comparée aux marchés développés.

**L'enjeu central** : Valider le modèle économique (qui paie quoi comment) avant d'élargir le scope produit ou d'investir dans des fonctionnalités différenciatrices de long terme.

---

## 📊 MARKET ANALYSIS

### Market Landscape

Zone UEMOA : 8 pays, ~130 millions de personnes, tissu économique dominé à 90%+ par les PME/TPE. Pénétration des outils de gestion digitale PME < 5% — marché quasi vierge. Mobile money omniprésent (Wave 8M+ users, Orange Money, MTN MoMo). Générations digitales natives entrant dans l'entrepreneuriat. Fenêtre first-mover ouverte 3–4 ans.

Segments cibles :
- Petites entreprises (5–20 employés) : cœur de cible Starter/Business, volume élevé, acquisition via intégrateur
- Moyennes entreprises (20–100 employés) : cible Pro/Distribution, ticket élevé, vente directe
- Micro (<5 employés) : hors cible — ticket trop bas, trop informel
- Grandes entreprises (100+) : territoire SAP/Sage — ne pas y aller

Timing : positif. COVID a accéléré la digitalisation. Adoption mobile en forte croissance. La fenêtre de first-mover ERP mobile-first PME UEMOA existe maintenant — pas dans 4 ans.

### Competitive Dynamics

Vrais concurrents par ordre de menace réelle :

1. Excel + Cahier de caisse (★★★★★) : gratuit, connu, offline, zéro friction. C'est le comportement à remplacer, pas un logiciel concurrent.
2. Wave Business en expansion (★★★★☆) : 8M users, trust établie, rails mobile money. Si Wave lance outils de gestion PME dans 18 mois, le marché change. Menace #1 à surveiller.
3. Inertie / informel (★★★★☆) : la résistance passive au changement est plus forte que toute concurrence active.
4. Développement custom local (★★★☆☆) : PMEs qui paient un dev local pour un outil sur-mesure — cher, non maintenu, mais perçu comme "le leur".
5. Odoo (★★☆☆☆) : présent à Abidjan/Dakar pour les segments tech-savvy. Trop complexe pour Blandine. Pas un concurrent direct sur le marché cible.
6. Sage (★★☆☆☆) : comptabilité desktop, legacy UX, zéro offline. Segment différent.

### Market Opportunities

1. Vide mobile-first offline-first ERP : aucun acteur sérieux ne propose un ERP réellement mobile-first ET offline-first pour PME UEMOA. Opportunité structurelle défendable.
2. Verticalisation pour le commerce africain : le modèle "gros & détail intégré" (type Blandine) est typique du commerce UEMOA et absent des ERPs occidentaux. Construire pour les workflows réels africains est un avantage concurrentiel durable.
3. Intégration mobile money : Wave/Orange Money sont les rails de paiement de l'économie informelle. Un ERP qui réconcilie les paiements mobile money nativement a une valeur immédiatement tangible.
4. Langue et contexte local natifs : les ERP existants sont traduits, pas localisés. Labels métier, workflows, unités (sachet, carton, sac 50kg), devises — tout est africain dans Scalario.
5. Expansion régionale via OHADA : droit des affaires unifié sur 8 pays. Conformité OHADA = déploiement régional avec peu d'adaptation. Côte d'Ivoire et Sénégal = marchés 2 et 3.

### Critical Insights

1. Le problème est comportemental, pas fonctionnel. Les PME savent qu'elles ont besoin de gestion. Elles ne savent pas encore qu'un outil peut remplacer Excel sans douleur. L'onboarding et la migration sont 80% du défi commercial.
2. Mobile money n'est pas une feature — c'est une condition d'entrée marché. Un ERP sans Wave natif sera perçu comme incomplet.
3. Le marché Burkinabè est politiquement risqué (3 coups depuis 2022). Prévoir l'expansion vers Côte d'Ivoire et Sénégal dès 12–18 mois post-traction.
4. L'intégrateur local est critique mais rare. La pénurie d'intégrateurs ERP qualifiés en UEMOA est sévère. La formation des intégrateurs doit être traitée comme un produit, pas comme un canal de distribution.

---

## 💼 BUSINESS MODEL ANALYSIS

### Current Business Model

ERP SaaS multi-vertical (Retail, Distribution, Restauration, Services) pour PMEs UEMOA 5–50 employés. Stack offline-first Flutter+NestJS+Supabase. Config sans code par businessType. Canal : vente directe par le fondateur seul. Revenu : 0. Un client en cours de closing (Blandine). Modèle intégrateur planifié mais non opérationnel.

Blocs Business Model Canvas :
- Segments : PMEs 5–50 employés, commerce UEMOA francophone
- Canal : direct (Carlos) uniquement, intégrateurs = 0% opérationnel
- Relations clients : accompagnement direct fondateur (non scalable mais adapté au stade)
- Ressources clés : Carlos × 1, codebase, relation Blandine
- Activités clés : développement, démo/closing, onboarding, support — tout par une seule personne
- Partenaires clés : Supabase (infra), intégrateurs futurs (inexistants)
- Structure de coûts : essentiellement temps Carlos + infra Supabase minimale

### Value Proposition Assessment

Jobs fonctionnels prioritaires (Blandine, boutique fruits/légumes/épices) :
- Tracer chaque produit du fournisseur au rayon avec responsabilité par rôle
- Éliminer les pertes "inexpliquées" (vol, erreur ou perte naturelle distingués)
- Contrôler à distance via mobile sans être présente physiquement
- Fermer la caisse chaque soir avec confrontation automatique stock/CA
- Maintenir les données fiables même sans connexion Internet

Pains réels qui coûtent de l'argent :
- Écarts de stock non attribuables (vol ? erreur ? déshydratation ?) = pertes invisibles
- Aucune responsabilité segmentée : si le commercial dit "c'est pourri à la réception", impossible de le prouver
- Perte de poids naturelle des fruits/légumes comptée comme vol = conflits employés
- Réconciliation manuelle CA fin de journée = erreurs chroniques
- Dépendance à la présence physique de Blandine pour tout contrôle

Gains attendus (ce qui justifie de payer) :
- Circuit de commande interne digitalisé (commercial→gestionnaire→Blandine)
- Taux de Frotte intégré : les pertes naturelles ne sont plus comptées comme vols
- Conversion Vrac→Sachet automatique pour les épices
- Code couleur fraîcheur pour vendre les produits prioritaires avant perte
- Résumé quotidien Blandine sur mobile : CA, pertes, produits à commander

Adéquation : très forte sur les pain points réels. Risque : proposition qui engage des features spécifiques (Taux de Frotte, Vrac→Sachet, WhatsApp) potentiellement hors scope V1 démo — à clarifier avant la démo.

### Revenue and Cost Structure

Pricing révisé — Architecture modulaire multi-entités :

Modèle de base (plateforme core + modules inclus selon tier) :
- Starter    : 15 000 FCFA/mois — 1 entité, modules de base (POS + Stock + Caisse), max 3 users
- Business   : 30 000 FCFA/mois — 1 entité, tous modules Retail/Distribution, utilisateurs illimités
- Pro        : 55 000 FCFA/mois — multi-entités (jusqu'à 3), tous modules, workflows inter-entités
- Enterprise : sur devis — multi-entités illimitées, Production + RH + intégrations sur mesure

Modules additionnels (add-ons activables) :
- Module Production/Fabrication : +15 000 FCFA/mois
- Module RH (présences, paie OHADA, congés) : +10 000 FCFA/mois
- Entité supplémentaire (au-delà de 3 en Pro) : +10 000 FCFA/mois/entité

Setup fee (obligatoire) : 75 000–150 000 FCFA selon complexité. Couvre formation sur place + configuration initiale.

Mécanisme de paiement : annuel prepaid avec remise 2 mois (ex : Business 300 000 FCFA/an vs 360 000 mensuel). Collecte via Wave ou virement bancaire — décision à prendre avant Blandine.

Note Blandine : 40 000 FCFA/mois (déjà communiqué) s'inscrit entre Business et Pro. À valider selon le nombre d'entités et de modules actifs dans son cas.

**Évolution du modèle tarifaire — Direction H2+ (à implémenter avec AI Config) :**
Les tiers fixes actuels (Starter/Business/Pro) sont une simplification valide pour H1 avant que l'AI Config soit opérationnelle. Le modèle cible à partir de H2 est le **pricing modulaire** : le client paie uniquement pour ce qui est activé. La facturation s'ajuste automatiquement à chaque activation de module ou d'extension via AI Config. Plus le client grandit et active, plus la facturation augmente — mais toujours en rapport direct avec ce qu'il utilise réellement. L'upsell devient naturel : un client commence avec Core, active la Comptabilité quand il en a besoin, puis les RH, puis la Production — chaque activation = revenu additionnel sans démarche commerciale. L'AI Config devient un moteur de croissance du revenu par client.

Structure de coûts : contrainte capacitaire (temps Carlos), pas financière. Supabase ~$25–100/mois, négligeable.

### Business Model Weaknesses

1. SPOF humain : Carlos = CEO + dev + commercial + support. Si Carlos est bloqué, tout s'arrête. Risque opérationnel réel, pas hypothétique.
2. Aucun trial sans Carlos : impossible d'essayer sans passer par une démo personnelle. Limite les leads au bandwidth physique de Carlos.
3. Collecte de paiement non résolue : mécanisme concret pour collecter chaque mois non défini.
4. Modèle intégrateur prématuré : recruter des intégrateurs sans playbook prouvé, sans product-market fit validé, et sans formation = intégrateurs qui ne vendent rien.
5. Customer success implicite et sous-estimé : onboarding et support des 5 employés de Blandine est du temps Carlos non chiffré.
6. Distribution pricing non décidé : arriver en démo sans prix Distribution = négociation sous pression et signal d'improvisation.

---

## ⚡ DISRUPTION OPPORTUNITIES

### Disruption Vectors

1. Disruption de la connectivité : architecture offline-first (Isar+Supabase) incopiable par les acteurs cloud-first sans refonte totale du stack. Avantage structurel durable en UEMOA où Internet coupe quotidiennement.
2. Disruption par le contexte africain natif : Taux de Frotte, vrac→sachet, unités locales (carton, sac 50kg), workflows gros & détail intégré — aucun ERP global ne construit pour ça. Impossible à copier rapidement.
3. Disruption du contrôle à distance : le "peace of mind mobile" du propriétaire absent. Valider workflows multi-rôles, recevoir alertes stock, consulter CA de la journée sur téléphone. Aucun outil existant accessible ne fait ça pour une PME de 5 personnes.
4. Disruption du canal de distribution : réseau ambassadeur→intégrateur→partenaire basé sur la confiance locale. Surperforme les forces de vente directes dans un marché relationnel. Non activé encore — mais moat fort si bien structuré.
5. Disruption par l'intégration mobile money : 80%+ des transactions UEMOA passent par Wave/Orange Money. Premier ERP à intégrer mobile money nativement = registre financier de facto du commerce, switching cost élevé.

### Unmet Customer Jobs

1. "Savoir qui a fait quoi, quand, et le prouver" : traçabilité par rôle dans un contexte multi-employé PME africain. Job le plus émotionnellement urgent — la peur du vol et de la négligence non attribuable. Non servi par aucun outil actuel.
2. "Gérer mon commerce sans être là" : propriétaires UEMOA cumulent souvent plusieurs activités. Besoin d'un système nerveux mobile qui rend compte en temps réel. Job universel dans ce marché, totalement non servi.
3. "Transitionner du papier au digital sans tout casser" : l'onboarding sans douleur (migration, formation, interface accessible à non-techniciens) est un job énorme ignoré par la plupart des éditeurs de logiciels. Déterminant pour le taux de rétention.
4. "Gérer des produits qui changent de forme et de poids" : transformation sac 5kg → sachets 100g, déshydratation naturelle, fraîcheur périssables. Job de niche mais à haute valeur perçue (directement lié aux pertes financières). Ignoré par tous les ERP généralistes.
5. "Commander en interne sans chaos" : digitalisation du circuit commercial→gestionnaire→propriétaire. Aujourd'hui : WhatsApp + appels + papier. Job universel dans les PME multi-hiérarchiques.

### Technology Enablers

- Flutter + Isar : ERP mobile-first offline-first sur Android/iOS — opérationnel maintenant
- Supabase Realtime : sync temps réel + résolution de conflits offline — opérationnel maintenant
- Wave API / Orange Money API : réconciliation paiements mobile money — disponible, non encore intégré
- WhatsApp Business API (Twilio/Meta) : alertes et résumés quotidiens propriétaire — disponible, non encore intégré (promis à Blandine)
- Notifications push Flutter : alertes stock, validation workflow, arrêt de caisse — opérationnel maintenant
- LLM/AI : onboarding par langage naturel, détection d'anomalies, reporting intelligent — mature techniquement, priorité Horizon 2 uniquement

### Strategic White Space

Espace blanc précis : "ERP mobile-first, offline-first, vertical africain natif, multi-rôle, pour PME 5–50 employés en zone UEMOA francophone."

Aucun acteur n'occupe cet espace : Odoo (trop complexe, web-first), Wave (fintech, pas ERP), Sage (desktop, comptabilité), Excel (zéro workflow/rôle/mobile).

Trois bords défendables :
1. Architecture offline-first — coûteuse à reproduire pour tout acteur existant
2. Contexte africain natif (Taux de Frotte, vrac→sachet, mobile money, OHADA) — impossible à reproduire rapidement par un acteur global
3. Réseau intégrateurs locaux formés — avantage distribution ancré dans la confiance locale, non copiable par un acteur étranger

---

## 🚀 INNOVATION OPPORTUNITIES

### Innovation Initiatives

HORIZON 1 (0–12 mois) :
- H1-1 : Vertical "Produits Frais" — aller au fond. Taux de Frotte, vrac→sachet, code couleur fraîcheur. Vertical incopiable, ciblé sur centaines de boutiques fruits/légumes/épices en UEMOA.
- H1-2 : Wave & Orange Money — intégration native. Condition pour que l'arrêt de caisse Phase 7 soit automatique. Priorité 2 post-Blandine.
- H1-3 : WhatsApp Business — résumé propriétaire quotidien. Feature virale : Blandine qui montre ses stats à ses amies commerçantes = démonstration commerciale organique.
- H1-4 : Setup Fee + Playbook Commercial documenté. 75 000–100 000 FCFA one-time. Condition préalable au canal intégrateur.
- H1-5 : Self-Demo Mode. Données fictives pré-chargées, tutoriel intégré. Réduit la dépendance au bandwidth de Carlos pour les prospects distants.

HORIZON 2 (12–36 mois) :
- H2-1 : Programme Intégrateur Formalisé — 3 à 5 intégrateurs à Ouaga, puis Abidjan, puis Dakar. Conditions préalables : playbook prouvé + 10 clients actifs + documentation de formation.
- H2-1b : Programme Cabinets Comptables (dès lancement module Comptabilité) — cibler 3–5 cabinets comptables Ouaga comme partenaires prioritaires. Chaque cabinet = 15–30 clients potentiels. Features : dashboard multi-clients, délégation d'accès client→comptable, espace gestion propre du cabinet. Condition préalable : module Comptabilité OHADA opérationnel.
- H2-2 : Expansion Côte d'Ivoire / Sénégal via intégrateurs locaux. OHADA facilite l'adaptation réglementaire.
- H2-3 : Vertical Restauration — extension naturelle des features produits frais. 70% de code réutilisable depuis le vertical Blandine.
- H2-4 : Freemium Starter pour funnel d'acquisition auto-alimenté. Conditions préalables : onboarding assez fluide pour auto-service.

PRINCIPE ARCHITECTURAL AI (s'applique à TOUS les horizons) :
L'AI est la couche d'interface universelle sur tout l'ERP — pas une feature parmi d'autres. Tout ce qui est configurable via une interface utilisateur doit être configurable via l'AI. Chaque module expose un ensemble d'actions AI-invocables (function calling / tool use). L'AI traduit l'intention naturelle en actions système sur l'intégralité de la plateforme : produits, rôles, permissions, workflows, alertes, rapports, dashboards, comptabilité, RH, multi-entités, migrations, diagnostics.

PATTERN D'IMPLÉMENTATION AI — Section LLM Dédiée (disponible à tous les utilisateurs) :
Les modules et écrans sont pré-construits, propres, prévisibles. Aucun bouton AI n'est injecté aléatoirement sur les écrans existants. L'AI vit dans une **section dédiée** (chat panel / command bar) où l'utilisateur va volontairement quand il veut une aide contextuelle.

Dans cette section, GenUI est libre : l'AI peut générer des listes, boutons, cards, formulaires dynamiques — tout ce qui répond à la requête de l'utilisateur. Les actions générées déclenchent des fonctions pré-définies dans les modules (AI-invocable actions).

Pattern technique : User ouvre l'assistant → pose une question ou décrit une action → AI (Python/FastAPI) analyse le contexte (rôle, données actuelles, module ouvert) → génère une réponse + UI contextuelle (boutons, listes, cards) → les actions déclenchent des fonctions pré-définies dans les modules.

Exemple : Gérant ouvre l'assistant → "j'ai des ruptures" → AI génère [Commander fournisseur X — 50 unités] [Voir les 3 produits concernés] [Envoyer alerte équipe]. Aucun de ces boutons n'apparaît sur l'écran Stock lui-même — uniquement dans l'assistant.

Inspirations : Notion AI panel, Linear Cmd+K, GitHub Copilot Chat. L'AI a son espace dédié, les screens gardent le leur. L'assistant est indisponible offline — acceptable car les screens fonctionnent normalement sans lui.

HORIZON 2 (12–36 mois) :
- H2-5a : AI Excel/CSV Import & Analysis (Mois 3–6, PRIORITÉ #1 AI) — upload Excel existant → AI configure automatiquement catalogue produits (noms, variantes, unités, prix, catégories, Taux de Frotte si produit frais). Onboarding catalogue : 3h → 10 minutes.
- H2-5b : AI Natural Language — toute la configuration produit, unités, variantes, prix par langage naturel. Résout nativement vrac→sachet, multi-unités, conversions complexes sans formulaire.
- H2-5c : AI Configuration Wizard Universel (Mois 6–12) — configure l'intégralité de l'entreprise via conversation : rôles, modules, workflows, permissions, multi-entités, comptabilité, RH, alertes, dashboards. Principe : "décris ton entreprise, Scalario se configure". Résout le goulot intégrateur : 4–8h → 30 minutes.
- H2-5d : AI Diagnostic & Support (Mois 6–12) — "pourquoi mon stock est négatif ?" / "mon rapport ne correspond pas" → AI analyse et résout. Réduit le support Carlos et intégrateurs.
- H2-6 : AI Pricing Basé sur l'Usage (Mois 12–18) — analyse usage réel et propose tier approprié automatiquement.

HORIZON 3 (36+ mois) :
- H3-1 : AI Features Avancées (analytique + prédiction) — détection d'anomalies, prédiction de ruptures, insights cross-clients, reporting intelligent. Base des partenariats FMCG et IMF. Pertinent à 50–100 clients actifs.
- H3-2 : Canal B2B Inter-Entreprises Scalario — workflow circuit de commande étendu entre entreprises clientes. Effets de réseau. Condition : 20+ clients même ville (Gate 6).
- H3-3 : Module & Template Marketplace / Écosystème Tiers — SDK public pour développeurs tiers, App Store de modules ET de templates sectoriels (Education, Healthcare, Hospitality, Mining, Agriculture, NGO, etc.). Templates = bundles pré-configurés de modules avec rôles/workflows/permissions typiques du secteur, fine-tunés par AI. Modèle similaire à Salesforce AppExchange. Commission 20–30%. Carlos maintient la plateforme, la communauté construit les verticaux.
- H3-4 : Conformité Fiscale Automatique — génération automatique déclarations TVA, liasses SYSCOHADA, états financiers par pays (DGI Burkina, DGI CI, etc.). Argument de rétention puissant, levier d'adoption par les experts-comptables.
- H3-5 : White-label / OEM — Scalario en marque blanche pour banques (Ecobank, Coris), telecoms (Orange Business), IMFs. Licence flat + revshare. Acquisition en volume sans effort commercial direct.
- H3-6 : Couche Services Financiers — partenariat IMF pour crédit de fonds de roulement. AI analytique (H3-1) est la condition préalable.
- H3-7 : Canal ONG / Organisations de Développement — accords avec World Bank, USAID, BOAD, AFD pour programmes de digitalisation PMEs. Un deal = 50–200 clients subventionnés. Canal massif sous-exploité.
- H3-8 : Scalario Academy — certification payante pour intégrateurs, comptables, gestionnaires. Revenu additionnel + contrôle qualité écosystème.

HORIZON 4 (futur) :
- H4-1 : AI Multi-Langue Locale — Config Wizard en Mooré, Dioula, Wolof, Haoussa. Barrière d'adoption rurale résolue.
- H4-2 : IoT / Hardware Integration — balances connectées, scanners, imprimantes. Liaison physique-digital, stickiness maximale.
- H4-3 : Reporting ESG / Impact — métriques emploi, femmes entrepreneurs, formalisation. Accès financement développement (Proparco, IFC, DEG).
- H4-4 : Pay-per-Transaction Micro-Business — modèle à la transaction (50 FCFA/vente) pour commerces 1–3 employés. Base d'entrée qui monte vers les tiers supérieurs.
- H4-5 : Canal Diaspora — acquisition via communities africaines en Europe/Amérique du Nord investissant au pays. "Owner-absent oversight" = leur besoin exact.

### Business Model Innovation

H1 — Modèle à implémenter maintenant :
- Revenu par client = Setup Fee one-time (75 000–100 000 FCFA) + Abonnement annuel prepaid
- Exemple Blandine : 100 000 FCFA setup + 400 000 FCFA/an = 500 000 FCFA Y1, puis 400 000 FCFA renouvellement
- Setup fee : signale la valeur, couvre l'onboarding, filtre les clients non sérieux

H2 — Modèle intégrateur aligné sur la rétention :
- Acquisition : 20% du (setup fee + 1ère année)
- Rétention : 15% du renouvellement annuel tant que le client reste actif
- Logique : l'intégrateur est incentivé à garder ses clients actifs, pas juste à signer

H2 — Modèle intégrateur mini-opérateur SaaS (évolution avec AI Config) :
Les intégrateurs deviennent des mini-opérateurs SaaS : ils créent leurs propres bundles sectoriels (ex : "Petit Commerce Ouaga", "Boucher Bundle", "Cabinet Médical Starter"), fixent leur propre prix dans une fourchette définie par Scalario, vendent l'abonnement directement à leurs clients, et touchent leur marge. L'AI aide l'intégrateur à configurer le bon bundle selon le budget du marchand ("mon client peut payer 10 000 FCFA/mois, il a besoin de POS + Stock + Rapports" → AI configure le bundle optimal).

Règles de protection de l'écosystème :
- Prix plancher (fixé par Scalario) : l'intégrateur ne peut pas vendre en dessous — protège la valeur perçue de Scalario et évite la guerre des prix
- Prix plafond (fixé par Scalario) : l'intégrateur ne peut pas vendre au-dessus — protège les clients et la réputation de la marque
- Dans cette fourchette : l'intégrateur fixe son prix librement selon son marché et sa valeur ajoutée

Fee dégressif selon volume (incitation à scaler) :
- 1–5 clients actifs : fee standard
- 6–20 clients actifs : -10% sur le fee wholesale
- 21–50 clients actifs : -20% sur le fee wholesale
- 50+ clients actifs : accord négocié directement

Modèle Shopify Partners appliqué à UEMOA : des centaines d'intégrateurs qui vendent Scalario à leurs propres clients, à leurs propres prix (dans la fourchette), Scalario scale sans effort commercial direct.

H3 — Plateforme multi-revenus :
- SaaS (abonnements) + Données (insights FMCG anonymisés) + Financier (referral IMF) + Marketplace (commandes B2B inter-clients Scalario)

### Value Chain Opportunities

Position actuelle : Scalario sert le Retailer (Blandine). Chaîne complète : Fabricant → Distributeur national → Distributeur régional → Retailer → Consommateur.

H1 — Renforcer le module Fournisseur/Approvisionnement (Phase 1 Blandine) : historique fournisseurs, délais de livraison, comparaison de prix. Valeur immédiate, zéro développement externe.

H2 — Étendre vers le Distributeur régional : si Scalario sert à la fois Blandine ET son distributeur, Scalario devient la couche de coordination inter-entreprises. Network effect : chaque client amène son fournisseur.

H3 — Réseau B2B intra-Scalario : module de commande directe entre clients Scalario (retailer → distributeur). Plateforme à effets de réseau. Move qui transforme Scalario de logiciel à infrastructure commerciale UEMOA.

### Partnership and Ecosystem Plays

H1 — Priorité immédiate :
- Wave Business : partenariat d'intégration technique + présence dans "Wave Partner Directory". Surfer sur la confiance Wave déjà établie avec les marchands.
- CCI-BF (Chambre de Commerce Burkina Faso) : accord de recommandation institutionnel. Faible coût, impact signal fort sur la crédibilité.

H2 — Moyen terme :
- Distributeurs FMCG (Nestlé/Unilever locaux) : sponsoriser des abonnements Scalario pour leurs réseaux retailers. Acquisition en volume, alignement d'intérêts.
- IMFs/Microfinance (Coris Bank, RCPB, Caisse Populaire) : referral mutuel. Elles cherchent des PMEs formalisées. Scalario formalise.
- **Cabinets Comptables & Experts-Comptables — Ecosystem Play stratégique (H2 mid, avec module Comptabilité)** : les experts-comptables UEMOA gèrent 15–30 clients PMEs chacun et sont obligatoires pour les entreprises formelles (OHADA). Si Scalario devient leur outil de travail, chaque comptable devient un canal d'acquisition multiplié. Modèle : le cabinet gère SA propre activité dans Scalario (facturation honoraires, suivi missions, gestion équipe) + accède aux données de ses clients via délégation d'accès. Features requises : (1) Dashboard multi-clients pour cabinet — vue consolidée de tous les clients Scalario du comptable ; (2) Délégation d'accès — le client autorise son comptable à accéder à sa compta depuis son propre compte ; (3) Espace cabinet — le comptable est lui-même client Scalario pour sa propre gestion. Double effet de réseau : le comptable amène ses clients sur Scalario, ses clients le retiennent sur Scalario. Parallèle exact du modèle Xero (NZ) qui est devenu licorne en ciblant les experts-comptables en premier. En UEMOA, les cabinets comptables sont un canal d'acquisition quasi captif et sous-exploité par tous les concurrents actuels.

- **Franchiseurs & Réseaux de Distribution — Adoption imposée (H2–H3)** : un franchiseur ou tête de réseau adopte Scalario → toutes ses unités (franchises, agents, points de vente) l'utilisent par obligation contractuelle ou par standard réseau. Mécanisme différent du comptable : le comptable recommande, le franchiseur impose. 1 deal B2B = 10–50 clients instantanément. Cibles UEMOA : chaînes de pharmacies, réseaux de stations-service, distributeurs avec agents terrain, franchises restauration rapide, réseaux de collecte agricole. Features requises : dashboard tête de réseau (vue consolidée toutes unités), benchmarking inter-unités, standards de config imposés par le franchiseur, reporting consolidé groupe.

- **Groupements / Coopératives / Associations de Commerçants — Adoption collective (H2–H3)** : en UEMOA les commerçants s'organisent en groupements d'achat, coopératives, associations sectorielles. Scalario signe avec le groupement → tous les membres adoptent collectivement. 1 négociation = 20–100 clients. Bonus stratégique : les groupements ont souvent accès à des financements institutionnels (BOAD, AFD, USAID, Proparco) pour digitaliser leurs membres — Scalario peut être l'outil bénéficiaire de ces programmes. Cibles : coopératives agricoles (production + vente dans Scalario), associations de femmes entrepreneures (tarif groupe + microfinance), groupements d'achat marchands (stock mutualisé + commandes groupées fournisseurs).

H3 — Long terme :
- Télécoms (Orange Burkina, Moov Africa) : bundle forfait business + Scalario. Négociation longue, asymétrie de pouvoir — après validation product-market fit uniquement.

---

## 🎲 STRATEGIC OPTIONS

### Option A: Vertical Premium — La Spécialisation Profonde

Devenir le meilleur ERP au monde pour les commerces de produits frais et spécialisés en UEMOA. Blandine = archétype. Taux de Frotte, vrac→sachet, fraîcheur, workflows multi-rôles complexes comme colonne vertébrale produit. Cible : boutiques fruits/légumes/épices, boucheries, poissonneries — tout commerce où le produit se transforme, périme ou se perd. Ticket : 40 000–60 000 FCFA/mois + setup fee 100 000 FCFA. Revenu Y1 par client = 500 000–700 000 FCFA.

**Pros:** Moat produit le plus défendable (aucun concurrent ne cible ça) ; ticket élevé (30 clients = 15M+ FCFA/an) ; clients très fidèles avec switching cost élevé ; Blandine + testers valident déjà la demande.

**Cons:** Marché total limité (quelques milliers de commerces frais en UEMOA) ; chaque client exigeant, onboarding long, support intensif ; difficile à déléguer à des intégrateurs sans formation spécialisée ; scalabilité lente — impossible d'atteindre 100 clients rapidement en solo.

### Option B: Retail de Masse — Le Volume

Se concentrer sur l'ERP le plus simple et le plus déployable pour n'importe quel commerçant UEMOA — épiceries générales, boissons, quincailleries, cosmétiques standard. Testeur boissons = archétype. Onboarding en 1 heure, interface utilisable sans formation informatique. POS + Stock + Caisse + Rôles simples. Ticket : 15 000–25 000 FCFA/mois. Marché adressable Burkina Faso : 10 000–50 000 commerces. UEMOA complet : 100 000+.

**Pros:** Volume énorme ; produit simple = onboarding scalable via intégrateurs non spécialisés ; chemin vers 100 clients nettement plus rapide ; base naturelle pour l'expansion régionale UEMOA.

**Cons:** Ticket faible (80+ clients pour atteindre 2M FCFA/mois) ; différenciation plus fragile vs Excel ; risque de commoditisation si Wave ou acteur bien capitalisé entre sur ce segment.

### Option C: Dual Track — Ancre Premium + Expansion Volume

Les deux simultanément avec règles claires. Blandine = client Premium qui finance la crédibilité. Vendeur boissons = modèle Standard qui construit le volume. Deux tiers de produit sur le même core. La complexité des features Premium ne doit jamais dégrader la simplicité du Standard. Tickets : 25 000 FCFA/mois Standard / 45 000 FCFA/mois Premium.

**Pros:** Blandine devient référence qui crédibilise la vente Standard ; les 3 cas de test actuels valident les 2 tiers en parallèle ; pricing différencié naturel ; double protection long terme (Premium = moat technique, Standard = moat distribution).

**Cons:** Complexité de maintenance double pour un solo founder ; risque de faire deux choses à 80% au lieu d'une à 100% ; communication commerciale plus complexe ; nécessite discipline stricte sur ce qui appartient à chaque tier.

---

## 🏆 RECOMMENDED STRATEGY

### Strategic Direction

Option C — Dual Track séquentiel (pas simultané). Blandine (Premium) = référence de crédibilité. Standard (boissons, cosmétiques) = moteur de volume. Même core produit, features Premium en modules opt-in, jamais en dépendances du Standard.

Stratégie en une phrase : Scalario est le premier système de gestion modulaire multi-département conçu nativement pour les PMEs africaines — offline-first, mobile-first, configurable sans code, tier Standard pour toute structure multi-rôles, tier Premium pour les verticaux complexes — distribué via un réseau d'intégrateurs locaux de confiance en zone UEMOA.

Règle de fer : Core Standard (POS + Stock + Rôles + Caisse) jamais pollué par la complexité Premium. Features Premium = extensions opt-in.

Menace principale à surveiller : Wave. S'ils lancent outils PME en 2026/2027, le Standard track devient plus compétitif. La réponse : dominer le Premium vertical avant que Wave arrive — Wave ne construira jamais un Taux de Frotte.

### Key Hypotheses to Validate

H1 (< 1 mois) : Blandine signe et paie. Si échoue → revoir pricing/promesse/profil Premium avant tout 2e client.
H2 (< 2 mois) : Les 2 testeurs utilisent Scalario activement sans Carlos. Si échoue → Standard trop complexe, onboarding à revoir avant toute vente à volume.
H3 (< 3 mois) : Un commerçant inconnu peut s'inscrire et utiliser le Standard seul (Self-Demo Mode). Si échoue → self-service prématuré, canal intégrateur obligatoire plus longtemps.
H4 (3–6 mois) : Le pricing annuel prepaid est accepté sans friction excessive sur 10 prospects (taux de conversion > 30%). Si échoue → tester mensuel pour identifier si c'est le montant ou le mécanisme.
H5 (6–12 mois) : Un intégrateur formé signe un client Standard sans Carlos au closing. Si échoue → playbook ou formation insuffisants, itérer avant de recruter d'autres intégrateurs.

### Critical Success Factors

1. Blandine documentée comme référence (cas d'usage, témoignage, chiffres avant/après) — un client Premium sans case study ne sert pas le canal intégrateur.
2. Wave/Orange Money intégré avant le 3e client payant — sans réconciliation mobile money native, le taux de renouvellement sera faible.
3. Playbook commercial documenté avant le 1er intégrateur recruté — si Carlos ne peut pas expliquer comment vendre Scalario en 10 slides, un intégrateur ne le fera pas.
4. Règle 3 mois testeurs appliquée sans exception — conversion ou départ, pas de gratuit indéfini.
5. Carlos protège son bandwidth Blandine dans les 30 prochains jours — démo Blandine > tout.
6. Expansion Côte d'Ivoire planifiée maintenant, exécutée à 12 mois — ne pas attendre d'en avoir besoin pour identifier l'intégrateur Abidjan.

---

## 📋 EXECUTION ROADMAP

### Phase 1: Immediate Impact (Mois 0–3)

Objectif : 1 client payant (Blandine), 2 testeurs en usage actif autonome, playbook commercial V1 documenté.

Semaines 1–2 : Démo Blandine → closing (setup fee 100 000 FCFA + 400 000 FCFA/an). Mécanisme de paiement décidé avant la démo (Wave ou virement). Scope V1 clarifié vs features post-contrat (WhatsApp, Taux de Frotte, vrac→sachet = livrables avec dates, pas promesses floues).
Semaines 2–4 : Onboarding Blandine sur place, formation 5 utilisateurs, go-live Phases 1–4 minimum. Documenter le cas d'usage comme référence commerciale.
En parallèle (max 4h/semaine) : Activer les 2 testeurs sur le core Standard, observer sans intervenir, noter les frictions = backlog prioritaire.
Mois 2–3 : Playbook commercial V1 (10 slides, script démo Standard, objections/réponses). Wave integration spécification technique. Règle 3 mois testeurs appliquée : conversion ou sortie.

Jalons : Blandine active sur 6/8 phases ; testeurs autonomes > 3 sessions/semaine ; playbook V1 rédigé.

### Phase 2: Foundation Building (Mois 3–12)

Objectif : 10 clients payants actifs, 2 intégrateurs opérationnels à Ouaga, Wave intégré, 1 vente sans Carlos.

Mois 3–6 : 5 clients Standard via vente directe (pharmacies, cosmétiques, épiceries structurées). Blandine utilisée comme référence dans chaque démo. Wave/Orange Money intégré avant 3e client. WhatsApp Business API livré.
Mois 4–6 : Programme Intégrateur V1 — identifier 2 candidats Ouaga (comptables, formateurs IT), former sur le playbook, premier client signé sous supervision. Modèle commission testé : 20% acquisition + 15% renouvellement.
Mois 6–9 : AI Configuration Wizard V1 — wizard conversationnel (LLM via API) qui configure rôles/modules/workflows par langage naturel. Réduit l'onboarding de 4–8h à 30 minutes. Condition : core stable sur les 3 cas réels. Déployer d'abord aux intégrateurs, pas encore aux clients finaux.
Mois 6–9 : Tester Scalario sur Restauration et Distribution (validation modularité multi-département au-delà du Retail).
Mois 9–12 : AI Pricing Wizard — analyse usage réel (modules actifs, utilisateurs, transactions) et propose automatiquement le tier approprié. Identifier intégrateurs potentiels Abidjan et Dakar.

Jalons : 10 clients payants ; revenu récurrent annualisé 3–4M FCFA/an ; 2 intégrateurs opérationnels ; 1 vente intégrateur sans Carlos.

### Phase 3: Scale & Optimization (Mois 12–36)

Objectif : 100 clients actifs (Burkina + CI + SN), 10+ intégrateurs certifiés, 25–30M FCFA/an ARR.

Mois 12–18 : 8–10 intégrateurs formés UEMOA, programme de certification Scalario, portail intégrateur. 60% nouveaux clients via intégrateurs.
Mois 15–24 : Expansion Côte d'Ivoire (intégrateur Abidjan, 5 premiers clients CI, pricing ajusté +30%).
Mois 18–24 : Expansion Sénégal via intégrateur Dakar.
Mois 24–36 : Freemium Starter (1 user, POS seul, 30 jours) pour funnel acquisition organique — uniquement si onboarding auto-service validé.
Mois 30–36 : Lancement vertical Restauration (extension naturelle Retail frais, 70% code réutilisable).

Jalons : 100 clients actifs ; 10+ intégrateurs certifiés ; 3 verticaux opérationnels ; taux de rétention annuel > 80% ; première discussion financement régional.

---

## 📈 SUCCESS METRICS

### Leading Indicators

Adoption produit : sessions actives/semaine par client (seuil : >5), workflows complétés/semaine, taux d'utilisation des modules activés, utilisateurs actifs sur clients multi-rôles.
Vélocité commerciale : temps moyen démo→signature (objectif <2 semaines Standard, <4 semaines Premium), taux de conversion démo→contrat (objectif >30% à 6 mois), temps signature→go-live (<1 semaine Standard, <3 semaines Premium).
Canal intégrateur : intégrateurs en formation active, clients en pipeline intégrateur, taux de conversion leads intégrateur.
AI Config (dès H2) : taux d'utilisation wizard par intégrateurs, temps de configuration moyen avant/après wizard, taux de configurations acceptées sans modification.

### Lagging Indicators

Mois 3 → Mois 12 → Mois 36 :
- ARR : 400K FCFA → 3–4M FCFA → 25–30M FCFA
- Clients payants actifs : 1 → 10 → 100
- Taux de rétention annuel : — → >70% → >80%
- % clients via intégrateurs : 0% → 20% → 60%
- Marchés actifs : Burkina → Burkina → Burkina + CI + SN
- Net Revenue Retention : — → >100% → >110% (NRR >100% = croissance sans acquisition = signal de santé critique)

### Decision Gates

Gate 1 (Mois 1) : Blandine signe → Go : continuer dual track / No-Go : comprendre avant tout 2e client Premium.
Gate 2 (Mois 3) : Testeurs autonomes sans Carlos → Go : lancer vente Standard active / No-Go : retravailler onboarding avant toute vente à volume.
Gate 3 (Mois 6) : 5 clients payants → Go : lancer Programme Intégrateur V1 / No-Go : identifier le blocage avant canal indirect.
Gate 4 (Mois 12) : 1 client signé par intégrateur sans Carlos → Go : scaler canal intégrateur / No-Go : playbook insuffisant, réitérer.
Gate 5 (Mois 12) : Core produit stable sur 3 verticaux → Go : développer AI Config Wizard / No-Go : wizard sur produit instable = frustration.
Gate 6 (Mois 18) : 20 clients actifs dans même zone géographique → Go : activer canal B2B inter-entreprises / No-Go : réseau pas assez dense, attendre seuil critique.

---

## ⚠️ RISKS AND MITIGATION

### Key Risks

1. Wave lance outils de gestion PME (probabilité haute, impact très élevé) : 8M+ users, trust établie, rails mobile money. Menace existentielle sur le Standard track.
2. Carlos burnout en solo founder (probabilité moyenne, impact existentiel) : 3 onboardings simultanés + dev + commercial = charge critique. Si Carlos tombe, tout s'arrête.
3. Blandine ne renouvelle pas après an 1 (probabilité moyenne, impact élevé) : features promises non livrées ou adoption insuffisante = référence Premium effondrée.
4. Pénurie d'intégrateurs qualifiés en UEMOA (probabilité haute, impact élevé) : densité réellement faible. Mauvais intégrateurs = dommage réputationnel.
5. Instabilité politique Burkina Faso (probabilité haute, impact moyen-élevé) : 3 coups depuis 2022. Dégradation possible de l'activité commerciale cible.
6. Testeurs gratuits indéfinis (probabilité haute, impact moyen) : sans règle stricte, ils consomment du support sans revenu et faussent les métriques d'adoption.
7. Chicken-and-egg canal B2B inter-entreprises (probabilité moyenne, impact moyen) : réseau sans masse critique = expérience décevante.

### Mitigation Strategies

1. Wave → Accélérer domination vertical Premium (Taux de Frotte, workflows complexes = Wave ne construira jamais ça). Verrouiller intégrateurs locaux avant Wave. Surveiller annonces produit trimestriellement.
2. Burnout → Règle stricte : Blandine = max 60% bandwidth les 30 prochains jours. Testeurs = max 4h/semaine. Identifier 1 personne de confiance pour support de base en cas d'indisponibilité.
3. Non-renouvellement Blandine → Livrer features promises avec dates fermes dans le contrat. Revues de satisfaction à 3, 6, 9 mois. Documenter les gains réels (pertes réduites, temps économisé).
4. Intégrateurs insuffisants → Sélection stricte, certification obligatoire, 3 premiers clients supervisés par Carlos, déréférencement immédiat si plainte fondée.
5. Instabilité Burkina → Expansion CI démarrée à Mois 12 sans attendre. Plafond : max 60% du revenu total sur Burkina à Mois 18. Intégrateur Abidjan identifié dès Mois 9.
6. Testeurs gratuits → Contrat verbal maintenant : 3 mois gratuits, proposition commerciale formelle à Mois 2, pas de prolongation tacite.
7. B2B prématuré → Gate 6 (20 clients même zone) = condition stricte. Pilote fermé entre 5 clients volontaires avant déploiement général.

---

## 🎯 POSITIONNEMENT CONCURRENTIEL

### One-Pager — Scalario vs Concurrents

| Critère | Excel | Sage | Odoo | Wave (futur) | **Scalario** |
|---|---|---|---|---|---|
| Mobile-first | ❌ | ❌ | ❌ | ✅ | ✅ |
| Offline-first | ✅ | ❌ | ❌ | ❌ | ✅ |
| Contexte africain natif | ❌ | ❌ | ❌ | ⚠️ | ✅ |
| Multi-entités / Multi-dept | ❌ | ⚠️ | ✅ | ❌ | ✅ |
| AI Configuration universelle | ❌ | ❌ | ❌ | ❌ | ✅ |
| Templates sectoriels | ❌ | ❌ | ⚠️ | ❌ | ✅ |
| Intégrateurs locaux UEMOA | ❌ | ❌ | ⚠️ | ❌ | ✅ |
| Prix accessible UEMOA | ✅ | ❌ | ❌ | ✅ | ✅ |
| Workflows inter-départements | ❌ | ❌ | ✅ | ❌ | ✅ |
| Universal (tous secteurs) | ❌ | ❌ | ✅ | ❌ | ✅ |

### Pitch en Une Phrase par Audience

**Pour un commerçant UEMOA :** "Scalario c'est votre Excel qui sait parler à vos employés, qui marche sans Internet, et qui vous envoie votre résumé du jour sur WhatsApp."

**Pour un intégrateur :** "Scalario vous donne une plateforme configurable pour n'importe quel type d'entreprise — vous déployez en quelques heures avec l'AI, pas en semaines de formation."

**Pour un investisseur :** "Scalario est la plateforme ERP universelle pour les marchés sous-servis mondiaux — mobile-first, offline-first, AI-driven, distribuée via intégrateurs locaux. Beachhead UEMOA, vision globale."

---

## 💰 MODÈLE FINANCIER DE BASE

### Viabilité — Les Chiffres Clés

**Burn mensuel actuel (Carlos solo) :**
- Supabase : ~15 000–30 000 FCFA/mois
- Domaine, outils divers : ~10 000 FCFA/mois
- Coût principal = temps Carlos (opportunity cost)
- **Cash burn réel : quasi nul**

**Revenu par client (année 1) :**

| Tier | Setup Fee | Abonnement annuel | Total Y1 | Renouvellement Y2+ |
|---|---|---|---|---|
| Standard | 75 000 FCFA | 270 000 FCFA | 345 000 FCFA | 270 000 FCFA |
| Premium (Blandine) | 100 000 FCFA | 400 000 FCFA | 500 000 FCFA | 400 000 FCFA |
| Pro Multi-entités | 150 000 FCFA | 540 000 FCFA | 690 000 FCFA | 540 000 FCFA |

**Breakeven / Default Alive :**

Si Carlos vise 500 000 FCFA/mois de revenus personnels (~800 USD) :
- Besoin : 6 000 000 FCFA/an
- Mix 70% Standard + 30% Premium : revenu moyen/client = ~380 000 FCFA/an
- **Breakeven : ~16 clients actifs**
- Avec renouvellements (NRR > 100%) : ~14 clients suffisent dès Y2

**Jalons financiers :**

| Jalons | Clients | ARR estimé | Signification |
|---|---|---|---|
| Ramen profitable | 10 | 3.5M FCFA | Carlos vit du produit |
| Default alive | 16 | 6M FCFA | Breakeven confortable |
| Premier recrutement | 20–25 | 8–10M FCFA | Peut payer un premier employé |
| Seed-ready | 50 | 20M FCFA | Traction suffisante pour lever |
| Série A | 200 | 80M FCFA | Expansion régionale prouvée |

---

## 👥 PLAN DE CONSTITUTION D'ÉQUIPE

### Philosophie : "Hire Who You Need When You Need It"

Pas de recrutement anticipé. Chaque recrutement répond à un blocage réel, financé par le revenu existant.

### Stack Actuelle : Carlos + AI Augmentation

Carlos ne travaille pas seul — il opère avec un stack d'outils AI qui multiplie sa capacité individuelle :

- **Claude Code (Anthropic)** : pair-programmer permanent — architecture, code review, refactoring, debugging, documentation
- **BMAD Agents (CIS)** : agents spécialisés pour la stratégie produit, business model, PRD, roadmap — remplace partiellement un product strategist senior
- **Principe** : les tâches qui prendraient 1 semaine à un développeur seul → 1–2 jours avec Claude Code. Les workshops stratégiques qui coûtent €5 000 avec un consultant → exécutables en autonomie avec BMAD.

**Impact sur les triggers de recrutement** : les seuils ci-dessous sont volontairement conservateurs car l'AI augmentation repousse le moment où Carlos est réellement en "blocage". Un développeur "solo" sans AI atteint le blocage à ~10 clients. Carlos peut tenir jusqu'à ~20 clients avant d'avoir besoin d'aide humaine.

### Séquence de Recrutement

**Trigger #1 — À ~20 clients : Customer Success / Onboarding Specialist**
- Symptôme déclencheur : Carlos passe >40% de son temps en support et onboarding au lieu de développer
- Profil : personne locale UEMOA, bonne pédagogie, à l'aise avec les outils digitaux. Pas obligatoirement développeur.
- Rôle : onboarding nouveaux clients, formation utilisateurs, support niveau 1, remontée des bugs produit
- Budget : 150 000–200 000 FCFA/mois

**Trigger #2 — À ~30 clients ou 3 intégrateurs actifs : Commercial / Partner Manager**
- Symptôme déclencheur : le pipeline commercial dépasse ce que Carlos peut gérer seul
- Profil : commercial terrain UEMOA, réseau PMEs ou experts-comptables, à l'aise en démo produit
- Rôle : gestion du canal intégrateur, prospection directe, closing
- Budget : base 150 000 FCFA + commission sur ventes

**Trigger #3 — À ~50 clients ou lancement H2 : Développeur Backend ou Flutter**
- Symptôme déclencheur : la roadmap produit accumule du retard à cause du bandwidth Carlos
- Profil : développeur NestJS ou Flutter junior/intermédiaire, peut être remote UEMOA ou diaspora
- Rôle : développement modules H2 (Comptabilité, RH, AI layer)
- Budget : 200 000–350 000 FCFA/mois selon profil et localisation

**Trigger #4 — À levée de fonds : Équipe structurée**
- CTO (si Carlos veut rester CEO) ou Head of Product
- Head of Sales UEMOA
- Data Engineer (pour la couche AI analytique H3)

### Principe directeur
Chaque recrutement doit être financé par le revenu actuel avant d'être exécuté. Pas de dette salary avant traction prouvée.

---

## 🔐 SÉCURITÉ & CONFORMITÉ DATA

### Pourquoi c'est un asset stratégique, pas juste une feature

Les secteurs premium (mines, santé, éducation nationale, gouvernement) ne signeront pas sans garanties de sécurité documentées. La sécurité est un argument commercial, pas seulement technique.

### Couches de Sécurité

**Infrastructure (Supabase/PostgreSQL) :**
- Chiffrement au repos (AES-256) et en transit (TLS 1.3) — natif Supabase
- Row-Level Security (RLS) — isolation totale des données entre tenants
- Backup automatique quotidien avec rétention 30 jours
- Option self-hosted pour clients exigeant la souveraineté des données

**Application :**
- Authentification multi-facteurs (MFA) pour les rôles sensibles (propriétaire, direction)
- Sessions avec timeout automatique
- Audit trail complet : qui a fait quoi, quand, depuis quel appareil — sur toute l'application
- Permissions granulaires par rôle, module, champ (déjà dans l'architecture)

**Conformité réglementaire UEMOA :**
- **Burkina Faso** : Loi n°010-2004/AN sur la protection des données personnelles, supervisée par l'ARTB
- **Côte d'Ivoire** : Loi n°2013-450 relative à la protection des données à caractère personnel, ARTCI
- **Sénégal** : Loi n°2008-12 sur la protection des données personnelles, CDP
- Conformité RGPD pour les clients avec opérations en Europe
- Politique de confidentialité et CGU adaptées par pays

**Pour les secteurs sensibles :**
- Option self-hosted Supabase ou PostgreSQL on-premise (mines, gouvernements, hôpitaux)
- Audit de sécurité annuel documenté (argument commercial fort pour les grands comptes)
- Contrat de traitement des données (DPA) disponible sur demande

### Protection contre les Accès Non Autorisés et l'Usage Illégitime

**Pourquoi le modèle SaaS est le meilleur anti-crack :**
Contrairement aux logiciels desktop, la logique métier de Scalario tourne sur les serveurs — pas sur l'appareil du client. Décompiler l'app Flutter ne donne accès à rien sans auth serveur valide. Le "crack" classique est structurellement impossible.

**Enforcement des abonnements (côté serveur, non contournable) :**
- Statut d'abonnement vérifié server-side à chaque requête API — jamais côté client
- Feature flags par tier enforced dans NestJS — impossible à bypasser depuis Flutter
- Tenant suspendu = accès coupé immédiatement au niveau API, données intactes
- Aucun fichier de licence local crackable — tout est en base

**Protection contre les accès non autorisés en masse :**
- Rate limiting sur toutes les routes API (NestJS + Redis) — limite les tentatives de force brute
- Blocage automatique après N tentatives de connexion échouées (compte + IP)
- JWT tokens courte durée + refresh tokens — une session volée expire vite
- Détection d'anomalies : connexion depuis pays inhabituel, export massif de données, requêtes anormalement fréquentes → alerte + blocage automatique (H2)
- API keys pour les intégrations tierces avec scopes limités — pas d'accès global

**Sécurité de l'app Flutter :**
- Certificate pinning — empêche les attaques man-in-the-middle sur mobile
- Code obfuscation Flutter — rend le reverse engineering difficile
- Détection root/jailbreak — avertissement si appareil compromis
- Pas de données sensibles stockées en clair sur l'appareil (Isar encrypté)

**Isolation entre tenants (anti-fuite de données) :**
- RLS PostgreSQL — au niveau base de données, un tenant ne peut physiquement pas lire les données d'un autre même si le code applicatif a un bug
- Audit trail complet — chaque accès est tracé, les accès anormaux sont détectables

### Roadmap Sécurité

- **H1** : MFA, audit trail, RLS validé, rate limiting, JWT courte durée, certificate pinning Flutter, politique de confidentialité par pays
- **H2** : Détection d'anomalies automatisée, penetration testing, DPA formalisé, certification ISO 27001 explorée
- **H3** : SOC 2 Type II pour marchés développés, conformité sectorielle santé/éducation, encryption par tenant

---

## 💼 STRATÉGIE DE FINANCEMENT

### Philosophie : Bootstrap First, Raise When Proven

Ne pas lever de fonds avant d'avoir la traction qui justifie la valorisation. Chaque euro levé trop tôt dilue pour pas grand chose.

### Phases de Financement

**Phase 0 — Bootstrap (maintenant → 16 clients) :**
- Financement : 0 FCFA externe. Revenu clients = seul carburant.
- Objectif : atteindre le breakeven (~16 clients) avant toute discussion externe.
- Avantage : zéro pression investisseur, pleine liberté de pivots.

**Phase 1 — Grants & Impact Capital (16–50 clients) :**
- Sources prioritaires :
  - **AFD / Expertise France** : programmes de digitalisation PMEs UEMOA
  - **BOAD** : fonds d'appui aux startups UEMOA
  - **Orange Ventures** : fonds tech Afrique francophone
  - **Startup Act Burkina** : cadre légal favorable aux startups burkinabè
  - **Google for Startups Africa** : crédits cloud + accompagnement
- Montant cible : 50–150M FCFA (75–230K USD)
- Usage : accélération développement modules H2 + premier recrutement

**Phase 2 — Seed Round (50–100 clients, expansion CI/SN prouvée) :**
- Sources prioritaires :
  - **Partech Africa** (fonds VC Afrique, Paris/Dakar)
  - **Janngo Capital** (impact VC Afrique francophone)
  - **Breega** (VC early-stage, focus Afrique)
  - **Business angels diaspora africaine** (France, Canada, USA)
- Montant cible : 500M–1.5B FCFA (750K–2.3M USD)
- Valorisation cible : 5–8× ARR = ~3–5M USD à 50 clients
- Usage : équipe structurée, expansion 3 marchés, AI layer H2

**Conditions préalables avant de lever :**
1. NRR > 100% (clients qui upgradent)
2. Au moins 1 intégrateur qui vend sans Carlos
3. Présence dans 2 marchés UEMOA (Burkina + CI ou SN)
4. ARR > 20M FCFA (~30K USD) — signal de willingness to pay réel

---

## 📣 STRATÉGIE MARKETING & MARQUE

### Slogan — À Définir

Slogan actuel "une solution, mille possibilités" = trop générique, à réviser. Direction validée : universel, inclusif, aucune exclusion par taille ou secteur (boutique ET groupe minier ET université). Candidats explorés : "Toute organisation. Une plateforme." / "Une plateforme. Toutes les organisations." / "One platform. Every organization." (global). Wording final à affiner via copywriting dédié avant lancement marketing.

### Dual Branding — Deux Entités Distinctes

```
CARLOS SIMPORÉ | BUILDER          SCALARIO
(Personal Brand)                   (Product Brand)
        ↓                                ↓
  TikTok + Facebook             Facebook + LinkedIn
  Multi-projets                  Clients & Partenaires
  Build in Public                Success Stories
  Défis & Apprentissages         Démos & Valeur Produit
        ↓                                ↓
         → Crédibilité → Confiance → Clients →
```

---

### Carlos Simporé | Builder — Stratégie Personal Brand

**Positionnement :** "Je suis un builder africain. Je construis des produits tech pour résoudre des problèmes réels en Afrique. En public."

**Plateformes prioritaires :**
- **TikTok** : format court, audience jeune, croissance organique forte. Contenu visuel rapide.
- **Facebook** : pénétration massive UEMOA, audience entrepreneurs/commerçants, groupes PME actifs.

**Piliers de Contenu — Build in Public :**

1. **#ScalarioBuild** — Le journal de bord de Scalario
   - "Aujourd'hui j'ai eu ma première démo avec Blandine"
   - "Voici pourquoi j'ai changé le pricing ce matin"
   - "Ce module m'a pris 3 jours — voici ce que j'ai appris"
   - Fréquence : 2–3 fois/semaine

2. **#FounderFails** — Les erreurs en public
   - "J'ai sous-estimé l'onboarding. Voici ce qui s'est passé."
   - "Mon premier client a failli partir. Voici pourquoi et comment j'ai réagi."
   - Ton : honnête, sans filtre, sans flatterie de soi-même
   - Fréquence : 1 fois/semaine

3. **#BuilderAfrique** — Perspective unique d'un dev entrepreneur en UEMOA
   - "Construire un SaaS au Burkina Faso : réalités qu'on ne dit pas"
   - "Pourquoi j'ai choisi Flutter pour un marché offline"
   - "Ce que les entrepreneurs africains attendent vraiment du digital"
   - Fréquence : 1 fois/semaine

4. **#MultiprojetsBuilder** — Les autres projets de Carlos (pas que Scalario)
   - Espace pour partager d'autres constructions, expérimentations, side projects
   - Construit l'image "builder prolifique" pas "fondateur d'une seule startup"
   - Fréquence : selon projets en cours

**Métriques de succès personal brand :**
- 1 000 abonnés en 3 mois → 10 000 en 12 mois
- Chaque post Scalario = 3–5 leads entrants potentiels
- Objectif final : Carlos est LA référence "tech entrepreneur UEMOA" dans son espace

---

### Scalario — Stratégie Product Brand

**Positionnement :** "Le système de gestion qui comprend comment vous travaillez."

**Ton :** professionnel mais accessible. Pas corporate. Humain. En français africain.

**Plateformes prioritaires :**
- **Facebook** : démos produit, success stories clients, groupes PME UEMOA
- **LinkedIn** : partenaires, intégrateurs, investisseurs, enterprise clients
- **WhatsApp** : communauté intégrateurs (groupe officiel), support clients

**Piliers de Contenu Scalario :**

1. **Success Stories clients** — "Blandine a réduit ses pertes de 40% en 2 mois"
   - Avec permission client, chiffres réels, témoignage vidéo si possible
   - Format : avant/après, problème → solution → résultat

2. **Démos produit** — "En 60 secondes, voici comment configurer un arrêt de caisse"
   - Format court TikTok/Reels sur les features clés
   - Objectif : montrer la simplicité

3. **Éducation PME** — "5 erreurs que font les commerçants UEMOA sur la gestion de stock"
   - Contenu de valeur qui attire les prospects avant qu'ils cherchent un ERP
   - Positionne Scalario comme l'expert, pas juste un outil

4. **Intégrateur Spotlight** — Mettre en avant les intégrateurs certifiés
   - Crédibilise le réseau, motive les intégrateurs, rassure les prospects

**Cohérence des deux marques :**
- Carlos parle de Scalario sur son personal brand → trafic vers la marque produit
- Scalario ne mentionne pas Carlos explicitement → crédibilité produit indépendante
- Les deux se renforcent sans se confondre

---

## 🛠️ STACK TECHNIQUE & ÉVOLUTION

### Stack Actuel (H1 — Garder)

| Couche | Technologie | Statut |
|---|---|---|
| Mobile / Desktop | Flutter + Isar | ✅ Core — ne pas changer |
| API Backend | NestJS (TypeScript) | ✅ Core — ne pas changer |
| Base de données | Supabase / PostgreSQL | ✅ Core — ne pas changer |
| Sync offline | Isar (local) + Supabase Realtime | ✅ Différenciateur clé |

**Flutter** : irremplaçable pour offline-first + mobile-first + Android/iOS/Desktop en un codebase. Limite future à surveiller : dashboards enterprise complexes (comptabilité, analytics lourds) — Flutter Web pas encore dominant pour ces cas.

**NestJS** : architecture modulaire alignée avec la vision modules Scalario. TypeScript = maintenabilité sur large codebase. Extensible avec microservices.

**Supabase** : surcouche PostgreSQL open source — pas de lock-in réel. RLS natif = multi-tenant. Realtime = sync offline. Self-hostable = souveraineté des données pour clients enterprise (mines, universités, gouvernements). Migration vers PostgreSQL direct possible en quelques jours si nécessaire.

### Additions Planifiées par Horizon

**H2 (Mois 6–18) — Additions critiques :**

- **Python/FastAPI microservice AI** : traitement LLM (Claude API), parsing Excel, ML analytics. NestJS appelle ce service — les deux coexistent. Ne pas forcer l'AI dans NestJS.
- **REST API publique versionnée** (`/api/v1/`) : condition pour le Marketplace et le SDK intégrateurs. À architecturer dès le début — impossible à changer proprement après.
- **TypeScript SDK** : premier SDK pour intégrateurs avancés construisant des modules custom.
- **Message Queue (Redis/BullMQ)** : jobs async pour sync offline, notifications, rapports lourds, envois WhatsApp.

**H3 (Mois 18–36) — Additions plateforme :**

- **Next.js/React (web dashboard)** : companion framework pour dashboards enterprise complexes (comptabilité, analytics, Template Builder web). Ne remplace pas Flutter — complète pour les vues lourdes web-only.
- **Python SDK** : second SDK pour développeurs data/ML qui intègrent avec Scalario.
- **PostgreSQL self-hosted option** : pour clients enterprise qui exigent la souveraineté des données (réglementation locale, données sensibles).

### Stack Cible H3+

```
Mobile / Desktop    →  Flutter (offline-first, utilisateurs terrain)
Web Dashboard       →  Next.js/React (analytics, comptabilité, admin enterprise)
API Core            →  NestJS (modules Scalario, business logic)
AI Layer            →  Python/FastAPI (Claude API, Excel parsing, ML)
Base de données     →  Supabase/PostgreSQL (multi-tenant, RLS, Realtime)
Queue               →  Redis/BullMQ (jobs async)
SDK Intégrateurs    →  REST API + TypeScript SDK + Python SDK
```

### Trajectoire Microservices

**Principe de base :** ne pas commencer avec des microservices. Commencer avec un monolithe modulaire, extraire uniquement quand la douleur est prouvée par des signaux concrets (lenteur, scaling bottleneck, équipe qui grandit).

**H1 — Monolithe modulaire (maintenant)**
NestJS est modulaire par nature — les modules NestJS créent des frontières internes propres sans complexité opérationnelle de microservices. Déploiement unique. Maintenance simple pour un fondateur solo.

**H2 — Premier microservice naturel (déjà planifié)**
Le service Python/FastAPI pour l'AI est le premier microservice de facto. NestJS appelle Python via HTTP ou queue Redis. La séparation est naturelle (deux langages, deux responsabilités distinctes). C'est le bon premier pas.

```
H2 : NestJS (core business) + Python/FastAPI (AI) + Redis/BullMQ (jobs async)
```

**H3 — Extraction conditionnelle (18–36 mois, si signaux prouvés)**
Extraire uniquement si un service spécifique crée un bottleneck réel :

| Service à extraire | Signal déclencheur |
|---|---|
| Reporting / Analytics | Requêtes lourdes pénalisent le POS temps réel |
| Notifications / WhatsApp | Volume élevé ralentit le core API |
| Sync Engine offline | Charge sync de 100+ clients simultanés |
| Search / Indexing | Recherche full-text lente à l'échelle |

Condition préalable : équipe backend 3+ développeurs. Un fondateur solo ne peut pas gérer 5 microservices en production.

**H4+ — Architecture microservices complète**
Justifiée uniquement si équipe 5+ devs backend ET besoins de scaling prouvés par les données. À ce stade le monolithe NestJS a été progressivement découpé en services indépendants le long des frontières naturelles des modules Scalario.

### Multi-Boutique : Modèles de Stock Supportés

Architecture multi-entité de Scalario supporte nativement trois modèles selon la configuration client :

**Modèle A — Stock Indépendant + Transferts Inter-Boutiques**
Chaque boutique possède son stock propre. Un transfert crée un mouvement bilatéral tracé : Boutique A (−10 unités) → Boutique B (+10 unités). Workflow avec approbation optionnelle par la Direction. Idéal pour : propriétaire de plusieurs boutiques indépendantes, franchises, points de vente géographiquement séparés.

**Modèle B — Stock Partagé (Dépôt Central)**
Un dépôt central détient le stock. Les boutiques font des demandes d'approvisionnement. Le dépôt est la source de vérité unique — les boutiques ne "possèdent" pas de stock, elles consomment depuis le pool central. Idéal pour : grossiste avec antennes de vente, chaîne de restauration avec cuisine centrale.

**Modèle C — Hybride Multi-Niveau**
Plusieurs dépôts + boutiques en cascade. Ex. : Dépôt National → Dépôt Régional Ouaga → Boutique Rue du Commerce. Chaque niveau peut transférer au niveau inférieur. Idéal pour : distribution nationale, coopératives avec entrepôts régionaux.

Ces modèles sont des **configurations**, pas des développements custom. Ils s'appuient sur :

- L'architecture multi-entité existante (chaque boutique/dépôt = une entité)
- Les workflows inter-entités (transferts = workflow avec approbation)
- Les permissions par rôle (le gérant Boutique A ne voit que son stock)
- La sync offline (un livreur fait un transfert sans connexion, sync à l'arrivée)

**Impact PRD** : ajouter module "Gestion Multi-Points de Vente" avec : configuration du modèle de stock, règles de transfert inter-entités, tableau de bord consolidé propriétaire (vue agrégée stock total / CA total toutes boutiques), rapports comparatifs par boutique.

---

### Décisions Architecturales à Prendre Maintenant (PRD)

1. **REST API versionnée dès V1** — `/api/v1/` obligatoire, ne pas exposer des endpoints non versionnés
2. **Python microservice AI** — architecturer la séparation NestJS/Python dès H2, pas retrofiter
3. **Self-hosted Supabase** — tester l'option avant d'avoir un client enterprise qui la demande
4. **Chaque module expose des actions AI-invocables** — principe architectural, pas une feature optionnelle
5. **i18n complet dès maintenant** — aucune string hardcodée en français, multi-devise natif
6. **Compliance framework pluggable** — OHADA = un plugin, pas du code core
7. **Payment adapter pattern** — Wave = un adapter, pas une intégration directe
8. **Template Builder = outil de configuration, pas de génération de code** — les intégrateurs configurent les modules existants (activer/masquer champs, renommer labels, définir workflows, rôles, permissions, données sectorielles par défaut). Ils ne génèrent pas de nouveaux écrans Flutter. Générer des écrans = maintenance impossible + qualité incontrôlable. Pour les cas vraiment custom (nouveau module from scratch) → SDK (H4, intégrateurs avancés uniquement).
9. **Flywheel Modules → Secteurs** — chaque nouveau module Core déverrouille plusieurs secteurs entiers servables via templates sans aucun développement sectoriel. Principe : Carlos construit des modules génériques, les intégrateurs configurent des templates sectoriels. Exemples : Gestion Documentaire → avocats + notaires + RH avancé + hôpitaux + administration publique ; Projets/Chantiers → BTP + agences + consultants + ONG ; Dossier Patient → cliniques + pharmacies + laboratoires. La priorisation des modules Core doit être guidée par le nombre de secteurs qu'ils déverrouillent, pas par l'affinité du fondateur pour un secteur donné.
10. **Verticalisation native : AI configure, UI-driven rend** — deux couches distinctes, pas des alternatives. L'AI est l'interface de configuration (input) : l'intégrateur décrit ce dont le business a besoin en langage naturel, l'AI configure les modules en conséquence. L'UI-driven est le rendu du résultat (output) : l'end user voit une vraie interface Flutter native, propre et cohérente. L'intégrateur ne touche jamais à un panneau de settings manuellement. Deux niveaux de configuration, tous deux via AI : (a) Template = labels, navigation, workflows, rôles, données par défaut ; (b) Extension Module = champs custom, règles de validation, calculs automatiques, automations sectorielles. Flow : "j'ai besoin d'un champ Taux de Frotte calculé sur les produits frais" → AI configure → UI rend le champ nativement dans Flutter. Un seul niveau demande du dev : Custom Module via SDK (H4). Le Template Builder est un outil métier piloté par AI, pas un outil développeur.
11. **Structure organisationnelle dynamique — rôles, permissions ET départements en base, jamais hardcodés** — les rôles et permissions sont des données stockées en base par tenant, pas des enums TypeScript dans le code. Chaque tenant définit ses propres noms de rôles (libres), ses propres permissions par module, ses propres règles d'accès. L'AI crée et configure les rôles selon la description du client : "j'ai un responsable magasin qui voit le stock mais pas les finances" → AI crée le rôle avec les permissions exactes. Les templates sectoriels incluent des jeux de rôles par défaut (ex : Template Cabinet Juridique → rôles "Associé", "Collaborateur", "Secrétaire juridique" préconfigurés). Aucun nom de rôle ne doit être hardcodé dans le code — ce sont des configurations. H1 peut avoir des rôles de base préconfigurés comme point de départ, mais l'architecture doit être dynamique dès le début pour ne pas bloquer H2.
12. **Action chips AI cacheable offline** — les suggestions d'actions AI courantes (top 20 queries par rôle) sont pré-calculées et cacheables localement. L'AI temps réel est un bonus, pas un prérequis pour l'UX de base.

---

_Generated using BMAD Creative Intelligence Suite - Innovation Strategy Workflow_
