import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { InventoryService } from '../inventory/inventory.service';

@Injectable()
export class InternalRequestsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly inventoryService: InventoryService,
  ) {}

  async create(data: {
    catalogItemId: string;
    quantity: number;
    urgency: 'normal' | 'urgent';
    tenantId: string;
    requestedBy: string;
  }) {
    return this.prisma.internalRequest.create({
      data: {
        catalogItemId: data.catalogItemId,
        quantity: data.quantity,
        urgency: data.urgency,
        tenantId: data.tenantId,
        requestedBy: data.requestedBy,
        status: 'pending',
      },
      include: { catalogItem: { select: { name: true } } },
    });
  }

  async prepare(id: string, tenantId: string, preparedBy: string) {
    const request = await this.prisma.internalRequest.findFirst({
      where: { id, tenantId },
    });
    if (!request) throw new NotFoundException('Demande introuvable');
    if (request.status !== 'pending') {
      throw new BadRequestException('La demande n\'est plus en attente');
    }

    const tenant = await this.prisma.tenant.findUnique({
      where: { id: tenantId },
      select: { skipManagerApproval: true },
    });
    const nextStatus = tenant?.skipManagerApproval ? 'approved' : 'prepared';

    const updated = await this.prisma.internalRequest.update({
      where: { id },
      data: { status: nextStatus, preparedBy },
      include: { catalogItem: { select: { name: true } } },
    });

    await this._sendNotification(updated, nextStatus, tenantId);
    return updated;
  }

  async approve(id: string, tenantId: string, approvedBy: string, quantity?: number) {
    const request = await this.prisma.internalRequest.findFirst({
      where: { id, tenantId },
    });
    if (!request) throw new NotFoundException('Demande introuvable');
    if (request.status !== 'prepared' && request.status !== 'pending') {
      throw new BadRequestException('La demande ne peut pas être approuvée dans son état actuel');
    }

    const finalQty = quantity ?? Number(request.quantity);

    const updated = await this.prisma.internalRequest.update({
      where: { id },
      data: {
        status: 'fulfilled',
        approvedBy,
        quantity: finalQty,
      },
      include: { catalogItem: { select: { name: true } } },
    });

    // FR31 — Générer automatiquement un TRANSFER_OUT
    await this.inventoryService.createMovement({
      type: 'TRANSFER_OUT',
      catalogItemId: request.catalogItemId,
      quantity: finalQty,
      reason: `Réapprovisionnement interne — demande ${id.substring(0, 8)}`,
      tenantId,
      userId: approvedBy,
    });

    await this._sendNotification(updated, 'fulfilled', tenantId);
    return updated;
  }

  async reject(id: string, tenantId: string, reason: string) {
    const request = await this.prisma.internalRequest.findFirst({
      where: { id, tenantId },
    });
    if (!request) throw new NotFoundException('Demande introuvable');
    if (request.status === 'fulfilled' || request.status === 'rejected') {
      throw new BadRequestException('La demande ne peut pas être rejetée dans son état actuel');
    }

    const updated = await this.prisma.internalRequest.update({
      where: { id },
      data: { status: 'rejected', reason },
      include: { catalogItem: { select: { name: true } } },
    });

    await this._sendNotification(updated, 'rejected', tenantId);
    return updated;
  }

  async list(params: { tenantId: string; status?: string; urgency?: string }) {
    return this.prisma.internalRequest.findMany({
      where: {
        tenantId: params.tenantId,
        ...(params.status ? { status: params.status } : {}),
        ...(params.urgency ? { urgency: params.urgency } : {}),
      },
      orderBy: [{ urgency: 'desc' }, { createdAt: 'desc' }],
      include: { catalogItem: { select: { name: true } } },
    });
  }

  async getOne(id: string, tenantId: string) {
    const request = await this.prisma.internalRequest.findFirst({
      where: { id, tenantId },
      include: { catalogItem: { select: { name: true } } },
    });
    if (!request) throw new NotFoundException('Demande introuvable');
    return request;
  }

  // ── Notifications in-app ────────────────────────────────────────────────────

  private async _sendNotification(
    request: { id: string; requestedBy: string; catalogItem: { name: string }; quantity: any; reason?: string | null },
    transition: string,
    tenantId: string,
  ) {
    const productName = request.catalogItem.name;
    const quantity = Number(request.quantity);

    if (transition === 'prepared') {
      // Notifier l'owner
      await this._notifyByRole(tenantId, ['owner'], {
        type: 'internal_request',
        title: 'Demande prête à approuver',
        body: `${productName} — ${quantity} unités préparées par le gestionnaire`,
        targetId: request.id,
      });
    } else if (transition === 'fulfilled') {
      // Notifier le commercial (requestedBy)
      await this._notifyUser(tenantId, request.requestedBy, {
        type: 'internal_request',
        title: 'Demande approuvée',
        body: `${productName} — transfert généré`,
        targetId: request.id,
      });
    } else if (transition === 'rejected') {
      // Notifier le commercial (requestedBy)
      await this._notifyUser(tenantId, request.requestedBy, {
        type: 'internal_request',
        title: 'Demande refusée',
        body: request.reason ?? 'Aucun motif fourni',
        targetId: request.id,
      });
    } else if (transition === 'approved') {
      // skipManagerApproval: notifier l'owner directement
      await this._notifyByRole(tenantId, ['owner'], {
        type: 'internal_request',
        title: 'Demande en attente d\'approbation',
        body: `${productName} — ${quantity} unités demandées`,
        targetId: request.id,
      });
    }
  }

  private async _notifyUser(
    tenantId: string,
    userId: string,
    payload: { type: string; title: string; body: string; targetId: string },
  ) {
    await this.prisma.notification.create({
      data: { tenantId, userId, ...payload },
    });
  }

  private async _notifyByRole(
    tenantId: string,
    roleNames: string[],
    payload: { type: string; title: string; body: string; targetId: string },
  ) {
    const roles = await this.prisma.role.findMany({
      where: { name: { in: roleNames }, vertical: 'retail' },
      select: { id: true },
    });
    const roleIds = roles.map((r) => r.id);

    const members = await this.prisma.organizationMember.findMany({
      where: { organizationId: tenantId, roleId: { in: roleIds } },
      select: { userId: true },
    });

    if (members.length === 0) return;

    await this.prisma.notification.createMany({
      data: members.map((m) => ({
        tenantId,
        userId: m.userId,
        ...payload,
      })),
      skipDuplicates: true,
    });
  }
}
