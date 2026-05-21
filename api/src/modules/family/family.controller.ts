import {
  Body,
  Controller,
  DefaultValuePipe,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseBoolPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { FamilyService } from './family.service';
import { CreateGroupDto } from './dto/create-group.dto';
import { SendInviteDto } from './dto/send-invite.dto';
import { CreateSharedBudgetDto } from './dto/create-shared-budget.dto';
import { UpdateSharedBudgetDto } from './dto/update-shared-budget.dto';

@Controller('family')
@UseGuards(JwtAuthGuard)
export class FamilyController {
  constructor(private readonly familyService: FamilyService) {}

  @Post('groups')
  @HttpCode(HttpStatus.CREATED)
  createGroup(
    @CurrentUser() user: { id: string },
    @Body() dto: CreateGroupDto,
  ) {
    return this.familyService.createGroup(user.id, dto);
  }

  @Get('groups')
  findGroups(@CurrentUser() user: { id: string }) {
    return this.familyService.findGroups(user.id);
  }

  @Get('shared-budgets/mine')
  findMySharedBudgets(@CurrentUser() user: { id: string }) {
    return this.familyService.findMySharedBudgets(user.id);
  }

  @Get('groups/:id')
  findGroup(@CurrentUser() user: { id: string }, @Param('id') groupId: string) {
    return this.familyService.findGroup(user.id, groupId);
  }

  @Post('groups/:id/invite')
  @HttpCode(HttpStatus.CREATED)
  sendInvite(
    @CurrentUser() user: { id: string },
    @Param('id') groupId: string,
    @Body() dto: SendInviteDto,
  ) {
    return this.familyService.sendInvite(user.id, groupId, dto);
  }

  @Post('invites/:token/accept')
  @HttpCode(HttpStatus.OK)
  acceptInvite(
    @CurrentUser() user: { id: string },
    @Param('token') token: string,
  ) {
    return this.familyService.acceptInvite(user.id, token);
  }

  @Post('invites/:token/reject')
  @HttpCode(HttpStatus.OK)
  rejectInvite(
    @CurrentUser() user: { id: string },
    @Param('token') token: string,
  ) {
    return this.familyService.rejectInvite(user.id, token);
  }

  @Delete('invites/:token')
  @HttpCode(HttpStatus.OK)
  cancelInvite(
    @CurrentUser() user: { id: string },
    @Param('token') token: string,
  ) {
    return this.familyService.cancelInvite(user.id, token);
  }

  @Post('groups/:id/budgets')
  @HttpCode(HttpStatus.CREATED)
  createSharedBudget(
    @CurrentUser() user: { id: string },
    @Param('id') groupId: string,
    @Body() dto: CreateSharedBudgetDto,
  ) {
    return this.familyService.createSharedBudget(user.id, groupId, dto);
  }

  @Patch('groups/:id/budgets/:budgetId')
  updateSharedBudget(
    @CurrentUser() user: { id: string },
    @Param('id') groupId: string,
    @Param('budgetId') budgetId: string,
    @Body() dto: UpdateSharedBudgetDto,
  ) {
    return this.familyService.updateSharedBudget(
      user.id,
      groupId,
      budgetId,
      dto,
    );
  }

  @Get('groups/:id/budgets')
  findSharedBudgets(
    @CurrentUser() user: { id: string },
    @Param('id') groupId: string,
    @Query('includeArchived', new DefaultValuePipe(false), ParseBoolPipe)
    includeArchived: boolean,
  ) {
    return this.familyService.findSharedBudgets(
      user.id,
      groupId,
      includeArchived,
    );
  }

  @Get('groups/:id/budgets/:budgetId/history')
  getSharedBudgetHistory(
    @CurrentUser() user: { id: string },
    @Param('id') groupId: string,
    @Param('budgetId') budgetId: string,
  ) {
    return this.familyService.getSharedBudgetHistory(
      user.id,
      groupId,
      budgetId,
    );
  }

  @Get('groups/:id/contributions')
  getContributions(
    @CurrentUser() user: { id: string },
    @Param('id') groupId: string,
    @Query('period') period?: string,
  ) {
    return this.familyService.getContributions(user.id, groupId, period);
  }

  @Delete('groups/:id/members/:userId')
  @HttpCode(HttpStatus.OK)
  removeMember(
    @CurrentUser() user: { id: string },
    @Param('id') groupId: string,
    @Param('userId') targetUserId: string,
  ) {
    return this.familyService.removeMember(user.id, groupId, targetUserId);
  }

  @Delete('groups/:id')
  @HttpCode(HttpStatus.OK)
  deleteGroup(
    @CurrentUser() user: { id: string },
    @Param('id') groupId: string,
  ) {
    return this.familyService.deleteGroup(user.id, groupId);
  }

  @Get('groups/:id/budgets/:budgetId/expenses')
  findSharedBudgetExpenses(
    @CurrentUser() user: { id: string },
    @Param('id') groupId: string,
    @Param('budgetId') budgetId: string,
  ) {
    return this.familyService.findSharedBudgetExpenses(
      user.id,
      groupId,
      budgetId,
    );
  }

  @Delete('groups/:id/budgets/:budgetId')
  @HttpCode(HttpStatus.OK)
  deleteSharedBudget(
    @CurrentUser() user: { id: string },
    @Param('id') groupId: string,
    @Param('budgetId') budgetId: string,
  ) {
    return this.familyService.deleteSharedBudget(user.id, groupId, budgetId);
  }
}
