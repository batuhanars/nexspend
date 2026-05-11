-- CreateTable
CREATE TABLE `inflation_rates` (
    `id` VARCHAR(36) NOT NULL,
    `category_key` VARCHAR(50) NOT NULL,
    `year` INTEGER NOT NULL,
    `month` INTEGER NOT NULL,
    `monthly_rate` DECIMAL(6, 2) NOT NULL,
    `yearly_rate` DECIMAL(6, 2) NOT NULL,
    `fetched_at` DATETIME(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),

    UNIQUE INDEX `inflation_rates_category_key_year_month_key`(`category_key`, `year`, `month`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `category_inflation_maps` (
    `id` VARCHAR(36) NOT NULL,
    `category_id` VARCHAR(36) NOT NULL,
    `inflation_key` VARCHAR(50) NOT NULL,

    UNIQUE INDEX `category_inflation_maps_category_id_key`(`category_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `category_inflation_maps` ADD CONSTRAINT `category_inflation_maps_category_id_fkey` FOREIGN KEY (`category_id`) REFERENCES `categories`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;
