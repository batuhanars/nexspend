-- AlterTable: Remove the kind column (MySQL ENUM inline, no separate type to drop)
ALTER TABLE `subscriptions` DROP COLUMN `kind`;
