import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/conflicts.dart';

/// DAO pour [Conflicts] — squelette pour STORY-035.
///
/// AC-08 : stocke les conflits de sync détectés.
final class ConflictDao extends DatabaseAccessor<ScalarioDatabase> {
  ConflictDao(super.attachedDatabase);

  Future<List<ConflictRecord>> getAll(String mutationId) =>
      (select(db.conflicts)
            ..where((t) => t.mutationId.equals(mutationId))
            ..orderBy([(t) => OrderingTerm(expression: t.detectedAt)]))
          .get();

  Future<ConflictRecord?> getById(String id) =>
      (select(db.conflicts)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<void> insert(ConflictsCompanion conflict) =>
      into(db.conflicts).insert(conflict);

  Future<void> markResolved(
    String id, {
    required String resolution,
  }) =>
      (update(db.conflicts)..where((t) => t.id.equals(id))).write(
        ConflictsCompanion(
          resolvedAt: Value(DateTime.now()),
          resolution: Value(resolution),
        ),
      );

  Future<void> deleteResolved() =>
      (delete(db.conflicts)..where((t) => t.resolvedAt.isNotNull())).go();
}
