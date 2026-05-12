import {
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { InsightService } from './insight.service';
import { InsightQueryDto } from './dto/insight-query.dto';

@Controller('insights')
@UseGuards(JwtAuthGuard)
export class InsightsController {
  constructor(private readonly insightService: InsightService) {}

  @Get()
  findAll(
    @CurrentUser() user: { id: string },
    @Query() query: InsightQueryDto,
  ) {
    return this.insightService.findAll(user.id, query);
  }

  @Get('summary')
  getSummary(@CurrentUser() user: { id: string }) {
    return this.insightService.findSummary(user.id);
  }

  @Patch(':id/read')
  @HttpCode(HttpStatus.OK)
  markRead(@CurrentUser() user: { id: string }, @Param('id') id: string) {
    return this.insightService.markRead(user.id, id);
  }

  @Patch(':id/dismiss')
  @HttpCode(HttpStatus.OK)
  dismiss(@CurrentUser() user: { id: string }, @Param('id') id: string) {
    return this.insightService.dismiss(user.id, id);
  }

  @Post('generate')
  @HttpCode(HttpStatus.OK)
  generate(@CurrentUser() user: { id: string }) {
    return this.insightService.generate(user.id);
  }
}
