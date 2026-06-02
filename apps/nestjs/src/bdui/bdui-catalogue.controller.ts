import { Controller, Get, Param, Logger } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { CatalogueGenericService } from './services/catalogue-generic.service';

@ApiTags('BDUI Catalogue')
@ApiBearerAuth()
@Controller(':tenant/catalogue')
export class BduiCatalogueController {
  private readonly logger = new Logger(BduiCatalogueController.name);

  constructor(
    private readonly genericService: CatalogueGenericService,
  ) {}

  @Get('theme')
  getTheme(@Param('tenant') tenant: string) {
    return this.genericService.loadJson(tenant, 'theme');
  }

  @Get('rbac')
  getRbac(@Param('tenant') tenant: string) {
    return this.genericService.loadJson(tenant, 'rbac');
  }

  @Get('dialogs/:dialogId')
  getDialog(
    @Param('tenant') tenant: string,
    @Param('dialogId') dialogId: string,
  ) {
    return this.genericService.loadJson(tenant, 'dialog', dialogId);
  }

  @Get('sheets/:sheetId')
  getSheet(
    @Param('tenant') tenant: string,
    @Param('sheetId') sheetId: string,
  ) {
    return this.genericService.loadJson(tenant, 'sheet', sheetId);
  }
}
