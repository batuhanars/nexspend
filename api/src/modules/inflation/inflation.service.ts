import { Injectable, Logger } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { firstValueFrom } from 'rxjs';
import { PrismaService } from '../../prisma/prisma.service';
import { EVDS_SERIES_MAP, InflationCategoryKey } from './inflation.constants';

interface EvdsItem {
  Tarih: string;
  [key: string]: string | null;
}

interface EvdsResponse {
  items: EvdsItem[];
}

@Injectable()
export class InflationService {
  private readonly logger = new Logger(InflationService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly http: HttpService,
    private readonly config: ConfigService,
  ) {}

  async getCurrentRates() {
    const latest = await this.prisma.inflationRate.findFirst({
      orderBy: [{ year: 'desc' }, { month: 'desc' }],
    });

    if (!latest) return [];

    const rates = await this.prisma.inflationRate.findMany({
      where: { year: latest.year, month: latest.month },
      orderBy: { categoryKey: 'asc' },
    });

    return rates.map((r) => this.formatRate(r));
  }

  async getHistory(months: number) {
    const pairs = this.buildRecentMonthPairs(months);

    const rates = await this.prisma.inflationRate.findMany({
      where: {
        OR: pairs.map(({ year, month }) => ({ year, month })),
      },
      orderBy: [{ year: 'asc' }, { month: 'asc' }],
    });

    const result: Record<
      string,
      Array<{
        year: number;
        month: number;
        monthlyRate: number;
        yearlyRate: number;
      }>
    > = {};

    for (const rate of rates) {
      if (!result[rate.categoryKey]) result[rate.categoryKey] = [];
      result[rate.categoryKey].push({
        year: rate.year,
        month: rate.month,
        monthlyRate: Number(rate.monthlyRate),
        yearlyRate: Number(rate.yearlyRate),
      });
    }

    return result;
  }

