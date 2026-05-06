/* eslint-disable @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-call, @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-return, @typescript-eslint/no-unsafe-argument */
import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import {
  AccountType,
  StatementStatus,
  TransactionType,
  TransactionSource,
} from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { BalanceService } from '../../common/services/balance.service';
import { PayStatementDto } from './dto/pay-statement.dto';

/**
 * Türkiye'de yaygın asgari ödeme yüzdesi. Bankalara göre %20-40 arası değişir;
 * kullanıcı başına yapılandırılabilirlik V2'de — şimdilik %30 sabit.
 */
const MINIMUM_PAYMENT_RATE = 0.3;

@Injectable()
export class StatementsService {
  private readonly logger = new Logger(StatementsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly balanceService: BalanceService,
  ) {}

  // -----------------------------------------------------------------
  // Read API'leri
  // -----------------------------------------------------------------

  async getAccountStatements(userId: string, accountId: string) {
    const account = await this.findOwnedCreditCard(userId, accountId);

    const allStatements = await this.prisma.creditCardStatement.findMany({
      where: { accountId },
      orderBy: { periodEnd: 'desc' },
    });

    const openStatements = allStatements.filter(
      (s) => s.status !== StatementStatus.PAID,
    );
    const history = allStatements.filter(
      (s) => s.status === StatementStatus.PAID,
    );

    const currentPeriod = await this.computeCurrentPeriod(
      account,
      allStatements[0] ?? null,
    );

    return {
      currentPeriod,
      openStatements: openStatements.map((s) => this.format(s)),
      history: history.map((s) => this.format(s)),
    };
  }

  async findOne(userId: string, statementId: string) {
    const statement = await this.findOwnedStatement(userId, statementId);
    return this.format(statement);
  }

  // -----------------------------------------------------------------
  // Ödeme
  // -----------------------------------------------------------------

  async payStatement(
    userId: string,
    statementId: string,
    dto: PayStatementDto,
  ) {
    const statement = await this.findOwnedStatement(userId, statementId);

    if (statement.status === StatementStatus.PAID) {
      throw new BadRequestException('Bu ekstre zaten ödenmiş');
    }

    const fromAccount = await this.prisma.account.findFirst({
      where: { id: dto.fromAccountId, userId, isArchived: false },
    });
    if (!fromAccount) throw new NotFoundException('Kaynak hesap bulunamadı');
    if (fromAccount.id === statement.accountId) {
      throw new BadRequestException('Aynı hesaptan ödeme yapılamaz');
    }
    if (fromAccount.type === AccountType.CREDIT_CARD) {
      throw new BadRequestException(
        'Kredi kartı ödemesi başka bir kredi kartından yapılamaz',
      );
    }

    const remaining =
      Number(statement.totalAmount) - Number(statement.paidAmount);
    if (dto.amount > remaining + 0.005) {
      throw new BadRequestException(
        `Tutar kalan borçtan büyük olamaz (kalan: ${remaining.toFixed(2)})`,
      );
    }

    const newPaid = Number(statement.paidAmount) + dto.amount;
    const total = Number(statement.totalAmount);
    const isFullPaid = newPaid + 0.005 >= total;

    const newStatus: StatementStatus = isFullPaid
      ? StatementStatus.PAID
      : statement.status === StatementStatus.OVERDUE
        ? StatementStatus.OVERDUE
        : StatementStatus.PARTIALLY_PAID;

    const transferDate = dto.transactionDate
      ? new Date(dto.transactionDate)
      : new Date();

    return await this.prisma.$transaction(async (tx) => {
      const transaction = await tx.transaction.create({
        data: {
          userId,
          accountId: fromAccount.id,
          type: TransactionType.TRANSFER,
          source: TransactionSource.MANUAL,
          amount: dto.amount,
          title: 'Kredi kartı ödemesi',
          transactionDate: transferDate,
          transferToAccountId: statement.accountId,
        },
      });

      await this.balanceService.apply(
        tx,
        fromAccount.id,
        TransactionType.TRANSFER,
        dto.amount,
        statement.accountId,
      );

      const updated = await tx.creditCardStatement.update({
        where: { id: statement.id },
        data: { paidAmount: newPaid, status: newStatus },
      });

      this.logger.log(
        `Ekstre ödemesi ${statement.id}: ${dto.amount} → ${newStatus}`,
      );

      return {
        statement: this.format(updated),
        transactionId: transaction.id,
      };
    });
  }

