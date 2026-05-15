/// STORY-012 — contrat plateforme-agnostique pour la persistance.
///
/// Phase 1 = stubs (Drift natif + IndexedDB livrés par STORY-035). La
/// surface est volontairement minimale ; elle existe pour matérialiser le
/// pattern `conditional imports` et permettre l'écriture d'un showcase qui
/// affiche la cible runtime.
library;

import 'package:meta/meta.dart';

@immutable
abstract interface class PlatformStorage {
  /// Identifiant humain de l'implémentation runtime (ex: `io`, `web`).
  String get backend;

  /// Chemin / quota / namespace logique — utilisé pour debug / diagnostics.
  String get location;
}
