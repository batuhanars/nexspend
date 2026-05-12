import { Module } from '@nestjs/common';
import { FamilyController } from './family.controller';
import { FamilyService } from './family.service';
import { FamilyEmailService } from './email.service';
import { SharedBudgetListener } from './shared-budget.listener';

@Module({
  controllers: [FamilyController],
  providers: [FamilyService, FamilyEmailService, SharedBudgetListener],
  exports: [FamilyService],
})
export class FamilyModule {}
