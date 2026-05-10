---
type: tokens
group: icons
---

# Tokens — Icônes

**Bibliothèque :** Material Icons (package Flutter natif — `Icons.*`)
**Style par défaut :** `_outlined` (outlined variant — plus aéré, moderne)
**Style actif :** filled (sans suffixe) — tab BottomNav sélectionnée, filtre actif

> Règle : ne jamais mélanger outlined et filled sur la même surface. Outlined = repos / Filled = actif.

---

## Tokens de taille

| Token | Valeur | Usage |
|-------|--------|-------|
| `icon-xs` | 16px | Inline dans texte, badges, chips compacts |
| `icon-sm` | 20px | Listes compactes, sous-labels, meta-données |
| `icon-md` | 24px | Standard — AppBar, BottomNav, boutons |
| `icon-lg` | 32px | Actions featured, illustrations fonctionnelles, EmptyState |

---

## Mapping sémantique

### Navigation

| Concept | Token | Valeur Flutter | Actif (filled) |
|---------|-------|----------------|----------------|
| Dashboard | `icon-nav-dashboard` | `Icons.home_outlined` | `Icons.home` |
| Vente / POS | `icon-nav-sales` | `Icons.shopping_cart_outlined` | `Icons.shopping_cart` |
| Stock | `icon-nav-stock` | `Icons.inventory_2_outlined` | `Icons.inventory_2` |
| Rapports | `icon-nav-reports` | `Icons.bar_chart_outlined` | `Icons.bar_chart` |
| Historique | `icon-nav-history` | `Icons.history` | `Icons.history` |
| Équipe | `icon-nav-team` | `Icons.group_outlined` | `Icons.group` |
| Opérations | `icon-nav-ops` | `Icons.assignment_outlined` | `Icons.assignment` |
| Paramètres | `icon-nav-settings` | `Icons.settings_outlined` | `Icons.settings` |

### Actions

| Concept | Token | Valeur Flutter |
|---------|-------|----------------|
| Ajouter | `icon-action-add` | `Icons.add` |
| Modifier | `icon-action-edit` | `Icons.edit_outlined` |
| Supprimer | `icon-action-delete` | `Icons.delete_outline` |
| Confirmer / Valider | `icon-action-confirm` | `Icons.check` |
| Annuler / Fermer | `icon-action-close` | `Icons.close` |
| Retour | `icon-action-back` | `Icons.arrow_back` |
| Rechercher | `icon-action-search` | `Icons.search` |
| Filtrer | `icon-action-filter` | `Icons.tune_outlined` |
| Envoyer | `icon-action-send` | `Icons.send_outlined` |
| Télécharger | `icon-action-download` | `Icons.download_outlined` |
| Imprimer | `icon-action-print` | `Icons.print_outlined` |
| Copier | `icon-action-copy` | `Icons.content_copy_outlined` |
| Plus d'options | `icon-action-more` | `Icons.more_vert` |
| Voir / Afficher | `icon-action-view` | `Icons.visibility_outlined` |
| Cacher | `icon-action-hide` | `Icons.visibility_off_outlined` |

### Feedback & État

| Concept | Token | Valeur Flutter | Couleur |
|---------|-------|----------------|---------|
| Notification | `icon-notif-bell` | `Icons.notifications_outlined` | neutral-700 |
| Sync en cours | `icon-sync-active` | `Icons.sync` | primary-500 (animé) |
| Offline | `icon-sync-offline` | `Icons.cloud_off_outlined` | warning-500 |
| Erreur | `icon-state-error` | `Icons.error_outline` | danger-500 |
| Avertissement | `icon-state-warning` | `Icons.warning_amber_rounded` | warning-500 |
| Succès | `icon-state-success` | `Icons.check_circle_outline` | success-500 |
| Info | `icon-state-info` | `Icons.info_outline` | primary-600 |
| Chargement | `icon-state-loading` | `Icons.refresh` | neutral-400 (animé) |

### Métier — POS & Caisse

