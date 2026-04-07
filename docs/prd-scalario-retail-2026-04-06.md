# Product Requirements Document: Scalario Retail — Phase 1

**Date:** 2026-04-06
**Auteur:** Carlos Simporé
**Version:** 1.0
**Type de projet:** Application mobile & desktop de gestion de boutique retail
**Niveau projet:** Level 3
**Statut:** Draft

---

## Document Overview

Ce PRD définit les exigences fonctionnelles et non-fonctionnelles pour Scalario Retail Phase 1. Il couvre uniquement le produit codé en dur — aucune référence aux phases futures (UI Engine, SDUI, config no-code, AI).

**Documents liés :**
- Brief Phase 1 : `_bmad-output/phase1-brief.md`

---

## Executive Summary

Scalario Retail Phase 1 est une application de gestion de boutique retail destinée à 3 types de business : produits frais périssables, boissons, et cosmétiques. Le produit permet aux propriétaires de contrôler leur boutique à distance, aux gérants de gérer les opérations quotidiennes, et aux vendeurs d'effectuer les ventes.

L'app fonctionne en mode offline-first (tout marche sans Internet) et couvre : point de vente, gestion de stock, taux de frotte, conversions vrac→sachet, caisse, dépenses, commandes internes, rapports et notifications.

---

## Product Goals

### Business Objectives

1. **Contrôle à distance** — Permettre aux propriétaires de suivre l'activité de leur boutique sans être physiquement présents (CA, stock, dépenses, commandes)
2. **Digitalisation des opérations** — Remplacer les cahiers et la gestion manuelle par un outil numérique fiable couvrant POS, stock, caisse et commandes
3. **Produit multi-vertical** — Couvrir 3 verticals retail (frais, boissons, cosmétiques) avec un seul produit, extensible à d'autres business types en dur

### Success Metrics

| Métrique | Cible | Deadline |
| -------- | ----- | -------- |
| Adoption testeurs | 3 testeurs actifs (Blandine + 2) utilisent l'app quotidiennement | Fin avril 2026 |
| Clients payants | 50-100 clients (mix local + cloud) | 1 an après lancement |
| Revenu par client | 5K-15K FCFA/mois (local) / 12.5K-15K FCFA/mois (cloud) | Dès lancement |
| Abandon ancien outil | Les testeurs n'utilisent plus cahier/Excel sous 2 semaines | Par testeur |
| Fiabilité offline | 0 perte de données après resync | Fin avril 2026 |
| Temps de setup | Boutique + premier produit créés en < 5 min | Fin avril 2026 |

---

## User Personas

### Blandine — La Boss Lointaine (Propriétaire, frais/périssables)

- **Situation :** Vit au Sénégal, ouvre une boutique de produits frais à Ouagadougou, jamais sur place
- **Équipe :** Propriétaire + Gérant + Commerciaux (3 niveaux hiérarchiques)
- **Besoin principal :** Chaîne de confiance — chaque maillon (commercial, gérant) confirme, elle valide au bout
- **Frustration actuelle :** Confie son argent et sa marchandise à des gens qu'elle ne peut pas voir ni vérifier
- **Workflow :** Circuit en 8 phases (commande → réception → rayons → vente → pertes → alertes → commandes → arrêt de caisse + inventaire hebdo)
- **Usage :** Consulte l'app matin et soir depuis le Sénégal, valide les commandes, lit les rapports
- **Palier :** Pro (cloud obligatoire — contrôle à distance depuis un autre pays)

### Yempabou — Le Patron Pragmatique (Propriétaire, boissons/divers)

- **Situation :** Parfois absent, gestion familiale, ~150 produits différents
- **Équipe :** Patron + Gérante (2 niveaux)
- **Outil actuel :** Cahier + Gescom (app web béninoise) — connaît le concept d'app de gestion
- **Besoin principal :** Stock dispo + alertes stock bas + état de la caisse + factures
- **Frustration actuelle :** Vol et pertes non prouvables, contrôle par appel quand absent
- **Usage :** Vérifie stock et caisse, veut des factures pour les clients
- **Palier :** Boutique (téléphone seul) → upsell Pro probable quand il verra la valeur du suivi à distance

### Vivien — Le Commerçant Connecté (Propriétaire, cosmétiques)

- **Situation :** Pas toujours à la boutique, 1 vendeuse, ~60 produits
- **Équipe :** Patron + Vendeuse (2 niveaux)
- **Outil actuel :** Cahier uniquement
- **Besoin principal :** Il entre les produits, elle vend — supervision bienveillante + impression de factures thermiques
- **Frustration actuelle :** Quand il n'est pas là, il ne sait pas combien a été vendu — appel uniquement
- **Workflow :** Ouverture caisse → vente → impression facture → arrêt de caisse en fin de journée avec la vendeuse
- **Usage :** Les deux utilisent l'app sur 2 téléphones distincts
- **Palier :** Pro (cloud, 2 devices)

### Gérant (rôle transversal)

- **Rôle :** Gestion quotidienne sur place
- **Besoin principal :** Gérer stock, caisse, commandes efficacement
- **Frustration actuelle :** Tout est sur papier, erreurs fréquentes
- **Usage :** Utilise l'app toute la journée — réception marchandise, entrées stock, fermeture caisse, commandes

### Commercial / Vendeur (rôle transversal)

- **Rôle :** Vente au comptoir
- **Besoin principal :** Encaisser vite, voir les prix, imprimer les factures
- **Frustration actuelle :** Doit demander les prix au gérant, pas d'historique
- **Usage :** POS toute la journée, impression factures, création de commandes ponctuelles

---

## Functional Requirements

Les Functional Requirements (FRs) définissent **ce que** le système fait. Priorité MoSCoW : Must Have (critique MVP) / Should Have (important, contournable) / Could Have (bonus).

