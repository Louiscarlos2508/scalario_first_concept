import { Controller, Get, Param, Logger } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { BduiNavigationService } from './services/bdui-navigation.service';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { AuthenticatedUser } from '../core/auth/interfaces/jwt-payload.interface';

@ApiTags('BDUI Navigation')
@ApiBearerAuth()
@Controller(':tenant/navigation')
export class BduiNavigationController {
  private readonly logger = new Logger(BduiNavigationController.name);

  constructor(
    private readonly navigationService: BduiNavigationService,
  ) {}

  @Get()
  getNavigation(
    @Param('tenant') tenant: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.navigationService.getNavigation(tenant, user.roles);
  }
}
