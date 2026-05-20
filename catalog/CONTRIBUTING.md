# Contribuer au Catalogue Scalario

## Conventions de nommage

- Fichiers domaine : `snake_case.json` (ex: `pharmacie_quartier.json`)
- Identifiants : `^[a-z][a-z0-9_]*$` (ex: `retail_fresh_produce`, `pharmacie_quartier`)
- Branches Git : `feat/catalog/<domain_id>` (ex: `feat/catalog/pharmacie_quartier`)
- Messages de commit : `feat(catalog): add domain <domain_id>`

## Processus de PR

1. **Créez une branche** depuis `main` :
   ```bash
   git checkout -b feat/catalog/mon_domaine
   ```

2. **Ajoutez/modifiez** les fichiers dans `catalog/` uniquement.

3. **Validez localement** :
   ```bash
   pnpm validate-catalogue
   ```
   Tout fichier doit passer la validation Zod avant PR.

4. **Commitez** :
   ```bash
   git add catalog/
   git commit -m "feat(catalog): add domain mon_domaine"
   ```

5. **Poussez et ouvrez une PR** sur GitHub :
   ```bash
   git push origin feat/catalog/mon_domaine
   ```

6. **Review** : un membre de l'équipe Scalario review sous ≤ 48h ouvrées. La CI re-valide automatiquement le catalogue (workflow `.github/workflows/validate-catalogue.yml`).

## Ce qui est validé automatiquement (CI)

- Conformité du fichier JSON au schema `module-config.schema.json`
- Validité des `$ref` vers d'autres schemas
- Présence de `schema_version`, `id`, `name`, `rbac_roles`
- Cohérence des `handler` patterns dans les actions
- Pas d'écrasement d'IDs existants

## Règles importantes

- **Ne modifiez pas** les fichiers dans `catalog/schemas/` — c'est le contrat BDUI gelé en v1.0.0. Toute évolution passe par un sprint Scalario.
- **Ne committez jamais** de données réelles (email, IBAN, téléphone, adresse). Utilisez des données fictives : `Jeanne Test`, `+226 00 00 00 00`.
- **Encodage** : tous les fichiers JSON en UTF-8 sans BOM. Terminez chaque fichier par une ligne vide.
- **Volume catalog/ monté en read-only** : le container NestJS ne peut pas écrire dans `catalog/`. Toute modification passe par Git.

## Gouvernance (Phase 1)

Pour la Phase 1, une seule personne valide les PR catalogue (Carlos). À partir de 5 intégrateurs actifs, un comité de 2 mainteneurs + 1 intégrateur senior sera formé (Phase 2).

## Sécurité

- Aucun secret (mot de passe, clé API, token) ne doit figurer dans un fichier de catalogue
- Les exemples doivent utiliser des données fictives uniquement
- La PR review humaine est la dernière barrière contre un fichier malicieux (gros JSON, deeply nested)
