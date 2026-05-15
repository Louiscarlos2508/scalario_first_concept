import '../rule_evaluator/user_context.dart';

/// Fournit le [UserContext] courant à l'Engine.
///
/// STORY-008 : un stub `DemoUserContextProvider` est injecté Sprint 2 avant
/// que STORY-014 (Auth JWT) ne fournisse une implémentation back-driven.
/// L'API reste identique → swap par DI au bootstrap.
abstract interface class UserContextProvider {
  UserContext get current;
}

/// Implémentation Sprint 2 — `UserContext` figé pour le sandbox.
/// Remplacée Sprint 2 par `JwtUserContextProvider` (STORY-014).
final class DemoUserContextProvider implements UserContextProvider {
  const DemoUserContextProvider({
    this.userId = 'dev',
    this.tenantId = 'demo',
    this.role = 'OWNER',
  });

  final String userId;
  final String tenantId;
  final String role;

  @override
  UserContext get current => UserContext(
        userId: userId,
        tenantId: tenantId,
        roles: <String>{role},
      );
}
