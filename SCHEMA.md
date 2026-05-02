# Stitch Wallet App — Veritabanı Şeması

> **Referans Dosyası** — Tüm Prisma modelleri, enum'lar, ER diyagramı ve kategori sistemi.
> Bu dosya hem V1 hem V2 tarafından kullanılır.
> 
> **İlişkili dosyalar:**
> - `DEVELOPMENT_PLAN_V1.md` — Temel özellikler (Sprint 0-8)
> - `DEVELOPMENT_PLAN_V2.md` — İleri özellikler (Sprint 9-12)
> - `TASK.md` — Görev takibi

---

## 2. Veritabanı Şeması (MySQL)

```prisma
// =============================================
// prisma/schema.prisma
// KONSOLİDE ŞEMA — Tüm modüller dahil (Bölüm 8.x ile senkronize)
// =============================================

generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "mysql"
  url      = env("DATABASE_URL")
}

// =============================================
// ENUM TANIMLARI
// =============================================

enum AccountType {
  BANK
  CASH
  CREDIT_CARD
  INVESTMENT
}

enum CategoryType {
  INCOME
  EXPENSE
  BOTH
}

enum TransactionType {
  INCOME
  EXPENSE
  TRANSFER
}

/// İşlemin kaynağını belirtir — raporlarda filtreleme ve ayrım için
enum TransactionSource {
  MANUAL          // Kullanıcı elle ekledi
  RECURRING       // Tekrarlayan işlem şablonundan otomatik oluştu
  DEBT_PAYMENT    // Borç ödemesi sonucu oluştu (EXPENSE)
  DEBT_COLLECTION // Alacak tahsilatı sonucu oluştu (INCOME — gerçek gelir değil)
  SUBSCRIPTION    // Abonelik yenilemesi sonucu oluştu (EXPENSE)
}

enum BudgetPeriod {
  WEEKLY
  MONTHLY
  YEARLY
}

enum DebtType {
  LENT      // alacak (verdiğin borç)
  BORROWED  // borç (aldığın borç)
}

enum DebtStatus {
  PENDING
  PAID
  OVERDUE
}

enum SubscriptionPeriod {
  WEEKLY
  MONTHLY
  YEARLY
}

enum RecurrenceFrequency {
  DAILY
  WEEKLY
  MONTHLY
  YEARLY
}

enum ReceiptStatus {
  PROCESSING   // OCR devam ediyor
  PARSED       // Parse başarılı, kullanıcı onayı bekliyor
  CONFIRMED    // Kullanıcı onayladı, Transaction oluşturuldu
  FAILED       // OCR/parse başarısız
}

// =============================================
// KULLANICI YÖNETİMİ
// =============================================

model User {
  id                    String   @id @default(uuid()) @db.VarChar(36)
  fullName              String   @map("full_name") @db.VarChar(100)
  email                 String   @unique @db.VarChar(255)
  passwordHash          String   @map("password_hash") @db.VarChar(255)
  avatarUrl             String?  @map("avatar_url") @db.VarChar(500)
  currency              String   @default("TRY") @db.VarChar(3)
  language              String   @default("tr") @db.VarChar(5)
  biometricEnabled      Boolean  @default(false) @map("biometric_enabled")
  notificationsEnabled  Boolean  @default(true) @map("notifications_enabled")
  googleId              String?  @map("google_id") @db.VarChar(255)
  createdAt             DateTime @default(now()) @map("created_at") @db.Timestamp(0)
  updatedAt             DateTime @updatedAt @map("updated_at") @db.Timestamp(0)

  // İlişkiler
  accounts              Account[]
  categories            Category[]
  transactions          Transaction[]
  budgets               Budget[]
  debts                 Debt[]
  subscriptions         Subscription[]
  receipts              Receipt[]
  passwordResetTokens   PasswordResetToken[]
  tags                  Tag[]
  recurringTransactions RecurringTransaction[]
  merchantCategoryMaps  MerchantCategoryMap[]
  insights              Insight[]
  familyMembers         FamilyMember[]

  @@map("users")
}

model PasswordResetToken {
  id        String   @id @default(uuid()) @db.VarChar(36)
  userId    String   @map("user_id") @db.VarChar(36)
  token     String   @unique @db.VarChar(255)
  expiresAt DateTime @map("expires_at") @db.Timestamp(0)
  used      Boolean  @default(false)
  createdAt DateTime @default(now()) @map("created_at") @db.Timestamp(0)

  // İlişkiler
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@map("password_reset_tokens")
}

// =============================================
// HESAPLAR (Banka / Nakit / Kredi Kartı / Yatırım)
// =============================================

model Account {
  id              String      @id @default(uuid()) @db.VarChar(36)
  userId          String      @map("user_id") @db.VarChar(36)
  name            String      @db.VarChar(100)              /// "Ziraat Bankası", "Nakit Cüzdan"
  type            AccountType
  balance         Decimal     @default(0.00) @db.Decimal(15, 2)
  icon            String?     @db.VarChar(50)
  color           String?     @db.VarChar(7)                /// hex renk
  isActive        Boolean     @default(true) @map("is_active")
  isDefault       Boolean     @default(false) @map("is_default")
  isArchived      Boolean     @default(false) @map("is_archived")

  // Kredi kartına özel alanlar
  creditLimit     Decimal?    @map("credit_limit") @db.Decimal(15, 2)   /// ₺10.000
  statementDay    Int?        @map("statement_day")                      /// ekstre kesim günü (1-28)
  paymentDueDay   Int?        @map("payment_due_day")                    /// son ödeme günü (1-28)

  createdAt       DateTime    @default(now()) @map("created_at") @db.Timestamp(0)
  updatedAt       DateTime    @updatedAt @map("updated_at") @db.Timestamp(0)

  // İlişkiler
  user                  User                   @relation(fields: [userId], references: [id], onDelete: Cascade)
  transactions          Transaction[]          @relation("AccountTransactions")
  transfersReceived     Transaction[]          @relation("TransferToAccount")
  recurringTransactions RecurringTransaction[]
  subscriptions         Subscription[]
  portfolioAssets       PortfolioAsset[]

  @@index([userId, isActive, isArchived], map: "idx_accounts_user_active")
  @@map("accounts")
}

// =============================================
// KATEGORİLER
// =============================================

model Category {
  id        String       @id @default(uuid()) @db.VarChar(36)
  userId    String?      @map("user_id") @db.VarChar(36)     /// NULL = sistem kategorisi
  parentId  String?      @map("parent_id") @db.VarChar(36)   /// NULL = ana kategori, dolu = alt kategori
  name      String       @db.VarChar(50)                      /// "Market", "Ulaşım", "Eğlence"
  icon      String       @db.VarChar(50)
  color     String       @db.VarChar(7)
  type      CategoryType
  isSystem  Boolean      @default(false) @map("is_system")
  sortOrder Int          @default(0) @map("sort_order")
  createdAt DateTime     @default(now()) @map("created_at") @db.Timestamp(0)

  // İlişkiler (self-referencing tree)
  parent               Category?            @relation("CategoryTree", fields: [parentId], references: [id], onDelete: SetNull)
  children             Category[]           @relation("CategoryTree")

  user                 User?                @relation(fields: [userId], references: [id], onDelete: Cascade)
  transactions         Transaction[]
  budgets              Budget[]
  subscriptions        Subscription[]
  recurringTransactions RecurringTransaction[]
  merchantCategoryMaps MerchantCategoryMap[]
  inflationMap         CategoryInflationMap?
  sharedBudgets        SharedBudget[]

  @@index([parentId], map: "idx_categories_parent")
  @@map("categories")
}

// =============================================
// ETİKETLER (Tag Sistemi — Çoklu Etiket)
// =============================================

model Tag {
  id        String   @id @default(uuid()) @db.VarChar(36)
  userId    String?  @map("user_id") @db.VarChar(36)      /// NULL = sistem etiketi
  name      String   @db.VarChar(50)                       /// "Temel İhtiyaç", "Sabit Gider"
  icon      String?  @db.VarChar(50)
  color     String   @db.VarChar(7)
  isSystem  Boolean  @default(false) @map("is_system")
  createdAt DateTime @default(now()) @map("created_at") @db.Timestamp(0)

  // İlişkiler
  user         User?            @relation(fields: [userId], references: [id], onDelete: Cascade)
  transactions TransactionTag[]

  @@unique([userId, name])
  @@map("tags")
}

model TransactionTag {
  transactionId String @map("transaction_id") @db.VarChar(36)
  tagId         String @map("tag_id") @db.VarChar(36)

  transaction Transaction @relation(fields: [transactionId], references: [id], onDelete: Cascade)
  tag         Tag         @relation(fields: [tagId], references: [id], onDelete: Cascade)

  @@id([transactionId, tagId])
  @@map("transaction_tags")
}

// =============================================
// İŞLEMLER (Gelir / Gider / Transfer)
// =============================================

model Transaction {
  id                   String            @id @default(uuid()) @db.VarChar(36)
  userId               String            @map("user_id") @db.VarChar(36)
  accountId            String            @map("account_id") @db.VarChar(36)
  categoryId           String?           @map("category_id") @db.VarChar(36)
  type                 TransactionType
  source               TransactionSource @default(MANUAL)
  amount               Decimal           @db.Decimal(15, 2)
  title                String            @db.VarChar(200)    /// "Migros market"
  note                 String?           @db.Text
  transactionDate      DateTime          @default(now()) @map("transaction_date") @db.Timestamp(0)
  receiptUrl           String?           @map("receipt_url") @db.VarChar(500)
  transferToAccountId  String?           @map("transfer_to_account_id") @db.VarChar(36)
  relatedDebtId        String?           @map("related_debt_id") @db.VarChar(36)
  relatedSubId         String?           @map("related_subscription_id") @db.VarChar(36)
  createdAt            DateTime          @default(now()) @map("created_at") @db.Timestamp(0)
  updatedAt            DateTime          @updatedAt @map("updated_at") @db.Timestamp(0)

  // İlişkiler
  user                User          @relation(fields: [userId], references: [id], onDelete: Cascade)
  account             Account       @relation("AccountTransactions", fields: [accountId], references: [id])
  category            Category?     @relation(fields: [categoryId], references: [id])
  transferToAccount   Account?      @relation("TransferToAccount", fields: [transferToAccountId], references: [id])
  relatedDebt         Debt?         @relation(fields: [relatedDebtId], references: [id])
  relatedSubscription Subscription? @relation(fields: [relatedSubId], references: [id])
  receipts            Receipt[]
  tags                TransactionTag[]

  @@index([userId, transactionDate], map: "idx_transactions_user_date")
  @@index([userId, type], map: "idx_transactions_user_type")
  @@index([categoryId], map: "idx_transactions_category")
  @@index([relatedDebtId], map: "idx_transactions_debt")
  @@index([relatedSubId], map: "idx_transactions_sub")
  @@map("transactions")
}

// =============================================
// TEKRARLAYAN İŞLEM ŞABLONLARI
// =============================================

model RecurringTransaction {
  id            String              @id @default(uuid()) @db.VarChar(36)
  userId        String              @map("user_id") @db.VarChar(36)
  accountId     String              @map("account_id") @db.VarChar(36)
  categoryId    String?             @map("category_id") @db.VarChar(36)
  type          TransactionType
  amount        Decimal             @db.Decimal(15, 2)
  title         String              @db.VarChar(200)     /// "Kira Ödemesi"
  note          String?             @db.Text
  frequency     RecurrenceFrequency                      /// MONTHLY, WEEKLY, vb.
  startDate     DateTime            @map("start_date") @db.Date
  endDate       DateTime?           @map("end_date") @db.Date   /// NULL = süresiz
  nextRunDate   DateTime            @map("next_run_date") @db.Date
  isActive      Boolean             @default(true) @map("is_active")
  createdAt     DateTime            @default(now()) @map("created_at") @db.Timestamp(0)
  updatedAt     DateTime            @updatedAt @map("updated_at") @db.Timestamp(0)

  // İlişkiler
  user     User      @relation(fields: [userId], references: [id], onDelete: Cascade)
  account  Account   @relation(fields: [accountId], references: [id])
  category Category? @relation(fields: [categoryId], references: [id])

  @@index([nextRunDate, isActive], map: "idx_recurring_next_run")
  @@map("recurring_transactions")
}

// =============================================
// BÜTÇELER
// =============================================

model Budget {
  id            String       @id @default(uuid()) @db.VarChar(36)
  userId        String       @map("user_id") @db.VarChar(36)
  categoryId    String       @map("category_id") @db.VarChar(36)
  name          String       @db.VarChar(100)              /// "Aylık Market Bütçesi"
  amount        Decimal      @db.Decimal(15, 2)            /// limit tutarı
  spent         Decimal      @default(0.00) @db.Decimal(15, 2) /// harcanan (cache — event ile güncellenir)
  period        BudgetPeriod @default(MONTHLY)
  note          String?      @db.Text
  smartTracking Boolean      @default(true) @map("smart_tracking") /// %80 bildirim
  isActive      Boolean      @default(true) @map("is_active")
  startDate     DateTime     @map("start_date") @db.Date
  endDate       DateTime?    @map("end_date") @db.Date
  createdAt     DateTime     @default(now()) @map("created_at") @db.Timestamp(0)
  updatedAt     DateTime     @updatedAt @map("updated_at") @db.Timestamp(0)

  // İlişkiler
  user     User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  category Category @relation(fields: [categoryId], references: [id])

  @@map("budgets")
}

// =============================================
// BORÇ TAKİBİ — GENİŞLETİLMİŞ (Taksit + Kısmi Ödeme)
// =============================================

model Debt {
  id              String     @id @default(uuid()) @db.VarChar(36)
  userId          String     @map("user_id") @db.VarChar(36)
  personName      String     @map("person_name") @db.VarChar(100) /// "Ahmet Yılmaz" veya "Ziraat Bankası (Kredi)"
  type            DebtType                                         /// LENT (alacak) / BORROWED (borç)
  totalAmount     Decimal    @map("total_amount") @db.Decimal(15, 2) /// toplam borç tutarı
  paidAmount      Decimal    @default(0.00) @map("paid_amount") @db.Decimal(15, 2) /// ödenen toplam
  status          DebtStatus @default(PENDING)
  dueDate         DateTime?  @map("due_date") @db.Date            /// son vade (taksitsiz borçlar için)
  note            String?    @db.Text
  hasInstallments Boolean    @default(false) @map("has_installments")
  createdAt       DateTime   @default(now()) @map("created_at") @db.Timestamp(0)
  updatedAt       DateTime   @updatedAt @map("updated_at") @db.Timestamp(0)

  // İlişkiler
  user         User              @relation(fields: [userId], references: [id], onDelete: Cascade)
  installments DebtInstallment[]
  payments     DebtPayment[]
  transactions Transaction[]     /// Bu borçla ilişkili işlemler (relatedDebtId)

  @@map("debts")
}

model DebtInstallment {
  id              String     @id @default(uuid()) @db.VarChar(36)
  debtId          String     @map("debt_id") @db.VarChar(36)
  installmentNo   Int        @map("installment_no")          /// 1, 2, 3, ... (sıra numarası)
  amount          Decimal    @db.Decimal(15, 2)               /// bu taksitin tutarı
  paidAmount      Decimal    @default(0.00) @map("paid_amount") @db.Decimal(15, 2)
  dueDate         DateTime   @map("due_date") @db.Date        /// bu taksitin vade tarihi
  status          DebtStatus @default(PENDING)
  createdAt       DateTime   @default(now()) @map("created_at") @db.Timestamp(0)

  // İlişkiler
  debt     Debt          @relation(fields: [debtId], references: [id], onDelete: Cascade)
  payments DebtPayment[]

  @@unique([debtId, installmentNo])
  @@index([dueDate, status], map: "idx_installment_due")
  @@map("debt_installments")
}

model DebtPayment {
  id              String   @id @default(uuid()) @db.VarChar(36)
  debtId          String   @map("debt_id") @db.VarChar(36)
  installmentId   String?  @map("installment_id") @db.VarChar(36) /// NULL = taksitsiz borç ödemesi
  accountId       String   @map("account_id") @db.VarChar(36)     /// Hangi hesaptan ödendi
  amount          Decimal  @db.Decimal(15, 2)
  paidAt          DateTime @default(now()) @map("paid_at") @db.Timestamp(0)
  note            String?  @db.Text
  createdAt       DateTime @default(now()) @map("created_at") @db.Timestamp(0)

  // İlişkiler
  debt        Debt             @relation(fields: [debtId], references: [id], onDelete: Cascade)
  installment DebtInstallment? @relation(fields: [installmentId], references: [id], onDelete: Cascade)

  @@map("debt_payments")
}

// =============================================
// ABONELİKLER — GENİŞLETİLMİŞ (Hesap Bağlantılı)
// =============================================

model Subscription {
  id          String             @id @default(uuid()) @db.VarChar(36)
  userId      String             @map("user_id") @db.VarChar(36)
  name        String             @db.VarChar(100)              /// "Netflix", "Spotify"
  amount      Decimal            @db.Decimal(15, 2)
  period      SubscriptionPeriod @default(MONTHLY)
  icon        String?            @db.VarChar(50)
  color       String?            @db.VarChar(7)
  startDate   DateTime           @map("start_date") @db.Date
  nextRenewal DateTime           @map("next_renewal") @db.Date /// zorunlu — bir sonraki yenilenme
  accountId   String             @map("account_id") @db.VarChar(36) /// hangi hesaptan düşülecek
  categoryId  String?            @map("category_id") @db.VarChar(36)
  isActive    Boolean            @default(true) @map("is_active")
  autoDeduct  Boolean            @default(true) @map("auto_deduct") /// otomatik işlem oluştursun mu
  createdAt   DateTime           @default(now()) @map("created_at") @db.Timestamp(0)
  updatedAt   DateTime           @updatedAt @map("updated_at") @db.Timestamp(0)

  // İlişkiler
  user         User          @relation(fields: [userId], references: [id], onDelete: Cascade)
  account      Account       @relation(fields: [accountId], references: [id])
  category     Category?     @relation(fields: [categoryId], references: [id])
  transactions Transaction[] /// Bu abonelikle ilişkili işlemler (relatedSubId)

  @@index([nextRenewal, isActive], map: "idx_subscription_renewal")
  @@map("subscriptions")
}

// =============================================
// FİŞ TARAMA — GENİŞLETİLMİŞ (Hibrit OCR + Satır Ayrıntı)
// =============================================

model Receipt {
  id              String        @id @default(uuid()) @db.VarChar(36)
  userId          String        @map("user_id") @db.VarChar(36)
  transactionId   String?       @map("transaction_id") @db.VarChar(36)
  imageUrl        String        @map("image_url") @db.VarChar(500)
  ocrRawText      String?       @map("ocr_raw_text") @db.Text
  ocrSource       String?       @map("ocr_source") @db.VarChar(20)    /// "ON_DEVICE" | "CLOUD"
  confidence      Decimal?      @db.Decimal(3, 2)                      /// 0.00 - 1.00
  parsedAmount    Decimal?      @map("parsed_amount") @db.Decimal(15, 2)
  parsedMerchant  String?       @map("parsed_merchant") @db.VarChar(200)
  parsedDate      DateTime?     @map("parsed_date") @db.Date
  parsedTax       Decimal?      @map("parsed_tax") @db.Decimal(15, 2) /// KDV tutarı
  paymentMethod   String?       @map("payment_method") @db.VarChar(20) /// NAKİT / KREDİ KARTI
  status          ReceiptStatus @default(PROCESSING)
  createdAt       DateTime      @default(now()) @map("created_at") @db.Timestamp(0)

  // İlişkiler
  user        User          @relation(fields: [userId], references: [id], onDelete: Cascade)
  transaction Transaction?  @relation(fields: [transactionId], references: [id])
  items       ReceiptItem[]

  @@map("receipts")
}

model ReceiptItem {
  id          String  @id @default(uuid()) @db.VarChar(36)
  receiptId   String  @map("receipt_id") @db.VarChar(36)
  name        String  @db.VarChar(200)            /// "SÜTAŞ SÜZME YOĞ"
  quantity    Int     @default(1)
  unitPrice   Decimal @map("unit_price") @db.Decimal(15, 2)
  totalPrice  Decimal @map("total_price") @db.Decimal(15, 2)
  sortOrder   Int     @default(0) @map("sort_order")

  // İlişkiler
  receipt Receipt @relation(fields: [receiptId], references: [id], onDelete: Cascade)

  @@map("receipt_items")
}

// =============================================
// AKILLI KATEGORİ EŞLEŞTİRME (Merchant → Category)
// =============================================

model MerchantCategoryMap {
  id           String   @id @default(uuid()) @db.VarChar(36)
  userId       String?  @map("user_id") @db.VarChar(36)          /// NULL = global (sistem) mapping
  merchantKey  String   @map("merchant_key") @db.VarChar(100)    /// normalize edilmiş ad: "migros"
  categoryId   String   @map("category_id") @db.VarChar(36)
  hitCount     Int      @default(1) @map("hit_count")            /// kaç kez eşleştirildi
  createdAt    DateTime @default(now()) @map("created_at") @db.Timestamp(0)
  updatedAt    DateTime @updatedAt @map("updated_at") @db.Timestamp(0)

  // İlişkiler
  user     User?    @relation(fields: [userId], references: [id], onDelete: Cascade)
  category Category @relation(fields: [categoryId], references: [id])

  @@unique([userId, merchantKey])
  @@map("merchant_category_maps")
}

// =============================================
// ENFLASYON TAKİBİ (TÜİK EVDS Entegrasyonu)
// =============================================

/// Aylık enflasyon verileri (TÜİK'ten çekilir)
model InflationRate {
  id           String   @id @default(uuid()) @db.VarChar(36)
  categoryKey  String   @map("category_key") @db.VarChar(50)   /// "gida", "ulasim", "genel"
  year         Int
  month        Int                                               /// 1-12
  monthlyRate  Decimal  @map("monthly_rate") @db.Decimal(6, 2)  /// aylık % değişim (örn: 3.45)
  yearlyRate   Decimal  @map("yearly_rate") @db.Decimal(6, 2)   /// yıllık % değişim (örn: 48.21)
  fetchedAt    DateTime @default(now()) @map("fetched_at") @db.Timestamp(0)

  @@unique([categoryKey, year, month])
  @@map("inflation_rates")
}

/// Kategori → TÜİK eşleştirme tablosu
model CategoryInflationMap {
  id           String @id @default(uuid()) @db.VarChar(36)
  categoryId   String @map("category_id") @db.VarChar(36)
  inflationKey String @map("inflation_key") @db.VarChar(50)    /// InflationRate.categoryKey ile eşleşir

  category Category @relation(fields: [categoryId], references: [id])

  @@unique([categoryId])
  @@map("category_inflation_maps")
}

// =============================================
// ALTIN / DÖVİZ PORTFÖY TAKİBİ
// =============================================

enum AssetType {
  USD
  EUR
  GBP
  GOLD_GRAM        // gram altın
  GOLD_QUARTER      // çeyrek altın
  GOLD_HALF         // yarım altın
  GOLD_FULL         // tam altın
}

/// Yatırım hesabındaki varlık kalemleri
model PortfolioAsset {
  id            String    @id @default(uuid()) @db.VarChar(36)
  accountId     String    @map("account_id") @db.VarChar(36)       /// INVESTMENT tipindeki hesap
  assetType     AssetType @map("asset_type")
  quantity      Decimal   @db.Decimal(15, 4)                       /// 3.5 gram altın, 500 USD
  avgBuyPrice   Decimal   @map("avg_buy_price") @db.Decimal(15, 4) /// ortalama alış fiyatı (TL)
  totalCost     Decimal   @map("total_cost") @db.Decimal(15, 2)    /// toplam maliyet (TL)
  createdAt     DateTime  @default(now()) @map("created_at") @db.Timestamp(0)
  updatedAt     DateTime  @updatedAt @map("updated_at") @db.Timestamp(0)

  // İlişkiler
  account      Account           @relation(fields: [accountId], references: [id], onDelete: Cascade)
  transactions PortfolioTx[]

  @@unique([accountId, assetType])
  @@map("portfolio_assets")
}

/// Alım/satım işlem geçmişi
model PortfolioTx {
  id            String    @id @default(uuid()) @db.VarChar(36)
  assetId       String    @map("asset_id") @db.VarChar(36)
  type          String    @db.VarChar(4)                           /// "BUY" | "SELL"
  quantity      Decimal   @db.Decimal(15, 4)
  pricePerUnit  Decimal   @map("price_per_unit") @db.Decimal(15, 4) /// birim fiyat (TL)
  totalAmount   Decimal   @map("total_amount") @db.Decimal(15, 2)
  txDate        DateTime  @map("tx_date") @db.Timestamp(0)
  note          String?   @db.Text
  createdAt     DateTime  @default(now()) @map("created_at") @db.Timestamp(0)

  // İlişkiler
  asset PortfolioAsset @relation(fields: [assetId], references: [id], onDelete: Cascade)

  @@map("portfolio_transactions")
}

/// Kur/fiyat cache tablosu (saatlik güncelleme)
model ExchangeRate {
  id          String    @id @default(uuid()) @db.VarChar(36)
  assetType   AssetType @map("asset_type")
  buyPrice    Decimal   @map("buy_price") @db.Decimal(15, 4)    /// alış fiyatı (TL)
  sellPrice   Decimal   @map("sell_price") @db.Decimal(15, 4)   /// satış fiyatı (TL)
  fetchedAt   DateTime  @default(now()) @map("fetched_at") @db.Timestamp(0)

  @@unique([assetType])
  @@map("exchange_rates")
}

// =============================================
// AKILLI HARCAMA ANALİZİ (Insight Engine)
// =============================================

/// Üretilen insight'lar (kullanıcıya gösterilmek üzere)
model Insight {
  id          String   @id @default(uuid()) @db.VarChar(36)
  userId      String   @map("user_id") @db.VarChar(36)
  ruleId      String   @map("rule_id") @db.VarChar(50)       /// "spending_spike", "unused_subscription"
  title       String   @db.VarChar(200)                       /// Insight başlığı
  message     String   @db.Text                                /// Detaylı mesaj
  category    String?  @db.VarChar(50)                         /// İlgili kategori (opsiyonel)
  severity    String   @db.VarChar(10)                         /// "info" | "warning" | "success"
  data        String?  @db.Text                                /// JSON — ek veri (grafikler için)
  isRead      Boolean  @default(false) @map("is_read")
  isDismissed Boolean  @default(false) @map("is_dismissed")
  period      String   @db.VarChar(7)                          /// "2026-04" (hangi ay için)
  createdAt   DateTime @default(now()) @map("created_at") @db.Timestamp(0)

  // İlişkiler
  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId, period, isDismissed], map: "idx_insights_user_period")
  @@map("insights")
}

// =============================================
// AİLE / ORTAK BÜTÇE
// =============================================

enum FamilyRole {
  OWNER    // grubu oluşturan
  MEMBER   // davet edilen
}

enum InviteStatus {
  PENDING
  ACCEPTED
  REJECTED
  EXPIRED
}

/// Aile / ortak bütçe grubu
model FamilyGroup {
  id        String   @id @default(uuid()) @db.VarChar(36)
  name      String   @db.VarChar(100)                        /// "Ev Bütçesi", "Aile"
  icon      String?  @db.VarChar(50)
  createdAt DateTime @default(now()) @map("created_at") @db.Timestamp(0)
  updatedAt DateTime @updatedAt @map("updated_at") @db.Timestamp(0)

  // İlişkiler
  members        FamilyMember[]
  sharedBudgets  SharedBudget[]
  invites        FamilyInvite[]

  @@map("family_groups")
}

/// Grup üyeleri
model FamilyMember {
  id        String     @id @default(uuid()) @db.VarChar(36)
  groupId   String     @map("group_id") @db.VarChar(36)
  userId    String     @map("user_id") @db.VarChar(36)
  role      FamilyRole @default(MEMBER)
  joinedAt  DateTime   @default(now()) @map("joined_at") @db.Timestamp(0)

  // İlişkiler
  group FamilyGroup @relation(fields: [groupId], references: [id], onDelete: Cascade)
  user  User        @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([groupId, userId])
  @@map("family_members")
}

/// Davet sistemi
model FamilyInvite {
  id        String       @id @default(uuid()) @db.VarChar(36)
  groupId   String       @map("group_id") @db.VarChar(36)
  invitedBy String       @map("invited_by") @db.VarChar(36)   /// davet eden userId
  email     String       @db.VarChar(255)                      /// davet edilen e-posta
  token     String       @unique @db.VarChar(255)
  status    InviteStatus @default(PENDING)
  expiresAt DateTime     @map("expires_at") @db.Timestamp(0)
  createdAt DateTime     @default(now()) @map("created_at") @db.Timestamp(0)

  // İlişkiler
  group FamilyGroup @relation(fields: [groupId], references: [id], onDelete: Cascade)

  @@map("family_invites")
}

/// Ortak bütçe
model SharedBudget {
  id            String       @id @default(uuid()) @db.VarChar(36)
  groupId       String       @map("group_id") @db.VarChar(36)
  categoryId    String       @map("category_id") @db.VarChar(36)
  name          String       @db.VarChar(100)                    /// "Ev Market Bütçesi"
  amount        Decimal      @db.Decimal(15, 2)
  spent         Decimal      @default(0.00) @db.Decimal(15, 2)
  period        BudgetPeriod @default(MONTHLY)
  startDate     DateTime     @map("start_date") @db.Date
  endDate       DateTime?    @map("end_date") @db.Date
  isActive      Boolean      @default(true) @map("is_active")
  createdAt     DateTime     @default(now()) @map("created_at") @db.Timestamp(0)
  updatedAt     DateTime     @updatedAt @map("updated_at") @db.Timestamp(0)

  // İlişkiler
  group    FamilyGroup @relation(fields: [groupId], references: [id], onDelete: Cascade)
  category Category    @relation(fields: [categoryId], references: [id])
  expenses SharedExpense[]

  @@map("shared_budgets")
}

/// Ortak bütçeye düşen harcamalar
model SharedExpense {
  id             String   @id @default(uuid()) @db.VarChar(36)
  sharedBudgetId String   @map("shared_budget_id") @db.VarChar(36)
  transactionId  String   @map("transaction_id") @db.VarChar(36)
  userId         String   @map("user_id") @db.VarChar(36)          /// harcamayı yapan üye
  amount         Decimal  @db.Decimal(15, 2)
  createdAt      DateTime @default(now()) @map("created_at") @db.Timestamp(0)

  // İlişkiler
  sharedBudget SharedBudget @relation(fields: [sharedBudgetId], references: [id], onDelete: Cascade)

  @@map("shared_expenses")
}
```

