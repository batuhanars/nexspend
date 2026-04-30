import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { AccountsService } from './accounts.service';
import { CreateAccountDto } from './dto/create-account.dto';
import { UpdateAccountDto } from './dto/update-account.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@Controller('accounts')
@UseGuards(JwtAuthGuard)
export class AccountsController {
  constructor(private readonly accountsService: AccountsService) {}

  @Get()
  findAll(@CurrentUser() user: { id: string }) {
    return this.accountsService.findAll(user.id);
  }

  @Post()
  create(
    @CurrentUser() user: { id: string },
    @Body() dto: CreateAccountDto,
  ) {
    return this.accountsService.create(user.id, dto);
  }

  // Statik rotalar :id'den önce gelmeli
  @Get('summary')
  getSummary(@CurrentUser() user: { id: string }) {
    return this.accountsService.getSummary(user.id);
  }

  @Get(':id')
  findOne(
    @CurrentUser() user: { id: string },
    @Param('id') id: string,
  ) {
    return this.accountsService.findOne(user.id, id);
  }

  @Patch(':id')
  update(
    @CurrentUser() user: { id: string },
    @Param('id') id: string,
    @Body() dto: UpdateAccountDto,
  ) {
    return this.accountsService.update(user.id, id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.OK)
  remove(
    @CurrentUser() user: { id: string },
    @Param('id') id: string,
  ) {
    return this.accountsService.remove(user.id, id);
  }

  @Patch(':id/archive')
  archive(
    @CurrentUser() user: { id: string },
    @Param('id') id: string,
  ) {
    return this.accountsService.archive(user.id, id);
  }

  @Patch(':id/restore')
  restore(
    @CurrentUser() user: { id: string },
    @Param('id') id: string,
  ) {
    return this.accountsService.restore(user.id, id);
  }

  @Patch(':id/set-default')
  setDefault(
    @CurrentUser() user: { id: string },
    @Param('id') id: string,
  ) {
    return this.accountsService.setDefault(user.id, id);
  }

  @Get(':id/statement')
  getStatement(
    @CurrentUser() user: { id: string },
    @Param('id') id: string,
  ) {
    return this.accountsService.getStatement(user.id, id);
  }

  @Get(':id/analytics')
  getAnalytics(
    @CurrentUser() user: { id: string },
    @Param('id') id: string,
  ) {
    return this.accountsService.getAnalytics(user.id, id);
  }

  @Get(':id/transactions')
  getTransactions(
    @CurrentUser() user: { id: string },
    @Param('id') id: string,
    @Query('page') page?: number,
    @Query('limit') limit?: number,
  ) {
    return this.accountsService.getTransactions(user.id, id, page, limit);
  }
}
