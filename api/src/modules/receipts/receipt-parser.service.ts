import { Injectable, Logger } from '@nestjs/common';
import { detectBank } from './banks';

export interface ParsedReceipt {
  amount: number | null;
  merchant: string | null;
  date: Date | null;
  tax: number | null;
  paymentMethod: string | null;
  bankName: string | null;
  items: ParsedReceiptItem[];
  confidence: number;
}

export interface ParsedReceiptItem {
  name: string;
  quantity: number;
  unitPrice: number;
  totalPrice: number;
}

@Injectable()
export class ReceiptParserService {
  private readonly logger = new Logger(ReceiptParserService.name);

  parse(rawText: string): ParsedReceipt {
    const lines = rawText
      .split('\n')
      .map((l) => l.trim())
      .filter(Boolean);

    this.logger.debug(
      `OCR ham metin (${lines.length} satır):\n${rawText.slice(0, 1000)}`,
    );

    const amount = this.extractAmount(lines);
    const date = this.extractDate(lines);
    const merchant = this.extractMerchant(lines);
    const tax = this.extractTax(lines);
    const paymentMethod = this.extractPaymentMethod(lines);
    const bankName = detectBank(rawText)?.name ?? null;
    const items = this.extractItems(lines);

    const confidence = this.calcConfidence({ amount, date, merchant, items });

    if (bankName) this.logger.debug(`Banka tespit edildi: ${bankName}`);

    return {
      amount,
      merchant,
      date,
      tax,
      paymentMethod,
      bankName,
      items,
      confidence,
    };
  }

  private extractAmount(lines: string[]): number | null {
    // OCR çıktısında bazen "198 ,00" gibi boşlukla ayrılmış ondalık olur
    const normalize = (s: string): string =>
      s.replace(/(\d)\s+([,.])/g, '$1$2').replace(/([,.])\s+(\d)/g, '$1$2');

    // Ondalık ayraç içeren geçerli tutar — saf integer (TCKN, barkod) reddedilir
    const findMoney = (s: string): number | null => {
      const n = normalize(s);
      const m = n.match(/\*?\s*(\d{1,7}[,.]\d{1,2})\b/);
      if (!m) return null;
      const v = this.parseDecimal(m[1]);
      return v !== null && v > 0 && v < 1_000_000 ? v : null;
    };

    // Öncelik 1: Kesin tutar etiketleri (kullanıcı teyit etti: "İŞLEM TUTARI" veya
    // "Ödenecek KDV Dahil Tutar" — aynı satır ya da altındaki satırlarda arama)
    const p1: Array<[RegExp, string]> = [
      [/GENEL\s*TOPLAM/i, 'GENEL TOPLAM'],
      [/(?:ÖDENECEK|ODENECEK).{0,30}TUTAR/i, 'ÖDENECEK TUTAR'],
      [/(?:İŞLEM|IŞLEM|ISLEM)\s+TUTAR/i, 'İŞLEM TUTARI'],
    ];

    for (let i = 0; i < lines.length; i++) {
      for (const [label, name] of p1) {
        if (!label.test(lines[i])) continue;
        const same = findMoney(lines[i]);
        if (same !== null) {
          this.logger.debug(`Tutar [${name} inline]: ${same}`);
          return same;
        }
        for (let j = i + 1; j < Math.min(i + 4, lines.length); j++) {
          const found = findMoney(lines[j]);
          if (found !== null) {
            this.logger.debug(`Tutar [${name}+${j - i} satır]: ${found}`);
            return found;
          }
        }
      }
    }

    // Öncelik 2: TOPLAM satırı — "TOPLAM KDV" hariç (KDV toplamını değil genel toplamı ister)
    for (let i = 0; i < lines.length; i++) {
      if (!/TOPLAM/i.test(lines[i])) continue;
      if (/TOPLAM\s+KDV/i.test(lines[i])) continue;
      const same = findMoney(lines[i]);
      if (same !== null) {
        this.logger.debug(`Tutar [TOPLAM inline]: ${same}`);
        return same;
      }
      for (let j = i + 1; j < Math.min(i + 3, lines.length); j++) {
        const found = findMoney(lines[j]);
        if (found !== null) {
          this.logger.debug(`Tutar [TOPLAM+${j - i} satır]: ${found}`);
          return found;
        }
      }
    }

    // Öncelik 3: Kart/nakit ödeme satırı ("Banka/Kredi Kartı *198,00")
    for (const line of lines) {
      if (
        /BANKA|KREDİ\s*KART|KREDI\s*KART|NAKİT|NAKIT|CONTACTLESS|TEMASSIZ/i.test(
          line,
        )
      ) {
        const found = findMoney(line);
        if (found !== null) {
          this.logger.debug(`Tutar [Ödeme satırı]: ${found}`);
          return found;
        }
      }
    }

    // Fallback: fişteki en büyük ondalıklı değer (barkod/TCKN gibi saf int'ler elenmiş)
    let max: number | null = null;
    for (const line of lines) {
      const n = normalize(line);
      const pattern = /\b(\d{1,6}[,.]\d{2})\b/g;
      let m: RegExpExecArray | null;
      while ((m = pattern.exec(n)) !== null) {
        const val = this.parseDecimal(m[1]);
        if (
          val !== null &&
          val > 0 &&
          val < 1_000_000 &&
          (max === null || val > max)
        )
          max = val;
      }
    }
    if (max !== null) this.logger.debug(`Tutar fallback (en büyük): ${max}`);
    return max;
  }

