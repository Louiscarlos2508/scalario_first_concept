import { UnauthorizedException } from '@nestjs/common';
import { LocalStrategy } from '../strategies/local.strategy';
import { AuthService } from '../auth.service';

describe('LocalStrategy', () => {
  const authMock: Pick<AuthService, 'validateLocalCredentials'> = {
    validateLocalCredentials: jest.fn(),
  };
  const strategy = new LocalStrategy(authMock as AuthService);

  beforeEach(() => jest.clearAllMocks());

  it('forwards email/password/tenant_slug to AuthService.validateLocalCredentials', async () => {
    (authMock.validateLocalCredentials as jest.Mock).mockResolvedValue({
      user: { id: 'u' },
      tenant: { id: 't' },
    });
    const result = await strategy.validate(
      { body: { tenant_slug: 'acme' } },
      'a@b.test',
      'pw',
    );
    expect(authMock.validateLocalCredentials).toHaveBeenCalledWith({
      email: 'a@b.test',
      password: 'pw',
      tenant_slug: 'acme',
    });
    expect(result).toEqual({ user: { id: 'u' }, tenant: { id: 't' } });
  });

  it('throws 401 when tenant_slug is missing', async () => {
    await expect(strategy.validate({ body: {} }, 'a@b.test', 'pw')).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
    await expect(strategy.validate({}, 'a@b.test', 'pw')).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });
});
