import { Module } from '@nestjs/common';
import { AccountsController } from './accounts.controller';
import { AccountsService } from './accounts.service';
import { CreditCardStatementJob } from './jobs/credit-card-statement.job';

@Module({
  controllers: [AccountsController],
  providers: [AccountsService, CreditCardStatementJob],
  exports: [AccountsService],
})
export class AccountsModule {}
