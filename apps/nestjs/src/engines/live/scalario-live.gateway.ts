import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ScalarioLiveService, LiveEvent } from './scalario-live.service';

interface AuthenticatedSocket extends Socket {
  userId?: string;
  tenantId?: string;
  roles?: string[];
}

@WebSocketGateway({
  path: '/live',
  cors: { origin: '*', credentials: true },
  namespace: '/',
})
export class ScalarioLiveGateway
  implements OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer()
  server!: Server;

  private readonly logger = new Logger(ScalarioLiveGateway.name);

  constructor(
    private readonly jwtService: JwtService,
    private readonly liveService: ScalarioLiveService,
  ) {}

  afterInit(): void {
    this.liveService.setServer(this.server);
    this.logger.log('Scalario Live Gateway initialized');
  }

  async handleConnection(client: AuthenticatedSocket): Promise<void> {
    try {
      const token =
        (client.handshake.query.token as string) ??
        client.handshake.auth?.token ??
        client.handshake.headers.authorization?.replace('Bearer ', '');

      if (!token) {
        this.logger.warn('Connection rejected: no token');
        client.disconnect();
        return;
      }

      const payload = this.jwtService.verify(token, {
        secret: process.env.JWT_SECRET,
      });

      client.userId = payload.sub;
      client.tenantId = payload.tenant_id;
      client.roles = payload.roles ?? [];

      if (client.tenantId) {
        client.join(`tenant_${client.tenantId}`);
      }
      client.join(`user_${client.userId}`);

      this.liveService.addUserConnection(client.userId ?? 'unknown', client.id);
      this.logger.log(
        `User ${client.userId} authenticated on WS, tenant ${client.tenantId}`,
      );
    } catch (err) {
      this.logger.warn(`Connection rejected: ${(err as Error).message}`);
      client.disconnect();
    }
  }

  handleDisconnect(client: AuthenticatedSocket): void {
    if (client.userId) {
      this.liveService.removeUserConnection(client.userId, client.id);
    }
  }

  @SubscribeMessage('ping')
  handlePing(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: unknown,
  ): { status: string; timestamp: string } {
    return { status: 'pong', timestamp: new Date().toISOString() };
  }

  @SubscribeMessage('ack_event')
  handleAck(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: { eventId: string },
  ): void {
    this.logger.debug(`Event acked: ${data.eventId} by user ${client.userId}`);
  }
}
