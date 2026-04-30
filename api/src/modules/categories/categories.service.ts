import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateCategoryDto } from './dto/create-category.dto';

@Injectable()
export class CategoriesService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(userId: string) {
    const categories = await this.prisma.category.findMany({
      where: {
        OR: [
          { isSystem: true, parentId: null },
          { userId, parentId: null },
        ],
      },
      include: {
        children: {
          where: {
            OR: [{ isSystem: true }, { userId }],
          },
          orderBy: { sortOrder: 'asc' },
        },
      },
      orderBy: { sortOrder: 'asc' },
    });

    return categories;
  }

  async create(userId: string, dto: CreateCategoryDto) {
    if (dto.parentId) {
      const parent = await this.prisma.category.findUnique({
        where: { id: dto.parentId },
      });
      if (!parent) throw new NotFoundException('Üst kategori bulunamadı');
    }

    return this.prisma.category.create({
      data: {
        userId,
        name: dto.name,
        icon: dto.icon,
        color: dto.color,
        type: dto.type,
        parentId: dto.parentId ?? null,
        isSystem: false,
      },
    });
  }

  async remove(userId: string, id: string) {
    const category = await this.prisma.category.findUnique({ where: { id } });

    if (!category) throw new NotFoundException('Kategori bulunamadı');
    if (category.isSystem) throw new ForbiddenException('Sistem kategorisi silinemez');
    if (category.userId !== userId) throw new ForbiddenException('Bu kategori size ait değil');

    await this.prisma.category.delete({ where: { id } });
    return { message: 'Kategori silindi' };
  }
}
