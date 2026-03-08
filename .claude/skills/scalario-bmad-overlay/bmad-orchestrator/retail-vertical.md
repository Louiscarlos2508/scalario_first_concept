# Retail Vertical — Boutique Management

## Overview

The retail vertical is Scalario's first business vertical. It serves small to medium
boutiques in West Africa with three initial sub-types: grocery (épicerie),
cosmetics (beauté), and beverages (boissons).

## The 8-Phase Operational Flow

Based on Blandine's grocery workflow, adapted for all retail sub-types:

```
Phase 1: COMMANDE          Propriétaire commande chez le fournisseur
Phase 2: RÉCEPTION          Gestionnaire reçoit et contrôle la livraison
Phase 3: TRANSFERT          Magasin → Rayon (avec double validation)
Phase 4: DÉCLASSEMENT       Déclaration des pertes (avec responsabilité)
Phase 5: ALERTE             Seuils critiques et demandes de réappro
Phase 6: RÉAPPRO INTERNE    Commercial → Gestionnaire → Propriétaire
Phase 7: VENTE + CAISSE     Point de vente et encaissement
Phase 8: CLÔTURE            Réconciliation caisse et inventaire
```

### Phase Details

**Phase 1 — Commande Fournisseur**
- Actor: Propriétaire
- Action: Crée une commande fournisseur (produits, quantités, poids théorique)
- Module: @scalario/purchasing
- Offline: Non (commande envoyée par réseau)

**Phase 2 — Réception et Contrôle Qualité**
- Actor: Gestionnaire
- Action: Reçoit la livraison, note les écarts quantité, ajoute des observations qualité
- Module: @scalario/purchasing + @scalario/stock
- Offline: Oui (réception peut se faire offline, sync après)
- Spécial grocery: Notes de qualité ("Tomates un peu trop mûres")
- Event émis: `purchasing.order.received` → stock increments

**Phase 3 — Transfert Interne (Magasin → Rayon)**
- Actor: Gestionnaire (envoie) + Commercial (valide réception)
- Action: Gestionnaire sort les produits, Commercial confirme la réception
- Module: @scalario/vertical-retail (specific entity: internal_transfer)
- Offline: Oui (double validation peut être async)
- Key rule: Stock ne devient "disponible à la vente" qu'APRÈS validation du Commercial
- Event émis: `retail.transfer.validated` → stock location update

**Phase 4 — Déclassement / Pertes**
- Actor: Gestionnaire ou Commercial
- Action: Déclare un produit perdu/pourri avec raison et localisation
- Module: @scalario/vertical-retail (loss_declaration) + @scalario/stock (movement)
- Offline: Oui
- Key rule: Responsabilité segmentée — perte au magasin (gestionnaire) vs en rayon (commercial)
- Event émis: `stock.movement.loss_declared` → reporting + notification propriétaire

**Phase 5 — Alertes Stock**
- Actor: Système (automatique)
- Action: Quand stock atteint le seuil minimum, alerte envoyée
- Module: @scalario/stock + @scalario/reporting
- Offline: Alertes locales possibles, notifications push nécessitent réseau

**Phase 6 — Réapprovisionnement Interne**
- Actor: Commercial → Gestionnaire → Propriétaire
- Action: Chaîne de validation pour demande de réappro
- Module: @scalario/vertical-retail (restock_request)
- Offline: Création de demande offline, validation nécessite réseau pour les 3 étapes

**Phase 7 — Vente et Encaissement**
- Actor: Commercial (caissier)
- Action: Sélection produits, saisie quantité/poids, encaissement
- Module: @scalario/sales + @scalario/cash
- Offline: OBLIGATOIRE — les ventes ne doivent JAMAIS être bloquées par le réseau
- Moyens de paiement: Espèces (offline OK), Mobile money (online requis)

**Phase 8 — Clôture et Réconciliation**
- Actor: Gestionnaire + Propriétaire
- Action: Arrêt de caisse quotidien, inventaire hebdomadaire
- Module: @scalario/cash + @scalario/stock + @scalario/reporting
- Offline: Clôture locale possible, rapport envoyé à la sync
- Key output: Rapport envoyé au propriétaire (WhatsApp/push)