---

### FR-001: Créer une vente détail

**Priorité:** Must Have

**Description:**
Le vendeur peut créer une vente en sélectionnant des produits, en ajustant les quantités, et en validant la transaction. Le prix total est calculé automatiquement.

**Acceptance Criteria:**
- [ ] Sélection de produits depuis le catalogue (recherche + liste)
- [ ] Ajustement quantité par produit
- [ ] Calcul automatique du prix total
- [ ] Confirmation de la vente et enregistrement en base locale
- [ ] La vente fonctionne sans connexion Internet

**Dependencies:** FR-006

---

### FR-002: Sélection du mode de paiement

**Priorité:** Must Have

**Description:**
Lors d'une vente, le vendeur sélectionne manuellement le mode de paiement utilisé par le client. Pas d'intégration API — simple sélection.

**Acceptance Criteria:**
- [ ] 3 modes disponibles : Cash, Wave, Orange Money
- [ ] Le mode sélectionné est enregistré avec la transaction
- [ ] Le mode apparaît dans les rapports et l'historique

**Dependencies:** FR-001

---

### FR-003: Historique des ventes

**Priorité:** Must Have

**Description:**
Consultation de l'historique des ventes avec filtres (date, vendeur, mode de paiement).

**Acceptance Criteria:**
- [ ] Liste des ventes triée par date (plus récent en premier)
- [ ] Filtres par date, vendeur, mode de paiement
- [ ] Détail d'une vente consultable (produits, quantités, montant, vendeur)

**Dependencies:** FR-001

---

### FR-004: Vente en gros

**Priorité:** Must Have

**Description:**
Vente par unité gros (carton, sac) à un prix gros distinct du prix détail. Le stock est décrémenté en conséquence.

**Acceptance Criteria:**
- [ ] Prix gros configurable par produit, distinct du prix détail
- [ ] Sélection du type de vente (détail ou gros) lors de la transaction
- [ ] Déduction stock correcte selon l'unité gros et son facteur de conversion
- [ ] Historique distingue ventes détail et gros

**Dependencies:** FR-001, FR-006

---

### FR-005: Unités gros avec conversion

**Priorité:** Must Have

**Description:**
Chaque produit peut avoir une unité gros (carton, sac) avec un facteur de conversion vers l'unité détail pour le suivi de stock unifié.

**Acceptance Criteria:**
- [ ] Configuration unité gros + facteur de conversion (ex : 1 carton = 12 unités)
- [ ] Le stock est toujours affiché en unité de base
- [ ] La vente gros décrémente le stock de (quantité × facteur)

**Dependencies:** FR-006

---

### FR-006: Gestion du catalogue produits (CRUD)

**Priorité:** Must Have

**Description:**
Créer, modifier, consulter et supprimer des produits dans le catalogue de la boutique.

**Acceptance Criteria:**
- [ ] Champs : nom, catégorie, prix détail, prix gros (optionnel), unité de base, image (optionnelle)
- [ ] Recherche et filtrage par catégorie
- [ ] Modification et suppression avec confirmation
- [ ] Fonctionne offline

---

### FR-007: Variantes produit

**Priorité:** Should Have

**Description:**
Un produit peut avoir des variantes (taille, poids, conditionnement) avec des prix et stocks distincts.

**Acceptance Criteria:**
- [ ] Ajout de variantes à un produit existant
- [ ] Chaque variante a son propre prix et stock
- [ ] Les variantes apparaissent dans le POS lors de la sélection

**Dependencies:** FR-006

---

### FR-008: Suivi des quantités en stock

**Priorité:** Must Have

**Description:**
Suivi en temps réel des quantités en stock avec historique des mouvements (entrée, sortie, ajustement manuel).

**Acceptance Criteria:**
- [ ] Quantité actuelle visible par produit
- [ ] Historique des mouvements (type, quantité, date, auteur)
- [ ] Ajustement manuel avec motif obligatoire
- [ ] Déduction automatique lors d'une vente

**Dependencies:** FR-006

---

### FR-009: Alertes stock bas

**Priorité:** Must Have

**Description:**
Alerte lorsqu'un produit passe sous un seuil de stock configurable.

**Acceptance Criteria:**
- [ ] Seuil configurable par produit
- [ ] Alerte visuelle dans l'app (badge, couleur)
- [ ] Liste des produits en stock bas accessible rapidement

**Dependencies:** FR-008

---

### FR-010: Entrée stock via approvisionnement

**Priorité:** Must Have

**Description:**
Enregistrement d'un approvisionnement (achat fournisseur) qui incrémente le stock et enregistre le coût.

**Acceptance Criteria:**
- [ ] Sélection des produits et quantités reçues
- [ ] Association optionnelle à un fournisseur
- [ ] Enregistrement du coût d'achat
- [ ] Incrémentation automatique du stock

**Dependencies:** FR-006, FR-008

---

### FR-011: Configuration du taux de frotte

**Priorité:** Must Have

**Description:**
Configurer un pourcentage de perte naturelle (frotte) par produit périssable. Ce taux représente la perte attendue entre l'achat et la vente.

**Acceptance Criteria:**
- [ ] Taux de frotte (%) configurable par produit
- [ ] Champ visible uniquement pour les produits marqués comme périssables
- [ ] Valeur par défaut à 0%

**Dependencies:** FR-006

---

### FR-012: Calcul prix avec taux de frotte

**Priorité:** Must Have

**Description:**
Le système suggère un prix de vente qui intègre le taux de frotte pour garantir la marge malgré les pertes naturelles.

**Acceptance Criteria:**
- [ ] Prix suggéré = coût d'achat / (1 - taux_frotte) × marge souhaitée
- [ ] Le prix suggéré est modifiable (suggestion, pas obligation)
- [ ] Affichage clair de l'impact du taux de frotte sur le prix

