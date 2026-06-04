# Sprint 11 Contract — Aile/Ortak Bütçe

> **Bu dosya neden var?** Backend ve frontend dev session'ları tek doğruluk kaynağından çalışsın diye. Sprint başında PM (proje yöneticisi rolündeki Opus) yazar; iki dev session da kendi tarafını implemente ederken bu sözleşmeye uyar.
>
> **Değiştirme kuralı:** Bu dosya sprint sırasında değişirse → PM güncelleyip ilgili session'a haber verir. Tek taraflı sapma yasak.
>
> **Kapsam:** `DEVELOPMENT_PLAN_V2.md → Section 8.9` mimarisinin sözleşmeye dökülmüş hali.

---

## 0. Sprint Hedefi

Ev bütçesini birlikte yöneten çiftler/aileler için ortak bütçe takibi. Kullanıcı partner'ını e-posta ile davet eder; ortak bütçe oluşturur; üyeler normal işlem yaparken ortak bütçeye otomatik katkı düşer; katkı dağılımı raporu görülebilir.

**Out of scope:** Banka hesabı paylaşımı (kişisel hesaplar gizli kalır), otomatik ödeme bölme (her üye kendi işlemini giriyor), SMS/WhatsApp davet (sadece e-posta), fintech "havuz hesabı" mantığı.

---

## 1. Veri Modelleri (✅ schema.prisma'da mevcut)

```prisma
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

model FamilyGroup {
  id        String   @id @default(uuid()) @db.VarChar(36)
  name      String   @db.VarChar(100)
  icon      String?  @db.VarChar(50)
  createdAt DateTime @default(now()) @map("created_at") @db.DateTime(0)
  updatedAt DateTime @updatedAt @map("updated_at") @db.DateTime(0)

  members       FamilyMember[]
  sharedBudgets SharedBudget[]
  invites       FamilyInvite[]

  @@map("family_groups")
}

model FamilyMember {
  id       String     @id @default(uuid()) @db.VarChar(36)
  groupId  String     @map("group_id") @db.VarChar(36)
  userId   String     @map("user_id") @db.VarChar(36)
  role     FamilyRole @default(MEMBER)
  joinedAt DateTime   @default(now()) @map("joined_at") @db.DateTime(0)

  group FamilyGroup @relation(fields: [groupId], references: [id], onDelete: Cascade)
  user  User        @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([groupId, userId])
  @@map("family_members")
}

model FamilyInvite {
  id        String       @id @default(uuid()) @db.VarChar(36)
  groupId   String       @map("group_id") @db.VarChar(36)
  invitedBy String       @map("invited_by") @db.VarChar(36)
  email     String       @db.VarChar(255)
  token     String       @unique @db.VarChar(255)
  status    InviteStatus @default(PENDING)
  expiresAt DateTime     @map("expires_at") @db.DateTime(0)
  createdAt DateTime     @default(now()) @map("created_at") @db.DateTime(0)

  group FamilyGroup @relation(fields: [groupId], references: [id], onDelete: Cascade)

  @@map("family_invites")
}

model SharedBudget {
  id         String       @id @default(uuid()) @db.VarChar(36)
  groupId    String       @map("group_id") @db.VarChar(36)
  categoryId String       @map("category_id") @db.VarChar(36)
  name       String       @db.VarChar(100)
  amount     Decimal      @db.Decimal(15, 2)
  spent      Decimal      @default(0.00) @db.Decimal(15, 2)
  period     BudgetPeriod @default(MONTHLY)
  startDate  DateTime     @map("start_date") @db.Date
  endDate    DateTime?    @map("end_date") @db.Date
  isActive   Boolean      @default(true) @map("is_active")
  createdAt  DateTime     @default(now()) @map("created_at") @db.DateTime(0)
  updatedAt  DateTime     @updatedAt @map("updated_at") @db.DateTime(0)

  group    FamilyGroup   @relation(fields: [groupId], references: [id], onDelete: Cascade)
  category Category      @relation(fields: [categoryId], references: [id])
  expenses SharedExpense[]

  @@map("shared_budgets")
}

model SharedExpense {
  id             String   @id @default(uuid()) @db.VarChar(36)
  sharedBudgetId String   @map("shared_budget_id") @db.VarChar(36)
  transactionId  String   @map("transaction_id") @db.VarChar(36)
  userId         String   @map("user_id") @db.VarChar(36)
  amount         Decimal  @db.Decimal(15, 2)
  createdAt      DateTime @default(now()) @map("created_at") @db.DateTime(0)

  sharedBudget SharedBudget @relation(fields: [sharedBudgetId], references: [id], onDelete: Cascade)

  @@map("shared_expenses")
}
```

