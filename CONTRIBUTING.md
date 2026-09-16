# Contributing to Scalario First Concept

Thanks for your interest in contributing.

This repository is the public experimental foundation of Scalario and explores metadata-driven business software, BDUI, modular ERP workflows, RBAC, dynamic business objects, and configurable interfaces.

## Ways to contribute

- Report reproducible bugs through GitHub Issues.
- Propose architecture or developer-experience improvements.
- Improve documentation and examples.
- Add tests or fix regressions.
- Submit focused pull requests that preserve the modular architecture.

## Before opening a pull request

1. Create a focused branch.
2. Keep changes scoped to one concern.
3. Add or update tests where behavior changes.
4. Run the relevant checks:
   - `cd apps/nestjs && pnpm test`
   - `cd apps/flutter && flutter analyze`
5. Explain the problem, approach, and any architectural trade-offs in the PR description.

## Architecture expectations

Contributions should avoid unnecessary coupling between business rules, UI rendering, persistence, and tenant-specific configuration. Prefer reusable contracts, explicit schemas, and backward-compatible changes where practical.

## Security

Do not open public issues containing credentials, secrets, personal data, or exploitable security details. Report sensitive security findings privately to the maintainer.

## License

By contributing, you agree that your contributions will be licensed under the Apache License 2.0.