**Dependencies:** FR-011, FR-010

---

### FR-013: Règles de conversion vrac → sachet

**Priorité:** Must Have

**Description:**
Définir des règles de conversion pour vendre un produit acheté en vrac dans des unités plus petites (ex : sac 5kg → sachets 100g).

**Acceptance Criteria:**
- [ ] Configuration : unité source, unité dérivée, facteur de conversion
- [ ] Un produit peut avoir plusieurs conversions
- [ ] Les unités dérivées apparaissent comme options de vente dans le POS

**Dependencies:** FR-006

---

### FR-014: Déduction stock automatique vrac → sachet

**Priorité:** Must Have

**Description:**
Lors d'une vente en unité dérivée (sachet), le stock de l'unité source (vrac) est décrémenté proportionnellement.

**Acceptance Criteria:**
- [ ] Vente de X sachets décrémente le stock vrac de X × (poids sachet / poids vrac)
- [ ] Le stock vrac restant est recalculé correctement
- [ ] Alerte si le stock vrac est insuffisant pour la conversion demandée

**Dependencies:** FR-013, FR-008

---

### FR-015: Indicateur visuel fraîcheur

**Priorité:** Should Have

**Description:**
Code couleur visuel sur les produits périssables pour indiquer leur niveau de fraîcheur et prioriser leur vente.

**Acceptance Criteria:**
- [ ] 3 niveaux : vert (frais), orange (à vendre en priorité), rouge (critique)
- [ ] Basé sur la date d'entrée en stock et la durée de vie configurée
- [ ] Visible dans le POS et la liste de stock

**Dependencies:** FR-006, FR-008

---

### FR-016: Alerte priorité de vente

**Priorité:** Should Have

**Description:**
Notification/alerte pour les produits proches de l'expiration qui doivent être vendus en priorité.

**Acceptance Criteria:**
- [ ] Liste des produits en zone orange/rouge accessible en un tap
- [ ] Suggestion de mise en avant dans le POS
- [ ] Compteur de produits critiques visible sur le dashboard

**Dependencies:** FR-015

---

### FR-017: Ouverture de caisse

**Priorité:** Must Have

**Description:**
Démarrer une session de caisse avec un fond de caisse initial déclaré.

**Acceptance Criteria:**
- [ ] Saisie du montant initial en caisse
- [ ] Horodatage de l'ouverture
- [ ] Association au vendeur/gérant qui ouvre
- [ ] Une seule caisse active à la fois

---

### FR-018: Fermeture de caisse et réconciliation

**Priorité:** Must Have

**Description:**
Fermer la caisse en fin de journée avec réconciliation entre le CA théorique (ventes enregistrées), les espèces comptées, et le stock.

**Acceptance Criteria:**
- [ ] Saisie du montant réel compté en caisse
- [ ] Calcul automatique de l'écart (théorique vs réel)
- [ ] Résumé : total ventes, ventilation par mode de paiement, écart
- [ ] Historique des fermetures de caisse consultable

**Dependencies:** FR-017, FR-001

---

### FR-019: Enregistrement des dépenses

**Priorité:** Must Have

**Description:**
Enregistrer les dépenses de la boutique (loyer, transport, fournitures, etc.) pour un suivi financier complet.

**Acceptance Criteria:**
- [ ] Champs : montant, catégorie, description, date
- [ ] Catégories prédéfinies + catégorie libre
- [ ] Les dépenses apparaissent dans le rapport financier journalier
- [ ] Fonctionne offline

---

### FR-020: Création de commande interne

**Priorité:** Must Have

**Description:**
Un commercial ou gérant peut créer une commande d'approvisionnement à faire valider par la hiérarchie.

**Acceptance Criteria:**
- [ ] Sélection des produits et quantités à commander
- [ ] Association optionnelle à un fournisseur
- [ ] Statut initial : "En attente"
- [ ] Le créateur peut annuler sa commande tant qu'elle n'est pas validée

**Dependencies:** FR-006

---

### FR-021: Circuit de validation des commandes

**Priorité:** Must Have

**Description:**
Les commandes suivent un circuit : commercial crée → gérant approuve → patron valide. Chaque niveau peut approuver ou rejeter.

**Acceptance Criteria:**
- [ ] Le gérant voit les commandes en attente et peut approuver/rejeter
- [ ] Le patron voit les commandes approuvées par le gérant et peut valider/rejeter
- [ ] Motif obligatoire en cas de rejet
- [ ] Historique des statuts de chaque commande

**Dependencies:** FR-020, FR-030

---

### FR-022: Notification commande en attente

**Priorité:** Must Have

**Description:**
Le patron reçoit une notification lorsqu'une commande attend sa validation.

**Acceptance Criteria:**
- [ ] Notification in-app immédiate
- [ ] Badge/compteur de commandes en attente sur le dashboard
- [ ] Tap sur la notification ouvre directement la commande

**Dependencies:** FR-021

---

### FR-023: Résumé quotidien push

**Priorité:** Should Have

**Description:**
Le propriétaire reçoit chaque soir une notification push avec le résumé de la journée.

**Acceptance Criteria:**
- [ ] Contenu : CA du jour, nombre de ventes, alertes stock, pertes
- [ ] Envoi automatique à une heure configurable
- [ ] Tap sur la notification ouvre le rapport détaillé
- [ ] Fonctionne même si le patron n'a pas ouvert l'app de la journée

---

### FR-024: Rapport CA journalier

**Priorité:** Must Have

**Description:**
Rapport du chiffre d'affaires journalier avec ventilation par mode de paiement et par vendeur.

