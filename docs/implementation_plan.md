# Implementation Plan - Phase 5, 6, 7

This plan outlines the execution steps effectively realizing the Scalario Code + POS MVP.

## User Review Required
> [!IMPORTANT]
> This plan initiates the Git repository and installs the BMAD methodology tools. It assumes `node`, `flutter`, and `nest` CLI tools are installed or available via `npx`.

## Proposed Steps

### Phase 5: Implementation Setup
1.  **Repository Creation**
    -   Create directory `scalario`
    -   Initialize Git
    -   Create folder structure (`apps`, `packages`, `docs`)
2.  **BMAD Installation**
    -   Run `npx bmad-method@alpha install` to set up the agent framework.
3.  **BMAD Initialization**
    -   Run `npx bmad workflow-init` (or equivalent) to bootstrap the project methodology.

### Phase 6: Tech Stacks Initialization
1.  **Frontend (Flutter)**
    -   Navigate to `apps/`
    -   Run `flutter create --org com.scalario --platforms android,ios,web,linux,windows frontend`
    -   *Note: Linux/Windows support added for Desktop POS.*
2.  **Backend (NestJS)**
    -   Navigate to `apps/`
    -   Run `nest new backend --package-manager npm` (or use npx if nest cli not global)
3.  **Supabase**
    -   Initialize Supabase config (local or cloud placeholder).

### Phase 7: Development Preparation
1.  **Documentation Migration**
    -   Move the created Artifacts (`PRD.md`, `ARCHITECTURE.md`, `product_brief.md`) into `docs/` folder of the new repo.

## Verification Plan
### Automated Verification
-   **Repo Check:** `ls -R scalario` to verify structure.
-   **Flutter Check:** `cd scalario/apps/frontend && flutter doctor`
-   **NestJS Check:** `cd scalario/apps/backend && npm run start:dev`

### Manual Verification
-   User confirms the structure matches the "Monorepo" vision.
