import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MindModule } from '../engines/mind/mind.module';
import { BduiController } from './bdui.controller';
import { BduiService } from './services/bdui.service';
import { CatalogueLoaderService } from './services/catalogue-loader.service';
import { A2uiToScreenConfigService } from './services/a2ui-to-screen-config.service';
import { BduiLayoutCacheService } from './cache/bdui-layout-cache.service';
import { TenantConfigEventsListener } from './cache/tenant-config-events.listener';
import { RbacComponentFilter } from './filters/rbac-component-filter';
import { ScreenConfigRepository } from './repositories/screen-config.repository';
import { ScreenConfigEntity } from './entities/screen-config.entity';

@Module({
  imports: [TypeOrmModule.forFeature([ScreenConfigEntity]), MindModule],
  controllers: [BduiController],
  providers: [
    BduiService,
    CatalogueLoaderService,
    A2uiToScreenConfigService,
    BduiLayoutCacheService,
    TenantConfigEventsListener,
    RbacComponentFilter,
    ScreenConfigRepository,
  ],
  exports: [BduiService, BduiLayoutCacheService],
})
export class BduiModule {}