  async fetchAndStoreRates(): Promise<void> {
    const apiKey = this.config.get<string>('EVDS_API_KEY');
    const baseUrl = this.config.get<string>(
      'EVDS_BASE_URL',
      'https://evds2.tcmb.gov.tr/service/evds/',
    );

    if (!apiKey) {
      this.logger.warn(
        'EVDS_API_KEY tanımlı değil, enflasyon verisi çekilmedi',
      );
      return;
    }

    const allSeries = Object.values(EVDS_SERIES_MAP).join(',');
    const now = new Date();
    // 25 ay öncesinden başla — 12 aylık yıllık oran hesabı için yeterli veri
    const startDate = this.toEvdsDate(
      new Date(now.getFullYear(), now.getMonth() - 25, 1),
    );
    const endDate = this.toEvdsDate(now);

    const items = await this.fetchWithRetry(
      baseUrl,
      allSeries,
      startDate,
      endDate,
      apiKey,
    );
    if (items.length === 0) {
      this.logger.warn('EVDS API boş yanıt döndü, mevcut DB verisi korunuyor');
      return;
    }

    items.sort(
      (a, b) => this.parseEvdsDate(a.Tarih) - this.parseEvdsDate(b.Tarih),
    );

    // Endeks haritası: "YYYY-MM" → { categoryKey → indexValue }
    const indexMap = new Map<string, Map<string, number>>();
    for (const item of items) {
      const periodKey = this.evdsToPeriodKey(item.Tarih);
      if (!indexMap.has(periodKey)) indexMap.set(periodKey, new Map());
      const periodData = indexMap.get(periodKey)!;

      for (const [catKey, series] of Object.entries(EVDS_SERIES_MAP) as [
        InflationCategoryKey,
        string,
      ][]) {
        const responseKey = series.replace(/\./g, '_');
        const val = item[responseKey];
        if (val != null && val !== '') {
          const num = parseFloat(val);
          if (!isNaN(num)) periodData.set(catKey, num);
        }
      }
    }

    const periodKeys = Array.from(indexMap.keys()).sort();
    const cutoff = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;

    const upserts: Promise<unknown>[] = [];

    for (let i = 1; i < periodKeys.length; i++) {
      const periodKey = periodKeys[i];
      if (periodKey > cutoff) continue;

      const [yr, mo] = periodKey.split('-').map(Number);
      const prevKey = periodKeys[i - 1];
      const yearAgoKey = `${yr - 1}-${String(mo).padStart(2, '0')}`;

      const current = indexMap.get(periodKey)!;
      const prev = indexMap.get(prevKey);
      const yearAgo = indexMap.get(yearAgoKey);

      for (const catKey of Object.keys(
        EVDS_SERIES_MAP,
      ) as InflationCategoryKey[]) {
        const currIdx = current.get(catKey);
        if (currIdx === undefined) continue;

        const prevIdx = prev?.get(catKey);
        const yearAgoIdx = yearAgo?.get(catKey);

        const monthlyRate =
          prevIdx !== undefined
            ? Math.round((currIdx / prevIdx - 1) * 100 * 100) / 100
            : 0;
        const yearlyRate =
          yearAgoIdx !== undefined
            ? Math.round((currIdx / yearAgoIdx - 1) * 100 * 100) / 100
            : 0;

        upserts.push(
          this.prisma.inflationRate.upsert({
            where: {
              categoryKey_year_month: {
                categoryKey: catKey,
                year: yr,
                month: mo,
              },
            },
            create: {
              categoryKey: catKey,
              year: yr,
              month: mo,
              monthlyRate,
              yearlyRate,
            },
            update: { monthlyRate, yearlyRate, fetchedAt: new Date() },
          }),
        );
      }
    }

    await Promise.all(upserts);
    this.logger.log(
      `Enflasyon verileri güncellendi: ${upserts.length} kayıt işlendi`,
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  private async fetchWithRetry(
    baseUrl: string,
    series: string,
    startDate: string,
    endDate: string,
    apiKey: string,
  ): Promise<EvdsItem[]> {
    const url = `${baseUrl}series=${series}&startDate=${startDate}&endDate=${endDate}&type=json&key=${apiKey}`;

    for (let attempt = 1; attempt <= 3; attempt++) {
      try {
        const response = await firstValueFrom(
          this.http.get<EvdsResponse>(url, { timeout: 15000 }),
        );
        return response.data?.items ?? [];
      } catch (err) {
        this.logger.warn(
          `EVDS API denemesi ${attempt}/3 başarısız: ${(err as Error).message}`,
        );
        if (attempt < 3) await this.sleep(5000);
      }
    }

    return [];
  }

  private formatRate(rate: {
    categoryKey: string;
    year: number;
    month: number;
    monthlyRate: unknown;
    yearlyRate: unknown;
    fetchedAt: Date;
  }) {
    return {
      categoryKey: rate.categoryKey,
      year: rate.year,
      month: rate.month,
      monthlyRate: Number(rate.monthlyRate),
      yearlyRate: Number(rate.yearlyRate),
      fetchedAt: rate.fetchedAt.toISOString(),
    };
  }

  private buildRecentMonthPairs(
    count: number,
  ): { year: number; month: number }[] {
    const pairs: { year: number; month: number }[] = [];
    const now = new Date();
    for (let i = 0; i < count; i++) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      pairs.push({ year: d.getFullYear(), month: d.getMonth() + 1 });
    }
    return pairs;
  }

  private toEvdsDate(d: Date): string {
    const mm = String(d.getMonth() + 1).padStart(2, '0');
    const yyyy = String(d.getFullYear());
    return `01-${mm}-${yyyy}`;
  }

  private parseEvdsDate(dateStr: string): number {
    const [dd, mm, yyyy] = dateStr.split('-');
    return new Date(`${yyyy}-${mm}-${dd}`).getTime();
  }

  private evdsToPeriodKey(dateStr: string): string {
    const [, mm, yyyy] = dateStr.split('-');
    return `${yyyy}-${mm}`;
  }

  private sleep(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
}
