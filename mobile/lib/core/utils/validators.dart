class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'E-posta adresi gerekli';
    final regex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(value.trim())) return 'Geçerli bir e-posta girin';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Şifre gerekli';
    if (value.length < 8) return 'Şifre en az 8 karakter olmalı';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'En az bir büyük harf içermeli';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'En az bir rakam içermeli';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Şifre tekrarı gerekli';
    if (value != password) return 'Şifreler eşleşmiyor';
    return null;
  }

  static String? required(String? value, {String fieldName = 'Bu alan'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName gerekli';
    return null;
  }

  static String? amount(String? value) {
    if (value == null || value.trim().isEmpty) return 'Tutar gerekli';
    final cleaned = value.replaceAll('.', '').replaceAll(',', '.');
    final parsed = double.tryParse(cleaned);
    if (parsed == null || parsed <= 0) return 'Geçerli bir tutar girin';
    return null;
  }

  // Şifre güvenlik kuralları (ResetPasswordPage checklist için)
  static bool hasMinLength(String value) => value.length >= 8;
  static bool hasUppercase(String value) => RegExp(r'[A-Z]').hasMatch(value);
  static bool hasNumber(String value) => RegExp(r'[0-9]').hasMatch(value);
  static bool hasSpecialChar(String value) =>
      RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value);
}
