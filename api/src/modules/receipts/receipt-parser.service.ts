import { Injectable, Logger } from '@nestjs/common';

export interface ParsedReceipt {
  amount: number | null;
  merchant: string | null;
  date: Date | null;
  tax: number | null;
  paymentMethod: string | null;
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

    this.logger.debug(`OCR ham metin (${lines.length} satır):\n${rawText.slice(0, 1000)}`);

    const amount = this.extractAmount(lines);
    const date = this.extractDate(lines);
    const merchant = this.extractMerchant(lines);
    const tax = this.extractTax(lines);
    const paymentMethod = this.extractPaymentMethod(lines);
    const items = this.extractItems(lines);

    const confidence = this.calcConfidence({ amount, date, merchant, items });

    return { amount, merchant, date, tax, paymentMethod, items, confidence };
  }

  private extractAmount(lines: string[]): number | null {
    // Öncelik 1: etiket + tutar AYNI satırda
    const inlinePatterns = [
      /GENEL\s*TOPLAM[\s:*.\-]*(\d[\d.,]+)/i,
      /(?:ÖDENECEK|ODENECEK)[\s\S]{0,30}TUTAR[\s:*.\-]*(\d[\d.,]+)/i,
      /TOPLAM\s+TUTAR[\s:*.\-]*(\d[\d.,]+)/i,
      /TOP\.?\s*TUTAR[\s:*.\-]*(\d[\d.,]+)/i,
      /TAH[Sİsi][İi]LAT[\s:*.\-]*(\d[\d.,]+)/i,
      /TUTAR[\s:*.\-]*(\d[\d.,]+)/i,
      /TOPLAM[\s:*.\-]*(\d[\d.,]+)/i,
      /TOP\.[\s:*.\-]*(\d[\d.,]+)/i,
    ];

    for (const line of lines) {
      for (const pattern of inlinePatterns) {
        const m = line.match(pattern);
        if (m) return this.parseDecimal(m[1]);
      }
    }

    // Öncelik 2: etiket satırın tamamını kaplarken tutar BİR SONRAKI satırda
    const labelPatterns = [
      /GENEL\s*TOPLAM/i,
      /(?:ÖDENECEK|ODENECEK)[\s\S]{0,30}TUTAR/i,
      /TOPLAM\s+TUTAR/i,
      /TOP\.?\s*TUTAR/i,
      /TAH[Sİsi][İi]LAT/i,
      /TOPLAM/i,
    ];
    const amountOnly = /^[\s*\-]*(\d[\d.,]+)[\s*\-]*$/;

    for (let i = 0; i < lines.length - 1; i++) {
      for (const lp of labelPatterns) {
        if (lp.test(lines[i])) {
          const next = lines[i + 1];
          const m = next.match(amountOnly);
          if (m) return this.parseDecimal(m[1]);
          // Sonraki satırda inline rakam varsa ilk rakamı al
          const inline = next.match(/(\d[\d.,]+)/);
          if (inline) return this.parseDecimal(inline[1]);
        }
      }
    }

    // Öncelik 3 (fallback): fişteki en büyük para miktarı — toplam genellikle en büyüktür
    const moneyPattern = /\b(\d{1,6}[.,]\d{2})\b/g;
    const fullText = lines.join('\n');
    let max: number | null = null;
    let match: RegExpExecArray | null;
    while ((match = moneyPattern.exec(fullText)) !== null) {
      const val = this.parseDecimal(match[1]);
      if (val !== null && (max === null || val > max)) max = val;
    }
    if (max !== null) this.logger.debug(`Tutar fallback (en büyük değer): ${max}`);
    return max;
  }

  private extractDate(lines: string[]): Date | null {
    const patterns = [
      /(\d{2})[./](\d{2})[./](\d{4})/, // DD.MM.YYYY veya DD/MM/YYYY
      /(\d{4})[./-](\d{2})[./-](\d{2})/, // YYYY-MM-DD
    ];

    for (const line of lines) {
      const m1 = line.match(patterns[0]);
      if (m1) {
        const d = new Date(`${m1[3]}-${m1[2]}-${m1[1]}`);
        if (!isNaN(d.getTime())) return d;
      }
      const m2 = line.match(patterns[1]);
      if (m2) {
        const d = new Date(`${m2[1]}-${m2[2]}-${m2[3]}`);
        if (!isNaN(d.getTime())) return d;
      }
    }
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
