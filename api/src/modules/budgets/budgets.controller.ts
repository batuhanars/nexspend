import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  Res,
  UseGuards,
  HttpCode,
  HttpStatus,
  DefaultValuePipe,
  ParseBoolPipe,
} from '@nestjs/common';
import { Response } from 'express';
import { BudgetsService } from './budgets.service';
import { CreateBudgetDto } from './dto/create-budget.dto';
import { UpdateBudgetDto } from './dto/update-budget.dto';
import { ApplyInflationDto } from './dto/apply-inflation.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@Controller('budgets')
@UseGuards(JwtAuthGuard)
export class BudgetsController {
  constructor(private readonly budgetsService: BudgetsService) {}

  @Get()
  findAll(
    @CurrentUser() user: { id: string },
    @Query('includeArchived', new DefaultValuePipe(false), ParseBoolPipe)
    includeArchived: boolean,
  ) {
    return this.budgetsService.findAll(user.id, includeArchived);
  }

  @Get('overview')
  getOverview(@CurrentUser() user: { id: string }) {
    return this.budgetsService.getOverview(user.id);
  }

  @Get(':id/history')
  getHistory(@CurrentUser() user: { id: string }, @Param('id') id: string) {
    return this.budgetsService.getHistory(user.id, id);
  }

  @Get(':id')
  findOne(@CurrentUser() user: { id: string }, @Param('id') id: string) {
    return this.budgetsService.findOne(user.id, id);
  }

  @Post()
  create(@CurrentUser() user: { id: string }, @Body() dto: CreateBudgetDto) {
    return this.budgetsService.create(user.id, dto);
  }

  @Patch(':id')
  update(
    @CurrentUser() user: { id: string },
    @Param('id') id: string,
    @Body() dto: UpdateBudgetDto,
  ) {
    return this.budgetsService.update(user.id, id, dto);
  }

  @Get(':id/inflation-suggestion')
  async getInflationSuggestion(
    @CurrentUser() user: { id: string },
    @Param('id') id: string,
    @Res() res: Response,
  ) {
    const suggestion = await this.budgetsService.getInflationSuggestion(
      user.id,
      id,
    );
    if (!suggestion) {
      return res.status(HttpStatus.NO_CONTENT).send();
    }
    return res.status(HttpStatus.OK).json({
      success: true,
      statusCode: HttpStatus.OK,
      data: suggestion,
    });
  }

  @Post(':id/apply-inflation')
  applyInflation(
    @CurrentUser() user: { id: string },
    @Param('id') id: string,
    @Body() dto: ApplyInflationDto,
  ) {
    return this.budgetsService.applyInflation(user.id, id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.OK)
  remove(@CurrentUser() user: { id: string }, @Param('id') id: string) {
    return this.budgetsService.remove(user.id, id);
  }
}
