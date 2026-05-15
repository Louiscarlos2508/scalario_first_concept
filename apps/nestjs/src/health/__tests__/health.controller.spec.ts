import { Test, TestingModule } from '@nestjs/testing';
import { HealthCheckService, TypeOrmHealthIndicator } from '@nestjs/terminus';
import { HealthController } from '../health.controller';
import { RedisHealthIndicator } from '../redis.health';

describe('HealthController', () => {
  let controller: HealthController;
  let healthCheck: jest.Mocked<HealthCheckService>;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [HealthController],
      providers: [
        {
          provide: HealthCheckService,
          useValue: { check: jest.fn() },
        },
        {
          provide: TypeOrmHealthIndicator,
          useValue: { pingCheck: jest.fn() },
        },
        {
          provide: RedisHealthIndicator,
          useValue: { isHealthy: jest.fn() },
        },
      ],
    }).compile();

    controller = module.get(HealthController);
    healthCheck = module.get(HealthCheckService);
  });

  it('returns ok when both postgres and redis are up', async () => {
    healthCheck.check.mockResolvedValue({
      status: 'ok',
      info: { postgres: { status: 'up' }, redis: { status: 'up' } },
      error: {},
      details: { postgres: { status: 'up' }, redis: { status: 'up' } },
    });

    const result = await controller.check();
    expect(result.status).toBe('ok');
    expect(result.info?.postgres.status).toBe('up');
    expect(result.info?.redis.status).toBe('up');
  });

  it('calls both postgres and redis indicators', async () => {
    healthCheck.check.mockImplementation(async (indicators) => {
      // Invoke each indicator to confirm wiring
      await Promise.all(indicators.map((i) => i()));
      return { status: 'ok', info: {}, error: {}, details: {} };
    });

    await controller.check();
    expect(healthCheck.check).toHaveBeenCalledTimes(1);
    expect(healthCheck.check.mock.calls[0][0]).toHaveLength(2);
  });
});