| Concept | Token | Valeur Flutter |
|---------|-------|----------------|
| Caisse / Session | `icon-biz-pos` | `Icons.point_of_sale_outlined` |
| Paiement cash | `icon-biz-cash` | `Icons.payments_outlined` |
| Paiement mobile | `icon-biz-mobile-money` | `Icons.phone_android_outlined` |
| Crédit / Facture | `icon-biz-credit` | `Icons.credit_score_outlined` |
| Ticket de caisse | `icon-biz-receipt` | `Icons.receipt_outlined` |
| Facture PDF | `icon-biz-invoice` | `Icons.description_outlined` |
| Monnaie rendue | `icon-biz-change` | `Icons.currency_exchange` |

### Métier — Stock & Produits

| Concept | Token | Valeur Flutter |
|---------|-------|----------------|
| Produit | `icon-biz-product` | `Icons.inventory_outlined` |
| Livraison fournisseur | `icon-biz-delivery` | `Icons.local_shipping_outlined` |
| Fournisseur | `icon-biz-supplier` | `Icons.store_outlined` |
| Perte / Déchet | `icon-biz-loss` | `Icons.delete_sweep_outlined` |
| Inventaire | `icon-biz-inventory` | `Icons.fact_check_outlined` |
| Alerte stock | `icon-biz-alert` | `Icons.notifications_active_outlined` |
| Transfert stock | `icon-biz-transfer` | `Icons.swap_horiz` |

### Partage & Connectivité

| Concept | Token | Valeur Flutter / Note |
|---------|-------|----------------------|
| WhatsApp | `icon-share-whatsapp` | SVG custom (brand icon — `assets/icons/whatsapp.svg`) |
| SMS | `icon-share-sms` | `Icons.sms_outlined` |
| Email | `icon-share-email` | `Icons.email_outlined` |
| Bluetooth | `icon-share-bluetooth` | `Icons.bluetooth` |
| Bluetooth scan | `icon-share-bluetooth-scan` | `Icons.bluetooth_searching` |
| PDF | `icon-share-pdf` | `Icons.picture_as_pdf_outlined` |

### Administration

| Concept | Token | Valeur Flutter |
|---------|-------|----------------|
| Tenant | `icon-admin-tenant` | `Icons.business_outlined` |
| Déploiement | `icon-admin-deploy` | `Icons.rocket_launch_outlined` |
| Monitoring | `icon-admin-monitor` | `Icons.monitor_heart_outlined` |
| Logs | `icon-admin-logs` | `Icons.article_outlined` |
| Facturation | `icon-admin-billing` | `Icons.receipt_long_outlined` |
| Support | `icon-admin-support` | `Icons.headset_mic_outlined` |
| Utilisateur | `icon-admin-user` | `Icons.person_outlined` |

---

## Règles d'utilisation

```
BottomNav :
  tab repos     → outlined (icon-md 24px, color-neutral-500)
  tab active    → filled  (icon-md 24px, color-primary-600)
  label         → Inter 11sp 500 (repos neutral-500 / actif neutral-900)

AppBar :
  actions droite → outlined (icon-md 24px, color-neutral-700)
  burger menu    → Icons.menu (icon-md 24px, color-neutral-900)

ActionButton :
  icône préfixe  → outlined (icon-sm 20px, couleur héritée du bouton)

AlertBanner :
  icône gauche   → icon-state-* selon sévérité (icon-sm 20px)

EmptyState :
  illustration   → icon-lg 48px, color-neutral-300

WhatsApp :
  toujours SVG custom — jamais Icons.* (marque propriétaire)
```

---

## Asset SVG tiers

| Icône | Chemin asset | Usage |
|-------|-------------|-------|
| WhatsApp | `assets/icons/whatsapp.svg` | Share BottomSheet (ReceiptPreview, InvoicePreview) |

> Les icônes de marque (WhatsApp, Wave, Orange Money) sont toujours des SVG dans `assets/icons/` — jamais de Material Icons pour des marques tierces.
