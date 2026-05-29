# A2UI Integration & Builder API (Future Reference)

**Status:** Documenté — pas implémenté
**Date:** 2026-05-28

## Problem

Le LLM génère du JSON DSL libre → trop d'hallucinations sur les types, refs, pipelines.

Le diagnostic complet est dans la discussion ChatGPT : le DSL est devenu complexe, les dépendances entre engines sont fortes, le LLM manque de garde-fous.

## Solution retenue pour maintenant

Bridge A2UI dans ScalarioCanvas → le LLM génère au format A2UI v0.9 (flat list, catalogue connu). Solution légère, immédiate, interopérable.

## Solution future (documentée)

### Builder API (TypeScript)

Remplacer la génération de JSON brut par des appels de fonction typés :

```ts
// Au lieu de prompter "génère le JSON"
createScreen("dashboard", {
  components: [
    kpiCard("ca_jour", { label: "CA Jour", source: "ventes" }),
    chartBar("evol_mois", { data: "$ventes.mensuel" }),
  ]
})
```

Le LLM utilise function calling → les builders produisent le JSON déjà valide.

### Scalario Compiler

Pipeline de compilation en 5 étapes :

1. **Parse** → AST
2. **Validate** → Zod + JSON Schema (existant)
3. **Resolve** → traque des `$variables` cross-pipeline, résolution de refs
4. **Infer** → déduction des types de sortie, dépendances, graphe d'exécution
5. **Generate** → production du runtime plan validé

### Contrats machine par registry

Chaque engine expose son contrat lisible par la machine + le LLM :

```json
{
  "registry": "sense",
  "functions": {
    "scanner": { "inputs": {}, "outputs": { "raw": "string", "type": "string" } }
  }
}
```

### Scalario Inspector

Dashboard web pour debugger :
- Pipelines
- Variables et types
- Flow graph
- Dépendances inter-engines
- Live execution

## Architecture cible (future)

```
LLM → Builder API (function calling)
  → Scalario Compiler (parse + validate + resolve + infer + generate)
    → A2UI JSON (garanti valide par construction)
      → A2UIBridge → ScalarioCanvas + Engines
```

## Pourquoi pas maintenant

- La Builder API est lourde à implémenter (tous les builders pour 34 composants + 8 engines)
- Le feedback loop validation + retry résout 80% du problème pour 5% de l'effort
- A2UI bridge seul donne déjà un format LLM-friendly et interopérable