> **MySQL Notları:**
> - UUID'ler `@db.VarChar(36)` olarak saklanır (MySQL'de native UUID tipi yoktur)
> - Timestamp'ler `@db.Timestamp(0)` kullanır (`@db.Timestamptz` PostgreSQL'e özgüdür, MySQL'de desteklenmez)
> - MySQL'de `sort: Desc` index ifadesi desteklenmez, `@@index` tanımlarından kaldırıldı

### 2.1 Entity-Relationship Özet

```
User ─┬─< Account ─────────────< Transaction (AccountTransactions)
      │                         ├─< Transaction (TransferToAccount)
      │                         ├─< RecurringTransaction
      │                         ├─< Subscription
      │                         └─< PortfolioAsset ──< PortfolioTx
      │
      ├─< Transaction ──────────> Account, Category, Debt?, Subscription?
      │                         └─< TransactionTag ──> Tag
      │
      ├─< Tag ──────────────────< TransactionTag
      ├─< RecurringTransaction ─> Account, Category
      │
      ├─< Budget ──────────────> Category
      │
      ├─< Debt ────────────────< DebtInstallment ──< DebtPayment
      │                         └─< DebtPayment (taksitsiz)
      │
      ├─< Subscription ────────> Account, Category
      │
      ├─< Receipt ─────────────> Transaction?
      │                         └─< ReceiptItem
      │
      ├─< Category (kullanıcı özel) ──< MerchantCategoryMap
      │                         ├─? CategoryInflationMap ──> InflationRate (categoryKey ile)
      │                         └─< SharedBudget
      │
      ├─< MerchantCategoryMap
      ├─< Insight
      ├─< FamilyMember ────────> FamilyGroup
      ├─< PasswordResetToken
      │
      │   (Bağımsız tablolar)
      ├── InflationRate (TÜİK TÜFE verileri)
      └── ExchangeRate (TCMB kur/altın verileri)

FamilyGroup ─┬─< FamilyMember ──> User
             ├─< SharedBudget ──> Category
             │                  └─< SharedExpense
             └─< FamilyInvite
```

