/// Çok-boyutlu işlem filtresi.
///
/// [type] — INCOME/EXPENSE/TRANSFER (null = hepsi)
/// [categoryId], [accountId] — tek seçim (backend sınırı)
/// [startDate], [endDate] — ISO 8601 (ör. "2026-05-01")
/// [search] — başlık + açıklama araması (debounced)
///
/// [activeCount] — type hariç kaç boyut aktif (rozet için).
class TransactionFilter {
  const TransactionFilter({
    this.type,
    this.categoryId,
    this.accountId,
    this.startDate,
    this.endDate,
    this.search,
  });

  static const empty = TransactionFilter();

  final String? type;
  final String? categoryId;
  final String? accountId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? search;

  /// type hariç aktif boyut sayısı (filtre rozeti için).
  int get activeCount {
    int n = 0;
    if (categoryId != null) n++;
    if (accountId != null) n++;
    if (startDate != null || endDate != null) n++;
    if (search != null && search!.isNotEmpty) n++;
    return n;
  }

  TransactionFilter copyWith({
    Object? type = _sentinel,
    Object? categoryId = _sentinel,
    Object? accountId = _sentinel,
    Object? startDate = _sentinel,
    Object? endDate = _sentinel,
    Object? search = _sentinel,
  }) {
    return TransactionFilter(
      type: type == _sentinel ? this.type : type as String?,
      categoryId:
          categoryId == _sentinel ? this.categoryId : categoryId as String?,
      accountId:
          accountId == _sentinel ? this.accountId : accountId as String?,
      startDate:
          startDate == _sentinel ? this.startDate : startDate as DateTime?,
      endDate: endDate == _sentinel ? this.endDate : endDate as DateTime?,
      search: search == _sentinel ? this.search : search as String?,
    );
  }

  /// Sadece type'ı sıfırla (chip bar "Hepsi" tıklandığında).
  TransactionFilter clearType() => copyWith(type: null);

  /// Tarih, kategori, hesap ve arama filtrelerini sıfırla (panel "Temizle").
  TransactionFilter clearPanel() => copyWith(
        categoryId: null,
        accountId: null,
        startDate: null,
        endDate: null,
        search: null,
      );

  @override
  bool operator ==(Object other) =>
      other is TransactionFilter &&
      other.type == type &&
      other.categoryId == categoryId &&
      other.accountId == accountId &&
      other.startDate == startDate &&
      other.endDate == endDate &&
      other.search == search;

  @override
  int get hashCode =>
      Object.hash(type, categoryId, accountId, startDate, endDate, search);
}

/// copyWith için sentinel: null ile "sıfırla" arasını ayırt eder.
const _sentinel = Object();
