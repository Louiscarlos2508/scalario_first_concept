# Key Insights & Implications Strategiques — Scalario Retail Phase 1

> Personas, drivers psychologiques et implications UX unifies

**Document:** Trigger Map - Key Insights
**Created:** 2026-04-06
**Status:** COMPLETE

---

## Le pattern central : "Qu'est-ce qui s'est passe pendant que je n'etais pas la ?"

Les 3 testeurs partagent le meme trigger emotionnel : la **perte de controle quand ils sont absents**. Tout le UX doit repondre a cette question. C'est le fil rouge qui traverse chaque ecran, chaque notification, chaque rapport.

---

## Personas

### Blandine — La Boss Lointaine (PRIMARY)

**Situation :** Vit au Senegal, ouvre une boutique de produits frais a Ouagadougou. Jamais sur place.

**Equipe :** Proprietaire + Gerant + Commerciaux (3 niveaux)

**Palier :** Pro (cloud obligatoire)

**Workflow :** Circuit en 8 phases — commande → reception magasin → rayons → vente → pertes → alertes → commandes → arret de caisse + inventaire hebdo. Chaque maillon confirme, elle valide au bout.

**Drivers positifs :**
1. **Maitrise totale** — chaque decision importante passe par elle
2. **Visibilite permanente** — savoir exactement ce qui se passe a tout moment
3. **Piloter a distance** — prouver qu'on peut gerer une boutique depuis un autre pays

**Drivers negatifs :**
1. **Perte de controle** — des choses se passent sans qu'elle soit au courant
2. **Decisions prises sans elle** — quelqu'un achete, depense ou jette sans sa validation
3. **Etre dans le flou** — ne pas avoir l'info pour savoir si la journee etait bonne ou mauvaise

**Scalario repond :** Circuit de validation a chaque etape + notifications push + rapports quotidiens + inventaire hebdo avec ecarts visibles.

---

### Yempabou — Le Patron Pragmatique (SECONDARY)

**Situation :** Parfois absent, gestion familiale, ~150 produits boissons/divers.

**Equipe :** Patron + Gerante (2 niveaux)

**Outil actuel :** Cahier + Gescom (app web beninoise, pas offline, pas de factures)

**Palier :** Boutique → upsell Pro probable

**Drivers positifs :**
1. **Vue d'ensemble immediate** — stock, alertes, caisse des l'ouverture de l'app
2. **Preuves tangibles** — factures, historique, chiffres concrets
3. **Mieux que Gescom** — offline, complet, natif, avec CRM et credit

**Drivers negatifs :**
1. **Vol et pertes non prouvables** — il soupconne mais ne peut pas demontrer
2. **Dependance a l'appel** — seul moyen de savoir quand absent
3. **Limites outil actuel** — Gescom ne couvre pas tout, pas offline

**Scalario repond :** Dashboard stock/alertes/caisse + factures + CRM clients avec suivi credit + fonctionnement offline total.

---

### Vivien — Le Commercant Connecte (SECONDARY)

**Situation :** Pas toujours a la boutique, 1 vendeuse, ~60 produits cosmetiques.

**Equipe :** Patron + Vendeuse (2 niveaux)

**Outil actuel :** Cahier uniquement

**Palier :** Pro (cloud, 2 devices)

**Drivers positifs :**
1. **Supervision bienveillante** — il entre les produits, elle vend, chacun son role
2. **Ventes en temps reel** — voir depuis son telephone sans etre a la boutique
3. **Professionnalisation** — factures imprimees, arret de caisse propre, fini le cahier

**Drivers negatifs :**
1. **L'angle mort** — quand il n'est pas la, il ne sait litteralement rien
2. **Le cahier ne suffit plus** — difficile de recouper, pas de preuve, pas d'historique fiable
3. **Pas de facture = pas professionnel** — perte de credibilite face aux clients

**Scalario repond :** 2 devices synchro (patron + vendeuse) + impression thermique + arret de caisse avec reconciliation.

---

## Prioritisation des drivers

| Rang | Driver | Type | Intensite |
| ---- | ------ | ---- | --------- |
| #1 | Perte de controle / angle mort quand absent | Negatif | Tres haute — les 3 testeurs |
| #2 | Visibilite en temps reel | Positif | Haute — reponse directe au #1 |
| #3 | Vol / pertes non prouvables | Negatif | Haute — touche l'argent |
| #4 | Maitrise et validation (circuit de confiance) | Positif | Haute — surtout Blandine |
| #5 | Professionnalisation (factures, preuves) | Positif | Moyenne-Haute — Vivien + Yempabou |

---

## Implications UX

### Dashboard (ecran d'accueil)

Doit repondre a : **"Qu'est-ce qui s'est passe ?"**

- CA du jour (ou de la veille si patron consulte le soir)
- Nombre de ventes + ventilation par mode de paiement
- Alertes stock bas (produits a commander)
- Commandes en attente de validation
- Ecarts de caisse non resolus
- Produits critiques (fraicheur rouge)