  // -----------------------------------------------------------------
  // Cron — günlük dönem kapatma
  // -----------------------------------------------------------------

  async closeStatementsForDate(date: Date = new Date()): Promise<number> {
    const today = startOfDay(date);
    const dayOfMonth = today.getDate();
    const lastDay = endOfMonth(today).getDate();

    // statementDay=31 olan kart için Şubat'ta ay sonu kapatma yapmak gerekiyor.
    // O yüzden ya bugün == statementDay ya da bugün ay sonu AND statementDay > ay sonu.
    const isLastDayOfMonth = dayOfMonth === lastDay;

    const cards = await this.prisma.account.findMany({
      where: {
        type: AccountType.CREDIT_CARD,
        isArchived: false,
        statementDay: { not: null },
      },
    });

    let closed = 0;
    for (const card of cards) {
      const sd = card.statementDay!;
      const matchesToday =
        sd === dayOfMonth || (isLastDayOfMonth && sd > lastDay);
      if (!matchesToday) continue;

      const created = await this.closePeriodForAccount(card, today);
      if (created) closed++;
    }
    return closed;
  }

  private async closePeriodForAccount(
    card: { id: string; createdAt: Date; paymentDueDay: number | null },
    today: Date,
  ): Promise<boolean> {
    // Önceki kapatılmış ekstre — dönem başlangıcını oradan al.
    const lastClosed = await this.prisma.creditCardStatement.findFirst({
      where: { accountId: card.id },
      orderBy: { periodEnd: 'desc' },
    });

    const periodStart = lastClosed
      ? addDays(startOfDay(lastClosed.periodEnd), 1)
      : startOfDay(card.createdAt);
    const periodEnd = today;

    // Aynı periyot için tekrar kapatma (idempotency)
    if (
      lastClosed &&
      isSameDay(startOfDay(lastClosed.periodEnd), periodEnd)
    ) {
      return false;
    }

    const expenseAgg = await this.prisma.transaction.aggregate({
      where: {
        accountId: card.id,
        type: TransactionType.EXPENSE,
        transactionDate: {
          gte: periodStart,
          lte: endOfDay(periodEnd),
        },
      },
      _sum: { amount: true },
    });
    const totalAmount = Number(expenseAgg._sum.amount ?? 0);

    // Sıfır harcama varsa boş ekstre üretme — gereksiz gürültü.
    if (totalAmount <= 0) {
      this.logger.debug(
        `Hesap ${card.id}: bu dönem harcama yok, ekstre üretilmedi`,
      );
      return false;
    }

    const minimumPayment =
      Math.round(totalAmount * MINIMUM_PAYMENT_RATE * 100) / 100;
    const dueDate = computeDueDate(periodEnd, card.paymentDueDay ?? 10);

    await this.prisma.creditCardStatement.create({
      data: {
        accountId: card.id,
        periodStart,
        periodEnd,
        dueDate,
        totalAmount,
        minimumPayment,
        status: StatementStatus.DUE,
      },
    });

    this.logger.log(
      `Ekstre kapatıldı: hesap ${card.id}, ${totalAmount} TRY, vade ${dueDate.toISOString().slice(0, 10)}`,
    );
    return true;
  }

  // -----------------------------------------------------------------
  // Cron — vadesi geçen ekstreleri OVERDUE işaretle
  // -----------------------------------------------------------------

  async markOverdue(date: Date = new Date()): Promise<number> {
    const today = startOfDay(date);
    const result = await this.prisma.creditCardStatement.updateMany({
      where: {
        status: { in: [StatementStatus.DUE, StatementStatus.PARTIALLY_PAID] },
        dueDate: { lt: today },
      },
      data: { status: StatementStatus.OVERDUE },
    });
    if (result.count > 0) {
      this.logger.log(`${result.count} ekstre OVERDUE olarak işaretlendi`);
    }
    return result.count;
  }

  // -----------------------------------------------------------------
  // Yardımcı/private
  // -----------------------------------------------------------------

