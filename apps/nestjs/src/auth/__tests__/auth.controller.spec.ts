import { Test } from '@nestjs/testing';
import { AuthController } from '../auth.controller';
import { AuthService } from '../auth.service';

describe('AuthController', () => {
  let controller: AuthController;
  const service = {
    login: jest.fn(),
    refresh: jest.fn(),
    logout: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const moduleRef = await Test.createTestingModule({
      controllers: [AuthController],
      providers: [{ provide: AuthService, useValue: service }],
    }).compile();
    controller = moduleRef.get(AuthController);
  });

  it('login() delegates to AuthService.login', async () => {
    service.login.mockResolvedValue({ access_token: 'A', refresh_token: 'R', expires_in: 900 });
    const dto = { email: 'a@b.test', password: 'Secret123', tenant_slug: 'acme' };
    await controller.login(dto);
    expect(service.login).toHaveBeenCalledWith(dto);
  });

  it('refresh() forwards refresh_token to AuthService.refresh', async () => {
    service.refresh.mockResolvedValue({});
    await controller.refresh({ refresh_token: 'r' });
    expect(service.refresh).toHaveBeenCalledWith('r');
  });

  it('logout() forwards refresh_token to AuthService.logout', async () => {
    service.logout.mockResolvedValue(undefined);
    await controller.logout({ refresh_token: 'r' });
    expect(service.logout).toHaveBeenCalledWith('r');
  });

  it('me() returns the request-injected user', () => {
    const user = {
      user_id: 'u1',
      tenant_id: 't1',
      roles: ['OWNER'],
      department_id: null,
    };
    expect(controller.me(user)).toEqual(user);
  });
});