> **Önemli:** DEVELOPMENT_PLAN_V2.md'de bazı DateTime alanları `@db.Timestamp(0)` — bu **yanlış**. Tüm datetime alanlar `@db.DateTime(0)` olmalı (Gotcha §8.1). Yukarıdaki tanım düzeltilmiş haldir.
>
> **İlişki eklemeleri:** `User` modeline `familyMembers FamilyMember[]`, `Category` modeline `sharedBudgets SharedBudget[]` eklenir.

**Sprint 11 ilk işi:** `npx prisma migrate dev --name add_family_models`

---

## 2. Sabit Tanımlar

### 2.1 İş Kuralları

```typescript
// api/src/modules/family/family.constants.ts

export const FAMILY_CONSTANTS = {
  MAX_MEMBERS: 5,               // Grup başına üye limiti (OWNER dahil)
  INVITE_EXPIRY_DAYS: 7,        // Davet geçerlilik süresi
  MAX_GROUPS_PER_USER: 3,       // Bir kullanıcı kaç gruba üye olabilir
} as const;
```

### 2.2 E-posta Servisi (Resend)

```env
# .env — yeni eklenecek
RESEND_API_KEY=re_xxxxx
RESEND_FROM_EMAIL=bütçe@nexspend.com
APP_BASE_URL=https://your-app.com   # deep link için (mobil: custom URL scheme kullanılacak)
```

**Backend package:** `@nestjs/mailer` + `resend` (ya da `@nestjs-modules/mailer` + Resend SMTP).

Tercih edilen yaklaşım: `resend` SDK doğrudan HttpService ile çağrısı (ekstra paket minimize):

