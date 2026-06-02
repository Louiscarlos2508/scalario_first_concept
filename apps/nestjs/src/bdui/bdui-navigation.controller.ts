import { Controller, Get, Param, Logger } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { BduiNavigationService } from './services/bdui-navigation.service';

@ApiTags('BDUI Navigation')
@ApiBearerAuth()
@Controller(':tenant/navigation')
export class BduiNavigationController {
  private readonly logger = new Logger(BduiNavigationController.name);

  constructor(
    private readonly navigationService: BduiNavigationService,
  ) {}

  @Get()
  getNavigation(@Param('tenant') tenant: string) {
    return this.navigationService.getNavigation(tenant);
  }
}
