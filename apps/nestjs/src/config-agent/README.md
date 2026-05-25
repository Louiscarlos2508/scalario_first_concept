# `config-agent/` — Scalario Forge backend (Phase 2)

**Status :** Placeholder. À implémenter en Phase 2 (V14-019 — Scalario Forge).

## Rôle (cf PRD v14 §17)

Le `ConfigAgent` est le backend de **Scalario Forge** — l'agent IA d'onboarding qui :
1. Consomme le `BusinessProfile` rempli par le futur client
2. Extrait via LLM la config technique (secteur, rôles, workflows, capabilities, modules)
3. Génère 3-7 questions de précision
4. Provisionne le tenant Demo Space

## Contenu attendu (Phase 2)

```
config-agent/
├── chat.gateway.ts          # WebSocket + SSE pour le chat onboarding
├── extraction.service.ts    # LLM → ERPConfig (via LangChain + Instructor)
├── tenant-generator.ts      # Provisioning tenant après validation
├── prompts/                 # Templates de prompts par secteur
└── __tests__/
```

## Dépendances futures

- `ai/` (pont vers FastAPI où tourne le LLM)
- `core/auth/` (création tenant initial)
- `engines/action/` (handlers pour les actions générées)

## Liens

- Story Phase 2 : `_bmad-output/stories/STORY-V14-019.md`
- PRD v14 §17 — Scalario Forge
