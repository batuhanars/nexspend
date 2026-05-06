/**
 * Türk bankaları için OCR eşleştirme sözlüğü.
 *
 * `aliases` — OCR ham metninde aranan büyük-küçük harfe duyarsız anahtar
 * kelimeler. Türkçe karakterler ASCII'ye çevrilmiş halde tutulur (OCR çıktısı
 * çoğu zaman aksansız döner ve eşleştirme normalize edilmiş metinde yapılır).
 *
 * Liste yalnızca "banka adı" bazlı tutuluyor — Bonus/Maximum/World/Axess gibi
 * **kart programı** isimleri kasıtlı olarak dahil edilmedi: bunlar bankalar
 * arasında lisanslanabiliyor ve yanlış pozitif üretiyor.
 */
export interface BankInfo {
  /** UI'da gösterilecek kanonik isim (Türkçe). */
  name: string;
  /** OCR çıktısında aranan aliaslar (UPPERCASE, ASCII). */
  aliases: string[];
}

export const TURKISH_BANKS: BankInfo[] = [
  {
    name: 'İş Bankası',
    aliases: ['ISBANK', 'IS BANKASI', 'TURKIYE IS BANKASI'],
  },
  { name: 'Garanti BBVA', aliases: ['GARANTI BBVA', 'GARANTI BANKASI', 'GARANTI'] },
  { name: 'Akbank', aliases: ['AKBANK'] },
  {
    name: 'Yapı Kredi',
    aliases: ['YAPI KREDI', 'YAPIKREDI', 'YKB'],
  },
  {
    name: 'Ziraat Bankası',
    aliases: ['ZIRAAT BANKASI', 'TC ZIRAAT', 'ZIRAATBANK'],
  },
  { name: 'Halkbank', aliases: ['HALKBANK', 'HALK BANKASI', 'TURKIYE HALK BANKASI'] },
  { name: 'Vakıfbank', aliases: ['VAKIFBANK', 'VAKIF BANKASI', 'TURKIYE VAKIFLAR BANKASI'] },
  { name: 'QNB Finansbank', aliases: ['QNB FINANSBANK', 'FINANSBANK', 'QNB FINANS'] },
  { name: 'DenizBank', aliases: ['DENIZBANK', 'DENIZ BANK'] },
  { name: 'ING', aliases: ['ING BANK'] },
  { name: 'HSBC', aliases: ['HSBC'] },
  { name: 'TEB', aliases: ['TURK EKONOMI BANKASI', 'TEB BANKASI'] },
  { name: 'Şekerbank', aliases: ['SEKERBANK', 'SEKER BANKASI'] },
  { name: 'Kuveyt Türk', aliases: ['KUVEYT TURK', 'KUVEYTTURK'] },
  { name: 'Albaraka Türk', aliases: ['ALBARAKA TURK', 'ALBARAKA'] },
  { name: 'Türkiye Finans', aliases: ['TURKIYE FINANS'] },
  { name: 'Vakıf Katılım', aliases: ['VAKIF KATILIM'] },
  { name: 'Ziraat Katılım', aliases: ['ZIRAAT KATILIM'] },
  { name: 'Anadolubank', aliases: ['ANADOLUBANK', 'ANADOLU BANKASI'] },
  { name: 'Fibabanka', aliases: ['FIBABANKA', 'FIBA BANKA'] },
  { name: 'Enpara', aliases: ['ENPARA'] },
  { name: 'Papara', aliases: ['PAPARA'] },
];

/**
 * Türkçe karakterleri ASCII'ye çevirip büyük harfe normalize eder.
 * OCR genelde aksansız üretir ama bazı satırlarda Türkçe karakterler kalabiliyor.
 */
export function normalizeForBankMatch(s: string): string {
  return s
    .toUpperCase()
    .replace(/İ/g, 'I')
    .replace(/Ş/g, 'S')
    .replace(/Ğ/g, 'G')
    .replace(/Ü/g, 'U')
    .replace(/Ö/g, 'O')
    .replace(/Ç/g, 'C');
}

/**
 * OCR ham metninde geçen bankayı tespit eder. Birden fazla banka eşleşirse
 * sözlükteki sıraya göre ilki döner — liste majör bankalar üstte gelecek
 * şekilde sıralı tutulmalı.
 */
export function detectBank(rawText: string): BankInfo | null {
  const haystack = normalizeForBankMatch(rawText);
  for (const bank of TURKISH_BANKS) {
    for (const alias of bank.aliases) {
      // Word boundary kontrolü: harfle çevrili eşleşmeleri (örn. "GARANTILI"
      // içinde "GARANTI") elemek için alias'ın çevresinde harf-olmayan karakter
      // veya başlangıç/bitiş aranır.
      const idx = haystack.indexOf(alias);
      if (idx === -1) continue;
      const before = idx === 0 ? '' : haystack[idx - 1];
      const after = haystack[idx + alias.length] ?? '';
      const isLetter = (c: string) => /[A-Z]/.test(c);
      if (!isLetter(before) && !isLetter(after)) {
        return bank;
      }
    }
  }
  return null;
}
