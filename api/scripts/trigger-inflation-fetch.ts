import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { InflationService } from '../src/modules/inflation/inflation.service';
import { PrismaService } from '../src/prisma/prisma.service';

async function main() {
  const app = await NestFactory.createApplicationContext(AppModule, {
    logger: ['log', 'warn', 'error'],
  });

  const inflation = app.get(InflationService);
  const prisma = app.get(PrismaService);

  console.log('\n=== EVDS fetch tetikleniyor ===');
  const start = Date.now();
  await inflation.fetchAndStoreRates();
  console.log(`Süre: ${Date.now() - start}ms`);

  const total = await prisma.inflationRate.count();
  console.log(`\nToplam inflation_rates kayıt sayısı: ${total}`);

  const latest = await prisma.inflationRate.findFirst({
    orderBy: [{ year: 'desc' }, { month: 'desc' }],
  });

  if (latest) {
    const sample = await prisma.inflationRate.findMany({
      where: { year: latest.year, month: latest.month },
      orderBy: { categoryKey: 'asc' },
    });
    console.log(`\nEn son dönem: ${latest.year}-${String(latest.month).padStart(2, '0')}`);
    console.table(
      sample.map((r) => ({
        kategori: r.categoryKey,
        aylik_pct: Number(r.monthlyRate),
        yillik_pct: Number(r.yearlyRate),
      })),
    );
  } else {
    console.log('\n⚠ Hiç veri yok — fetch başarısız veya API boş döndü');
  }

  await app.close();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
