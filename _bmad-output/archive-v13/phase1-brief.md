# Brief Phase 1 — Scalario Retail

**Date :** 2026-04-06
**Statut :** Verrouillé
**Scope :** Phase 1 uniquement — produit codé, pas de config no-code, pas de templates, pas d'engines

---

## Objectif

Livrer une app de gestion de boutique retail fonctionnelle pour 3 types de business précis. Produit codé en dur, architecture classique. Les phases futures (UI Engine, SDUI, config no-code, AI) sont hors scope — elles ne doivent PAS apparaître dans le PRD ni l'architecture Phase 1.

---

## Business Types Phase 1 (codés en dur, extensibles progressivement)

| | Blandine | Testeur Boissons | Testeur Cosmétiques |
|---|---|---|---|
| **Business** | Fruits, légumes, épices (produits frais périssables) | Jus, vins, bières, produits divers | Savons, machines, produits chimiques |
| **Vente** | Détail + gros possible | Détail + gros possible | Détail |
| **Rôles** | Propriétaire + Gérant + Commerciaux | Patron + Vendeurs | Patron + Vendeurs |
| **Complexité** | Haute (frais, frotte, vrac→sachet) | Faible (produits standards) | Moyenne (variants, catégories variées) |

Pattern commun : le patron n'est pas toujours à la boutique, il a des vendeurs/employés, il veut contrôler à distance.

D'autres business types retail pourront être ajoutés en dur au fur et à mesure, sans attendre les phases futures.

---

## Modules IN Phase 1

1. **POS (Point de Vente)** — vente détail, encaissement
2. **Vente en Gros** — vente par carton/sac, prix gros distinct (besoin transversal, pas juste Blandine)
3. **Stock / Inventaire** — suivi quantités, mouvements, alertes
4. **Taux de Frotte** — perte naturelle périssables, intégré au calcul de prix (indispensable pour Blandine et beaucoup de business retail)
5. **Vrac→Sachet** — conversion unités (ex : sac 5kg → sachets 100g)
6. **Code couleur fraîcheur** — priorité de vente périssables
7. **Caisse / Arrêt de caisse** — fermeture journalière, réconciliation CA vs stock
8. **Dépenses** — enregistrement dépenses boutique
9. **Commande interne** — circuit commercial→gérant→patron
10. **Notifications push** — résumé quotidien patron dans l'app
11. **Rapports** — CA journalier, état stock, pertes
12. **Gestion fournisseurs** — historique achats, approvisionnement
13. **Inventaire hebdomadaire** — comptage physique, comparaison avec stock théorique, validation par le gérant et le patron
14. **Factures** — génération automatique à chaque vente, export PDF, partage WhatsApp
15. **Impression thermique** — impression factures/reçus via imprimante Bluetooth (ESC/POS)
16. **CRM clients** — fiche client (nom, téléphone), historique achats, solde crédit
17. **Vente à crédit** — toggle on/off par le patron ; si activé, le vendeur peut enregistrer une vente à crédit liée à un client, suivi des impayés

---

## Rôles Phase 1 (codés en dur)

- **Propriétaire** — accès total, reçoit les résumés, valide les commandes internes
- **Gérant** — gestion quotidienne, stock, caisse, commandes
- **Commercial/Vendeur** — POS, ventes, commandes limitées

Rôles codés en dur avec possibilité de retirer certains accès (toggle on/off sur des permissions). Pas de création de rôles custom.

---

## Backoffice Super Admin Scalario (interne, pour le fondateur)

Interface interne pour opérer la plateforme — pas visible par les clients :
- Création de tenant (nouvelle boutique)
- Activation / suspension de tenant
- Reset password utilisateur
- Voir les logs de sync

---

## Offres Phase 1 — Pricing

| Plan | Prix/mois | Ce que ça inclut |
| ---- | --------- | ---------------- |
| **Solo** | 5 000 FCFA | 1 appareil, 1 compte, offline, pas de cloud |
| **Boutique** | 7 500 FCFA | 1 appareil, multi-comptes (patron + vendeurs), offline, pas de cloud |
| **Pro** | 15 000 FCFA | Multi-device, cloud sync, contrôle à distance, notifications push |
| **Pro Annuel** | 12 500 FCFA/mois | = 10 mois payés, 2 offerts (150 000 FCFA/an) |
| **Installation** | Variable | Setup boutique, formation, import données |

**Multi-comptes local (Solo/Boutique)** : plusieurs utilisateurs se connectent sur le même appareil avec leur propre profil. Les permissions par rôle s'appliquent. Pas de sync cloud — upgrade possible vers Pro.

**Cible :** 50–100 clients (mix local + cloud) dans la première année après lancement.

---

## Paiements Phase 1

Sélection manuelle du mode de paiement à la caisse :
- Cash
- Wave
- Orange Money

Pas d'intégration API mobile money. Le vendeur sélectionne le mode utilisé, c'est tout.

---

## Architecture Phase 1

- **Mobile :** Flutter + Isar (offline-first)
- **Backend :** NestJS (monolithe modulaire)
- **Database :** Supabase / PostgreSQL
- **Sync :** Offline-first — tout fonctionne sans Internet, sync au retour de la connexion
- **Multi-tenant** — chaque boutique est un tenant isolé, RBAC + feature flags par module
- **13+ business types** préconfigurés (extensibles)

---

## OUT Phase 1 — Ne pas inclure dans le PRD ni l'architecture

- Templates sectoriels, UI Engine, Config Engine, SDUI
- Module Production / Fabrication
- WhatsApp Business API
- Intégration API Mobile Money (Wave, Orange Money)
- AI (toute forme)
- Multi-boutique (sauf si client le demande)
- Rôles dynamiques / RBAC configurable
- Tout ce qui concerne les phases futures (engines, composants atomiques, config no-code)

---

## Contexte post-Phase 1 (pour mémoire, pas pour le PRD)

- Phase 2 : refonte architecture, UI Engine, composants atomiques, SDUI, début config no-code
- Nouveaux business types ajoutés en dur entre Phase 1 et Phase 2
- Migration progressive — on ne casse rien, on ajoute les engines un par un
