# Catalogue Scalario — Guide Intégrateur

## 1. Qu'est-ce que le catalogue ?

Le catalogue est le **produit** de Scalario. C'est un dossier de fichiers JSON qui décrivent des secteurs d'activité (retail, pharmacie, BTP, transport...). Le backend et l'app mobile ne contiennent **aucun code métier** — ils lisent ce dossier et rendent l'expérience correspondante.

> Métaphore : Scalario est un orchestre. Le catalogue est la partition. Sans partition, les musiciens (le code) ne savent pas quoi jouer.

Cela veut dire que pour ajouter un nouveau secteur (ou un nouveau module dans un secteur existant), vous **n'écrivez aucune ligne de TypeScript ni de Dart**. Vous écrivez du JSON.

---

## 2. Anatomie d'un template

Un template sectoriel (un "domaine") est un fichier JSON dans `catalog/domains/` :

```
catalog/
├── domains/                # Templates par secteur (ex: pharmacie_quartier.json)
├── modules/                # Modules réutilisables (ex: pos.json, stock.json)
├── fusions/                # Combinaisons multi-domaines (réservé Phase 2)
└── schemas/                # JSON Schemas (le contrat — ne pas modifier)
```

### Structure d'un fichier domaine

```json
{
  "id": "pharmacie_quartier",
  "schema_version": "1.0.0",
  "name": "Pharmacie de quartier",
  "i18n_key": "domain.pharmacie_quartier",
  "icon": "package",
  "entities": [],
  "actions": {},
  "rbac_roles": ["OWNER"],
  "abac_rules": [],
  "conflict_strategy": "server_wins"
}
```

Chaque champ est documenté dans [`catalog/schemas/module-config.schema.json`](./schemas/module-config.schema.json) et expliqué dans [`catalog/schemas/README.md`](./schemas/README.md).

---

## 3. Checklist en 5 étapes — Créer un nouveau domaine

### Étape 1 — Scaffold

```bash
bash scripts/scaffold-domain.sh pharmacie_quartier
```

Cela crée `catalog/domains/pharmacie_quartier.json` avec le squelette minimum.

### Étape 2 — Éditer le JSON

Ouvrez `catalog/domains/pharmacie_quartier.json` et remplissez :
- `name` (ex: "Pharmacie de quartier")
- `entities` (liste des choses qu'on stocke — ex: ordonnance, medicament)
- `actions` (les opérations possibles — ex: enregistrer_ordonnance)
- `rbac_roles` (qui peut faire quoi — ex: ["PHARMACIEN", "PREPARATEUR"])

Référez-vous à [`catalog/schemas/README.md`](./schemas/README.md) pour la liste exacte des champs.

### Étape 3 — Valider localement

```bash
bun run validate-catalogue
```

S'il y a des erreurs, elles seront affichées champ par champ.

### Étape 4 — Commit & PR

```bash
git checkout -b feat/catalog/pharmacie_quartier
git add catalog/domains/pharmacie_quartier.json
git commit -m "feat(catalog): add pharmacie_quartier domain"
git push origin feat/catalog/pharmacie_quartier
```

Ouvrez la PR sur GitHub. La CI re-valide automatiquement.

### Étape 5 — Review & merge

Un membre de l'équipe Scalario passe en review (≤ 48h). Une fois mergé, le domaine est disponible pour provisionner un nouveau tenant.

---

## 4. Validation locale

### Prérequis

```bash
pnpm install
```

### Valider tous les fichiers du catalogue

```bash
pnpm validate-catalogue
```

### Valider un fichier spécifique

```bash
bun scripts/validate-catalogue.ts catalog/domains/mon_fichier.json
```

### Que faire en cas d'erreur ?

Lisez le message : il contient le chemin JSON exact du champ invalide et la raison. Exemple :

```
catalog/domains/pharmacie_quartier.json: entities[0].type: must match pattern "^[a-z][a-z0-9_]*$"
```

Corrigez, puis re-validez.

---

## 5. FAQ

### Puis-je modifier le code Flutter ou NestJS ?

**Non.** Si votre besoin nécessite un changement de code, c'est un changement plateforme qui passe par un sprint produit Scalario. Le catalogue ne couvre que les domaines exprimables dans le schéma.

### Comment ajouter un module à un domaine existant ?

1. Ouvrez le fichier JSON du domaine dans `catalog/domains/`.
2. Ajoutez une entrée dans le tableau `entities`.
3. Ajoutez les `actions` correspondantes.
4. Validez avec `pnpm validate-catalogue`.

### Que faire si Zod me retourne une erreur ?

Lisez attentivement le chemin indiqué. Les erreurs les plus fréquentes :
- `must have required property 'schema_version'` → vous avez oublié le champ obligatoire `"schema_version": "1.0.0"`.
- `must match pattern "^[a-z][a-z0-9_]*$"` → l'identifiant contient des caractères interdits (majuscules, tirets, espaces). Utilisez `snake_case`.
- `must be equal to const "1.0.0"` → `schema_version` doit être exactement `"1.0.0"`.

### Combien de temps prend une PR review ?

L'équipe Scalario s'engage à reviewer sous **48 heures ouvrées**. Si votre PR est urgente, mentionnez-le dans la description.

### Comment tester localement avant la PR ?

```bash
# 1. Lancez la stack de validation
pnpm validate-catalogue

# 2. (Optionnel) Lancez le backend en local
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
# Le volume catalog/ est monté automatiquement — modification = hot-reload

# 3. Vérifiez que votre domaine est chargé
curl http://localhost:3000/api/v1/{tenant}/layout/{screen}
```

### Le hot-reload fonctionne-t-il en dev ?

Oui. Le dossier `catalog/` est monté en volume read-only dans le container Docker (`docker-compose.dev.yml`). Une modification d'un fichier JSON côté host est immédiatement visible par le service NestJS (après le délai de cache Redis — jusqu'à 5 min). Pour une invalidation immédiate, contactez l'équipe Scalario.

### Un fichier mal formé peut-il casser le service ?

Non. Le validateur Zod (CI) bloque toute PR contenant un fichier invalide. En local, le service NestJS ignore silencieusement un fichier qui ne passe pas la validation — il logge une erreur mais ne crash pas.

---

## Liens utiles

- [Documentation HTML des schémas BDUI](../docs/bdui-schema/index.html)
- [Règles de contribution](./CONTRIBUTING.md)
- [Contrat JSON Schema v1.0.0](./schemas/component-config.schema.json)
- [Exemple complet : retail_fresh_produce.json](./domains/retail_fresh_produce.json)
