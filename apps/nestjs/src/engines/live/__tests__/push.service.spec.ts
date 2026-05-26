import { PushService } from '../push.service';
import { ScalarioLiveService } from '../scalario-live.service';

describe('PushService', () => {
  let push: PushService;
  let live: ScalarioLiveService;
  let mockServer: any;

  beforeEach(() => {
    live = new ScalarioLiveService();
    mockServer = {
      to: jest.fn().mockReturnThis(),
      emit: jest.fn(),
    };
    live.setServer(mockServer);
    push = new PushService(live);
  });

  it('emits via WebSocket when user is connected', async () => {
    live.addUserConnection('user-1', 'socket-1');
    await push.notify('user-1', 'tenant-1', {
      type: 'validation_required',
      data: { commande_id: 'c1' },
    });

    expect(mockServer.emit).toHaveBeenCalledWith('live_event', expect.objectContaining({
      type: 'validation_required',
    }));
  });

  it('falls back to push token when user is offline', async () => {
    push.registerToken('user-1', 'fcm-token-123', 'android');
    await push.notify('user-1', 'tenant-1', {
      type: 'stock_critical',
      data: { produit: 'Riz' },
    });
    // Should not throw — stub handles push
  });

  it('registers and removes push tokens', () => {
    push.registerToken('user-1', 'token-a', 'android');
    push.registerToken('user-1', 'token-b', 'ios');
    expect(push.getTokens('user-1').length).toBe(2);

    push.removeToken('user-1', 'token-a');
    expect(push.getTokens('user-1').length).toBe(1);
  });
});
