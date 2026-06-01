import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { DataSource } from 'typeorm';
import { Tenant } from '../src/core/auth/entities/tenant.entity';
import { User } from '../src/core/auth/entities/user.entity';
import * as bcrypt from 'bcrypt';

async function main() {
  const app = await NestFactory.createApplicationContext(AppModule, { logger: false });
  const ds = app.get(DataSource);
  const tenantRepo = ds.getRepository(Tenant);
  const userRepo = ds.getRepository(User);

  const existing = await tenantRepo.findOne({ where: { slug: 'blandine' } });
  if (existing) {
    console.log('Tenant blandine already exists. Email: owner@blandine.bf / owner123');
    await app.close();
    process.exit(0);
  }

  const tenant = tenantRepo.create({
    name: 'Blandine Épicerie Fine',
    slug: 'blandine',
    is_active: true,
    config: { roles: ['OWNER', 'MANAGER', 'COMMERCIAL'] },
  });
  await tenantRepo.save(tenant);

  const owner = userRepo.create({
    tenant_id: tenant.id,
    email: 'owner@blandine.bf',
    password_hash: await bcrypt.hash('owner123', 12),
    roles: ['OWNER'],
    is_active: true,
  });
  await userRepo.save(owner);

  const commercial = userRepo.create({
    tenant_id: tenant.id,
    email: 'commercial@blandine.bf',
    password_hash: await bcrypt.hash('commercial123', 12),
    roles: ['COMMERCIAL'],
    is_active: true,
  });
  await userRepo.save(commercial);

  console.log('Seeded: owner@blandine.bf / owner123 | commercial@blandine.bf / commercial123');
  await app.close();
}

main().catch((err) => { console.error(err); process.exit(1); });