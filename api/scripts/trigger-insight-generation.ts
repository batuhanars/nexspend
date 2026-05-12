import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { InsightService } from '../src/modules/insights/insight.service';
import { PrismaService } from '../src/prisma/prisma.service';

async function main() {
  const app = await NestFactory.createApplicationContext(AppModule, {
    logger: ['log', 'warn', 'error'],
  });

  const insightService = app.get(InsightService);
  const prisma = app.get(PrismaService);

  const now = new Date();
  const period = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;

  console.log(`\n=== Insight üretimi tetikleniyor (${period}) ===`);

  const users = await prisma.user.findMany({ select: { id: true, email: true } });
  console.log(`Toplam kullanıcı: ${users.length}`);

  let totalGenerated = 0;
  for (const user of users) {
    const start = Date.now();
    const result = await insightService.generate(user.id, period);
    totalGenerated += result.generated;
    console.log(
      `[${user.email}] ${result.generated} insight — ${Date.now() - start}ms`,
    );
  }

  console.log(`\nToplam insight: ${totalGenerated}`);

  const dbCount = await prisma.insight.count({ where: { period } });
  console.log(`Veritabanındaki toplam (${period}): ${dbCount}`);

  await app.close();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
