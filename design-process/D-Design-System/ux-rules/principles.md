---
type: ux-rules
slug: principles
---

# UX Rules — Principes Scalario

> Ces règles s'appliquent à TOUTES les surfaces Scalario.
> Elles ont priorité sur les préférences stylistiques.

---

## P1 — 30 secondes maximum

**Règle :** Chaque dashboard doit permettre à l'utilisateur de comprendre l'état critique en ≤ 30 secondes.

**Application :**
- Les alertes critiques sont TOUJOURS au-dessus du fold
- Maximum 4 KPICards above the fold sur mobile
- Pas de modal ou loading au démarrage sauf si indispensable
- L'action primaire est visible sans scroll

---

## P2 — Une action primaire par vue

**Règle :** Chaque vue a exactement une `ActionButton` primaire — pleine largeur, impossible à rater.

**Application :**
- Dashboard COMMERCIAL : "Nouvelle vente" — au-dessus de tout
- Dashboard MANAGER : "Réceptionner livraison" si réception en attente, sinon les 3 actions sont égales
- Formulaires : "Sauvegarder" ou "Confirmer" — toujours en bas, toujours visible
- Jamais deux boutons primaires sur le même écran

---

## P3 — Offline transparent, pas alarmiste

**Règle :** L'état offline ne bloque jamais une action. Il est visible mais discret.

**Application :**
- `SyncStatusBar` toujours en bas de page, jamais en modal bloquant
- Texte offline : "Données locales à jour" — pas "Connexion perdue !"
- Les actions continuent normalement depuis Drift
- La sync s'effectue silencieusement au retour du réseau
- Pas d'`AlertBanner` rouge pour offline — seulement `SyncStatusBar` ambre

---

## P4 — Traçabilité mutuelle — protection des deux côtés

**Règle :** Chaque action sensible notifie les deux parties et crée un audit trail.

**Application :**
- Clôture caisse : Commercial protégé, Blandine informée (S03)
- Déclaration perte : Ibrahim protégé, Blandine notifiée discrètement (S06)
- Annulation vente : Commercial protégé par le motif, Blandine notifiée (S14)
- Vente crédit : tracée automatiquement, Blandine notifiée (S15)
- Le ton des notifications : informatif, jamais accusateur

---

## P5 — Zéro friction sur le chemin critique

**Règle :** Le flow le plus fréquent (vente) ne doit jamais avoir plus de 3 taps du dashboard à la confirmation.

**Application :**
- S02 : Dashboard → Sélection articles → Confirmation = 3 taps max
- POS : articles les plus vendus en premier (tri automatique par fréquence)
- Clavier numérique apparaît automatiquement sur QuantityControl
- Pas de confirmation intermédiaire sur le flow de vente standard

---

## P6 — BDUI — aucun écran codé en dur

**Règle :** Aucun composant Flutter ne contient de logique métier ou de contenu texte hardcodé.

**Application :**
- Labels des boutons viennent du JSON template
- Types de produits viennent de `pos_type` dans le catalogue
- Alertes disponibles viennent du template JSON
- Permissions viennent du backend (rôle + département)
- Exceptions tolérées : messages d'erreur système, textes légaux

---

## P7 — Hiérarchie AlertBanner stricte

**Règle :** Une seule `AlertBanner` visible à la fois, selon cette priorité décroissante.

**Priorité :**
1. 🔴 Critique rouge — stock sous seuil, clôture manquée, erreur sync
2. 🟡 Warning ambre — livraison en attente, écart livraison, perte déclarée
3. 🟢 Succès vert — action confirmée (disparaît après 2 secondes)
4. 🔵 Info bleu — mode offline discret
5. Absent — état nominal

**Application :**
- Si 2 alertes critiques : la plus récente prime
- Le succès vert est toujours éphémère (2 secondes) — pas de dismiss manuel
- L'ambre persiste jusqu'à action ou dismiss manuel

---

## P8 — Personas isolés — chaque rôle voit son périmètre

**Règle :** Un Commercial ne voit pas les données financières globales. Un Manager ne voit pas les rapports OWNER.

**Application :**
- Commercial : CA personnel uniquement, pas CA total magasin
- Manager : opérations terrain (stock, réceptions, pertes), pas les marges
- OWNER : tout — c'est son business
- Kofi : uniquement ses tenants assignés
- Admin Scalario : tout — accès lecture sur tous les tenants

---

## P9 — Langue française partout

**Règle :** Tous les labels, messages, notifications sont en français.

**Application :**
- Pas d'anglais dans les labels utilisateur (OK pour les noms de composants techniques)
- Montants : FCFA avec espace insécable (12 500 FCFA)
- Dates : format JJ/MM ou "9 mai" — jamais MM/JJ
- Heures : 24h (19:30) — pas AM/PM
- Messages d'erreur : humains, pas techniques ("Le stock est insuffisant" pas "Error 422")

---

## P10 — Confirmation obligatoire sur actions destructives

**Règle :** Toute action irréversible déclenche un `ConfirmationDialog` avant exécution.

**Actions concernées :**
- Annulation de vente (S14)
- Suspension d'un employé (S10)
- Suspension d'un tenant (A02)
- Révocation accès intégrateur (A03)
- Toute suppression de données

**Le dialog doit :**
- Rappeler l'action en clair ("Annuler cette vente de 12 500 FCFA")
- Préciser les conséquences ("Le stock sera remis à jour")
- Avoir un bouton Annuler toujours à gauche
- Avoir le bouton destructif toujours à droite, en rouge