> **Toplam: 27 model, 13 enum**

### 2.2 Prisma Kullanım Notları

NestJS tarafında Prisma entegrasyonu için `prisma/schema.prisma` dosyası projenin kök dizininde yer alır. Temel komutlar:

```bash
# Prisma client oluştur
npx prisma generate

# Migration oluştur ve uygula
npx prisma migrate dev --name init

# Veritabanını seed'le (sistem kategorileri vb.)
npx prisma db seed

# Prisma Studio (veritabanı görsel arayüzü)
npx prisma studio
```

NestJS'de `PrismaService` olarak sarmalanır:

```typescript
// src/prisma/prisma.service.ts
import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  async onModuleInit() {
    await this.$connect();
  }
  async onModuleDestroy() {
    await this.$disconnect();
  }
}
```

### 2.3 Kategori Sistemi

Uygulama **2 seviyeli hiyerarşik** kategori yapısı kullanır: Ana Kategori → Alt Kategori. `parentId` ile self-referencing ağaç yapısı oluşturulur.

#### Tasarım Kuralları

1. **Sistem kategorileri** (`isSystem: true`, `userId: null`) seed ile oluşturulur, silinemez
2. **Kullanıcı kategorileri** (`isSystem: false`, `userId: xxx`) kullanıcı tarafından eklenir/silinir
3. **Alt kategoriler** ana kategorinin `type` (INCOME/EXPENSE) değerini miras alır
4. **İşlem kaydında:** Kullanıcı ya ana ya da alt kategori seçebilir (ikisi de geçerli)
5. **Raporlama:** Alt kategori seçilmişse, ana kategoriye de dahil edilir (roll-up)
6. **Bütçe:** Bütçe her zaman ana kategoriye bağlanır (alt kategoriler otomatik dahil)

