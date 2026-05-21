-- Mevcut NULL olan end_date değerlerini period + start_date'ten hesapla (backfill)
UPDATE `budgets` SET `end_date` = CASE `period`
  WHEN 'WEEKLY'  THEN DATE_ADD(`start_date`, INTERVAL 6 DAY)
  WHEN 'MONTHLY' THEN DATE_SUB(DATE_ADD(`start_date`, INTERVAL 1 MONTH), INTERVAL 1 DAY)
  WHEN 'YEARLY'  THEN DATE_SUB(DATE_ADD(`start_date`, INTERVAL 1 YEAR), INTERVAL 1 DAY)
END
WHERE `end_date` IS NULL;

UPDATE `shared_budgets` SET `end_date` = CASE `period`
  WHEN 'WEEKLY'  THEN DATE_ADD(`start_date`, INTERVAL 6 DAY)
  WHEN 'MONTHLY' THEN DATE_SUB(DATE_ADD(`start_date`, INTERVAL 1 MONTH), INTERVAL 1 DAY)
  WHEN 'YEARLY'  THEN DATE_SUB(DATE_ADD(`start_date`, INTERVAL 1 YEAR), INTERVAL 1 DAY)
END
WHERE `end_date` IS NULL;

-- end_date sütunlarını NOT NULL yap
ALTER TABLE `budgets` MODIFY `end_date` DATE NOT NULL;
ALTER TABLE `shared_budgets` MODIFY `end_date` DATE NOT NULL;

-- Cron için index: süresi geçmiş aktif bütçeleri hızlı bul
CREATE INDEX `idx_budget_endDate_active` ON `budgets`(`end_date`, `is_active`);
-- History için index: aynı user+category geçmiş dönemleri
CREATE INDEX `idx_budget_history` ON `budgets`(`user_id`, `category_id`, `end_date`);

-- SharedBudget cron index
CREATE INDEX `idx_sb_endDate_active` ON `shared_budgets`(`end_date`, `is_active`);
-- SharedBudget history index
CREATE INDEX `idx_sb_history` ON `shared_budgets`(`group_id`, `category_id`, `end_date`);