**Acceptance Criteria:**
- [ ] CA total du jour
- [ ] Ventilation par mode de paiement (Cash, Wave, Orange Money)
- [ ] Ventilation par vendeur
- [ ] Comparaison avec les jours précédents (graphique simple)
- [ ] Filtrable par période

**Dependencies:** FR-001

---

### FR-025: Rapport état stock

**Priorité:** Must Have

**Description:**
Rapport montrant les niveaux de stock actuels et les mouvements récents.

**Acceptance Criteria:**
- [ ] Liste des produits avec quantité actuelle et valeur stock
- [ ] Mouvements récents (entrées, sorties, ajustements)
- [ ] Filtre par catégorie
- [ ] Export ou partage possible (PDF ou image)

**Dependencies:** FR-008

---

### FR-026: Rapport pertes

**Priorité:** Must Have

**Description:**
Rapport des pertes (frotte, produits expirés, écarts de stock) pour mesurer l'impact financier.

**Acceptance Criteria:**
- [ ] Pertes par frotte (calculées depuis le taux)
- [ ] Produits expirés/jetés (enregistrés manuellement)
- [ ] Montant total des pertes sur la période
- [ ] Tendance sur les dernières semaines

**Dependencies:** FR-011, FR-008

---

### FR-027: Gestion fournisseurs (CRUD)

**Priorité:** Should Have

**Description:**
Créer et gérer une liste de fournisseurs avec leurs coordonnées.

**Acceptance Criteria:**
- [ ] Champs : nom, téléphone, adresse, notes
- [ ] Association fournisseur ↔ produits fournis
- [ ] Recherche par nom

---

### FR-028: Historique achats par fournisseur

**Priorité:** Should Have

**Description:**
Consulter l'historique des approvisionnements par fournisseur.

**Acceptance Criteria:**
- [ ] Liste des approvisionnements filtrée par fournisseur
- [ ] Total acheté par fournisseur sur une période
- [ ] Détail de chaque approvisionnement (produits, quantités, coûts)

**Dependencies:** FR-010, FR-027

---

### FR-029: Authentification utilisateur

**Priorité:** Must Have

**Description:**
Connexion sécurisée par email et mot de passe.

**Acceptance Criteria:**
- [ ] Inscription avec email + mot de passe
- [ ] Connexion avec persistance de session
- [ ] Déconnexion
- [ ] Réinitialisation de mot de passe par email

---

### FR-030: Rôles et permissions

**Priorité:** Must Have

**Description:**
3 rôles codés en dur (Propriétaire, Gérant, Commercial) avec possibilité de désactiver certaines permissions par utilisateur.

**Acceptance Criteria:**
- [ ] Attribution d'un rôle à chaque utilisateur de la boutique
- [ ] Permissions par défaut selon le rôle
- [ ] Le propriétaire peut activer/désactiver des permissions spécifiques par utilisateur
- [ ] Les restrictions sont appliquées côté client ET serveur

**Dependencies:** FR-029

---

### FR-031: Fonctionnement offline complet

**Priorité:** Must Have

**Description:**
Toutes les opérations fonctionnent sans connexion Internet. Les données sont stockées localement (Drift/SQLite) et synchronisées au retour de la connexion.

**Acceptance Criteria:**
- [ ] Ventes, stock, caisse, commandes, dépenses fonctionnent offline
- [ ] Aucune fonctionnalité bloquée par l'absence de réseau
- [ ] Indicateur visuel du statut de connexion
- [ ] Les données créées offline sont horodatées correctement

---

### FR-032: Synchronisation automatique

**Priorité:** Must Have

**Description:**
Les données locales sont synchronisées automatiquement avec le serveur au retour de la connexion, sans intervention utilisateur.

**Acceptance Criteria:**
- [ ] Sync automatique dès détection de connexion
- [ ] Gestion des conflits (même produit modifié sur 2 devices)
- [ ] Indicateur de progression de la sync
- [ ] Retry automatique en cas d'échec
- [ ] Aucune perte de données

**Dependencies:** FR-031

---

### FR-033: Backoffice Super Admin Scalario

**Priorité:** Must Have

**Description:**
Interface interne réservée au fondateur pour opérer la plateforme. Ce n'est PAS le backoffice des clients — c'est l'outil d'administration Scalario.

**Acceptance Criteria:**
- [ ] Créer un nouveau tenant (boutique) avec ses informations de base
- [ ] Activer / suspendre un tenant
- [ ] Reset du mot de passe d'un utilisateur
- [ ] Consulter les logs de synchronisation par tenant
- [ ] Interface web accessible uniquement par le super admin

**Dependencies:** Aucune

---

### FR-034: Inventaire hebdomadaire

**Priorité:** Must Have

**Description:**
Réaliser un inventaire physique périodique (hebdomadaire recommandé) pour comparer le stock théorique (système) avec le stock réel (compté physiquement). Permet de détecter les écarts (vol, pertes non enregistrées, erreurs).

**Acceptance Criteria:**

- [ ] Lancer un inventaire : sélection des produits à compter (tous ou par catégorie)
- [ ] Saisie des quantités réelles comptées par produit
- [ ] Calcul automatique de l'écart (théorique - réel) par produit
- [ ] Résumé de l'inventaire : nombre de produits avec écart, valeur totale des écarts
- [ ] Validation de l'inventaire par le gérant, puis transmission au patron
- [ ] Historique des inventaires consultable avec comparaison entre périodes
- [ ] Fonctionne offline

**Dependencies:** FR-008

---

### FR-035: Génération de facture

**Priorité:** Must Have

**Description:**
Générer une facture pour chaque vente (détail ou gros) avec les informations de la boutique, les produits vendus, les quantités, les prix et le mode de paiement. La facture peut être visualisée dans l'app, partagée (PDF/WhatsApp) ou imprimée.

**Acceptance Criteria:**

