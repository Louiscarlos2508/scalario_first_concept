# STORY-V14-018 : Docling parsing — PDF/Excel/Word → chunks indexables

**Epic :** EPIC-V14-010 — Scalario Search
**Priorité :** Should Have
**Story Points :** 3
**Status :** defined
**Sprint :** v14-7 (Phase 2)
**Dépendances :** V14-014 (FastAPI)

---

## User Story

> **En tant que** Scalario Search (RAG hybride),
> **je veux** parser PDF, Excel, Word en chunks structurés + métadonnées (titre, page, section), puis indexer dans pgvector + tsvector,
> **so that** un user qui uploade un catalogue fournisseur PDF puisse poser des questions dessus en langage naturel via Scalario Mind.

---

## Description

### Background

PRD v14 §23 mentionne Docling (IBM, open source) comme parser de docs structurés. Supérieur à PyPDF2/python-docx pour les tableaux et la mise en page.

### Scope

**In scope :**
- Endpoint `services/fastapi/embeddings.py` : `POST /embeddings/index { tenant_id, doc_id, file_url, doc_type }`.
- Docling pipeline : download file → parse → chunks de ~512 tokens avec overlap 50 → embed → insert pgvector + tsvector.
- Métadonnées par chunk : `{ doc_id, page, section, title, type }`.
- 3 formats supportés : PDF, XLSX, DOCX.
- Test : upload PDF de 10 pages → 30-50 chunks indexés, retrievables via Scalario Search.

**Out of scope :**
- OCR sur PDF scannés — Phase 3
- Images embeddings (CLIP) — Phase 3
- Webcrawler — Phase 3

---

## Acceptance Criteria

- [ ] **AC-01** — `POST /embeddings/index` accepte file URL (S3/MinIO) + doc_type.
- [ ] **AC-02** — Docling parse PDF/XLSX/DOCX → liste de chunks structurés.
- [ ] **AC-03** — Chunking : ~512 tokens par chunk, overlap 50 tokens, préserve les frontières de paragraphe.
- [ ] **AC-04** — Embed chaque chunk via DeepSeek embeddings (ou Cohere multilingual-v3).
- [ ] **AC-05** — Insert dans `tenant_<id>.embeddings` (pgvector) + `tsvector` pour BM25.
- [ ] **AC-06** — Métadonnées : `{ doc_id, page, section, title, type }` stockées.
- [ ] **AC-07** — Test E2E : upload `pharma_catalogue_2026.pdf` (10 pages) → 30-50 chunks → query "vaccin grippe prix" retourne la bonne page.
- [ ] **AC-08** — Latency indexation < 5s pour 10 pages.

---

## Technical Notes

### Docling

```python
from docling.document_converter import DocumentConverter

converter = DocumentConverter()
result = converter.convert(file_path)
chunks = chunker.chunk(result.document, max_tokens=512, overlap=50)

for chunk in chunks:
    embedding = await embed(chunk.text)
    await pgvector.insert(
        content=chunk.text,
        embedding=embedding,
        metadata={
            'doc_id': doc_id,
            'page': chunk.page,
            'section': chunk.section,
            'title': chunk.title,
            'type': doc_type
        }
    )
```

### Edge cases

- PDF protégé par mot de passe → erreur 422
- Excel avec macros → ignorer macros (security)
- Document > 100 MB → reject 413
- Document encodé Windows-1252 → Docling gère via détection encodage

---

## Dependencies

- **Prérequis :** V14-014 (FastAPI), V14-015 (embeddings via LLM hébergé)
- **Stories bloquées :** V14-016 (RAG nécessite des embeddings indexés)

---

## Definition of Done

- [ ] Endpoint indexation fonctionnel
- [ ] 3 formats testés (PDF, XLSX, DOCX)
- [ ] Test E2E upload→indexation→query
- [ ] Latency p95 documentée
- [ ] sprint-status.yaml V14-018 = completed

---

## Story Points Breakdown

| Tâche | Points |
|---|---|
| Docling setup + pipeline parse | 1.0 |
| Chunking + embedding + insert pgvector | 1.5 |
| Tests 3 formats | 0.5 |
| **Total** | **3** |

---

## Progress Tracking

- 2026-05-25 : Created (Carlos via `/bmad:create-story`)

**Actual Effort :** TBD
