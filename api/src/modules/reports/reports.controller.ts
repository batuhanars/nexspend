import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ReportsService } from './reports.service';
import { QueryReportDto } from './dto/query-report.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { IsOptional, IsString } from 'class-validator';

class InflationComparisonQueryDto {
  @IsOptional()
  @IsString()
  period?: string;
}

@Controller('reports')
@UseGuards(JwtAuthGuard)
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) {}

  @Get('expense-distribution')
  getExpenseDistribution(
    @CurrentUser() user: { id: string },
    @Query() query: QueryReportDto,
  ) {
    return this.reportsService.getExpenseDistribution(user.id, query);
  }

  @Get('cash-flow')
  getCashFlow(
    @CurrentUser() user: { id: string },
    @Query() query: QueryReportDto,
  ) {
    return this.reportsService.getCashFlow(user.id, query);
  }

  @Get('trends')
  getTrends(
    @CurrentUser() user: { id: string },
    @Query() query: QueryReportDto,
  ) {
    return this.reportsService.getTrends(user.id, query);
  }

  @Get('inflation-comparison')
  getInflationComparison(
    @CurrentUser() user: { id: string },
    @Query() query: InflationComparisonQueryDto,
  ) {
    return this.reportsService.getInflationComparison(user.id, query.period);
  }
}
