import { NestFactory } from '@nestjs/core';
import { Logger } from '@nestjs/common';
import { AppModule } from './app.module';

async function bootstrap() {
  if (!process.env.JWT_SECRET || process.env.JWT_SECRET.length < 32) {
    throw new Error('JWT_SECRET must be set and at least 32 characters long (>= 256 bits).');
  }
  const app = await NestFactory.create(AppModule, { bufferLogs: true });

  const port = Number(process.env.PORT ?? 3000);
  await app.listen(port, '0.0.0.0');

  Logger.log(`Scalario NestJS up on http://0.0.0.0:${port}`, 'Bootstrap');
}

bootstrap().catch((err) => {
  // eslint-disable-next-line no-console
  console.error('Fatal bootstrap error', err);
  process.exit(1);
});
