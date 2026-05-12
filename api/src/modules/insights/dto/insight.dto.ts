export class InsightDto {
  id: string;
  ruleId: string;
  title: string;
  message: string;
  category: string | null;
  severity: 'info' | 'warning' | 'success';
  data: unknown;
  isRead: boolean;
  isDismissed: boolean;
  period: string;
  createdAt: string;
}

export class InsightSummaryDto {
  unreadCount: number;
  totalCount: number;
  latestInsight: InsightDto | null;
}

export class InsightListDto {
  items: InsightDto[];
  total: number;
  page: number;
  limit: number;
}

export class GenerateInsightResultDto {
  generated: number;
  period: string;
}
