# 01: Blandine pilote depuis Dakar

**Project:** Scalario Retail Phase 1
**Created:** 2026-04-06
**Method:** Whiteport Design Studio (WDS)

---

## Transaction (Q1)

**What this scenario covers:**
Vérifier l'état de sa boutique de Ouaga depuis Dakar et partager une preuve à un tiers — l'acte complet : ouvrir l'app le matin, comprendre la journée d'hier en quelques secondes, repérer ce qui cloche, et envoyer un rapport WhatsApp à un conseiller.

---

## Business Goal (Q2)

**Goal:** THE ENGINE — 3 testeurs actifs fin avril 2026
**Objective:** Si Blandine ouvre l'app tous les matins depuis Dakar et trouve la réponse à "qu'est-ce qui s'est passé hier ?", la Priorité #1 du flywheel est validée. Justifie aussi le palier Pro 15K FCFA (cloud + multi-device + push).

---

## User & Situation (Q3)

**Persona:** Blandine (PRIMARY)
**Situation:** Propriétaire d'une boutique de fruits/légumes/épices à Ouagadougou, vit à Dakar. 6h47 du matin, dans sa cuisine au Sénégal, café à la main, juste après avoir reçu la notification push "Résumé d'hier — Boutique Ouaga". Elle a 4 minutes avant de réveiller les enfants pour l'école.

---

## Driving Forces (Q4)

**Hope:** Voir en un coup d'œil que la journée a été correcte, que personne n'a fait de bêtise, et avoir une preuve à montrer si besoin.

**Worry:** Découvrir qu'il manque de l'argent en caisse, qu'une commande a été passée sans son accord, ou pire — ne rien voir et rester dans le flou.

---

## Device & Starting Point (Q5 + Q6)

**Device:** Mobile (Android)
**Entry:** Notification push reçue à 6h45 ("Résumé d'hier — CA 47 500 F · 1 commande à valider · 1 écart caisse"). Elle tape la notif, l'app s'ouvre directement sur le Dashboard Patron — session persistante, profil propriétaire actif.

---

## Best Outcome (Q7)

**User Success:**
En moins de 60 secondes, Blandine sait : (a) le CA d'hier, (b) qu'il y a 1 commande à valider et 1 écart caisse à comprendre, (c) elle exporte le rapport CA de la semaine en PDF et l'envoie sur WhatsApp à son comptable. Elle pose son téléphone, sereine.

**Business Success:**
Ouverture quotidienne confirmée (DAU 100% sur 30 jours pour Blandine). Validation THE ENGINE. Preuve que le palier Pro vaut 15K FCFA. Elle devient référence active pour vendre à d'autres patrons absents.

---

## Shortest Path (Q8)

1. **Centre notifications (38)** — Tape la push "Résumé d'hier", l'app s'ouvre.
2. **Splash / Login (1)** — Session active, redirection automatique (aucune saisie).
3. **Sélection profil (2)** — Profil "Blandine — Propriétaire" déjà actif, skip.
4. **Dashboard Patron (4)** — Voit en 5s : CA d'hier 47 500 F, 1 commande à valider, 1 écart caisse rouge, 3 alertes stock bas, 2 produits fraîcheur rouge.
5. **Hub rapports (34)** — Tape "Rapports" pour creuser et avoir une preuve à partager.
6. **Rapport CA (35)** — Sélectionne période "7 derniers jours", voit ventilation par jour + mode de paiement + vendeur.
7. **Rapport stock (36)** — Vérifie valeur stock, mouvements, produits critiques.
8. **Rapport pertes (37)** — Confirme les pertes frotte/expirés sur la semaine.
9. **Retour Hub rapports (34)** — Tape "Exporter en PDF" puis "Partager WhatsApp" → rapport envoyé au comptable. ✓

---

## Trigger Map Connections

**Persona:** Blandine (PRIMARY)

**Driving Forces Addressed:**
- ✅ **Want:** Maîtrise totale + visibilité permanente + piloter à distance
- ❌ **Fear:** Perte de contrôle + décisions sans elle + être dans le flou

**Business Goal:** THE ENGINE (Priorité #1) — 3 testeurs actifs fin avril 2026, validation du flywheel

---

## Scenario Steps

Steps are outlined one at a time after scenario creation. The first step is processed automatically.

| Step | Folder | Purpose | Exit Action |
|------|--------|---------|-------------|
| 01.1 | `01.1-centre-notifications/` | Recevoir et ouvrir le résumé quotidien | Tape la notification "Résumé d'hier" → Dashboard |
| 01.2 | `01.2-dashboard-patron/` | Comprendre l'état de la boutique en 5s | Tape "Voir les rapports" → Hub rapports |
| 01.3 | `01.3-hub-rapports/` | Choisir le rapport à consulter | Tape "Rapport CA" → Rapport CA |
| 01.4 | `01.4-rapport-ca/` | Voir la performance commerciale de la semaine | Tape "Rapport stock" depuis le filtre |
| 01.5 | `01.5-rapport-stock/` | Vérifier valeur stock et produits critiques | Tape "Rapport pertes" |
| 01.6 | `01.6-rapport-pertes/` | Confirmer les pertes frotte/expirés | Retour Hub rapports |
| 01.7 | `01.7-export-partage/` | Exporter PDF et partager WhatsApp | Partage envoyé ✓ |