- [ ] Facture générée automatiquement à chaque vente validée
- [ ] Contenu : nom boutique, date, numéro de facture, liste produits (nom, qté, prix unitaire, total ligne), total général, mode de paiement
- [ ] Visualisation dans l'app après validation de la vente
- [ ] Export PDF et partage (WhatsApp, email)
- [ ] Numérotation séquentielle des factures
- [ ] Fonctionne offline (génération locale)

**Dependencies:** FR-001, FR-004

---

### FR-036: Impression thermique Bluetooth

**Priorité:** Should Have

**Description:**
Imprimer les factures/reçus sur une imprimante thermique Bluetooth (type POS) connectée au téléphone ou à la tablette.

**Acceptance Criteria:**

- [ ] Appairage Bluetooth avec imprimante thermique (protocole ESC/POS)
- [ ] Impression de la facture depuis l'écran de vente (bouton "Imprimer")
- [ ] Format ticket optimisé pour largeur 58mm ou 80mm
- [ ] Fonctionne offline (impression locale directe)
- [ ] Gestion des erreurs : imprimante non connectée, papier épuisé

**Dependencies:** FR-035

---

### FR-037: Gestion clients (CRM)

**Priorité:** Must Have

**Description:**
Créer et gérer une base de clients avec fiche de contact, historique d'achats et solde crédit.

**Acceptance Criteria:**

- [ ] Fiche client : nom, téléphone, notes (optionnel)
- [ ] Recherche client par nom ou téléphone
- [ ] Historique des achats par client (liste de ventes liées)
- [ ] Solde crédit visible sur la fiche client (total dû)
- [ ] Association optionnelle d'une vente à un client lors de la transaction
- [ ] Fonctionne offline

---

### FR-038: Vente à crédit

**Priorité:** Must Have

**Description:**
Permettre la vente à crédit liée à un client, avec toggle d'activation par le propriétaire. Quand désactivé, aucune vente à crédit n'est possible.

**Acceptance Criteria:**

- [ ] Toggle on/off de la vente à crédit dans les paramètres boutique (propriétaire uniquement)
- [ ] Quand activé : mode de paiement "Crédit" disponible lors d'une vente
- [ ] Vente à crédit obligatoirement liée à un client existant
- [ ] Montant ajouté au solde crédit du client
- [ ] Enregistrement d'un paiement partiel ou total sur un crédit existant
- [ ] Liste des clients avec crédit en cours, triée par montant dû
- [ ] Historique des paiements crédit par client
- [ ] Le crédit apparaît dans les rapports financiers (CA vs encaissé vs crédit)
- [ ] Fonctionne offline

**Dependencies:** FR-037, FR-001

---

## Pricing

| Plan | Prix/mois | Ce que ça inclut |
| ---- | --------- | ---------------- |
| **Solo** | 5 000 FCFA | 1 appareil, 1 compte, offline, pas de cloud |
| **Boutique** | 7 500 FCFA | 1 appareil, multi-comptes (patron + vendeurs), offline, pas de cloud |
| **Pro** | 15 000 FCFA | Multi-device, cloud sync, contrôle à distance, notifications push |
| **Pro Annuel** | 12 500 FCFA/mois | = 10 mois payés, 2 offerts (150 000 FCFA/an) |
| **Installation** | Variable | Setup boutique, formation, import données |

**Multi-comptes local (Solo/Boutique)** : plusieurs utilisateurs se connectent sur le même appareil avec leur propre profil. Les permissions par rôle s'appliquent. Pas de sync cloud — upgrade possible vers Pro.

---

## Non-Functional Requirements

Les Non-Functional Requirements (NFRs) définissent **comment** le système performe.

---

### NFR-001: Performance offline

**Priorité:** Must Have

**Description:**
Toute opération en mode offline doit répondre en moins de 500ms.

**Acceptance Criteria:**
- [ ] Création de vente < 500ms
- [ ] Recherche produit < 300ms
- [ ] Navigation entre écrans < 200ms

**Rationale:**
Les vendeurs doivent encaisser rapidement, surtout en période d'affluence.

---

### NFR-002: Support appareils milieu de gamme

**Priorité:** Must Have

**Description:**
L'app doit fonctionner de façon fluide sur des smartphones Android milieu de gamme (2GB RAM, processeur quad-core).

**Acceptance Criteria:**
- [ ] Pas de freeze ni crash sur appareil 2GB RAM
- [ ] Consommation mémoire < 150MB en utilisation normale
- [ ] Taille APK < 50MB

**Rationale:**
Les utilisateurs cibles en Afrique de l'Ouest utilisent majoritairement des appareils milieu de gamme.

---

### NFR-003: Zéro perte de données

**Priorité:** Must Have

**Description:**
Aucune transaction enregistrée offline ne doit être perdue lors de la synchronisation.

**Acceptance Criteria:**
- [ ] 100% des transactions offline sont retrouvées après sync
- [ ] Test : créer 100 ventes offline, sync, vérifier 100 présentes côté serveur
- [ ] En cas d'échec de sync, les données restent en local et sont retentées

**Rationale:**
La perte de données financières détruirait la confiance des utilisateurs.

---

### NFR-004: Résolution de conflits de sync

**Priorité:** Must Have

**Description:**
Les conflits de synchronisation (même donnée modifiée sur 2 devices) sont résolus automatiquement.

**Acceptance Criteria:**
- [ ] Stratégie définie par type de donnée (last-write-wins pour produits, merge pour stock)
- [ ] Aucune intervention utilisateur requise
- [ ] Log des conflits résolus accessible pour diagnostic

**Rationale:**
Propriétaire et gérant peuvent modifier les mêmes données depuis des devices différents.

---

### NFR-005: Disponibilité backend

**Priorité:** Should Have

