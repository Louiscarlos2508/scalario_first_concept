# Scalario Roadmap: Core + POS MVP

## Phase 1: Product Discovery & Brief <!-- id: 1 -->
- [x] **1.1 Launch BMAD / Product Discovery** <!-- id: 1.1 -->
    - [x] Activate Product Manager Agent
    - [x] Conduct Discovery Q&A (Skipped - User provided full context)
- [x] **1.2 Create Product Brief** <!-- id: 1.2 -->
    - [x] Define ERP Core Vision
    - [x] Define POS as First Commercial Module
    - [x] Address African/Emerging Market Constraints (Offline-first)
    - [x] Define Scalability Strategy

## Phase 2: PRD (Product Requirements Document) <!-- id: 2 -->
- [x] **2.1 Mobile/Web POS + Core PRD** <!-- id: 2.1 -->
    - [x] Define Scalario Core (Shared Services)
    - [x] Define POS MVP Features
    - [x] Define User Roles
    - [x] Define Cashing Flow (Flux Caisse)
    - [x] Stock Management
    - [x] Payments
    - [x] Offline/Online Sync Strategy
    - [x] Core vs Module Distinction

## Phase 3: Architecture <!-- id: 3 -->
- [x] **3.1 Functional High-Level Architecture** <!-- id: 3.1 -->
    - [x] Modular ERP Core
    - [x] Multi-tenant SaaS
    - [x] Offline-first Principles
    - [x] API-first Design
- [x] **3.2 Technical Architecture (Tech Stack)** <!-- id: 3.2 -->
    - [x] Flutter (Mobile, Desktop, Web)
    - [x] NestJS (Backend Logic)
    - [x] Supabase (Auth, DB, Realtime, Storage)
    - [x] Security & Multi-tenancy Implementation

## Phase 4: Modular Boundaries <!-- id: 4 -->
- [x] **4.1 Define Core vs POS Modules** <!-- id: 4.1 -->
    - [x] Core: Auth, Tenant, Roles, Billing, Sync, Audit
    - [x] POS: Sales, Products, Stock, Payments, Offline Cache

## Phase 5: Implementation Setup <!-- id: 5 -->
- [/] **5.1 Repository Creation** <!-- id: 5.1 -->
    - [x] `mkdir scalario`, `git init`
    - [x] Structure: `apps/` (frontend, backend), `packages/` (core), `docs/`
    - [ ] *Migration note: Move to personal projects folder later*
- [x] **5.2 Install BMAD** (`npx bmad-method@alpha install`) <!-- id: 5.2 -->
- [ ] **5.3 Initialize BMAD** (`workflow-init` or equivalent) <!-- id: 5.3 -->

## Phase 6: Tech Projects Initialization <!-- id: 6 -->
- [x] **6.1 Flutter Frontend** (`apps/frontend`) <!-- id: 6.1 -->
    - [x] Configure Mobile, Web, Desktop
- [x] **6.2 NestJS Backend** (`apps/backend`) <!-- id: 6.2 -->
- [ ] **6.3 Supabase Project** <!-- id: 6.3 -->
    - [ ] Auth, Postgres, Realtime, Storage Config

## Phase 7: Development (Story by Story) <!-- id: 7 -->
- [ ] **7.1 Create Development Stories** <!-- id: 7.1 -->
    - [ ] Auth & Organization Setup
    - [ ] POS: Create Sale Offline & Sync
