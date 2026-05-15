import { ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AbacGuard } from '../guards/abac.guard';
import { ABAC_ACTION_KEY } from '../decorators/abac-action.decorator';
import type { AbacAbility } from '../types';

function ctx(req: unknown, handlerMeta?: unknown, classMeta?: unknown): ExecutionContext {
  const handler = () => undefined;
  const klass = class {};
  if (handlerMeta) Reflect.defineMetadata(ABAC_ACTION_KEY, handlerMeta, handler);
  if (classMeta) Reflect.defineMetadata(ABAC_ACTION_KEY, classMeta, klass);
  return {
    getHandler: () => handler,
    getClass: () => klass,
    switchToHttp: () => ({ getRequest: () => req }),
  } as unknown as ExecutionContext;
}

function abilityThatAllows(allow: boolean): AbacAbility {
  return { can: () => allow } as unknown as AbacAbility;
}

describe('AbacGuard', () => {
  const guard = new AbacGuard(new Reflector());

  it('skips routes without @AbacAction (AC-10)', () => {
    expect(guard.canActivate(ctx({}))).toBe(true);
  });

  it('denies when ability is missing (AC-09)', () => {
    expect(() =>
      guard.canActivate(ctx({ user: { user_id: 'u' } }, { action: 'read', subject: 'Invoice' })),
    ).toThrow(ForbiddenException);
  });

  it('allows when ability.can returns true (AC-08)', () => {
    expect(
      guard.canActivate(
        ctx(
          { user: { user_id: 'u' }, ability: abilityThatAllows(true) },
          { action: 'read', subject: 'Invoice' },
        ),
      ),
    ).toBe(true);
  });

  it('denies and logs when ability.can returns false (AC-09)', () => {
    expect(() =>
      guard.canActivate(
        ctx(
          { user: { user_id: 'u', tenant_id: 't' }, ability: abilityThatAllows(false) },
          { action: 'read', subject: 'Invoice' },
        ),
      ),
    ).toThrow(ForbiddenException);
  });
});