**Description:**
Le backend doit être disponible 99% du temps (hors maintenance planifiée).

**Acceptance Criteria:**
- [ ] Uptime ≥ 99% mesuré mensuellement
- [ ] Maintenance planifiée notifiée 24h à l'avance
- [ ] L'app reste fonctionnelle en mode offline pendant les pannes

**Rationale:**
Le mode offline rend ce NFR moins critique, mais la sync doit fonctionner de façon fiable.

---

### NFR-006: Authentification sécurisée

**Priorité:** Must Have

**Description:**
Authentification par tokens JWT avec sessions expirables.

**Acceptance Criteria:**
- [ ] Tokens JWT avec expiration configurable
- [ ] Refresh token pour renouvellement sans re-login
- [ ] Invalidation de session côté serveur possible

**Rationale:**
Plusieurs personnes utilisent l'app sur le même device potentiellement — les sessions doivent être sécurisées.

---

### NFR-007: Chiffrement données locales

**Priorité:** Must Have

**Description:**
Les données stockées localement sur le device sont chiffrées.

**Acceptance Criteria:**
- [ ] Base SQLite chiffrée via SQLCipher (clé dérivée stockée en secure storage)
- [ ] Les données ne sont pas lisibles si le device est rooté

**Rationale:**
Protection des données financières et commerciales en cas de vol/perte du téléphone.

---

### NFR-008: Isolation des permissions

**Priorité:** Must Have

**Description:**
Les vendeurs ne peuvent pas accéder aux rapports financiers, modifier les prix, ni gérer les utilisateurs.

**Acceptance Criteria:**
- [ ] Vérification des permissions côté client (UI masquée)
- [ ] Vérification des permissions côté serveur (API rejet)
- [ ] Test : un vendeur ne peut pas atteindre les endpoints admin

**Rationale:**
Le propriétaire doit pouvoir faire confiance à l'app pour limiter ce que ses employés voient et font.

---

### NFR-009: Interface accessible

**Priorité:** Must Have

**Description:**
Interface utilisable par des personnes peu familières avec le numérique — gros boutons, navigation simple, icônes explicites.

**Acceptance Criteria:**
- [ ] Boutons de taille minimum 48x48dp
- [ ] Navigation principale en 2 taps max depuis l'accueil
- [ ] Icônes accompagnées de labels texte
- [ ] Pas de gestes complexes (swipe, long press) pour les actions critiques

**Rationale:**
Les vendeurs et gérants cibles ne sont pas forcément à l'aise avec les apps complexes.

---

### NFR-010: Langue française

**Priorité:** Must Have

**Description:**
L'interface est entièrement en français. Pas d'internationalisation en Phase 1.

**Acceptance Criteria:**
- [ ] Tous les textes, messages d'erreur et notifications en français
- [ ] Formats numériques : séparateur décimal = virgule, milliers = espace (1 000,50)
- [ ] Devise : FCFA

---

### NFR-011: Onboarding rapide

**Priorité:** Should Have

**Description:**
Un nouveau propriétaire peut configurer sa boutique et ajouter son premier produit en moins de 5 minutes.

**Acceptance Criteria:**
- [ ] Setup guidé étape par étape
- [ ] Nombre d'étapes ≤ 5
- [ ] Pré-remplissage intelligent (catégories par défaut selon le type de business)

---

### NFR-012: Compatibilité multi-plateforme

**Priorité:** Must Have

**Description:**
L'application fonctionne sur Android, iOS et Desktop (Windows/macOS) via Flutter.

**Acceptance Criteria:**
- [ ] Android 8.0+ (API 26+)
- [ ] iOS 13+
- [ ] Desktop : Windows 10+ et macOS 11+
- [ ] Même base de code, même fonctionnalités sur toutes les plateformes

---

### NFR-013: API REST standard

**Priorité:** Must Have

**Description:**
Communication mobile ↔ backend via API REST standard.

**Acceptance Criteria:**
- [ ] Endpoints RESTful avec versioning (v1/)
- [ ] Réponses JSON avec codes HTTP standards
- [ ] Documentation API auto-générée (Swagger/OpenAPI)

---

### NFR-014: Couverture de tests

**Priorité:** Should Have

**Description:**
Couverture de tests > 70% sur la logique métier critique.

**Acceptance Criteria:**
- [ ] Tests unitaires sur : calcul prix (frotte, gros), stock (mouvements, conversions), caisse (réconciliation)
- [ ] Tests d'intégration sur la synchronisation offline
- [ ] Coverage mesurée et rapportée dans la CI

---

### NFR-015: Interface responsive

**Priorité:** Must Have

**Description:**
L'interface s'adapte aux différentes tailles d'écran : téléphone, tablette et desktop.

**Acceptance Criteria:**
- [ ] Layout adaptatif (pas juste étiré)
- [ ] Navigation adaptée : bottom nav sur mobile, sidebar sur desktop/tablette
- [ ] Tous les écrans testés sur 3 breakpoints minimum

---

## Epics

Les epics regroupent les FRs par domaine fonctionnel. Chaque epic sera décomposé en user stories lors du sprint planning.

---

### EPIC-001: Point de Vente (POS)

**Description:**
Module de vente complet couvrant la vente au détail et en gros, avec sélection du mode de paiement et historique des transactions.

**Functional Requirements:**
- FR-001: Créer une vente détail
- FR-002: Sélection du mode de paiement
- FR-003: Historique des ventes
- FR-004: Vente en gros
- FR-005: Unités gros avec conversion
- FR-035: Génération de facture
- FR-036: Impression thermique Bluetooth

**Story Count Estimate:** 8-10

**Priority:** Must Have

**Business Value:**
Coeur du produit — sans POS, pas de digitalisation possible. C'est l'écran que les vendeurs utilisent toute la journée. La facture et l'impression sont demandées par les testeurs.

