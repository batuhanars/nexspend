import '../../../data/models/account_model.dart';
import '../../../data/models/receipt_model.dart';

/// Backend'in OCR'dan döndürdüğü `ReceiptAccountHint`'i kullanıcının hesap
/// listesiyle eşleştirir. Test edilebilirlik için bloc'tan ayrı tutuldu.
class ReceiptAccountMatcher {
  ReceiptAccountMatcher._();

  /// Eşleştirme önceliği:
  /// 1. Banka adı eşleşmesi — `account.name` ile `hint.bankName` çift yönlü
  ///    normalize edilmiş contains. Birden fazla aday varsa paymentMethod
  ///    tipine uyanı tercih edilir.
  /// 2. Banka adı bulunamazsa paymentMethod → AccountType filtresi.
  /// 3. Hiçbir şey eşleşmezse null — çağıran taraf default account fallback'i
  ///    uygular (eski davranış).
  static AccountModel? match(
    ReceiptAccountHint? hint,
    List<AccountModel> accounts,
  ) {
    if (hint == null || hint.isEmpty || accounts.isEmpty) return null;
    final active = accounts.where((a) => !a.isArchived).toList();
    if (active.isEmpty) return null;

    final expectedTypes = _typesFor(hint.paymentMethod);

    if (hint.bankName != null) {
      final needle = _normalize(hint.bankName!);
      final byName = active.where((a) {
        final hay = _normalize(a.name);
        return hay.contains(needle) || needle.contains(hay);
      }).toList();
      if (byName.isNotEmpty) {
        if (expectedTypes.isNotEmpty) {
          final typed = byName.where((a) => expectedTypes.contains(a.type));
          if (typed.isNotEmpty) return typed.first;
        }
        return byName.first;
      }
    }

    if (expectedTypes.isEmpty) return null;
    final byType =
        active.where((a) => expectedTypes.contains(a.type)).toList();
    if (byType.isEmpty) return null;
    final defaults = byType.where((a) => a.isDefault);
    return defaults.isNotEmpty ? defaults.first : byType.first;
  }

  static List<AccountType> _typesFor(String? paymentMethod) {
    return switch (paymentMethod) {
      'CASH' => const [AccountType.CASH],
      'CREDIT_CARD' => const [AccountType.CREDIT_CARD],
      'DEBIT_CARD' => const [AccountType.BANK],
      // Temassız: kart olduğu kesin ama tipi belirsiz; kredi kartı daha sık.
      'CONTACTLESS' => const [AccountType.CREDIT_CARD, AccountType.BANK],
      _ => const [],
    };
  }

  static String _normalize(String s) => s
      .toUpperCase()
      .replaceAll('İ', 'I')
      .replaceAll('Ş', 'S')
      .replaceAll('Ğ', 'G')
      .replaceAll('Ü', 'U')
      .replaceAll('Ö', 'O')
      .replaceAll('Ç', 'C')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
