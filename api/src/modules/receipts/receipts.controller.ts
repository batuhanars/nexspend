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
  UseInterceptors,
  UploadedFile,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname, join } from 'path';
import { ReceiptsService } from './receipts.service';
import { ScanReceiptDto } from './dto/scan-receipt.dto';
import { ConfirmReceiptDto } from './dto/confirm-receipt.dto';
import { UpdateReceiptDto } from './dto/update-receipt.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { ReceiptStatus } from '@prisma/client';

const multerStorage = diskStorage({
  destination: join(process.cwd(), 'uploads', 'receipts'),
  filename: (_, file, cb) => {
    const unique = `${Date.now()}-${Math.round(Math.random() * 1e6)}`;
    cb(null, `${unique}${extname(file.originalname)}`);
  },
});

@Controller('receipts')
@UseGuards(JwtAuthGuard)
export class ReceiptsController {
  constructor(private readonly receiptsService: ReceiptsService) {}

  @Get()
  findAll(
    @CurrentUser() user: { id: string },
    @Query('status') status?: ReceiptStatus,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.receiptsService.findAll(
      user.id,
      status,
      page ? Number(page) : 1,
      limit ? Number(limit) : 20,
    );
  }

  @Get(':id')
  findOne(@CurrentUser() user: { id: string }, @Param('id') id: string) {
    return this.receiptsService.findOne(user.id, id);
  }

  @Post('scan')
  @UseInterceptors(FileInterceptor('image', { storage: multerStorage }))
  scan(
    @CurrentUser() user: { id: string },
    @Body() dto: ScanReceiptDto,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    const imageUrl = file
      ? `/uploads/receipts/${file.filename}`
      : 'pending';
    return this.receiptsService.scan(user.id, dto, imageUrl);
  }

  @Patch(':id')
  update(
    @CurrentUser() user: { id: string },
    @Param('id') id: string,
    @Body() dto: UpdateReceiptDto,
  ) {
    return this.receiptsService.update(user.id, id, dto);
  }

  @Post(':id/confirm')
  confirm(
    @CurrentUser() user: { id: string },
    @Param('id') id: string,
    @Body() dto: ConfirmReceiptDto,
  ) {
    return this.receiptsService.confirm(user.id, id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.OK)
  remove(@CurrentUser() user: { id: string }, @Param('id') id: string) {
    return this.receiptsService.remove(user.id, id);
  }

  @Get('merchant-mappings')
  getMerchantMappings(@CurrentUser() user: { id: string }) {
    return this.receiptsService.getMerchantMappings(user.id);
  }

  @Post('merchant-mappings')
  upsertMerchantMapping(
    @CurrentUser() user: { id: string },
    @Body() body: { merchantKey: string; categoryId: string },
  ) {
    return this.receiptsService.upsertMerchantMapping(
      user.id,
      body.merchantKey,
      body.categoryId,
    );
  }
}