---

### EPIC-002: Catalogue & Stock

**Description:**
Gestion du catalogue produits et suivi des stocks avec mouvements, alertes et approvisionnement.

**Functional Requirements:**
- FR-006: Gestion du catalogue produits (CRUD)
- FR-007: Variantes produit
- FR-008: Suivi des quantités en stock
- FR-009: Alertes stock bas
- FR-010: Entrée stock via approvisionnement
- FR-034: Inventaire hebdomadaire

**Story Count Estimate:** 7-9

**Priority:** Must Have

**Business Value:**
Le stock est le nerf de la guerre pour les boutiques retail. Sans suivi précis, impossible de contrôler les pertes et les marges.

---

### EPIC-003: Périssables & Conversions

**Description:**
Fonctionnalités spécifiques aux produits périssables (frotte, fraîcheur) et aux conversions d'unités (vrac → sachet).

**Functional Requirements:**
- FR-011: Configuration du taux de frotte
- FR-012: Calcul prix avec taux de frotte
- FR-013: Règles de conversion vrac → sachet
- FR-014: Déduction stock automatique vrac → sachet
- FR-015: Indicateur visuel fraîcheur
- FR-016: Alerte priorité de vente

**Story Count Estimate:** 5-7

**Priority:** Must Have

**Business Value:**
Différenciateur clé de Scalario — les concurrents ne gèrent pas le frotte ni le vrac→sachet. Indispensable pour Blandine (produits frais) et transposable à d'autres business.

---

### EPIC-004: Caisse & Dépenses

**Description:**
Gestion de la caisse (ouverture, fermeture, réconciliation) et enregistrement des dépenses de la boutique.

**Functional Requirements:**
- FR-017: Ouverture de caisse
- FR-018: Fermeture de caisse et réconciliation
- FR-019: Enregistrement des dépenses

**Story Count Estimate:** 4-5

**Priority:** Must Have

**Business Value:**
La réconciliation de caisse est ce qui permet au patron de vérifier que l'argent n'a pas disparu. Les dépenses complètent le tableau financier.

---

### EPIC-005: Commandes Internes

**Description:**
Circuit de commande interne avec workflow de validation hiérarchique (commercial → gérant → patron).

**Functional Requirements:**
- FR-020: Création de commande interne
- FR-021: Circuit de validation des commandes
- FR-022: Notification commande en attente

**Story Count Estimate:** 3-5

**Priority:** Must Have

**Business Value:**
Permet au patron de garder le contrôle sur les achats même à distance. Évite les commandes non autorisées.

---

### EPIC-006: Rapports & Notifications

**Description:**
Tableaux de bord, rapports analytiques et notifications push pour le suivi d'activité.

**Functional Requirements:**
- FR-023: Résumé quotidien push
- FR-024: Rapport CA journalier
- FR-025: Rapport état stock
- FR-026: Rapport pertes

**Story Count Estimate:** 5-7

**Priority:** Should Have (FR-024/25/26 sont Must, FR-023 est Should)

**Business Value:**
C'est ce que le patron consulte matin et soir. Les rapports transforment des données brutes en décisions.

---

### EPIC-007: Fournisseurs

**Description:**
Gestion des fournisseurs et historique des approvisionnements.

**Functional Requirements:**
- FR-027: Gestion fournisseurs (CRUD)
- FR-028: Historique achats par fournisseur

**Story Count Estimate:** 2-3

**Priority:** Should Have

**Business Value:**
Simplifie le réapprovisionnement et permet de comparer les fournisseurs sur le temps.

---

### EPIC-009: CRM & Crédit

**Description:**
Gestion des clients (fiches, historique achats) et vente à crédit avec toggle d'activation par le propriétaire.

**Functional Requirements:**
- FR-037: Gestion clients (CRM)
- FR-038: Vente à crédit

**Story Count Estimate:** 4-6

**Priority:** Must Have

**Business Value:**
La vente à crédit est une pratique courante dans le retail en Afrique de l'Ouest. Le CRM permet le suivi des impayés et la fidélisation. Le toggle donne au patron le contrôle sur le risque crédit.

---

### EPIC-008: Auth, Rôles & Sync

**Description:**
Authentification, gestion des rôles/permissions, fonctionnement offline et synchronisation.

**Functional Requirements:**
- FR-029: Authentification utilisateur
- FR-030: Rôles et permissions
- FR-031: Fonctionnement offline complet
- FR-032: Synchronisation automatique

**Story Count Estimate:** 5-7

**Priority:** Must Have

**Business Value:**
Fondation technique du produit — sans auth, pas de multi-utilisateur. Sans offline/sync, pas d'utilité en contexte africain où la connexion est instable.

---

## User Stories (High-Level)

Les user stories détaillées seront créées lors du sprint planning (Phase 4).

---

## User Flows

### Flow 1: Vente au comptoir (le plus fréquent)
1. Vendeur ouvre le POS
2. Sélectionne les produits (recherche ou liste)
3. Ajuste les quantités
4. Sélectionne détail ou gros
5. Choisit le mode de paiement
6. Valide la vente
7. Stock décrémenté automatiquement

### Flow 2: Fermeture de caisse (fin de journée)
1. Gérant ouvre l'écran Caisse
2. Compte les espèces physiquement
3. Saisit le montant réel
4. Le système affiche l'écart avec le théorique
5. Gérant confirme la fermeture
6. Le résumé est envoyé au patron

### Flow 3: Commande interne → validation
1. Commercial constate un stock bas
2. Crée une commande (produits + quantités)
3. Le gérant reçoit une notification → approuve ou rejette
4. Si approuvé, le patron reçoit une notification → valide ou rejette
5. Si validé, la commande passe en statut "À exécuter"