```typescript
// api/src/modules/family/email.service.ts

@Injectable()
export class FamilyEmailService {
  async sendInvite(params: { to: string; groupName: string; token: string; inviterName: string }) {
    const deepLink = `wallet://invite/${params.token}`;
    // HTTP POST to api.resend.com/emails
  }
}
```

### 2.3 Deep Link Şeması (Davet Linki)

```
wallet://invite/<token>
```

GoRouter'da bu scheme'i handle eden route eklenir:

```dart
GoRoute(
  path: '/invite/:token',
  builder: (context, state) => InvitePage(token: state.pathParameters['token']!),
)
```

Davet e-postasında hem deep link hem de fallback web URL (`APP_BASE_URL/invite/<token>`) bulunur. Uygulama yüklü değilse web URL store'a yönlendirir.

---

## 3. DTOs (TypeScript / Dart isim eşleşmesi)

| Backend (DTO) | Frontend (Model) | Alanlar |
|---|---|---|
| `FamilyGroupDto` | `FamilyGroupModel` | `id, name, icon?, memberCount: number, role: 'OWNER'\|'MEMBER', createdAt` |
| `FamilyMemberDto` | `FamilyMemberModel` | `id, userId, name: string, email: string, role: 'OWNER'\|'MEMBER', joinedAt` |
| `FamilyInviteDto` | `FamilyInviteModel` | `id, groupId, email, status: 'PENDING'\|'ACCEPTED'\|'REJECTED'\|'EXPIRED', expiresAt, createdAt` |
| `SharedBudgetDto` | `SharedBudgetModel` | `id, groupId, categoryId, categoryName: string, name, amount: number, spent: number, remainingPercent: number, period, startDate, isActive` |
| `ContributionReportDto` | `ContributionReportModel` | `period: string, members: [{userId, name, totalAmount: number, percentage: number, byCategory: [{categoryName, amount}]}]` |
| `CreateGroupDto` | — (request) | `name: string (max 100), icon?: string` |
| `SendInviteDto` | — (request) | `email: string` |
| `CreateSharedBudgetDto` | — (request) | `categoryId: string, name: string (max 100), amount: number, startDate: string (ISO date)` |

---

## 4. Endpoint Contract

Tüm endpoint'ler `JwtAuthGuard` korumalı.

### 4.1 `POST /api/family/groups`

Yeni grup oluştur.

**Body:**
```json
{ "name": "Ev Bütçesi", "icon": "home" }
```

**Side effect:**
1. `FamilyGroup` oluştur
2. `FamilyMember` oluştur (role: OWNER)
3. `MAX_GROUPS_PER_USER` sınırı aşılırsa `400`

**Response 201:** `FamilyGroupDto` döner.

### 4.2 `GET /api/family/groups`

Kullanıcının üye olduğu gruplar.

**Response 200:** `FamilyGroupDto[]`

### 4.3 `GET /api/family/groups/:id`

Grup detayı (üyeler + bütçeler + bekleyen davetler).

**Response 200:**
```json
{
  "success": true,
  "statusCode": 200,
  "data": {
    "id": "uuid",
    "name": "Ev Bütçesi",
    "icon": "home",
    "role": "OWNER",
    "members": [ /* FamilyMemberDto[] */ ],
    "sharedBudgets": [ /* SharedBudgetDto[] */ ],
    "pendingInvites": [ /* FamilyInviteDto[] — sadece OWNER görebilir */ ]
  }
}
```

**Auth:** Gruba üye olmayan kullanıcı `403` alır.

### 4.4 `POST /api/family/groups/:id/invite`

Üye davet et.

**Body:** `{ "email": "ayse@example.com" }`

**Validation:**
- Davet eden OWNER rolünde olmalı, değilse `403`
- `MAX_MEMBERS` aşılacaksa `400` (mesaj: "Grup üye sınırına ulaşıldı (max 5)")
- Aynı e-postaya zaten PENDING davet varsa `400`
- E-posta zaten grup üyesiyse `400`

**Side effect:**
1. `FamilyInvite` oluştur (token: UUID, expiresAt: +7 gün)
2. Resend ile davet e-postası gönder

**Response 201:** `FamilyInviteDto` döner.

### 4.5 `POST /api/family/invites/:token/accept`

Daveti kabul et. Token URL'den okunur (deep link: `wallet://invite/<token>`).

**Auth:** Token'ı kabul eden kullanıcı e-posta adresi, `FamilyInvite.email` ile eşleşmeli. Eşleşmiyorsa `403`.

**Validation:**
- Token yoksa `404`
- `expiresAt` geçmişse: `FamilyInvite.status = EXPIRED` güncelle, `410 Gone` dön (mesaj: "Davet süresi dolmuş")
- Token `PENDING` değilse `400`

**Side effect (Prisma $transaction):**
1. `FamilyInvite.status = ACCEPTED`
2. `FamilyMember` oluştur (role: MEMBER)

**Response 200:** `FamilyGroupDto` döner (kullanıcı artık gruba dahil).

### 4.6 `POST /api/family/invites/:token/reject`

Daveti reddet.

**Side effect:** `FamilyInvite.status = REJECTED`. Üye eklenmez.

**Response 200:** `{ "success": true, "statusCode": 200, "data": null }`

### 4.7 `POST /api/family/groups/:id/budgets`

Ortak bütçe oluştur.

**Body:**
```json
{
  "categoryId": "uuid",
  "name": "Ev Market Bütçesi",
  "amount": 5000.00,
  "startDate": "2026-05-01"
}
```

**Auth:** OWNER veya MEMBER (tüm üyeler bütçe oluşturabilir).

**Response 201:** `SharedBudgetDto` döner.

### 4.8 `GET /api/family/groups/:id/budgets`

Grubun ortak bütçeleri.

**Response 200:** `SharedBudgetDto[]` (sadece isActive: true olanlar, query param `?includeInactive=true` ile tümü)

### 4.9 `GET /api/family/groups/:id/contributions`

Katkı dağılımı raporu.

**Query:** `period?: string (YYYY-MM, default bu ay)`

