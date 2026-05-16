-- Transaction'a sharedBudgetId FK ekle (Kişisel/Ortak ayrımı için).
ALTER TABLE `transactions`
  ADD COLUMN `shared_budget_id` VARCHAR(36) NULL AFTER `related_subscription_id`;

ALTER TABLE `transactions`
  ADD CONSTRAINT `transactions_shared_budget_id_fkey`
  FOREIGN KEY (`shared_budget_id`) REFERENCES `shared_budgets`(`id`)
  ON DELETE SET NULL ON UPDATE CASCADE;

CREATE INDEX `idx_transactions_shared_budget` ON `transactions`(`shared_budget_id`);

-- Mevcut SharedExpense kayıtlarını Transaction.sharedBudgetId'ye taşı,
-- ardından artık ihtiyaç kalmayan tabloyu drop et.
UPDATE `transactions` t
  INNER JOIN `shared_expenses` se ON se.`transaction_id` = t.`id`
  SET t.`shared_budget_id` = se.`shared_budget_id`;

DROP TABLE `shared_expenses`;

-- SharedBudget.spent'i Transaction.sharedBudgetId uzerinden yeniden hesapla.
-- Onceden listener her kategori eslesmesinde SharedExpense uretiyordu, simdi
-- sadece kullanici acikca atadigi transaction'lar sayilir.
UPDATE `shared_budgets` sb
  LEFT JOIN (
    SELECT `shared_budget_id`, SUM(`amount`) AS total
    FROM `transactions`
    WHERE `shared_budget_id` IS NOT NULL AND `type` = 'EXPENSE'
    GROUP BY `shared_budget_id`
  ) agg ON agg.`shared_budget_id` = sb.`id`
  SET sb.`spent` = COALESCE(agg.total, 0);
