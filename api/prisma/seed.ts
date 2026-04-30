import 'dotenv/config';
import { PrismaClient } from '@prisma/client';
import { PrismaMariaDb } from '@prisma/adapter-mariadb';

type CategoryType = 'INCOME' | 'EXPENSE' | 'BOTH';

const adapter = new PrismaMariaDb(process.env['DATABASE_URL'] as string);
const prisma = new (PrismaClient as any)({ adapter }) as InstanceType<typeof PrismaClient>;

// =============================================
// KATEGORİ SEED DATA
// =============================================

interface ChildCategory {
  name: string;
  icon: string;
  color: string;
  sortOrder: number;
}

interface ParentCategory {
  name: string;
  icon: string;
  color: string;
  type: CategoryType;
  sortOrder: number;
  inflationKey?: string;
  children?: ChildCategory[];
}

const EXPENSE_CATEGORIES: ParentCategory[] = [
  {
    name: 'Market',
    icon: 'shopping_cart',
    color: '#4CAF50',
    type: 'EXPENSE',
    sortOrder: 1,
    inflationKey: 'gida',
    children: [
      { name: 'Migros', icon: 'store', color: '#4CAF50', sortOrder: 1 },
      { name: 'BİM', icon: 'store', color: '#4CAF50', sortOrder: 2 },
      { name: 'A101', icon: 'store', color: '#4CAF50', sortOrder: 3 },
      { name: 'Şok', icon: 'store', color: '#4CAF50', sortOrder: 4 },
      { name: 'Diğer Market', icon: 'store', color: '#4CAF50', sortOrder: 5 },
    ],
  },
  {
    name: 'Ulaşım',
    icon: 'directions_car',
    color: '#2196F3',
    type: 'EXPENSE',
    sortOrder: 2,
    inflationKey: 'ulasim',
    children: [
      { name: 'Benzin', icon: 'local_gas_station', color: '#2196F3', sortOrder: 1 },
      { name: 'Toplu Taşıma', icon: 'directions_bus', color: '#2196F3', sortOrder: 2 },
      { name: 'Taksi', icon: 'local_taxi', color: '#2196F3', sortOrder: 3 },
      { name: 'Otopark', icon: 'local_parking', color: '#2196F3', sortOrder: 4 },
      { name: 'Bakım/Servis', icon: 'build', color: '#2196F3', sortOrder: 5 },
    ],
  },
  {
    name: 'Yeme-İçme',
    icon: 'restaurant',
    color: '#FF9800',
    type: 'EXPENSE',
    sortOrder: 3,
    inflationKey: 'lokanta',
    children: [
      { name: 'Restoran', icon: 'restaurant', color: '#FF9800', sortOrder: 1 },
      { name: 'Kafe', icon: 'local_cafe', color: '#FF9800', sortOrder: 2 },
      { name: 'Fast Food', icon: 'fastfood', color: '#FF9800', sortOrder: 3 },
      { name: 'Yemek Siparişi', icon: 'delivery_dining', color: '#FF9800', sortOrder: 4 },
    ],
  },
  {
    name: 'Faturalar',
    icon: 'receipt_long',
    color: '#9C27B0',
    type: 'EXPENSE',
    sortOrder: 4,
    inflationKey: 'konut',
    children: [
      { name: 'Elektrik', icon: 'bolt', color: '#9C27B0', sortOrder: 1 },
      { name: 'Su', icon: 'water_drop', color: '#9C27B0', sortOrder: 2 },
      { name: 'Doğalgaz', icon: 'local_fire_department', color: '#9C27B0', sortOrder: 3 },
      { name: 'İnternet', icon: 'wifi', color: '#9C27B0', sortOrder: 4 },
      { name: 'Telefon', icon: 'phone', color: '#9C27B0', sortOrder: 5 },
    ],
  },
  {
    name: 'Kira / Konut',
    icon: 'home',
    color: '#795548',
    type: 'EXPENSE',
    sortOrder: 5,
    inflationKey: 'konut',
    children: [
      { name: 'Kira', icon: 'home', color: '#795548', sortOrder: 1 },
      { name: 'Aidat', icon: 'apartment', color: '#795548', sortOrder: 2 },
      { name: 'Tamir/Tadilat', icon: 'handyman', color: '#795548', sortOrder: 3 },
    ],
  },
  {
    name: 'Sağlık',
    icon: 'local_hospital',
    color: '#F44336',
    type: 'EXPENSE',
    sortOrder: 6,
    inflationKey: 'saglik',
    children: [
      { name: 'İlaç', icon: 'medication', color: '#F44336', sortOrder: 1 },
      { name: 'Muayene', icon: 'medical_services', color: '#F44336', sortOrder: 2 },
      { name: 'Diş', icon: 'dental_care', color: '#F44336', sortOrder: 3 },
      { name: 'Gözlük/Lens', icon: 'visibility', color: '#F44336', sortOrder: 4 },
    ],
  },
  {
    name: 'Eğlence',
    icon: 'movie',
    color: '#E91E63',
    type: 'EXPENSE',
    sortOrder: 7,
    inflationKey: 'eglence',
    children: [
      { name: 'Sinema', icon: 'local_movies', color: '#E91E63', sortOrder: 1 },
      { name: 'Konser', icon: 'music_note', color: '#E91E63', sortOrder: 2 },
      { name: 'Oyun', icon: 'sports_esports', color: '#E91E63', sortOrder: 3 },
      { name: 'Hobi', icon: 'palette', color: '#E91E63', sortOrder: 4 },
      { name: 'Tatil', icon: 'beach_access', color: '#E91E63', sortOrder: 5 },
    ],
  },
  {
    name: 'Alışveriş',
    icon: 'shopping_bag',
    color: '#00BCD4',
    type: 'EXPENSE',
    sortOrder: 8,
    inflationKey: 'giyim',
    children: [
      { name: 'Giyim', icon: 'checkroom', color: '#00BCD4', sortOrder: 1 },
      { name: 'Ayakkabı', icon: 'steps', color: '#00BCD4', sortOrder: 2 },
      { name: 'Aksesuar', icon: 'watch', color: '#00BCD4', sortOrder: 3 },
      { name: 'Kozmetik', icon: 'face', color: '#00BCD4', sortOrder: 4 },
    ],
  },
  {
    name: 'Eğitim',
    icon: 'school',
    color: '#3F51B5',
    type: 'EXPENSE',
    sortOrder: 9,
    inflationKey: 'egitim',
    children: [
      { name: 'Okul', icon: 'school', color: '#3F51B5', sortOrder: 1 },
      { name: 'Kurs', icon: 'class', color: '#3F51B5', sortOrder: 2 },
      { name: 'Kitap', icon: 'menu_book', color: '#3F51B5', sortOrder: 3 },
      { name: 'Online Eğitim', icon: 'laptop', color: '#3F51B5', sortOrder: 4 },
    ],
  },
  {
    name: 'Teknoloji',
    icon: 'computer',
    color: '#607D8B',
    type: 'EXPENSE',
    sortOrder: 10,
    inflationKey: 'diger',
    children: [
      { name: 'Elektronik', icon: 'devices', color: '#607D8B', sortOrder: 1 },
      { name: 'Yazılım', icon: 'code', color: '#607D8B', sortOrder: 2 },
      { name: 'Uygulama', icon: 'apps', color: '#607D8B', sortOrder: 3 },
    ],
  },
  {
    name: 'Spor',
    icon: 'fitness_center',
    color: '#8BC34A',
    type: 'EXPENSE',
    sortOrder: 11,
    inflationKey: 'eglence',
    children: [
      { name: 'Spor Salonu', icon: 'fitness_center', color: '#8BC34A', sortOrder: 1 },
      { name: 'Ekipman', icon: 'sports', color: '#8BC34A', sortOrder: 2 },
      { name: 'Supplement', icon: 'science', color: '#8BC34A', sortOrder: 3 },
    ],
  },
  {
    name: 'Kişisel Bakım',
    icon: 'spa',
    color: '#FF5722',
    type: 'EXPENSE',
    sortOrder: 12,
    inflationKey: 'diger',
    children: [
      { name: 'Kuaför', icon: 'content_cut', color: '#FF5722', sortOrder: 1 },
      { name: 'Cilt Bakımı', icon: 'face_retouching_natural', color: '#FF5722', sortOrder: 2 },
      { name: 'Parfüm', icon: 'air', color: '#FF5722', sortOrder: 3 },
    ],
  },
  {
    name: 'Sigorta',
    icon: 'security',
    color: '#455A64',
    type: 'EXPENSE',
    sortOrder: 13,
    inflationKey: 'diger',
    children: [
      { name: 'Sağlık Sigortası', icon: 'health_and_safety', color: '#455A64', sortOrder: 1 },
      { name: 'Araç Sigortası', icon: 'car_crash', color: '#455A64', sortOrder: 2 },
      { name: 'DASK', icon: 'home_repair_service', color: '#455A64', sortOrder: 3 },
    ],
  },
  {
    name: 'Ulaşım (Araç)',
    icon: 'directions_car',
    color: '#37474F',
    type: 'EXPENSE',
    sortOrder: 14,
    inflationKey: 'ulasim',
    children: [
      { name: 'Vergi', icon: 'account_balance', color: '#37474F', sortOrder: 1 },
      { name: 'Muayene', icon: 'fact_check', color: '#37474F', sortOrder: 2 },
      { name: 'Kasko', icon: 'shield', color: '#37474F', sortOrder: 3 },
    ],
  },
  {
    name: 'Hediye / Bağış',
    icon: 'card_giftcard',
    color: '#AD1457',
    type: 'EXPENSE',
    sortOrder: 15,
    inflationKey: 'diger',
    children: [
      { name: 'Hediye', icon: 'card_giftcard', color: '#AD1457', sortOrder: 1 },
      { name: 'Bağış', icon: 'volunteer_activism', color: '#AD1457', sortOrder: 2 },
      { name: 'Zekat/Fitre', icon: 'mosque', color: '#AD1457', sortOrder: 3 },
    ],
  },
  {
    name: 'Çocuk',
    icon: 'child_care',
    color: '#FFD54F',
    type: 'EXPENSE',
    sortOrder: 16,
    inflationKey: 'egitim',
    children: [
      { name: 'Kreş', icon: 'child_friendly', color: '#FFD54F', sortOrder: 1 },
      { name: 'Oyuncak', icon: 'toys', color: '#FFD54F', sortOrder: 2 },
      { name: 'Çocuk Giyim', icon: 'checkroom', color: '#FFD54F', sortOrder: 3 },
    ],
  },
  {
    name: 'Diğer (Gider)',
    icon: 'category',
    color: '#9E9E9E',
    type: 'EXPENSE',
    sortOrder: 17,
    inflationKey: 'genel',
  },
];

