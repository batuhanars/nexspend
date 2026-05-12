import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }

  Future<bool> hasTokens() async {
    final token = await _storage.read(key: _accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  static const _biometricEnabledKey = 'biometric_enabled';

  Future<void> saveBiometricEnabled(bool value) =>
      _storage.write(key: _biometricEnabledKey, value: value.toString());

  Future<bool> getBiometricEnabled() async {
    final val = await _storage.read(key: _biometricEnabledKey);
    return val == 'true';
  }

  static const _languageKey = 'language';

  Future<void> saveLanguage(String languageCode) =>
      _storage.write(key: _languageKey, value: languageCode);

  Future<String> getLanguage() async {
    final val = await _storage.read(key: _languageKey);
    return val ?? 'tr';
  }

  static const _currencyKey = 'currency';

  Future<void> saveCurrency(String code) =>
      _storage.write(key: _currencyKey, value: code);

  Future<String> getCurrency() async {
    final val = await _storage.read(key: _currencyKey);
    return val ?? 'TRY';
  }

  static const _onboardingCompleteKey = 'onboarding_complete';

  Future<void> saveOnboardingComplete() =>
      _storage.write(key: _onboardingCompleteKey, value: 'true');

  Future<bool> isOnboardingComplete() async {
    final val = await _storage.read(key: _onboardingCompleteKey);
    return val == 'true';
  }

  static const _coachMarkSeenKey = 'coach_mark_seen';

  Future<void> saveCoachMarkSeen() =>
      _storage.write(key: _coachMarkSeenKey, value: 'true');

  Future<bool> isCoachMarkSeen() async {
    final val = await _storage.read(key: _coachMarkSeenKey);
    return val == 'true';
  }
}