**Regle UX :** En 5 secondes, le patron sait si la journee est bonne ou mauvaise.

### POS (ecran de vente)

Doit repondre a : **"Encaisser vite, sans erreur"**

- Recherche produit rapide (nom ou scan)
- Ajout quantite en 1 tap
- Selection mode de paiement (Cash, Wave, Orange Money, Credit si active)
- Association client optionnelle
- Validation → facture generee automatiquement
- Bouton imprimer si imprimante connectee

**Regle UX :** Une vente complete en moins de 30 secondes.

### Circuit de validation (commandes internes)

Doit repondre a : **"Rien ne se fait sans mon accord"**

- Commercial cree → notification gerant
- Gerant approuve → notification patron
- Patron valide ou rejette avec motif
- Historique complet des decisions

**Regle UX :** Le patron voit toutes les demandes en attente en 1 tap depuis le dashboard.

### Arret de caisse

Doit repondre a : **"L'argent est la ?"**

- Montant theorique (calcule depuis les ventes)
- Montant reel (saisi par le gerant/vendeur)
- Ecart visible immediatement (vert = OK, rouge = probleme)
- Ventilation par mode de paiement
- Transmis au patron automatiquement

**Regle UX :** L'ecart est le chiffre le plus visible de l'ecran.

### Inventaire

Doit repondre a : **"Le stock reel correspond au stock systeme ?"**

- Lancer un inventaire (tous produits ou par categorie)
- Saisie quantites reelles
- Ecart calcule automatiquement par produit
- Resume : nombre de produits avec ecart + valeur totale
- Validation gerant → transmission patron

**Regle UX :** Les ecarts negatifs (stock reel < theorique) sont mis en evidence — c'est la ou se cachent le vol et les pertes.

### Rapports

Doit repondre a : **"Montrez-moi les preuves"**

- Rapport CA : journalier, par periode, par vendeur, par mode de paiement
- Rapport stock : niveaux actuels, mouvements, valeur stock
- Rapport pertes : frotte, produits expires, ecarts inventaire
- Export PDF / partage WhatsApp

**Regle UX :** Chaque rapport doit pouvoir etre partage en 1 tap (le patron au Senegal l'envoie a un conseiller, un ami, un investisseur).

### CRM & Credit

Doit repondre a : **"Qui me doit de l'argent ?"**

- Liste clients avec solde credit
- Historique achats par client
- Enregistrement paiement credit
- Toggle on/off par le patron

**Regle UX :** La liste des debiteurs est triee par montant du — le plus gros en haut.

---

## Facteurs critiques de succes

1. **Offline-first sans compromis** — tout fonctionne sans Internet, la sync est invisible
2. **5 secondes pour comprendre** — le dashboard repond a "comment ca va ?" en un coup d'oeil
3. **Circuit de confiance** — chaque action sensible est tracee et validee
4. **Preuves exportables** — factures, rapports, arrets de caisse partageable en PDF/WhatsApp
5. **30 secondes par vente** — le POS ne doit jamais ralentir le vendeur

---

## Transformation emotionnelle visee

- **Blandine :** "Je sais exactement ce qui se passe dans ma boutique, meme depuis Dakar."
- **Yempabou :** "J'ai les preuves. Si quelque chose disparait, je le vois."
- **Vivien :** "Ma vendeuse vend, je controle, et les clients recoivent une vraie facture."
- **Tout patron :** "Je ne suis plus dans le flou. Mon telephone est ma fenetre sur ma boutique."

---

## Focus Statement

**Scalario Phase 1 cible en priorite les proprietaires de boutique retail qui ne sont pas toujours sur place.** Le produit doit eliminer l'angle mort en offrant une visibilite en temps reel, un circuit de validation qui empeche les decisions non autorisees, et des preuves tangibles qui rendent les pertes et le vol detectables. Si un patron au Senegal peut piloter sa boutique a Ouaga avec confiance, alors tout proprietaire qui s'absente quelques heures peut le faire aussi.

---

## Benchmark : Scalario vs Gescom

| Critere | Gescom | Scalario |
| ------- | ------ | -------- |
| Offline | Non (web only) | Oui — tout fonctionne sans Internet |
| App native | Non (navigateur) | Oui — Flutter mobile + desktop |
| Factures | Oui | Oui + impression thermique Bluetooth |
| CRM / Credit | Non mentionne | Oui — fiche client + suivi credit |
| Notifications push | Non | Oui — alertes + resume quotidien |
| Circuit validation | Non | Oui — commercial → gerant → patron |
| Frotte / perissables | Non | Oui — taux de frotte + fraicheur |
| Vrac → sachet | Non | Oui — conversion unites |
| Prix entree | 5K FCFA (50 produits max) | 5K FCFA (produits illimites) |

---

## Documents lies

- **[00-trigger-map.md](00-trigger-map.md)** - Hub et diagramme
- **[01-Business-Goals.md](01-Business-Goals.md)** - Objectifs et metriques

---

_Back to [Trigger Map](00-trigger-map.md)_
