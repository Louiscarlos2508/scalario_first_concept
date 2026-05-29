import {
  Controller,
  Post,
  Param,
  Body,
  Logger,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { z } from 'zod';
import { AiRelayService } from './services/ai-relay.service';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { CurrentTenant } from '../common/decorators/current-tenant.decorator';
import { ZodValidationPipe } from '../common/pipes/zod-validation.pipe';
import type { AuthenticatedUser } from '../core/auth/interfaces/jwt-payload.interface';

const GenerateScreenSchema = z.object({
  surfaceId: z.string().min(1),
  intent: z.string().min(1),
  context: z.object({
    screen: z.string().optional(),
    data: z.record(z.unknown()).optional(),
    previousMessages: z.array(z.string()).optional(),
  }).optional(),
});

type GenerateScreenDto = z.infer<typeof GenerateScreenSchema>;

@ApiTags('AI Relay')
@ApiBearerAuth()
@Controller('api/v1/:tenant/ai-relay')
export class AiRelayController {
  private readonly logger = new Logger(AiRelayController.name);

  constructor(private readonly aiRelay: AiRelayService) {}

  @Post('generate')
  async generate(
    @Param('tenant') tenant: string,
    @Body(new ZodValidationPipe(GenerateScreenSchema)) dto: GenerateScreenDto,
    @CurrentUser() user: AuthenticatedUser,
    @CurrentTenant() tenantId: string,
  ) {
    if (tenant !== tenantId) {
      throw new ForbiddenException('Cross-tenant access denied');
    }

    this.logger.log(`Generate screen: tenant=${tenantId} surface=${dto.surfaceId}`);

    return this.aiRelay.generateAndPush({
      tenantId,
      userId: user.user_id,
      surfaceId: dto.surfaceId,
      intent: dto.intent,
      context: dto.context,
    });
  }
}