#### Sistem Kategorileri — GİDER (EXPENSE)

| # | Ana Kategori | İkon | Renk | Alt Kategoriler | TÜİK Eşleşme |
|---|---|---|---|---|---|
| 1 | Market | 🛒 | #4CAF50 | Migros, BİM, A101, Şok, Diğer Market | Gıda ve alkolsüz içecekler |
| 2 | Ulaşım | 🚗 | #2196F3 | Benzin, Toplu Taşıma, Taksi, Otopark, Bakım/Servis | Ulaştırma |
| 3 | Yeme-İçme | 🍽️ | #FF9800 | Restoran, Kafe, Fast Food, Yemek Siparişi | Lokanta ve oteller |
| 4 | Faturalar | 💡 | #9C27B0 | Elektrik, Su, Doğalgaz, İnternet, Telefon | Konut, su, elektrik, gaz |
| 5 | Kira / Konut | 🏠 | #795548 | Kira, Aidat, Tamir/Tadilat | Konut (kira) |
| 6 | Sağlık | 💊 | #F44336 | İlaç, Muayene, Diş, Gözlük/Lens | Sağlık |
| 7 | Eğlence | 🎬 | #E91E63 | Sinema, Konser, Oyun, Hobi, Tatil | Eğlence ve kültür |
| 8 | Alışveriş | 🛍️ | #00BCD4 | Giyim, Ayakkabı, Aksesuar, Kozmetik | Giyim ve ayakkabı |
| 9 | Eğitim | 📚 | #3F51B5 | Okul, Kurs, Kitap, Online Eğitim | Eğitim |
| 10 | Teknoloji | 💻 | #607D8B | Elektronik, Yazılım, Uygulama | Çeşitli mal ve hizmetler |
| 11 | Spor | 🏋️ | #8BC34A | Spor Salonu, Ekipman, Supplement | Eğlence ve kültür |
| 12 | Kişisel Bakım | 💈 | #FF5722 | Kuaför, Cilt Bakımı, Parfüm | Çeşitli mal ve hizmetler |
| 13 | Sigorta | 🛡️ | #455A64 | Sağlık Sigortası, Araç Sigortası, DASK | Çeşitli mal ve hizmetler |
| 14 | Ulaşım (Araç) | 🚙 | #37474F | Vergi, Muayene, Kasko | Ulaştırma |
| 15 | Hediye / Bağış | 🎁 | #AD1457 | Hediye, Bağış, Zekat/Fitre | Çeşitli mal ve hizmetler |
| 16 | Çocuk | 👶 | #FFD54F | Kreş, Oyuncak, Çocuk Giyim, Eğitim | Eğitim |
| 17 | Diğer (Gider) | 📦 | #9E9E9E | — | Genel TÜFE |

