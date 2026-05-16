# Gelecek Özellik Önerileri

> Mevcut altyapıya (Transaction Hub, event-driven mimari, enflasyon verisi, ortak aile bütçesi, recurring + bildirim sistemi) doğal oturan, Türkiye pazarına özel özellik önerileri. Güçlüden zayıfa sıralı.

**Erteleme listesi (bilinen):** Altın & döviz portföyü → ileride.

---

## 1) Türkiye'ye Özel Finansal Yükümlülükler (yüksek değer)

### Fatura takvimi & hatırlatıcı
Elektrik / su / doğalgaz / internet son ödeme tarihleri, otomatik kategorize.
- **Altyapı:** Bildirim sistemi zaten kurulu; yeni `BillReminder` modeli + recurring akışı yeterli.
- **Değer:** Günlük kullanım, gecikme faizini engeller.

### Kredi kartı hesap kesim / son ödeme takibi
Türkiye'de neredeyse herkesin derdi. Hesap kesim tarihi → "şu an harcadıkların bir sonraki ekstreye yansıyacak" görseli.
- **Altyapı:** Mevcut `Account` modeline `statementDay` + `dueDay` alanları yeterli.
- **Değer:** Asgari ödeme tuzağını engeller, nakit akışı görünürlüğü.

### Vergi / SGK takvimi
KDV beyannamesi, MTV (Ocak/Temmuz), trafik sigortası + kasko yenileme, gelir vergisi taksitleri.
- **Hedef kitle:** Serbest meslek erbabı, küçük işletme sahibi için altın değerinde.
- **Değer:** Cezadan kaçınma, planlama.

### Kira artış hesaplayıcı (TÜFE bazlı)
Mevcut enflasyon verisi ile mükemmel uyum.
- **Mekanik:** Kontrat başlangıç tarihi + güncel 12 aylık TÜFE ortalaması → yasal tavanlı yeni kira önerisi.
- **Hedef:** Hem kiracı hem ev sahibi tarafı için kullanılabilir.

---

## 2) Mevcut Fiş Tarama Sisteminin Uzantıları

> Fiş tarama altyapısı zaten var: `receipts` modülü + `ReceiptParserService` (TR pattern'leri, banka tespiti, confidence) + `Receipt` / `ReceiptItem` / `MerchantCategoryMap` modelleri + Flutter tarafında hibrit OCR (ML Kit + sunucu fallback). Aşağıdakiler bunun **üstüne** somut uzantılar.

### E-Arşiv / E-Fatura QR okuma
Türkiye'de market fişlerinde QR kodu standart. QR → doğrudan GİB verisi (kağıt OCR'dan çok daha güvenilir, kalemler yapısal hazır gelir).
- **Altyapı:** `ReceiptParser` yanına `EArsivParser` eklenir, aynı `ParsedReceipt` çıktısını döner.
- **Değer:** OCR güven skoru sorununu büyük ölçüde ortadan kaldırır.

### Ürün bazlı kişisel enflasyon
`ReceiptItem.name` + `unitPrice` zaten kaydediliyor.
- **Çıktı:** "Aynı süt 6 ay önce 32 ₺, şimdi 47 ₺ → %47 artış" kişisel sepet enflasyonu.
- **Altyapı:** Enflasyon modülüyle doğal eşleşme; TÜİK karşılaştırması da mümkün.

### Garanti belgesi arşivi
Elektronik / beyaz eşya fişleri için "garanti bitiş" alanı + bildirim.
- **Altyapı:** `Receipt` zaten görsel saklıyor; sadece `warrantyEndDate` alanı + recurring bildirim entegrasyonu.
- **Değer:** Tek bir uygulamada hem mali kayıt hem garanti arşivi.

### Sepet bölme (ortak aile bütçesi)
Bir fişteki kalemlerden bazılarını başka aile üyesine / kategoriye ata.
- **Mekanik:** `ReceiptItem` → çoklu `Transaction` split akışı.
- **Altyapı:** Ortak bütçe modülüyle uyumlu, Transaction Hub `MANUAL` source üzerinden.

### Yıllık KDV iadesi takibi
TR'de bazı kategorilerde gelir vergisi mükellefleri için KDV iadesi hakkı mevcut.
- **Altyapı:** `parsedTax` zaten kayıtlı; sadece yıllık toplam + kategori filtresi raporu.
- **Hedef kitle:** Serbest meslek erbabı.

### MerchantCategoryMap UX iyileştirmesi
Backend tarafı (akıllı kategori öğrenme) zaten var, frontend onay akışı net mi belirsiz.
- **Öneri:** "Migros'u X kez Market olarak işaretledin — bundan sonra otomatik atayalım mı?" diyaloğu + ayarlardan yönetim ekranı.
- **Değer:** Mevcut altyapının kullanıcıya dönmüş yüzü; az iş, çok değer.

---

## 3) Otomasyon & Veri Girişi

### SMS banka bildirimleri okuma (Android)
Türk bankaları hâlâ SMS atıyor. Permission ile parse + öneri olarak Transaction Hub'a düş (otomatik kayıt değil — onaylı kayıt).
- **Kısıt:** Android-only; iOS'ta API izin vermiyor.
- **Değer:** Otomatik harcama yakalama, %80+ giriş ortadan kalkar.

