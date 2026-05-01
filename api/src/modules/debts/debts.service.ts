import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { DebtType, DebtStatus, TransactionType, TransactionSource } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { TransactionCreatedEvent } from '../../common/events/transaction.events';
import { CreateDebtDto } from './dto/create-debt.dto';
import { UpdateDebtDto } from './dto/update-debt.dto';
import { CreateDebtPaymentDto } from './dto/create-debt-payment.dto';

@Injectable()
export class DebtsService {
  private readonly logger = new Logger(DebtsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async findAll(userId: string) {
    const debts = await this.prisma.debt.findMany({
      where: { userId },
      include: {
        installments: { orderBy: { installmentNo: 'asc' } },
        _count: { select: { payments: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
    return debts.map(this.format);
  }

  async getSummary(userId: string) {
    const debts = await this.prisma.debt.findMany({
      where: { userId, status: { not: DebtStatus.PAID } },
    });

    const lent = debts.filter((d) => d.type === DebtType.LENT);
    const borrowed = debts.filter((d) => d.type === DebtType.BORROWED);

    return {
      totalLent: lent.reduce((s, d) => s + Number(d.totalAmount), 0),
      remainingLent: lent.reduce(
        (s, d) => s + (Number(d.totalAmount) - Number(d.paidAmount)),
        0,
      ),
      totalBorrowed: borrowed.reduce((s, d) => s + Number(d.totalAmount), 0),
      remainingBorrowed: borrowed.reduce(
        (s, d) => s + (Number(d.totalAmount) - Number(d.paidAmount)),
        0,
      ),
      overdueCount: debts.filter((d) => d.status === DebtStatus.OVERDUE).length,
    };
  }

  async findOne(userId: string, id: string) {
    return this.format(await this.findOwned(userId, id));
  }

  async create(userId: string, dto: CreateDebtDto) {
    const debt = await this.prisma.debt.create({
      data: {
        userId,
        personName: dto.personName,
        type: dto.type,
        totalAmount: dto.totalAmount,
        dueDate: dto.dueDate ? new Date(dto.dueDate) : null,
        note: dto.note ?? null,
        hasInstallments: dto.hasInstallments ?? false,
      },
    });

    if (dto.hasInstallments && dto.installmentCount && dto.firstInstallmentDate) {
      const installmentAmount = dto.totalAmount / dto.installmentCount;
      const firstDate = new Date(dto.firstInstallmentDate);

      const installments = Array.from({ length: dto.installmentCount }, (_, i) => {
        const dueDate = new Date(firstDate);
        dueDate.setMonth(dueDate.getMonth() + i);
        return {
          debtId: debt.id,
          installmentNo: i + 1,
          amount: installmentAmount,
          dueDate,
        };
      });

      await this.prisma.debtInstallment.createMany({ data: installments });
    }

    return this.format(
      await this.prisma.debt.findUniqueOrThrow({
        where: { id: debt.id },
        include: { installments: { orderBy: { installmentNo: 'asc' } } },
      }),
    );
  }

  async update(userId: string, id: string, dto: UpdateDebtDto) {
    await this.findOwned(userId, id);

    return this.format(
      await this.prisma.debt.update({
        where: { id },
        data: {
          ...(dto.personName !== undefined && { personName: dto.personName }),
          ...(dto.totalAmount !== undefined && { totalAmount: dto.totalAmount }),
          ...(dto.status !== undefined && { status: dto.status }),
          ...(dto.dueDate !== undefined && { dueDate: new Date(dto.dueDate) }),
          ...(dto.note !== undefined && { note: dto.note }),
        },
        include: { installments: { orderBy: { installmentNo: 'asc' } } },
      }),
    );
  }

  async remove(userId: string, id: string) {
    await this.findOwned(userId, id);
    await this.prisma.debt.delete({ where: { id } });
    return { message: 'Borç silindi' };
  }

  async createPayment(userId: string, debtId: string, dto: CreateDebtPaymentDto) {
    const debt = await this.findOwned(userId, debtId);
    const remaining = Number(debt.totalAmount) - Number(debt.paidAmount);

    if (dto.amount > remaining) {
      throw new BadRequestException(
        `Ödeme tutarı kalan borçtan fazla olamaz (kalan: ${remaining})`,
      );
    }

    const paidAt = dto.paidAt ? new Date(dto.paidAt) : new Date();
    const systemCategory = await this.getSystemCategory(debt.type);

    const result = await this.prisma.$transaction(async (tx) => {
      // DebtPayment oluştur
      const payment = await tx.debtPayment.create({
        data: {
          debtId,
          installmentId: dto.installmentId ?? null,
          accountId: dto.accountId,
          amount: dto.amount,
          paidAt,
          note: dto.note ?? null,
        },
      });

      // Taksit varsa güncelle
      if (dto.installmentId) {
        const installment = await tx.debtInstallment.findFirst({
          where: { id: dto.installmentId, debtId },
        });
        if (!installment) throw new NotFoundException('Taksit bulunamadı');

        const newPaid = Number(installment.paidAmount) + dto.amount;
        const newStatus: DebtStatus =
          newPaid >= Number(installment.amount) ? DebtStatus.PAID : DebtStatus.PENDING;

        await tx.debtInstallment.update({
          where: { id: dto.installmentId },
          data: { paidAmount: newPaid, status: newStatus },
        });
      }

      // Borç paidAmount güncelle
      const newPaidAmount = Number(debt.paidAmount) + dto.amount;
      const isFullyPaid = newPaidAmount >= Number(debt.totalAmount);

      await tx.debt.update({
        where: { id: debtId },
        data: {
          paidAmount: newPaidAmount,
          ...(isFullyPaid && { status: DebtStatus.PAID }),
        },
      });

      // Hesap bakiyesi güncelle + Transaction oluştur
      const txType =
        debt.type === DebtType.BORROWED ? TransactionType.EXPENSE : TransactionType.INCOME;
      const txSource =
        debt.type === DebtType.BORROWED
          ? TransactionSource.DEBT_PAYMENT
          : TransactionSource.DEBT_COLLECTION;

      if (txType === TransactionType.EXPENSE) {
        await tx.account.update({
          where: { id: dto.accountId },
          data: { balance: { decrement: dto.amount } },
        });
      } else {
        await tx.account.update({
          where: { id: dto.accountId },
          data: { balance: { increment: dto.amount } },
        });
      }

      const transaction = await tx.transaction.create({
        data: {
          userId,
          accountId: dto.accountId,
          categoryId: systemCategory?.id ?? null,
          type: txType,
          source: txSource,
          amount: dto.amount,
          title: `${debt.personName} — ${debt.type === DebtType.BORROWED ? 'Borç Ödemesi' : 'Alacak Tahsilatı'}`,
          note: dto.note ?? null,
          transactionDate: paidAt,
          relatedDebtId: debtId,
        },
      });

      return { payment, transaction };
    });

    this.eventEmitter.emit(
      'transaction.created',
      new TransactionCreatedEvent(
        result.transaction.id,
        userId,
        systemCategory?.id ?? null,
        result.transaction.type,
        result.transaction.source,
        dto.amount,
        paidAt,
      ),
    );

    return result.payment;
  }

  async getPayments(userId: string, debtId: string) {
    await this.findOwned(userId, debtId);
    return this.prisma.debtPayment.findMany({
      where: { debtId },
      orderBy: { paidAt: 'desc' },
    });
  }

  async getInstallments(userId: string, debtId: string) {
    await this.findOwned(userId, debtId);
    return this.prisma.debtInstallment.findMany({
      where: { debtId },
      orderBy: { installmentNo: 'asc' },
    });
  }

  // Cron job tarafından çağrılır
  async markOverdue() {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // Vadesi geçmiş borçları OVERDUE yap
    const overdueDebts = await this.prisma.debt.updateMany({
      where: {
        status: DebtStatus.PENDING,
        dueDate: { lt: today },
      },
      data: { status: DebtStatus.OVERDUE },
    });

    // Vadesi geçmiş taksitleri OVERDUE yap
    const overdueInstallments = await this.prisma.debtInstallment.updateMany({
      where: {
        status: DebtStatus.PENDING,
        dueDate: { lt: today },
      },
      data: { status: DebtStatus.OVERDUE },
    });

    this.logger.log(
      `${overdueDebts.count} borç, ${overdueInstallments.count} taksit OVERDUE yapıldı`,
    );
  }

  async getDueTomorrow() {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(0, 0, 0, 0);
    const dayAfter = new Date(tomorrow);
    dayAfter.setDate(dayAfter.getDate() + 1);

    return this.prisma.debt.findMany({
      where: {
        status: { not: DebtStatus.PAID },
        dueDate: { gte: tomorrow, lt: dayAfter },
      },
      include: { user: { select: { email: true, fullName: true } } },
    });
  }

  private async getSystemCategory(debtType: DebtType) {
    const name = debtType === DebtType.BORROWED ? 'Borç Ödemesi' : 'Alacak Tahsilatı';
    return this.prisma.category.findFirst({ where: { name, isSystem: true } });
  }

  private async findOwned(userId: string, id: string) {
    const debt = await this.prisma.debt.findFirst({
      where: { id, userId },
      include: { installments: { orderBy: { installmentNo: 'asc' } } },
    });
    if (!debt) throw new NotFoundException('Borç bulunamadı');
    return debt;
  }

  private format(d: any) {
    const total = Number(d.totalAmount);
    const paid = Number(d.paidAmount);
    return {
      ...d,
      totalAmount: total,
      paidAmount: paid,
      remainingAmount: total - paid,
      installments: d.installments?.map((i: any) => ({
        ...i,
        amount: Number(i.amount),
        paidAmount: Number(i.paidAmount),
      })),
    };
  }
}
