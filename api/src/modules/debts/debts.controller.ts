import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { DebtsService } from './debts.service';
import { CreateDebtDto } from './dto/create-debt.dto';
import { UpdateDebtDto } from './dto/update-debt.dto';
import { CreateDebtPaymentDto } from './dto/create-debt-payment.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@Controller('debts')
@UseGuards(JwtAuthGuard)
export class DebtsController {
  constructor(private readonly debtsService: DebtsService) {}

  @Get()
  findAll(@CurrentUser() user: { id: string }) {
    return this.debtsService.findAll(user.id);
  }

  @Get('summary')
  getSummary(@CurrentUser() user: { id: string }) {
    return this.debtsService.getSummary(user.id);
  }

  @Get(':id')
  findOne(@CurrentUser() user: { id: string }, @Param('id') id: string) {
    return this.debtsService.findOne(user.id, id);
  }

  @Post()
  create(@CurrentUser() user: { id: string }, @Body() dto: CreateDebtDto) {
    return this.debtsService.create(user.id, dto);
  }

  @Patch(':id')
  update(
    @CurrentUser() user: { id: string },
    @Param('id') id: string,
    @Body() dto: UpdateDebtDto,
  ) {
    return this.debtsService.update(user.id, id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.OK)
  remove(@CurrentUser() user: { id: string }, @Param('id') id: string) {
    return this.debtsService.remove(user.id, id);
  }

  @Post(':id/payments')
  createPayment(
    @CurrentUser() user: { id: string },
    @Param('id') id: string,
    @Body() dto: CreateDebtPaymentDto,
  ) {
    return this.debtsService.createPayment(user.id, id, dto);
  }

  @Get(':id/payments')
  getPayments(@CurrentUser() user: { id: string }, @Param('id') id: string) {
    return this.debtsService.getPayments(user.id, id);
  }

  @Get(':id/installments')
  getInstallments(
    @CurrentUser() user: { id: string },
    @Param('id') id: string,
  ) {
    return this.debtsService.getInstallments(user.id, id);
  }
}