### Hedef bazlı tasarruf kovaları
"Ev peşinatı", "Tatil", "Düğün", "Yeni telefon" gibi sanal kovalar.
- **Plus:** Her kovaya enflasyon-düzeltilmiş hedef (10.000 ₺ hedef → bir yıl sonra TÜFE'ye göre 13.500 ₺ olabilir).

---

## 4) Türkiye Sosyo-Kültürel

### Hediye / davet takibi
Düğün, sünnet, kına, doğum günü harcamaları + "X kişiye Y verdim" hatırlatması.
- **Bonus:** "Karşılık beklentisi" netliği — bizim kültürde önemli.
- Niş ama çok sevilir.

### Altın günü / kumbara döngüsü
Hem alınan hem verilen ay/tutar.
- **Altyapı:** Aile bütçesi modülü zaten var, oraya eklenir.

### Ramazan / Kurban / bayram bütçesi
Mevsimsel kategori; geçen yıl ne harcadın → bu yıl enflasyon korelasyonlu öneri.
- "Geçen yıl bayramda 8.500 ₺ harcadın, bu yıl tahmin 11.700 ₺."

### Zekat / sadaka hesaplayıcı
Nisap üstü varlık kontrolü, yıllık hesap.
- **Hedef kitle:** Dini yükümlülük takibi yapan kullanıcılar.

---

## 5) Yatırım & Analiz

### TEFAS fonu portföyü (manuel)
Altın/döviz ertelendi ama TEFAS fonları için halka açık API yok — manuel ama önemli.
- **Fark:** Reel getiri (nominal getiri − TÜFE) görselleştirme.

### BES (Bireysel Emeklilik) takibi
Devlet katkısı %30, çoğu kullanıcı yıllık ne kadar biriktiğini bilmiyor.
- **Değer:** Yıllık özet, devlet katkısı görünürlüğü.

### Kategori bazlı enflasyon karşılaştırma
TÜİK alt-endeksleri (gıda, ulaşım, sağlık, eğitim vs.).
- **Çıktı:** "Senin gıda enflasyonun TÜİK ortalamasından %X yüksek/düşük."
- **Altyapı:** Enflasyon altyapısı zaten yarı yolda.

### Reel getiri hesaplayıcı
Mevduat / fon getirisi vs. TÜFE.
- **Değer:** Türkiye'de en kritik finansal okuryazarlık aracı — nominal %50 getiri ama enflasyon %60 → kaybettin.

---

## 6) Aile Bütçesi Genişletmeleri

### Çocuk harçlığı modülü
Çocuğa "sanal hesap", görev → harçlık akışı, harcama eğitimi.
- **Hedef:** Aile içi finansal okuryazarlık.

---

## 7) Mevcut Borç / Alacak Modülünün Uzantıları

> Borç modülü zaten kapsamlı: `Debt` + `DebtInstallment` + `DebtPayment`, `LENT`/`BORROWED` ayrımı, vade hatırlatma + gecikme cron job'ları, Transaction Hub'da `DEBT_PAYMENT` + `DEBT_COLLECTION` source'ları. Aşağıdakiler bunun üstüne uzantı.

### WhatsApp / SMS hatırlatma deep link
Vade yaklaşan borç için "Ahmet'e hatırlat" butonu.
- **Mekanik:** WhatsApp deep link (`https://wa.me/...?text=...`) hazır metinle açılır — kullanıcı sadece gönder der.
- **Altyapı:** `Debt.personName` var, opsiyonel `personPhone` alanı eklenir.

### Grup borç (Splitwise tarzı)
Yemek, tatil, hediye gibi ortak harcamalarda otomatik bölüştürme.
- **Mekanik:** 1 kişi 800 ₺ ödedi, 4 kişi → diğer 3'üne 200 ₺ `LENT` borç otomatik açılır.
- **Altyapı:** Mevcut `Debt` üzerine `DebtGroup` (id + başlık + üyeler) eklenir.
- **Değer:** Splitwise kullanıcılarını tek uygulamaya çeker.

### Net pozisyon görünümü
"Ahmet ile net pozisyonun: +850 ₺ alacaklısın" — karşılıklı borç-alacak netleştirme.
- **Altyapı:** `personName` üzerinden grupla, `LENT` − `BORROWED` netini hesapla.
- **UX:** Kişi bazlı liste sayfasında özet kart.

### Borç makbuzu PDF paylaşımı
Borç verirken/alırken resmi olmasa da yazılı kayıt.
- **Mekanik:** `Debt` + imza alanı → PDF üret, WhatsApp/e-posta paylaş.
- **Değer:** Kültürel olarak "söz" üstüne kayıt eklenmesi rahatlık verir.

---

## Önerilen Sıralama

| Sprint | İçerik | Gerekçe |
|---|---|---|
| **Sprint 13** | Fatura takvimi + Kredi kartı hesap kesim + Vergi takvimi | En yüksek günlük değer, en az yeni mimari. Mevcut bildirim + recurring altyapısını kullanır. |
| **Sprint 14** | Kira artış + Reel getiri + Kategori enflasyon | Enflasyon altyapısının ROI'sini katlar. Tek tema. |
| **Sprint 15** | E-Arşiv QR + Ürün bazlı enflasyon + MerchantCategoryMap UX | Mevcut fiş altyapısını "tam değer" haline getirir; az iş, çok kazanç. |
| **Sprint 16** | SMS banka parser (Android) + Hedef kovaları + Sepet bölme + Net pozisyon + WhatsApp hatırlatma | UX sıçraması — manuel giriş + borç hatırlatma sürtünmesi kalkar. |
| **Sprint 17** | Hediye/davet + Bayram bütçesi + Zekat + Grup borç (Splitwise) | TR-kültürel + sosyal paket. Ortak harcama akışı doğal devamı. |
| **Sprint 18** | TEFAS + BES + Garanti arşivi + KDV iadesi raporu + Borç makbuzu PDF | Yatırım modülü + arşiv/raporlama rötuşları. |
| **Ertelenen** | Altın & döviz portföyü | Daha önce ertelendi, Sprint 18 sonrası uygun olur. |

---

*Tarih: 2026-05-13*
*Hazırlayan: Claude (Opus 4.7) — kullanıcının onayı ile sprint planına alınacak.*