---

## Dependencies

### Internal Dependencies

- **Drift / SQLite** — base de données locale Flutter (offline storage)
- **Flutter** — framework UI multi-plateforme
- **NestJS** — backend API
- **Supabase/PostgreSQL** — base de données serveur

### External Dependencies

- **Firebase Cloud Messaging (FCM)** — notifications push
- **Service email** — réinitialisation mot de passe (Supabase Auth ou SMTP)
- **Connexion Internet** — pour la synchronisation (pas pour l'usage quotidien)
- **Imprimante thermique Bluetooth** — impression factures/reçus (protocole ESC/POS, 58mm ou 80mm)

---

## Assumptions

1. Les utilisateurs ont un smartphone Android milieu de gamme minimum (2GB RAM)
2. La connexion Internet est intermittente mais disponible au moins une fois par jour pour sync
3. Une seule boutique par installation (mono-boutique)
4. Les prix sont en FCFA (pas de multi-devises)
5. Le volume de données par boutique reste modeste (< 10 000 produits, < 1 000 ventes/jour)
6. Les 3 business types couvrent les besoins des testeurs initiaux

---

## Out of Scope

- Templates sectoriels, UI Engine, Config Engine, SDUI
- Module Production / Fabrication
- WhatsApp Business API
- Intégration API Mobile Money (Wave, Orange Money) — sélection manuelle uniquement
- AI (toute forme)
- Multi-boutique (sauf si un client le demande explicitement)
- Rôles dynamiques / RBAC configurable
- Internationalisation (français uniquement)
- iOS-specific features (App Clips, etc.)

---

## Open Questions

1. **Multi-device par utilisateur** — Un vendeur peut-il être connecté sur 2 devices simultanément ?
2. **Durée de vie produits** — Comment les utilisateurs saisissent-ils la date de péremption ? (date exacte vs estimation)
3. **Modèles d'imprimantes** — Quels modèles d'imprimantes thermiques Bluetooth sont courants à Ouaga/Burkina ? (pour tester la compatibilité)

---

## Approval & Sign-off

### Stakeholders

| Rôle | Nom | Statut |
|------|-----|--------|
| Fondateur / Product Owner | Carlos Simporé | En attente |

### Approval Status

- [ ] Product Owner

---

## Revision History

| Version | Date | Auteur | Changements |
|---------|------|--------|-------------|
| 1.0 | 2026-04-06 | Carlos Simporé | PRD initial Phase 1 |
| 1.1 | 2026-04-06 | Carlos Simporé | Ajout pricing (Solo/Boutique/Pro), FR-034 inventaire hebdo, success metrics SMART avec deadlines |
| 1.2 | 2026-04-06 | Carlos Simporé | FR-035 factures, FR-036 impression thermique, retrait impression du Out of Scope |
| 1.3 | 2026-04-06 | Carlos Simporé | FR-037 CRM clients, FR-038 vente à crédit, EPIC-009, personas enrichis (Blandine/Yempabou/Vivien) |

---

## Next Steps

Lancer `/architecture` pour concevoir l'architecture système basée sur ces exigences.

---

**Ce document a été créé avec la méthode BMAD v6 — Phase 2 (Planning)**

*Pour continuer : lancer `/workflow-status` pour voir l'avancement.*

---

## Appendix A: Requirements Traceability Matrix

| Epic ID | Epic Name | Functional Requirements | Story Count (Est.) |
|---------|-----------|-------------------------|-------------------|
| EPIC-001 | Point de Vente (POS) | FR-001, FR-002, FR-003, FR-004, FR-005, FR-035, FR-036 | 8-10 |
| EPIC-002 | Catalogue & Stock | FR-006, FR-007, FR-008, FR-009, FR-010, FR-034 | 7-9 |
| EPIC-003 | Périssables & Conversions | FR-011, FR-012, FR-013, FR-014, FR-015, FR-016 | 5-7 |
| EPIC-004 | Caisse & Dépenses | FR-017, FR-018, FR-019 | 4-5 |
| EPIC-005 | Commandes Internes | FR-020, FR-021, FR-022 | 3-5 |
| EPIC-006 | Rapports & Notifications | FR-023, FR-024, FR-025, FR-026 | 5-7 |
| EPIC-007 | Fournisseurs | FR-027, FR-028 | 2-3 |
| EPIC-008 | Auth, Rôles & Sync | FR-029, FR-030, FR-031, FR-032 | 5-7 |
| EPIC-009 | CRM & Crédit | FR-037, FR-038 | 4-6 |
| **TOTAL** | | **38 FRs** | **48-65 stories** |

---

## Appendix B: Prioritization Details

### Functional Requirements

| Priorité | Count | Pourcentage |
|----------|-------|-------------|
| Must Have | 31 | 82% |
| Should Have | 7 | 18% |
| Could Have | 0 | 0% |

**Must Have (31):** FR-001 à FR-006, FR-008 à FR-014, FR-017 à FR-022, FR-024 à FR-026, FR-029 à FR-035, FR-037, FR-038

**Should Have (7):** FR-007 (Variantes), FR-015 (Fraîcheur visuelle), FR-016 (Alerte priorité vente), FR-023 (Push quotidien), FR-027 (Fournisseurs CRUD), FR-028 (Historique achats), FR-036 (Impression thermique)

### Non-Functional Requirements

| Priorité | Count | Pourcentage |
|----------|-------|-------------|
| Must Have | 12 | 80% |
| Should Have | 3 | 20% |

**Must Have (12):** NFR-001 à NFR-004, NFR-006 à NFR-010, NFR-012, NFR-013, NFR-015

**Should Have (3):** NFR-005 (Uptime 99%), NFR-011 (Onboarding rapide), NFR-014 (Tests 70%)
