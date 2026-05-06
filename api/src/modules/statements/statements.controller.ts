import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { StatementsService } from './statements.service';
import { PayStatementDto } from './dto/pay-statement.dto';

@Controller()
@UseGuards(JwtAuthGuard)
export class StatementsController {
  constructor(private readonly statementsService: StatementsService) {}

  @Get('accounts/:accountId/statements')
  getAccountStatements(
    @CurrentUser() user: { id: string },
    @Param('accountId') accountId: string,
  ) {
    return this.statementsService.getAccountStatements(user.id, accountId);
  }

  @Get('statements/:id')
  getStatement(@CurrentUser() user: { id: string }, @Param('id') id: string) {
    return this.statementsService.findOne(user.id, id);
  }

  @Post('statements/:id/pay')
  payStatement(
    @CurrentUser() user: { id: string },
    @Param('id') id: string,
    @Body() dto: PayStatementDto,
  ) {
    return this.statementsService.payStatement(user.id, id, dto);
  }
}
