import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { InflationService } from './inflation.service';
import { InflationHistoryQueryDto } from './dto/inflation-history-query.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

@Controller('inflation')
@UseGuards(JwtAuthGuard)
export class InflationController {
  constructor(private readonly inflationService: InflationService) {}

  @Get('current')
  getCurrent() {
    return this.inflationService.getCurrentRates();
  }

  @Get('history')
  getHistory(@Query() query: InflationHistoryQueryDto) {
    return this.inflationService.getHistory(query.months ?? 6);
  }
}
