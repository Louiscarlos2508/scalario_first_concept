# UX Scenarios : Scalario

> Outlines de scénarios connectant les personas du Trigger Map à des parcours utilisateurs concrets

**Créé :** 2026-03-31
**Auteur :** Carlos Simpore avec Saga (Whiteport Design Studio)
**Méthode :** Whiteport Design Studio (WDS) — Phase 3

---

## Résumé des Scénarios

| ID | Scénario | Persona | Vues | Priorité | Statut |
|----|----------|---------|------|----------|--------|
| 01 | Blandine Ferme Sa Caisse à Distance | Blandine | 4 | ⭐ P1 | ✅ Outlined |
| 02 | Blandine Surveille Sa Boutique à Distance | Blandine | 2 | ⭐ P1 | ✅ Outlined |
| 03 | Bernard Découvre Scalario Seul | Bernard | 3 | ⭐ P1 | ✅ Outlined |
| 04 | Bernard Vend et Sait Ce Qu'il a Gagné | Bernard | 6 | ⭐ P1 | ✅ Outlined |
| 05 | Cheick Configure Ses Variantes | Cheick | 4 | ⭐ P2 | ✅ Outlined |
| 06 | Cheick Vend à un Client à Crédit | Cheick | 2 | ⭐ P2 | ✅ Outlined |
| 07 | Cheick Agit Sur Ses Péremptions | Cheick | 1 | ⭐ P2 | ✅ Outlined |
| 08 | Ibrahim Déploie Son Premier Client | Ibrahim | 2 | ⭐ P2 | ✅ Outlined |
| 09 | Blandine Ajuste Sa Configuration | Blandine | 4 | ☆ P3 | ✅ Outlined |
| 10 | Le Gestionnaire Réceptionne une Livraison | Gestionnaire | 3 | ☆ P3 | ✅ Outlined |
| 11 | Blandine Lit Ses Rapports | Blandine | 2 | ☆ P3 | ✅ Outlined |

**Total : 11 scénarios · 33 vues couvertes**

---

## Scénarios

### [01 : Blandine Ferme Sa Caisse à Distance](01-blandine-ferme-sa-caisse/01-blandine-ferme-sa-caisse.md)
**Persona :** Blandine — preuve attribution + sign-off propriétaire remote
**Vues :** Arrêt caisse étape 1, étape 2, étape 3, historique sessions
**Valeur utilisateur :** Elle signe la caisse en 3 minutes depuis l'étranger, avec la preuve de qui a fait quoi
**Valeur business :** Feature décisive démo → signature → Gate 1 ARR 400K FCFA

---

### [02 : Blandine Surveille Sa Boutique à Distance](02-blandine-surveille-a-distance/02-blandine-surveille-a-distance.md)
**Persona :** Blandine — contrôle distance + alertes WhatsApp
**Vues :** Dashboard propriétaire, Centre d'alertes
**Valeur utilisateur :** Certitude en 2 minutes depuis son PC, sans appeler personne
**Valeur business :** Sessions > 5/semaine → adoption prouvée → O2.2

---

### [03 : Bernard Découvre Scalario Seul](03-bernard-decouvre-scalario-seul/03-bernard-decouvre-scalario-seul.md)
**Persona :** Bernard — friction zéro dès le premier contact
**Vues :** Splash, Login, Onboarding wizard
**Valeur utilisateur :** Boutique configurée et première vente test en < 10 minutes, seul
**Valeur business :** Onboarding Standard autonome validé → Gate 2 → O2.3

---

### [04 : Bernard Vend et Sait Ce Qu'il a Gagné](04-bernard-vend-et-sait-ce-quil-a-gagne/04-bernard-vend-et-sait-ce-quil-a-gagne.md)
**Persona :** Bernard — certitude CA quotidienne + attribution par employé
**Vues :** Dashboard employé, POS catalogue, POS panier, POS paiement, POS reçu, Stock liste
**Valeur utilisateur :** Le soir, CA exact + stock restant + ventes par employé en < 5 minutes
**Valeur business :** Usage quotidien → rétention Standard → O1.2 10 clients

---

### [05 : Cheick Configure Ses Variantes](05-cheick-configure-ses-variantes/05-cheick-configure-ses-variantes.md)
**Persona :** Cheick — inventaire SKU précis par variante
**Vues :** Produits liste catalogue, Produits création/édition, Variantes gestion multi-SKU, Stock fiche produit + variantes
**Valeur utilisateur :** Son catalogue complexe est dans Scalario — il n'a plus besoin d'un autre outil
**Valeur business :** Switching cost naturel → NRR anchor Standard+ → O2.1

---

### [06 : Cheick Vend à un Client à Crédit](06-cheick-vend-a-un-client-a-credit/06-cheick-vend-a-un-client-a-credit.md)
**Persona :** Cheick — solde crédit visible au moment de la vente
**Vues :** Clients liste, Clients fiche + solde crédit
**Valeur utilisateur :** Solde exact en 2 secondes, créance enregistrée devant le client
**Valeur business :** Feature différenciante Standard+ → rétention → O2.1

---

