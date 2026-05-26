import { Injectable, Logger } from '@nestjs/common';

export interface LiveEvent {
  type: 'validation_required' | 'stock_critical' | 'data_updated' | 'config_updated' | 'alert_triggered' | 'session_expired';
  data: Record<string, unknown>;
  timestamp: string;
}

@Injectable()
export class ScalarioLiveService {
  private readonly logger = new Logger(ScalarioLiveService.name);
  private server: any = null;
  private readonly connectedUsers = new Map<string, Set<string>>();

  setServer(server: any): void {
    this.server = server;
  }

  addUserConnection(userId: string, socketId: string): void {
    if (!this.connectedUsers.has(userId)) {
      this.connectedUsers.set(userId, new Set());
    }
    this.connectedUsers.get(userId)!.add(socketId);
    this.logger.log(`User ${userId} connected (${this.connectedUsers.get(userId)!.size} sockets)`);
  }

  removeUserConnection(userId: string, socketId: string): void {
    const sockets = this.connectedUsers.get(userId);
    if (sockets) {
      sockets.delete(socketId);
      if (sockets.size === 0) this.connectedUsers.delete(userId);
    }
    this.logger.log(`User ${userId} socket ${socketId} disconnected`);
  }

  isUserConnected(userId: string): boolean {
    return this.connectedUsers.has(userId);
  }

  emit(tenantId: string, event: LiveEvent): void {
    if (!this.server) {
      this.logger.warn('WebSocket server not set, event dropped');
      return;
    }
    const room = `tenant_${tenantId}`;
    this.server.to(room).emit('live_event', event);
    this.logger.log(`Emitted ${event.type} to room ${room}`);
  }

  emitToUser(userId: string, event: LiveEvent): void {
    if (!this.server) return;
    const sockets = this.connectedUsers.get(userId);
    if (!sockets || sockets.size === 0) return;
    for (const socketId of sockets) {
      this.server.to(socketId).emit('live_event', event);
    }
    this.logger.log(`Emitted ${event.type} to user ${userId}`);
  }
}
