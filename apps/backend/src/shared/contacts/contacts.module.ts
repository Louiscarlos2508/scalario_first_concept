import { DynamicModule, Module } from '@nestjs/common';
import { ContactsService } from './contacts.service';
import { ContactsController } from './contacts.controller';

@Module({})
export class ContactsModule {
  static register(): DynamicModule {
    return {
      module: ContactsModule,
      providers: [ContactsService],
      controllers: [ContactsController],
      exports: [ContactsService],
    };
  }
}
