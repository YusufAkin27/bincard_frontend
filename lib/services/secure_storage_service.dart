import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true, // EncryptedSharedPreferences kullanımı
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock, // İlk kilit açıldığında erişilebilir
    ),
  );

  // Kullanılacak anahtar isimleri
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _accessTokenExpiryKey = 'access_token_expiry';
  static const String _refreshTokenExpiryKey = 'refresh_token_expiry';

  // Singleton pattern
  static final SecureStorageService _instance = SecureStorageService._internal();
  
  factory SecureStorageService() {
    return _instance;
  }
  
  SecureStorageService._internal();

  // Access token kaydetme
  Future<void> setAccessToken(String token) async {
    await _secureStorage.write(key: _accessTokenKey, value: token);
  }

  // Access token alma
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }

  // Refresh token kaydetme
  Future<void> setRefreshToken(String token) async {
    await _secureStorage.write(key: _refreshTokenKey, value: token);
  }

  // Refresh token alma
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  // Kullanıcı bilgilerini kaydetme (JSON string olarak)
  Future<void> setUserData(String userJson) async {
    await _secureStorage.write(key: _userDataKey, value: userJson);
  }

  // Kullanıcı bilgilerini alma
  Future<String?> getUserData() async {
    return await _secureStorage.read(key: _userDataKey);
  }

  // Biyometrik doğrulama tercihini kaydetme
  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(key: _biometricEnabledKey, value: enabled.toString());
  }

  // Biyometrik doğrulama tercihini alma
  Future<bool> getBiometricEnabled() async {
    final value = await _secureStorage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  // Tüm verileri silme (çıkış yapma durumunda)
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
  }
  
  // Belirli bir anahtar değerini silme
  Future<void> delete(String key) async {
    await _secureStorage.delete(key: key);
  }
  
  // Sadece token bilgilerini silme
  Future<void> clearTokens() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }

  // Access token expiry tarihini kaydet
  Future<void> setAccessTokenExpiry(String expiryDate) async {
    await _secureStorage.write(key: _accessTokenExpiryKey, value: expiryDate);
  }
  
  // Access token expiry tarihini al
  Future<String?> getAccessTokenExpiry() async {
    return await _secureStorage.read(key: _accessTokenExpiryKey);
  }
  
  // Refresh token expiry tarihini kaydet
  Future<void> setRefreshTokenExpiry(String expiryDate) async {
    await _secureStorage.write(key: _refreshTokenExpiryKey, value: expiryDate);
  }
  
  // Refresh token expiry tarihini al
  Future<String?> getRefreshTokenExpiry() async {
    return await _secureStorage.read(key: _refreshTokenExpiryKey);
  }
} 