const INCOME_CATEGORIES: ParentCategory[] = [
  {
    name: 'Maaş',
    icon: 'payments',
    color: '#70D8C8',
    type: 'INCOME',
    sortOrder: 1,
    children: [
      { name: 'Ana Maaş', icon: 'paid', color: '#70D8C8', sortOrder: 1 },
      { name: 'Ek İş', icon: 'work', color: '#70D8C8', sortOrder: 2 },
      { name: 'Prim', icon: 'stars', color: '#70D8C8', sortOrder: 3 },
    ],
  },
  {
    name: 'Freelance',
    icon: 'laptop_mac',
    color: '#BAC3FF',
    type: 'INCOME',
    sortOrder: 2,
    children: [
      { name: 'Proje', icon: 'assignment', color: '#BAC3FF', sortOrder: 1 },
      { name: 'Danışmanlık', icon: 'support_agent', color: '#BAC3FF', sortOrder: 2 },
    ],
  },
  {
    name: 'Yatırım Geliri',
    icon: 'trending_up',
    color: '#FFD54F',
    type: 'INCOME',
    sortOrder: 3,
    children: [
      { name: 'Faiz', icon: 'percent', color: '#FFD54F', sortOrder: 1 },
      { name: 'Temettü', icon: 'account_balance', color: '#FFD54F', sortOrder: 2 },
      { name: 'Kira Geliri', icon: 'home', color: '#FFD54F', sortOrder: 3 },
      { name: 'Altın Satış', icon: 'diamond', color: '#FFD54F', sortOrder: 4 },
    ],
  },
  {
    name: 'Devlet',
    icon: 'account_balance',
    color: '#A5D6A7',
    type: 'INCOME',
    sortOrder: 4,
    children: [
      { name: 'Vergi İadesi', icon: 'price_check', color: '#A5D6A7', sortOrder: 1 },
      { name: 'Teşvik', icon: 'star', color: '#A5D6A7', sortOrder: 2 },
      { name: 'Burs', icon: 'school', color: '#A5D6A7', sortOrder: 3 },
    ],
  },
  {
    name: 'Diğer (Gelir)',
    icon: 'attach_money',
    color: '#9E9E9E',
    type: 'INCOME',
    sortOrder: 5,
    children: [
      { name: 'Hediye', icon: 'card_giftcard', color: '#9E9E9E', sortOrder: 1 },
      { name: 'İkinci El Satış', icon: 'sell', color: '#9E9E9E', sortOrder: 2 },
    ],
  },
];

