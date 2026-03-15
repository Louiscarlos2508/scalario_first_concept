/// Scalario responsive breakpoints.
/// Source: docs/design-system.md — Responsive Layout Strategy section.
///
/// Usage:
/// ```dart
/// if (constraints.maxWidth < kCompact) return CompactLayout();
/// if (constraints.maxWidth < kMedium) return MediumLayout();
/// return ExpandedLayout();
/// ```
library;

/// compact (< 600px) — Phone: single column, bottom nav, full-screen modals
const double kCompact = 600.0;

/// medium (600–1024px) — Tablet: split view, navigation rail
const double kMedium = 1024.0;