**Response 200:**
```json
{
  "success": true,
  "statusCode": 200,
  "data": {
    "period": "2026-05",
    "members": [
      {
        "userId": "uuid",
        "name": "Batuhan",
        "totalAmount": 3200.00,
        "percentage": 64.0,
        "byCategory": [
          { "categoryName": "Market", "amount": 2100.00 },
          { "categoryName": "Faturalar", "amount": 600.00 }
        ]
      },
      {
        "userId": "uuid",
        "name": "Ayşe",
        "totalAmount": 1800.00,
        "percentage": 36.0,
        "byCategory": [ /* ... */ ]
      }
    ]
  }
}
```

### 4.10 `DELETE /api/family/groups/:id/members/:userId`

Üyeyi çıkar.

**Auth:** Sadece OWNER kaldırabilir. OWNER kendini çıkaramaz (`400`).

**Side effect:**
1. `FamilyMember` sil
2. Kullanıcının `SharedExpense` kayıtları kalır (tarihsel veri)

**Response 200:** `{ "success": true, "statusCode": 200, "data": null }`

---

## 5. Event-Driven: SharedBudget Otomatik Güncelleme

Üye bir işlem yaptığında ortak bütçe otomatik güncellenir — Transaction Hub event'i üzerinden:

```typescript
// api/src/modules/family/shared-budget.listener.ts

@Injectable()
export class SharedBudgetListener {
  @OnEvent('transaction.created')
  async handleTransactionCreated(event: TransactionCreatedEvent): Promise<void> {
    // 1. transaction.type == EXPENSE mi? (gelir veya transfer değil)
    if (event.type !== 'EXPENSE') return;

    // 2. userId'nin üye olduğu grupları al
    const groups = await this.findUserGroups(event.userId);
    if (!groups.length) return;

    // 3. Her grup için: bu kategoride aktif SharedBudget var mı?
    for (const group of groups) {
      const sharedBudget = await this.findMatchingBudget(group.id, event.categoryId);
      if (!sharedBudget) continue;

      // 4. Prisma $transaction:
      //    SharedExpense oluştur
      //    SharedBudget.spent += amount
      await this.recordExpense(sharedBudget.id, event.transactionId, event.userId, event.amount);
    }

    // 5. Grup üyelerine FCM: "Batuhan marketten ₺450 harcadı"
    await this.notifyGroupMembers(group, event);
  }
}
```

**Önemli:** Event listener Prisma `$transaction` dışında çalışır — transaction commit sonrası emit (Sprint 9 event-driven pattern, bkz. `nexspend-master.md §3.2`). Listener hata verirse `transaction.created` akışı geri alınmaz (fire-and-forget).

---

## 6. UI Yerleşim Sözleşmesi

### 6.1 Navigasyon

**Giriş noktası:** Ayarlar sayfasına yeni "Aile Bütçesi" bölümü eklenir.

```
Ayarlar
├── Profil
├── Tema
├── Bildirimler
└── Aile Bütçesi  ← YENİ
    └── → /family (grup listesi veya grup oluştur)
```

### 6.2 /family — Grup Listesi / Oluşturma

`presentation/family/pages/family_group_page.dart`

- Grup yoksa: "Aile bütçesi oluştur" CTA + açıklama
- Gruplar varsa: kart listesi (grup adı, üye sayısı, bütçe özeti)
- FAB: yeni grup oluştur

### 6.3 /family/:id — Grup Detayı

`presentation/family/pages/family_group_detail_page.dart`

- `member_avatar_row.dart` — üye avatarları + rolleri
- Ortak bütçe kartları listesi (`shared_budget_card.dart`) — progress bar ile spent/amount
- OWNER için: "Üye Davet Et" butonu + bekleyen davetler listesi

### 6.4 /family/invite/:token — Davet Kabul

`presentation/family/pages/invite_page.dart`

- Deep link ile açılır
- "Batuhan seni Ev Bütçesi grubuna davet etti" açıklaması
- [Kabul Et] / [Reddet] butonları
- Süresi dolmuş token: "Bu davet süresi dolmuş" error state

### 6.5 Katkı Raporu

`presentation/family/pages/contribution_report_page.dart`

