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
import { SubscriptionsService } from './subscriptions.service';
import { CreateSubscriptionDto } from './dto/create-subscription.dto';
import { UpdateSubscriptionDto } from './dto/update-subscription.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@Controller('subscriptions')
@UseGuards(JwtAuthGuard)
export class SubscriptionsController {
  constructor(private readonly subscriptionsService: SubscriptionsService) {}

  @Get()
  findAll(@CurrentUser() user: { id: string }) {
    return this.subscriptionsService.findAll(user.id);
  }

  @Get('summary')
  getSummary(@CurrentUser() user: { id: string }) {
    return this.subscriptionsService.getSummary(user.id);
  }

  @Get('upcoming')
  getUpcoming(
    @CurrentUser() user: { id: string },
    @Query('days') days?: string,
  ) {
    return this.subscriptionsService.getUpcoming(user.id, days ? Number(days) : 7);
  }

  @Get(':id')
  findOne(@CurrentUser() user: { id: string }, @Param('id') id: string) {
    return this.subscriptionsService.findOne(user.id, id);
  }

  @Post()
  create(@CurrentUser() user: { id: string }, @Body() dto: CreateSubscriptionDto) {
    return this.subscriptionsService.create(user.id, dto);
  }

  @Patch(':id')
  update(
    @CurrentUser() user: { id: string },
    @Param('id') id: string,
    @Body() dto: UpdateSubscriptionDto,
  ) {
    return this.subscriptionsService.update(user.id, id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.OK)
  remove(@CurrentUser() user: { id: string }, @Param('id') id: string) {
    return this.subscriptionsService.remove(user.id, id);
  }

  @Patch(':id/toggle')
  toggle(@CurrentUser() user: { id: string }, @Param('id') id: string) {
    return this.subscriptionsService.toggle(user.id, id);
  }
}
