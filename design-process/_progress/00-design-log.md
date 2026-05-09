# Design Log: Scalario

> Project memory — all phases, decisions, and artifacts

**Project:** Scalario
**Founder:** Carlos Simporé
**Started:** 2026-05-09

---

## Progress

### 2026-05-09 — Phase 2: Trigger Mapping Complete

**Agent:** Saga (Strategic Analyst)
**Mode:** Documentation Synthesis (00a→00f) + Suggest

**Artifacts Created:**
- `B-Trigger-Map/trigger-map.md`

**Summary:** Trigger Map construit depuis les documents Phase 1 via synthèse documentaire. 3 business goals (3×3 SMART), 3 personas priorisés (Blandine #1, Kofi intégrateur #2, Ibrahim manager #3), 12 driving forces scorées (Fréquence × Intensité × Fit). 5 drivers critiques score 14-15 identifiés. Tension Blandine/Ibrahim documentée — traçabilité mutuelle comme résolution. Design Focus Statement validé.

**Next:** Phase 3 — UX Scenarios

---

### 2026-05-09 — Phase 1: Product Brief Complete

**Agent:** Saga (Strategic Business Analyst)
**Brief Level:** Standard (Confirmation Mode — 4 source documents provided)

**Artifacts Created:**
- `A-Product-Brief/project-brief.md`
- `A-Product-Brief/content-language.md`
- `A-Product-Brief/inspiration-analysis.md`
- `A-Product-Brief/visual-direction.md`
- `A-Product-Brief/platform-requirements.md`

**Summary:** Scalario établi comme premier "Instant Business OS" pour les PME UEMOA — moteur BDUI + catalogue JSON permettant à un intégrateur de déployer un ERP complet en 45 minutes sans coder. Contraintes non-négociables identifiées : offline-first natif, zéro logique métier dans Flutter, Gate 0 = 8 juillet 2026 (Blandine live). Direction visuelle : Material Design 3 flat, dark-first avec dual mode, palette 4 couleurs sémantiques, typographie tri-stack (Bebas Neue + Inter + Roboto Mono).

**Next:** Phase 2 — Trigger Mapping

---

## Key Decisions

| Date | Décision | Phase | Décideurs |
|------|----------|-------|-----------|
| 2026-05-09 | Brief Level : Standard complet (pas simplifié) — 4 documents source riches disponibles, Confirmation Mode activé | Phase 1: Product Brief | Saga + Carlos |
| 2026-05-09 | Catégorie produit : "Instant Business OS" — nouvelle catégorie, pas ERP de plus | Phase 1: Product Brief | Saga + Carlos |
| 2026-05-09 | Stack décidée et fixe : Flutter + NestJS + FastAPI + PostgreSQL + Redis + MinIO | Phase 1: Product Brief | Carlos (existant) |
| 2026-05-09 | Offline-first natif — Drift/Isar = source de vérité, backend = service de sync | Phase 1: Product Brief | Carlos (existant) |
| 2026-05-09 | Gate 0 = 8 juillet 2026 (J+60 depuis 2026-05-09) — Blandine live, date fixe non négociable | Phase 1: Product Brief | Saga + Carlos |
| 2026-05-09 | UI Style : Material Design 3 flat + Service Center aesthetic — dark-first, dual mode | Phase 1: Product Brief | Saga + Carlos |
| 2026-05-09 | Typographie : Bebas Neue (display) + Inter (UI) + Roboto Mono (données) | Phase 1: Product Brief | Saga + Carlos |
| 2026-05-09 | Contact strategy Phase 1 : WhatsApp direct Carlos — pas de formulaire classique | Phase 1: Product Brief | Saga + Carlos |
| 2026-05-09 | SEO hors scope WDS — landing page gérée séparément | Phase 1: Product Brief | Carlos |
| 2026-05-09 | Content structure hors scope WDS — 100% data-driven depuis templates JSON BDUI | Phase 1: Product Brief | Carlos |
| 2026-05-09 | Références visuelles : Airbnb + Uber + Binance — principe "zero learning curve for domain experts" | Phase 1: Product Brief | Saga + Carlos |
| 2026-05-09 | Trigger Map Mode : Documentation Synthesis (00a→00f) — 4 documents source suffisants pour éviter les workshops from scratch | Phase 2: Trigger Mapping | Saga + Carlos |
| 2026-05-09 | Priorité design #1 : Blandine — certitude visuelle en 30 sec. Intégrateur #2 — puissance sans complexité visible | Phase 2: Trigger Mapping | Saga + Carlos |
| 2026-05-09 | Tension identifiée Blandine/Ibrahim : traçabilité mutuelle (pas surveillance unilatérale) — résolution par le cadrage UX | Phase 2: Trigger Mapping | Saga + Carlos |
| 2026-05-09 | Scalario = moteur BDUI JSON, pas ERP codé en dur — correction appliquée aux drivers intégrateur | Phase 2: Trigger Mapping | Carlos |
