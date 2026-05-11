import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { InflationController } from './inflation.controller';
import { InflationService } from './inflation.service';
import { InflationFetchJob } from './inflation-fetch.job';

@Module({
  imports: [HttpModule],
  controllers: [InflationController],
  providers: [InflationService, InflationFetchJob],
  exports: [InflationService],
})
export class InflationModule {}