  private extractDate(lines: string[]): Date | null {
    // DD.MM.YYYY / DD/MM/YYYY / DD-MM-YYYY — Türk formatı, 1-2 hane gün/ay,
    // ayırıcı çevresinde opsiyonel boşluk (OCR sıkça `03 . 05 . 2026` üretir).
    const ddmmyyyy = /\b(\d{1,2})\s*[./-]\s*(\d{1,2})\s*[./-]\s*(\d{4})\b/;
    // YYYY-MM-DD / YYYY.MM.DD / YYYY/MM/DD — e-fatura ve ISO formatı.
    const yyyymmdd = /\b(\d{4})\s*[./-]\s*(\d{1,2})\s*[./-]\s*(\d{1,2})\b/;
    // Sadece boşlukla ayrılmış varyant — OCR ayırıcıyı yutarsa (`01 04 2026`).
    // tryParse'ın yıl/ay/gün validation'ı sayesinde rastgele 3-grup sayı
    // sıraları (barkod, hesap no) elenir.
    const ddmmyyyySpace = /\b(\d{1,2})\s+(\d{1,2})\s+(\d{4})\b/;

    // Date.UTC ile UTC midnight olarak inşa et — `new Date(y,m,d)` local tz'de
    // midnight üretir ve frontend'de off-by-one güne kayar.
    const tryParse = (y: number, m: number, d: number): Date | null => {
      if (m < 1 || m > 12 || d < 1 || d > 31 || y < 2020 || y > 2100) return null;
      const date = new Date(Date.UTC(y, m - 1, d));
      if (
        date.getUTCFullYear() !== y ||
        date.getUTCMonth() !== m - 1 ||
        date.getUTCDate() !== d
      )
        return null;
      return date;
    };

    const matchIn = (
      text: string,
      source: string,
    ): Date | null => {
      const m1 = text.match(ddmmyyyy);
      if (m1) {
        const d = tryParse(parseInt(m1[3]), parseInt(m1[2]), parseInt(m1[1]));
        if (d) {
          this.logger.debug(
            `Tarih [DD.MM.YYYY ${source}]: ${d.toISOString().slice(0, 10)} ← "${m1[0]}"`,
          );
          return d;
        }
      }
      const m2 = text.match(yyyymmdd);
      if (m2) {
        const d = tryParse(parseInt(m2[1]), parseInt(m2[2]), parseInt(m2[3]));
        if (d) {
          this.logger.debug(
            `Tarih [YYYY-MM-DD ${source}]: ${d.toISOString().slice(0, 10)} ← "${m2[0]}"`,
          );
          return d;
        }
      }
      const m3 = text.match(ddmmyyyySpace);
      if (m3) {
        const d = tryParse(parseInt(m3[3]), parseInt(m3[2]), parseInt(m3[1]));
        if (d) {
          this.logger.debug(
            `Tarih [DD MM YYYY ${source}]: ${d.toISOString().slice(0, 10)} ← "${m3[0]}"`,
          );
          return d;
        }
      }
      return null;
    };

    // 1. Tek satır içinde tarih ara — gürültüden uzak, en güvenilir
    for (const line of lines) {
      const found = matchIn(line, 'satır');
      if (found) return found;
    }

    // 2. Fallback: satırları birleştir — OCR tarihi satıra böldüyse
    // (örn. `01/04/` \n `2026`) bu fallback yakalar.
    const joined = matchIn(lines.join(' '), 'birleşik');
    if (joined) return joined;

    // Tarih bulunamadı — kullanıcının paylaşması için OCR'dan gelen 4 haneli
    // sayı içeren satırları logla (büyük ihtimalle tarih oradadır).
    const candidates = lines.filter((l) => /\d{4}/.test(l)).slice(0, 6);
    this.logger.warn(
      `Tarih bulunamadı. 4 haneli sayı içeren satırlar:\n${candidates.join('\n')}`,
    );
    return null;
  }

