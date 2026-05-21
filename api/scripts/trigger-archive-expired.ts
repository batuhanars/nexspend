import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { BudgetsService } from '../src/modules/budgets/budgets.service';
import { PrismaService } from '../src/prisma/prisma.service';

async function main() {
  const app = await NestFactory.createApplicationContext(AppModule, {
    logger: ['log', 'warn', 'error'],
  });

  const budgets = app.get(BudgetsService);
  const prisma = app.get(PrismaService);

  console.log('\n=== Bütçe dönem sonu arşivleme tetikleniyor ===');

  const today = new Date();
  today.setUTCHours(0, 0, 0, 0);

  const personalCandidates = await prisma.budget.count({
    where: { isActive: true, endDate: { lt: today } },
  });
  const sharedCandidates = await prisma.sharedBudget.count({
    where: { isActive: true, endDate: { lt: today } },
  });
  console.log(
    `Arşivlenecek aday — kişisel: ${personalCandidates}, ortak: ${sharedCandidates}`,
  );

  const start = Date.now();
  const stats = await budgets.archiveExpired();
  console.log(
    `Arşivleme tamamlandı — kişisel: ${stats.personal}, ortak: ${stats.shared} (${Date.now() - start}ms)`,
  );

  const remainingActiveExpired = await prisma.budget.count({
    where: { isActive: true, endDate: { lt: today } },
  });
  console.log(
    `Kalan aktif-ama-süresi-geçmiş kişisel bütçe: ${remainingActiveExpired} (0 olmalı)`,
  );

  await app.close();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