// Borç Ödemesi / Alacak Tahsilatı / Abonelik sistem kategorileri
const SYSTEM_SPECIAL_CATEGORIES: ParentCategory[] = [
  {
    name: 'Borç Ödemesi',
    icon: 'money_off',
    color: '#EF5350',
    type: 'EXPENSE',
    sortOrder: 98,
  },
  {
    name: 'Alacak Tahsilatı',
    icon: 'savings',
    color: '#66BB6A',
    type: 'INCOME',
    sortOrder: 98,
  },
  {
    name: 'Abonelik',
    icon: 'subscriptions',
    color: '#AB47BC',
    type: 'EXPENSE',
    sortOrder: 99,
  },
];

async function seedCategories() {
  console.log('Kategoriler oluşturuluyor...');
  const allCategories = [
    ...EXPENSE_CATEGORIES,
    ...INCOME_CATEGORIES,
    ...SYSTEM_SPECIAL_CATEGORIES,
  ];

  const categoryIdMap: Record<string, string> = {};

  for (const cat of allCategories) {
    const parent = await prisma.category.upsert({
      where: {
        // isSystem + name kombinasyonuyla benzersiz yap
        id: `sys_${cat.name.toLowerCase().replace(/[^a-z0-9]/g, '_')}`,
      },
      update: {},
      create: {
        id: `sys_${cat.name.toLowerCase().replace(/[^a-z0-9]/g, '_')}`,
        name: cat.name,
        icon: cat.icon,
        color: cat.color,
        type: cat.type,
        isSystem: true,
        sortOrder: cat.sortOrder,
      },
    });

    categoryIdMap[cat.name] = parent.id;

    if (cat.children) {
      for (const child of cat.children) {
        const childId = `sys_${cat.name.toLowerCase().replace(/[^a-z0-9]/g, '_')}_${child.name.toLowerCase().replace(/[^a-z0-9]/g, '_')}`;
        await prisma.category.upsert({
          where: { id: childId },
          update: {},
          create: {
            id: childId,
            parentId: parent.id,
            name: child.name,
            icon: child.icon,
            color: child.color,
            type: cat.type,
            isSystem: true,
            sortOrder: child.sortOrder,
          },
        });
      }
    }
  }

  console.log(`✓ ${allCategories.length} ana kategori oluşturuldu`);
  return categoryIdMap;
}