  private extractMerchant(lines: string[]): string | null {
    // İşyeri adı genellikle ilk 3 satırda yer alır
    const businessPatterns =
      /A\.Ş\.|LTD\.|TİC\.|MARKET|MARKETİ|GIDA|RESTORAN|CAFE|KAFE|A\.S\./i;

    for (let i = 0; i < Math.min(5, lines.length); i++) {
      const line = lines[i];
      if (businessPatterns.test(line)) return this.cleanMerchantName(line);
    }

    // Pattern bulunamazsa ilk anlamlı satırı al
    for (let i = 0; i < Math.min(3, lines.length); i++) {
      const line = lines[i];
      if (line.length > 3 && !/^\d/.test(line))
        return this.cleanMerchantName(line);
    }
    return null;
  }

  private extractTax(lines: string[]): number | null {
    const patterns = [
      /TOPKDV\s*[:\s]*(\d[\d.,]*)/i,
      /KDV\s*%?\d*\s*[:\s]*(\d[\d.,]*)/i,
      /K\.D\.V\.\s*[:\s]*(\d[\d.,]*)/i,
    ];

    for (const line of lines) {
      for (const pattern of patterns) {
        const m = line.match(pattern);
        if (m) return this.parseDecimal(m[1]);
      }
    }
    return null;
  }

  private extractPaymentMethod(lines: string[]): string | null {
    const text = lines.join(' ').toUpperCase();
    if (/TEMASSIZ|CONTACTLESS/.test(text)) return 'CONTACTLESS';
    if (/KREDİ KARTI|KREDI KARTI|CREDIT/.test(text)) return 'CREDIT_CARD';
    if (/BANKA KARTI|DEBIT/.test(text)) return 'DEBIT_CARD';
    if (/NAKİT|NAKIT|CASH/.test(text)) return 'CASH';
    return null;
  }

  private extractItems(lines: string[]): ParsedReceiptItem[] {
    const items: ParsedReceiptItem[] = [];
    // Satır formatı: ÜRÜN ADI [ADET x BİRİM FİYAT] TOPLAM
    const itemPattern = /^(.+?)\s+(\d+)\s*[xX]\s*(\d[\d.,]*)\s+(\d[\d.,]*)$/;
    const simplePattern = /^(.{3,40}?)\s{2,}(\d[\d.,]+)$/;

    for (const line of lines) {
      const m1 = line.match(itemPattern);
      if (m1) {
        items.push({
          name: m1[1].trim(),
          quantity: parseInt(m1[2]),
          unitPrice: this.parseDecimal(m1[3]) ?? 0,
          totalPrice: this.parseDecimal(m1[4]) ?? 0,
        });
        continue;
      }

      const m2 = line.match(simplePattern);
      if (m2 && !this.isHeaderLine(m2[1])) {
        const price = this.parseDecimal(m2[2]);
        if (price && price > 0) {
          items.push({
            name: m2[1].trim(),
            quantity: 1,
            unitPrice: price,
            totalPrice: price,
          });
        }
      }
    }

    return items.slice(0, 50); // Makul bir limit
  }

  private calcConfidence(parsed: {
    amount: number | null;
    date: Date | null;
    merchant: string | null;
    items: ParsedReceiptItem[];
  }): number {
    let score = 0;
    if (parsed.amount !== null) score += 0.5;
    if (parsed.date !== null) score += 0.3;
    if (parsed.merchant !== null) score += 0.1;
    if (parsed.items.length >= 3) score += 0.1;
    return Math.round(score * 100) / 100;
  }

  private parseDecimal(s: string): number | null {
    const t = s.trim();
    let cleaned: string;
    if (t.includes('.') && t.includes(',')) {
      // Türk format: 1.234,56 → 1234.56
      cleaned = t.replace(/\./g, '').replace(',', '.');
    } else if (t.includes(',')) {
      // Virgüllü ondalık: 198,00 → 198.00
      cleaned = t.replace(',', '.');
    } else {
      // Noktalı ondalık (e-fatura): 351.54 → 351.54
      cleaned = t;
    }
    const n = parseFloat(cleaned);
    return isNaN(n) ? null : n;
  }

  private cleanMerchantName(s: string): string {
    return s
      .replace(/[^a-zA-ZğüşıöçĞÜŞİÖÇ0-9\s.,&'-]/g, '')
      .trim()
      .slice(0, 100);
  }

  private isHeaderLine(s: string): boolean {
    const headers =
      /TOPLAM|KDV|TARİH|SAAT|FİŞ|SIRA|VKN|TCKN|ÖDEME|MAKBUZi|SATIŞ/i;
    return headers.test(s);
  }
}
