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
import { RecurringTransactionsService } from './recurring-transactions.service';
import { CreateRecurringTransactionDto } from './dto/create-recurring-transaction.dto';
import { UpdateRecurringTransactionDto } from './dto/update-recurring-transaction.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@Controller('recurring-transactions')
@UseGuards(JwtAuthGuard)
export class RecurringTransactionsController {
  constructor(
    private readonly recurringService: RecurringTransactionsService,
  ) {}

  @Get()
  findAll(@CurrentUser() user: { id: string }) {
    return this.recurringService.findAll(user.id);
  }

  @Get(':id')
  findOne(@CurrentUser() user: { id: string }, @Param('id') id: string) {
    return this.recurringService.findOne(user.id, id);
  }

  @Post()
  create(
    @CurrentUser() user: { id: string },
    @Body() dto: CreateRecurringTransactionDto,
  ) {
    return this.recurringService.create(user.id, dto);
  }

  @Patch(':id')
  update(
    @CurrentUser() user: { id: string },
    @Param('id') id: string,
    @Body() dto: UpdateRecurringTransactionDto,
  ) {
    return this.recurringService.update(user.id, id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.OK)
  remove(@CurrentUser() user: { id: string }, @Param('id') id: string) {
    return this.recurringService.remove(user.id, id);
  }
}
