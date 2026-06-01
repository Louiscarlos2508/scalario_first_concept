import { NestFactory } from '@nestjs/core';
import { Logger } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';

async function bootstrap() {
  if (!process.env.JWT_SECRET || process.env.JWT_SECRET.length < 32) {
    throw new Error('JWT_SECRET must be set and at least 32 characters long (>= 256 bits).');
  }
  const app = await NestFactory.create(AppModule, { bufferLogs: true });

  app.enableCors({
    origin: true,
    credentials: true,
  });

  app.setGlobalPrefix('api/v1', { exclude: ['health'] });

  // Swagger setup — AC-01 to AC-04
  const config = new DocumentBuilder()
    .setTitle('Scalario API')
    .setDescription('Scalario — Instant Business OS for African SMEs. BDUI Engine + JSON Templates.')
    .setVersion('1.0.0')
    .addBearerAuth()
    .addApiKey(
      { type: 'apiKey', name: 'X-Tenant-ID', in: 'header' },
      'X-Tenant-ID',
    )
    .addApiKey(
      { type: 'apiKey', name: 'X-Client-Mutation-Id', in: 'header' },
      'X-Client-Mutation-Id',
    )
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document, {
    swaggerOptions: { persistAuthorization: true },
    customSiteTitle: 'Scalario API Docs',
  });

  const port = Number(process.env.PORT ?? 3000);
  await app.listen(port, '0.0.0.0');

  Logger.log(`Scalario NestJS up on http://0.0.0.0:${port}`, 'Bootstrap');
  Logger.log(`Swagger docs on http://0.0.0.0:${port}/api/docs`, 'Bootstrap');
}

bootstrap().catch((err) => {
  // eslint-disable-next-line no-console
  console.error('Fatal bootstrap error', err);
  process.exit(1);
});
