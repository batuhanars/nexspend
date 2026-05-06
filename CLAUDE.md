# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with this repository.

---

## Proje Özeti

"The Digital Private Vault" — kişisel finans yönetim uygulaması.
- `api/` — NestJS backend (port 3000)
- `mobile/` — Flutter frontend (Android/iOS)

> **Bu dosya cross-cutting kuralları içerir.** Backend için ek detay: `api/CLAUDE.md`. Frontend için ek detay: `mobile/CLAUDE.md`. Bir alt dizinden session açıldığında her iki dosya (root + subdirectory) context'e yüklenir.

---

## Referans Dosyaları

| Dosya | İçerik |
|---|---|
| `TASK.md` | Sprint görev takibi (canlı durum) |
| `SCHEMA.md` | Veritabanı şeması (27 model, 13 enum) |
| `DEVELOPMENT_PLAN_V1.md` | Sprint 0-8 mimarisi (tamamlandı) |
| `DEVELOPMENT_PLAN_V2.md` | Sprint 9-12 mimarisi (sıradaki odak) |
| `SPRINT_X_CONTRACT.md` | Aktif sprint için backend↔frontend sözleşmesi (varsa) |
| `STITCH_PROMPTS.md` | UI tasarım promptları (Stitch project ID `5496994793442531801`) |

---

## Çapraz Mimari İlkeler

Bu kurallar **hem backend hem frontend** tarafını ilgilendirir:

- **Response envelope:** Tüm başarılı yanıtlar `{ success: true, statusCode, data: ... }`. Backend `TransformInterceptor` üretir, frontend repository'leri `response.data['data']` ile çıkarır.
- **Hata envelope:** Tüm hatalar aynı formatta — `{ success: false, statusCode, message, error, timestamp, path }`.
- **Transaction Hub:** Tüm işlemler tek noktadan akar. `TransactionSource` enum (`MANUAL` / `RECURRING` / `DEBT_PAYMENT` / `DEBT_COLLECTION` / `SUBSCRIPTION`) ile ayrılır. Yeni kaynak eklenirken bu enum'a eklenir.
- **Event-driven bağımlılık:** Modüller event üzerinden konuşur — `transaction.created` / `updated` / `deleted`. Doğrudan service çağrısı yerine event emit/listen tercih edilir.
- **DEBT_COLLECTION ≠ gerçek gelir:** Raporlamada `source` filtresi ile alacak tahsilatı gerçek gelirden ayrılır. Yeni rapor eklerken bu ayrımı bozma.
- **BalanceService atomik:** Hesap bakiyesi değişiklikleri Prisma `$transaction` içinde `BalanceService.apply()` / `revert()` ile yapılır. Doğrudan `account.update({ balance: ... })` yasak.

---

## Test ve Lint Zorunluluğu

Push'tan önce **lokal'de** geçirmen gereken kontroller:

- Backend: `cd api && npm run lint && npm test && npm run build`
- Frontend: `cd mobile && flutter analyze && flutter test`

CI yeşil olmadan PR merge edilmez (branch protection rule aktif). Detaylar: alt dizinlerin CLAUDE.md dosyaları.

---

## Çalışma Modeli

- **PM session (proje yöneticisi rolündeki Opus):** Plan, contract, TASK.md güncelleme, dokümantasyon. Genelde kod yazmaz, dev session'lara contract halinde delege eder.
- **Backend dev session (Sonnet):** `cd api` ile çalışır, `api/CLAUDE.md` kurallarını okur.
- **Frontend dev session (Sonnet):** `cd mobile` ile çalışır, `mobile/CLAUDE.md` kurallarını okur.

İki dev session arasında alignment için **`SPRINT_X_CONTRACT.md` tek doğruluk kaynağıdır** — endpoint imzaları, DTO şekilleri, enum değerleri, side effect'ler oraya yazılır. Sapma yapılmaz; gerekirse PM contract'ı günceller, iki session'a bildirir.