#### Sistem Kategorileri — GELİR (INCOME)

| # | Ana Kategori | İkon | Renk | Alt Kategoriler |
|---|---|---|---|---|
| 1 | Maaş | 💰 | #70D8C8 | Ana Maaş, Ek İş, Prim |
| 2 | Freelance | 💼 | #BAC3FF | Proje, Danışmanlık |
| 3 | Yatırım Geliri | 📈 | #FFD54F | Faiz, Temettü, Kira Geliri, Altın Satış |
| 4 | Devlet | 🏛️ | #A5D6A7 | Vergi İadesi, Teşvik, Burs |
| 5 | Diğer (Gelir) | 💵 | #9E9E9E | Hediye, İkinci El Satış |

#### Seed Script Yapısı

```typescript
// prisma/seed.ts
const SYSTEM_CATEGORIES = [
  {
    name: 'Market',
    icon: 'shopping_cart',     // Flutter Material Icons
    color: '#4CAF50',
    type: 'EXPENSE',
    sortOrder: 1,
    children: [
      { name: 'Migros', icon: 'store', color: '#4CAF50', sortOrder: 1 },
      { name: 'BİM', icon: 'store', color: '#4CAF50', sortOrder: 2 },
      { name: 'A101', icon: 'store', color: '#4CAF50', sortOrder: 3 },
      { name: 'Şok', icon: 'store', color: '#4CAF50', sortOrder: 4 },
      { name: 'Diğer Market', icon: 'store', color: '#4CAF50', sortOrder: 5 },
    ],
  },
  // ... diğer kategoriler aynı yapıda
];

async function seedCategories(prisma: PrismaClient) {
  for (const cat of SYSTEM_CATEGORIES) {
    const parent = await prisma.category.create({
      data: {
        name: cat.name,
        icon: cat.icon,
        color: cat.color,
        type: cat.type as CategoryType,
        isSystem: true,
        sortOrder: cat.sortOrder,
      },
    });

    if (cat.children) {
      for (const child of cat.children) {
        await prisma.category.create({
          data: {
            parentId: parent.id,
            name: child.name,
            icon: child.icon,
            color: child.color,
            type: cat.type as CategoryType, // parent'tan miras
            isSystem: true,
            sortOrder: child.sortOrder,
          },
        });
      }
    }
  }
}
```

#### API Kuralları (Categories Module)

| Kural | Açıklama |
|---|---|
| GET `/categories` | `?type=EXPENSE&parentId=null` → ana kategoriler; `?parentId=xxx` → alt kategoriler |
| POST `/categories` | Kullanıcı özel kategori ekler. `parentId` opsiyonel. `isSystem: false` otomatik set |
| DELETE `/categories/:id` | Sadece `isSystem: false` silinebilir. Alt kategoriler varsa cascade |
| Sistem kategorileri | Düzenlenemez, silinemez. Sadece `sortOrder` değiştirilebilir |
| İşlem kaydı | `categoryId` hem ana hem alt kategoriye işaret edebilir |
| Raporlama | Alt kategori seçilmişse → `WHERE categoryId = :id OR category.parentId = :id` ile roll-up |