```
Batuhan: ₺3.200 (%64)  ████████░░
Ayşe:    ₺1.800 (%36)  █████░░░░░
```

`contribution_bar.dart` widget — `AppColors.primary` vs `AppColors.secondary` ile üyeler renk kodlanır.

---

## 7. Hata Envelope (referans)

| Endpoint | Olası özel kodlar |
|---|---|
| `POST /api/family/groups` | 401, 400 (max group limit) |
| `POST /api/family/groups/:id/invite` | 401, 403 (owner değil), 400 (limit, duplicate, already member) |
| `POST /api/family/invites/:token/accept` | 401, 403 (e-posta eşleşmez), 404 (token yok), 400 (expired), 410 (süresi dolmuş) |
| `POST /api/family/invites/:token/reject` | 401, 404, 400 (zaten reject/accept edilmiş) |
| `DELETE /api/family/groups/:id/members/:userId` | 401, 403 (owner değil), 400 (owner kendini çıkaramaz) |

---

## 8. Bağımsızlık Sözleşmesi

| Backend yazarken | Frontend yazarken |
|---|---|
| Resend API key yoksa: `FamilyEmailService` mock modda çalışsın (log console'a), hata fırlatmasın | Deep link test: Android emülatörde `adb shell am start -W -a android.intent.action.VIEW -d "wallet://invite/test-token" com.yourapp` |
| `SharedBudgetListener` event fire-and-forget — listener hata versen bile işlem kaydı korunur | Invite kabul sonrası grup listesi otomatik yenilensin (BLoC event: `FamilyGroupRefresh`) |
| `FamilyInvite.token` = `crypto.randomUUID()` (NestJS crypto module, no extra dep) | Token expiry UI'da mesaj gösterir, backend'e istek atmaz (410 döndüğünde göster) |
| Contribution hesabı: `SharedExpense` üzerinden aggregate query — kişisel `Transaction` tablosuna dokunulmuyor | Katkı raporu sayfa navigasyonunda `period` param ile açılır: `/family/:id/contributions?period=2026-05` |

---

## 9. Tamamlanma Kriterleri (Definition of Done)

### Backend

- [ ] `npx prisma migrate dev --name add_family_models` koşmuş
- [ ] 10 endpoint canlı, tümü `@UseGuards(JwtAuthGuard)`
- [ ] `SharedBudgetListener` event-driven bağlantısı çalışıyor (smoke test: işlem ekle → SharedBudget.spent güncelleniyor)
- [ ] Resend e-posta gönderimi test edildi (gerçek davet e-postası)
- [ ] `family.service.spec.ts` (invite flow, contribution aggregation, owner guard)
- [ ] `npm run lint && npm test && npm run build` yeşil

### Frontend

- [ ] `/family` grup listesi + oluşturma akışı
- [ ] Davet e-postasındaki deep link uygulamayı açıyor ve InvitePage gösteriyor
- [ ] Kabul/red akışı çalışıyor, grup listesi güncelleniyor
- [ ] Ortak bütçe kartları + katkı raporu render oluyor
- [ ] `family_bloc_test.dart` (create group, accept invite, contribution fetch)
- [ ] `flutter analyze && flutter test` lokal'de yeşil

### PR Gate

- [ ] CI 3/3 yeşil
- [ ] TASK.md Sprint 12 maddeleri `[x]` olarak işaretli

---

## 10. Açık Sorular (Çözüldü)

1. ✅ **E-posta servisi:** Resend (API tabanlı, `RESEND_API_KEY` `.env`'e eklenir, ücretsiz tier 3.000 e-posta/ay).
2. ✅ **Deep link format:** `wallet://invite/<token>` — GoRouter'da handler eklenir.
3. ✅ **Üye limiti:** 5 kişi (OWNER dahil) — `FAMILY_CONSTANTS.MAX_MEMBERS`.
4. ✅ **SharedBudget güncelleme mekanizması:** `transaction.created` event üzerinden listener (Transaction Hub bozulmaz).
5. ✅ **Kişisel veri gizliliği:** Üyeler sadece SharedExpense toplamlarını görür, birbirinin bireysel Transaction kaydına erişemez.
