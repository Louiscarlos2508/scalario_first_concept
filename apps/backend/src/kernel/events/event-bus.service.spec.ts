import { Test, TestingModule } from '@nestjs/testing';
import { EventBusService } from './event-bus.service';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { TransactionCreatedEvent } from './domain-events';

describe('EventBusService', () => {
  let service: EventBusService;

  const mockEventEmitter = {
    emit: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        EventBusService,
        { provide: EventEmitter2, useValue: mockEventEmitter },
      ],
    }).compile();

    service = module.get<EventBusService>(EventBusService);
  });

  afterEach(() => {
    jest.resetAllMocks();
  });

  describe('publish', () => {
    it('should delegate to EventEmitter2.emit with the given event name and payload', () => {
      mockEventEmitter.emit.mockReturnValue(true);
      const event = new TransactionCreatedEvent(
        'tenant-uuid',
        'tx-uuid',
        5000,
        'user-uuid',
      );

      const result = service.publish('transaction.created', event);

      expect(mockEventEmitter.emit).toHaveBeenCalledWith('transaction.created', event);
      expect(result).toBe(true);
    });

    it('should return false when no listeners are registered for the event', () => {
      mockEventEmitter.emit.mockReturnValue(false);

      const result = service.publish('unknown.event', { data: 'test' });

      expect(result).toBe(false);
    });

    it('should support wildcard event names (e.g. transaction.*)', () => {
      mockEventEmitter.emit.mockReturnValue(true);

      service.publish('transaction.created', { tenantId: 'tenant-uuid' });

      expect(mockEventEmitter.emit).toHaveBeenCalledWith(
        'transaction.created',
        { tenantId: 'tenant-uuid' },
      );
    });

    it('should pass any event payload type through to EventEmitter2', () => {
      mockEventEmitter.emit.mockReturnValue(true);
      const payload = { custom: 'payload', nested: { value: 42 } };

      service.publish('custom.event', payload);

      expect(mockEventEmitter.emit).toHaveBeenCalledWith('custom.event', payload);
    });
  });
});
