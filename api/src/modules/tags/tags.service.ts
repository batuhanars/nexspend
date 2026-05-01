import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  ConflictException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateTagDto } from './dto/create-tag.dto';

@Injectable()
export class TagsService {
  constructor(private readonly prisma: PrismaService) {}

  findAll(userId: string) {
    return this.prisma.tag.findMany({
      where: { userId },
      orderBy: { name: 'asc' },
    });
  }

  async create(userId: string, dto: CreateTagDto) {
    const existing = await this.prisma.tag.findFirst({
      where: { userId, name: dto.name },
    });
    if (existing) throw new ConflictException('Bu isimde bir etiket zaten var');

    return this.prisma.tag.create({
      data: { userId, name: dto.name, color: dto.color, icon: dto.icon ?? null },
    });
  }

  async remove(userId: string, id: string) {
    const tag = await this.prisma.tag.findUnique({ where: { id } });
    if (!tag) throw new NotFoundException('Etiket bulunamadı');
    if (tag.userId !== userId) throw new ForbiddenException('Bu etiket size ait değil');

    await this.prisma.tag.delete({ where: { id } });
    return { message: 'Etiket silindi' };
  }
}