## Sub-Type Specifics

### Grocery (Épicerie — Blandine)

**Extra features:**
- Conversion vrac → sachet (épices: sac 5kg → sachets 50g/100g)
- Taux de frotte (shrinkage): tolérance perte de poids naturelle par évaporation
- Code couleur fraîcheur (🟢🟠🔴) pour produits périssables
- Prix au gramme pour épices chères
- Date de fraîcheur estimée (pas une date d'expiration fixe)

**Stock extension config:**
```json
{
  "enableShrinkageRate": true,
  "defaultShrinkagePercent": 3,
  "enableFreshnessTracking": true,
  "freshnessThresholds": {
    "warning_days": 3,
    "critical_days": 1
  },
  "enableBulkConversion": true,
  "unitConversions": [
    { "from": "kg", "to": "sachet_50g", "factor": 20 },
    { "from": "kg", "to": "sachet_100g", "factor": 10 }
  ]
}
```

**Roles:**
- Propriétaire (Blandine): Tout voir, valider arrivages, modifier prix, clôturer caisse
- Gestionnaire (Magasin): Réception, transferts, contrôle stock magasin
- Commercial (Rayon): Vendre, déclarer pertes rayon, demander réappro

### Cosmetics (Beauté)

**Extra features:**
- Variantes produit (taille, couleur, référence)
- Suivi date d'expiration stricte (cosmétiques réglementés)
- Gestion marge par produit (alerte si marge < seuil)
- Catalogue fournisseur avec images

**Stock extension config:**
```json
{
  "enableVariants": true,
  "variantTypes": ["size", "color", "shade"],
  "enableExpiryTracking": true,
  "expiryStrictMode": true,
  "enableMarginTracking": true,
  "minMarginPercent": 15
}
```

**Roles:** Similar to grocery (adapt labels to context)

### Beverages (Boissons et Divers)

**Extra features:**
- Gestion par lot/batch (traçabilité par fournisseur et date)
- Consignes/emballages retournables (bouteilles, casiers)
- Remises volume (achat par casier)
- Distinction boissons fraîches (frigo) vs température ambiante

**Stock extension config:**
```json
{
  "enableBatchTracking": true,
  "enableDepositManagement": true,
  "depositItems": [
    { "name": "Casier 24", "depositAmount": 2500 },
    { "name": "Bouteille verre", "depositAmount": 100 }
  ],
  "enableVolumeDiscounts": true,
  "enableStorageZones": true,
  "storageZones": ["frigo", "ambiant"]
}
```

## Roles & Permissions Matrix (Retail)

```
Action                  Propriétaire  Gestionnaire  Commercial
─────────────────────────────────────────────────────────────
Voir chiffre d'affaires      ✅            ✅           ❌
Valider un arrivage          ✅            ✅           ❌
Vendre un produit            ✅            ❌           ✅
Déclarer produit pourri      ✅            ✅           ✅
Modifier les prix            ✅            ❌           ❌
Clôturer caisse              ✅            ✅           ❌
Créer commande fournisseur   ✅            ❌           ❌
Transférer magasin→rayon     ❌            ✅           ❌
Valider réception rayon      ❌            ❌           ✅
Demander réappro             ❌            ❌           ✅
Voir rapports                ✅            ✅(limité)   ❌
Gérer utilisateurs           ✅            ❌           ❌
```

## Daily Summary (Notification Propriétaire)

Every evening, the system sends the owner a summary:

```
📊 Résumé du jour — [Date]

💰 Chiffre d'affaires: 125.750 F CFA
📦 Pertes déclarées: 3.200 F CFA
🔴 Stock critique:
   - Tomates (reste 2 kg, seuil: 5 kg)
   - Sachets piment (reste 8, seuil: 20)
💵 Écart caisse: -750 F CFA
📋 Commandes en attente: 2

Bonne soirée ! 🌙
```

Delivery: WhatsApp preferred (most used in West Africa), push notification as fallback.
