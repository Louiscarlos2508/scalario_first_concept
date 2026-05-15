import { redact } from './redact.interceptor';

describe('redact()', () => {
  it('replaces sensitive keys with [REDACTED]', () => {
    const input = {
      email: 'a@b.c',
      password: 'secret',
      nested: { refresh_token: 'r', access_token: 'a', ok: 1 },
      list: [{ password_hash: 'h', name: 'x' }],
    };
    expect(redact(input)).toEqual({
      email: 'a@b.c',
      password: '[REDACTED]',
      nested: { refresh_token: '[REDACTED]', access_token: '[REDACTED]', ok: 1 },
      list: [{ password_hash: '[REDACTED]', name: 'x' }],
    });
  });

  it('handles null/undefined/primitives', () => {
    expect(redact(null)).toBeNull();
    expect(redact(undefined)).toBeUndefined();
    expect(redact('s')).toBe('s');
    expect(redact(42)).toBe(42);
  });
});