### [07 : Cheick Agit Sur Ses Péremptions](07-cheick-agit-sur-ses-peremptions/07-cheick-agit-sur-ses-peremptions.md)
**Persona :** Cheick — alerte proactive avant perte
**Vues :** Péremptions tableau de bord
**Valeur utilisateur :** Il agit avant la perte, pas après
**Valeur business :** Usage proactif déclenché → rétention Standard+ → O2.1

---

### [08 : Ibrahim Déploie Son Premier Client](08-ibrahim-deploie-son-premier-client/08-ibrahim-deploie-son-premier-client.md)
**Persona :** Ibrahim — déploiement autonome < 1 jour
**Vues :** AI Config Wizard, Dashboard intégrateur
**Valeur utilisateur :** Tenant complet configuré sans appeler Carlos
**Valeur business :** Canal intégrateur autonome validé → Gate 5 → O3.1

---

### [09 : Configuration de la Boutique](09-configuration-de-la-boutique/09-configuration-de-la-boutique.md)
**Persona :** Blandine — gestion équipe à distance
**Vues :** Utilisateurs liste + rôles, Utilisateurs création/édition, Paramètres général, Paramètres intégrations
**Valeur utilisateur :** Nouvel employé configuré depuis l'étranger en 5 minutes
**Valeur business :** Autonomie de gestion → zéro appel support → scalabilité

---

### [10 : Le Gestionnaire Réceptionne une Livraison](10-le-gestionnaire-receptionne-une-livraison/10-le-gestionnaire-receptionne-une-livraison.md)
**Persona :** Gestionnaire de Blandine — audit trail réception complet
**Vues :** Stock réception marchandise, Stock inventaire/ajustement, Paramètres Taux de Frotte
**Valeur utilisateur :** Réception tracée en 5 minutes, stock exact pour Blandine
**Valeur business :** Audit trail complet → preuve Premium → rétention → O2.2

---

### [11 : Blandine Lit Ses Rapports](11-blandine-lit-ses-rapports/11-blandine-lit-ses-rapports.md)
**Persona :** Blandine — analytics GenUI en langage naturel
**Vues :** Rapports ventes, Rapports stock
**Valeur utilisateur :** Questions en langage naturel → listes, graphiques, tableaux générés → décision en 10 minutes
**Valeur business :** Usage analytique hebdomadaire → engagement Premium → upsell → O2.1

---

## Matrice de Couverture des Vues

| Vue | Scénario | Rôle dans le flow |
|-----|----------|-------------------|
| Splash / Loading | 03 | Première impression — accueil app |
| Login | 03 | Création compte / connexion invitation |
| Onboarding wizard | 03 | Configuration boutique + première vente test |
| Dashboard Propriétaire | 02 | Surveillance chiffres clés à distance |
| Dashboard Employé | 04 | Ouverture session + accès POS |
| POS — catalogue produits | 04 | Sélection produits à vendre |
| POS — panier en cours | 04 | Composition vente |
| POS — paiement | 04 | Encaissement cash / mobile money |
| POS — reçu / confirmation | 04 | Confirmation transaction |
| Stock — liste produits | 04 | Consultation CA soir + niveaux stock |
| Stock — fiche produit + variantes | 05 | Vérification produit complet après config |
| Stock — réception marchandise | 10 | Enregistrement livraison fournisseur |
| Stock — inventaire / ajustement | 10 | Vérification stock post-réception |
| Arrêt de caisse — Étape 1 | 01 | Caissier soumet récapitulatif fin de journée |
| Arrêt de caisse — Étape 2 | 01 | Gestionnaire valide les chiffres |
| Arrêt de caisse — Étape 3 | 01 | Blandine signe à distance |
| Historique sessions de caisse | 01 | Archive horodatée 3 signatures |
| Clients — liste | 06 | Recherche client habituel |
| Clients — fiche + solde crédit | 06 | Vérification solde + enregistrement créance |
| Centre d'alertes | 02 | Traitement alerte en suspens |
| Péremptions — tableau de bord | 07 | Vue produits à risque + action |
| Utilisateurs — liste + rôles | 09 | Vue équipe + création nouvel employé |
| Utilisateurs — création / édition | 09 | Configuration accès + rôle |
| Produits — liste catalogue | 05 | Point de départ création produit |
| Produits — création / édition | 05 | Définition produit de base |
| Variantes — gestion multi-SKU | 05 | Configuration attributs + génération SKUs |
| Rapports — ventes | 11 | CA semaine + GenUI analytics ventes |
| Rapports — stock | 11 | Mouvements stock + GenUI réappro |
| Paramètres — général | 09 | Configuration boutique générale |
| Paramètres — Taux de Frotte | 10 | Configuration perte naturelle produits frais |
| Paramètres — intégrations | 09 | Config mobile money + WhatsApp |
| AI Config Wizard | 08 | Déploiement tenant guidé A à Z |
| Dashboard intégrateur | 08 | Suivi clients + confirmation déploiement |

**Couverture : 33/33 vues ✅ · Aucun doublon ✅**

---

## Phase Suivante

Ces outlines alimentent **Phase 4 : UX Design** où chaque vue reçoit :
- Spécifications de page détaillées
- Sketches wireframe
- Définitions des composants
- Détails d'interaction

---

_Généré avec Whiteport Design Studio — Phase 3 Scenarios · 2026-03-31_
