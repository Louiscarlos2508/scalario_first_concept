"""Scalario FastAPI service — Phase 2 stub (STORY-013).

Phase 1 (Gate 0) exposes only a health endpoint so the service can join the
Docker network and pass healthchecks. Routes IA/RAG seront ajoutées Phase 2
(FR-024+). Tout PR qui ajoute des routes métier hors Phase 2 doit être rejeté.
"""

from fastapi import FastAPI

app = FastAPI(title="Scalario FastAPI (Phase 2 stub)", version="0.1.0")


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "phase2-stub"}