  private async computeCurrentPeriod(
    account: { id: string; statementDay: number | null; createdAt: Date },
    lastClosed: { periodEnd: Date } | null,
  ) {
    const today = startOfDay(new Date());
    const periodStart = lastClosed
      ? addDays(startOfDay(lastClosed.periodEnd), 1)
      : startOfDay(account.createdAt);
    const periodEnd = computeNextCutoff(today, account.statementDay ?? 1);

    const txAgg = await this.prisma.transaction.aggregate({
      where: {
        accountId: account.id,
        type: TransactionType.EXPENSE,
        transactionDate: {
          gte: periodStart,
          lte: endOfDay(today),
        },
      },
      _sum: { amount: true },
      _count: true,
    });

    return {
      periodStart: periodStart.toISOString().slice(0, 10),
      periodEnd: periodEnd.toISOString().slice(0, 10),
      spentAmount: Number(txAgg._sum.amount ?? 0),
      transactionCount: txAgg._count,
    };
  }

  private async findOwnedCreditCard(userId: string, accountId: string) {
    const account = await this.prisma.account.findFirst({
      where: { id: accountId, userId, type: AccountType.CREDIT_CARD },
    });
    if (!account) {
      throw new NotFoundException('Kredi kartı hesabı bulunamadı');
    }
    return account;
  }

  private async findOwnedStatement(userId: string, statementId: string) {
    const statement = await this.prisma.creditCardStatement.findFirst({
      where: { id: statementId, account: { userId } },
    });
    if (!statement) throw new NotFoundException('Ekstre bulunamadı');
    return statement;
  }

  private format(s: {
    id: string;
    accountId: string;
    periodStart: Date;
    periodEnd: Date;
    dueDate: Date;
    totalAmount: unknown;
    minimumPayment: unknown;
    paidAmount: unknown;
    status: StatementStatus;
    closedAt: Date;
  }) {
    return {
      id: s.id,
      accountId: s.accountId,
      periodStart: s.periodStart.toISOString().slice(0, 10),
      periodEnd: s.periodEnd.toISOString().slice(0, 10),
      dueDate: s.dueDate.toISOString().slice(0, 10),
      totalAmount: Number(s.totalAmount),
      minimumPayment: Number(s.minimumPayment),
      paidAmount: Number(s.paidAmount),
      remainingAmount: Number(s.totalAmount) - Number(s.paidAmount),
      status: s.status,
      closedAt: s.closedAt.toISOString(),
    };
  }
}

// =============================================
// Tarih yardımcıları — module-private
// =============================================

function startOfDay(d: Date): Date {
  const x = new Date(d);
  x.setHours(0, 0, 0, 0);
  return x;
}

function endOfDay(d: Date): Date {
  const x = new Date(d);
  x.setHours(23, 59, 59, 999);
  return x;
}

function endOfMonth(d: Date): Date {
  return new Date(d.getFullYear(), d.getMonth() + 1, 0);
}

function addDays(d: Date, n: number): Date {
  const x = new Date(d);
  x.setDate(x.getDate() + n);
  return x;
}

function isSameDay(a: Date, b: Date): boolean {
  return (
    a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate()
  );
}

/**
 * `cutoffDate`'ten sonra gelen ilk `dueDay`. Eğer dueDay > cutoffDate.day ise
 * aynı ay, değilse bir sonraki ay. Hedef ayda `dueDay` o ayın gün sayısından
 * büyükse ay sonuna sıkıştırılır (örn. dueDay=31, Şubat → 28/29).
 */
function computeDueDate(cutoffDate: Date, dueDay: number): Date {
  let year = cutoffDate.getFullYear();
  let month = cutoffDate.getMonth();
  if (dueDay <= cutoffDate.getDate()) {
    month += 1;
    if (month > 11) {
      month = 0;
      year += 1;
    }
  }
  const lastDayOfMonth = new Date(year, month + 1, 0).getDate();
  const day = Math.min(dueDay, lastDayOfMonth);
  return new Date(year, month, day);
}

/**
 * `today`'den sonra (today dahil) gelen ilk `statementDay`. Mevcut dönemi
 * göstermek için periodEnd hesaplamasında kullanılır.
 */
function computeNextCutoff(today: Date, statementDay: number): Date {
  let year = today.getFullYear();
  let month = today.getMonth();
  if (statementDay < today.getDate()) {
    month += 1;
    if (month > 11) {
      month = 0;
      year += 1;
    }
  }
  const lastDayOfMonth = new Date(year, month + 1, 0).getDate();
  const day = Math.min(statementDay, lastDayOfMonth);
  return new Date(year, month, day);
}
