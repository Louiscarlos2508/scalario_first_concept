import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

@Module({
  imports: [
    TypeOrmModule.forRootAsync({
      useFactory: () => ({
        type: 'postgres',
        url: process.env.DATABASE_URL,
        synchronize: false,
        migrationsRun: false,
        migrations: ['dist/migrations/*.js'],
        autoLoadEntities: true,
        extra: { max: 10 },
      }),
    }),
  ],
  exports: [TypeOrmModule],
})
export class DatabaseModule {}
