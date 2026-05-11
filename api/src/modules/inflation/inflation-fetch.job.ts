import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { InflationService } from './inflation.service';

@Injectable()
export class InflationFetchJob {
  private readonly logger = new Logger(InflationFetchJob.name);

  constructor(private readonly inflationService: InflationService) {}

  @Cron('0 10 5 * *')
  async runPrimary() {
    this.logger.log("Enflasyon verisi çekme başladı (birincil — ayın 5'i)");
    await this.inflationService.fetchAndStoreRates();
  }

  @Cron('0 10 10 * *')
  async runFallback() {
    this.logger.log("Enflasyon verisi çekme başladı (yedek — ayın 10'u)");
    await this.inflationService.fetchAndStoreRates();
  }
}
