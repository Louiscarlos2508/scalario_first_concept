import { Module } from '@nestjs/common';
import { PosController } from './pos.controller';
import { PosService } from './pos.service';

import { PosSessionService } from './pos-session.service';
import { PosSessionController } from './pos-session.controller';
import { CustomerService } from './customer.service';
import { CustomerController } from './customer.controller';

@Module({
    providers: [PosService, PosSessionService, CustomerService],
    controllers: [PosController, PosSessionController, CustomerController],
})
export class PosModule { }
