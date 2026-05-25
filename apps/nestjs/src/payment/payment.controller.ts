import {
  BadRequestException,
  Body,
  Controller,
  ForbiddenException,
  Logger,
  NotFoundException,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../core/auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { ZodValidationPipe } from '../common/pipes/zod-validation.pipe';
import type { AuthenticatedUser } from '../core/auth/interfaces/jwt-payload.interface';
import {
  PaymentInitiateBody,
  PaymentInitiateBodySchema,
  PaymentVerifyBody,
  PaymentVerifyBodySchema,
} from './dto/payment.dto';
import { PaymentAdapterRegistry } from './payment-adapter.registry';
import { PaymentAdapterNotFoundError } from './payment.types';

@Controller('api/v1/:tenant/payment')
@UseGuards(JwtAuthGuard)
export class PaymentController {
  private readonly logger = new Logger(PaymentController.name);

  constructor(private readonly registry: PaymentAdapterRegistry) {}

  @Post('initiate')
  async initiate(
    @Param('tenant') tenantSlug: string,
    @Body(new ZodValidationPipe(PaymentInitiateBodySchema)) body: PaymentInitiateBody,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    if (tenantSlug !== user.tenant_id) {
      throw new ForbiddenException('Cross-tenant payment denied');
    }
    let adapter;
    try {
      adapter = this.registry.getAdapter(user.tenant_id, body.method, body.provider);
    } catch (err) {
      if (err instanceof PaymentAdapterNotFoundError) {
        throw new BadRequestException({
          error: 'ERR_PAYMENT_ADAPTER_NOT_FOUND',
          message: err.message,
        });
      }
      throw err;
    }
    return adapter.initiate({
      tenantId: user.tenant_id,
      amount: body.amount,
      currency: body.currency,
      method: body.method,
      provider: body.provider,
      meta: { ...body.meta, user_id: user.user_id },
    });
  }

  @Post('verify')
  async verify(
    @Param('tenant') tenantSlug: string,
    @Body(new ZodValidationPipe(PaymentVerifyBodySchema)) body: PaymentVerifyBody,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    if (tenantSlug !== user.tenant_id) {
      throw new ForbiddenException('Cross-tenant payment denied');
    }
    // Phase 1: the adapter is inferred from the session id prefix. Cash
    // uses raw UUID; mobile_money prefixes with 'stub_'; credit uses raw
    // UUID. To keep verify() simple we try each adapter and return the
    // first hit. Phase 2 should persist the (session_id → adapter)
    // mapping in DB.
    for (const adapter of this.registry.list()) {
      const result = await adapter.verify(body.session_id);
      if (result.status !== 'failed') {
        return result;
      }
    }
    throw new NotFoundException({
      error: 'ERR_PAYMENT_SESSION_NOT_FOUND',
      message: `No payment session with id '${body.session_id}'`,
    });
  }
}