async function seedCategoryInflationMaps(categoryIdMap: Record<string, string>) {
  console.log('CategoryInflationMap oluşturuluyor...');

  const mappings = EXPENSE_CATEGORIES.filter((c) => c.inflationKey).map(
    (cat) => ({
      categoryId: categoryIdMap[cat.name],
      inflationKey: cat.inflationKey!,
    }),
  );

  for (const mapping of mappings) {
    if (!mapping.categoryId) continue;

    await prisma.categoryInflationMap.upsert({
      where: { categoryId: mapping.categoryId },
      update: { inflationKey: mapping.inflationKey },
      create: {
        categoryId: mapping.categoryId,
        inflationKey: mapping.inflationKey,
      },
    });
  }

  console.log(`✓ ${mappings.length} inflation mapping oluşturuldu`);
}

async function seedSystemTags() {
  console.log('Sistem etiketleri oluşturuluyor...');

  const systemTags = [
    { id: 'tag_essential', name: 'Temel İhtiyaç', color: '#66BB6A', icon: 'check_circle' },
    { id: 'tag_fixed', name: 'Sabit Gider', color: '#42A5F5', icon: 'lock' },
    { id: 'tag_variable', name: 'Değişken Gider', color: '#FFA726', icon: 'trending_up' },
    { id: 'tag_luxury', name: 'Lüks', color: '#AB47BC', icon: 'diamond' },
  ];

  for (const tag of systemTags) {
    await prisma.tag.upsert({
      where: { id: tag.id },
      update: {},
      create: {
        id: tag.id,
        name: tag.name,
        color: tag.color,
        icon: tag.icon,
        isSystem: true,
      },
    });
  }

  console.log(`✓ ${systemTags.length} sistem etiketi oluşturuldu`);
}

async function main() {
  console.log('🌱 Seed başlatılıyor...\n');

  const categoryIdMap = await seedCategories();
  await seedCategoryInflationMaps(categoryIdMap);
  await seedSystemTags();

  console.log('\n✅ Seed tamamlandı!');
}

main()
  .catch((e) => {
    console.error('❌ Seed hatası:', e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
