import { ScalarioLiveService, LiveEvent } from '../scalario-live.service';

describe('ScalarioLiveService', () => {
  let service: ScalarioLiveService;
  let mockServer: any;

  beforeEach(() => {
    service = new ScalarioLiveService();
    mockServer = {
      to: jest.fn().mockReturnThis(),
      emit: jest.fn(),
    };
    service.setServer(mockServer);
  });

  it('emits event to tenant room', () => {
    const event: LiveEvent = {
      type: 'validation_required',
      data: { commande_id: 'c1', montant: 500000 },
      timestamp: new Date().toISOString(),
    };
    service.emit('tenant-1', event);
    expect(mockServer.to).toHaveBeenCalledWith('tenant_tenant-1');
    expect(mockServer.emit).toHaveBeenCalledWith('live_event', event);
  });

  it('tracks user connections', () => {
    service.addUserConnection('user-1', 'socket-1');
    expect(service.isUserConnected('user-1')).toBe(true);

    service.addUserConnection('user-1', 'socket-2');
    expect(service.isUserConnected('user-1')).toBe(true);

    service.removeUserConnection('user-1', 'socket-1');
    expect(service.isUserConnected('user-1')).toBe(true);

    service.removeUserConnection('user-1', 'socket-2');
    expect(service.isUserConnected('user-1')).toBe(false);
  });

  it('drops event when server not set', () => {
    const svc = new ScalarioLiveService();
    const event: LiveEvent = {
      type: 'alert_triggered',
      data: { message: 'test' },
      timestamp: new Date().toISOString(),
    };
    expect(() => svc.emit('tenant-1', event)).not.toThrow();
  });

  it('emits to specific user', () => {
    const mockUserServer = {
      to: jest.fn().mockReturnThis(),
      emit: jest.fn(),
    };
    service.setServer(mockUserServer);
    service.addUserConnection('user-1', 'socket-1');

    const event: LiveEvent = {
      type: 'data_updated',
      data: { source: 'ventes' },
      timestamp: new Date().toISOString(),
    };
    service.emitToUser('user-1', event);

    expect(mockUserServer.to).toHaveBeenCalledWith('socket-1');
    expect(mockUserServer.emit).toHaveBeenCalledWith('live_event', event);
  });
});
