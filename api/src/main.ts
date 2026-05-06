import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NestExpressApplication } from '@nestjs/platform-express';
import { AppModule } from './app.module';
import { GlobalExceptionFilter } from './common/filters/http-exception.filter';
import { TransformInterceptor } from './common/interceptors/transform.interceptor';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  // /uploads klasörü artık public servis edilmiyor — avatar ve fiş görselleri
  // sadece JWT korumalı streaming endpoint'leri üzerinden erişilebilir
  // (GET /api/users/me/avatar, GET /api/receipts/:id/image).

  const configService = app.get(ConfigService);
  const port = configService.get<number>('port') ?? 3000;
  const frontendUrl =
    configService.get<string>('frontend.url') ?? 'http://localhost:3001';

  app.setGlobalPrefix('api');

  app.enableCors({
    origin: [frontendUrl, 'http://localhost:3000'],
    methods: ['GET', 'POST', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true,
  });

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );

  app.useGlobalFilters(new GlobalExceptionFilter());
  app.useGlobalInterceptors(new TransformInterceptor());

  await app.listen(port, '0.0.0.0');
  console.log(`Application running on http://localhost:${port}/api`);
}
void bootstrap();
