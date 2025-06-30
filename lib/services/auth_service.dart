import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as Math;
import 'api_service.dart';
import 'secure_storage_service.dart';
import 'token_service.dart';
import 'biometric_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter/widgets.dart';
import '../main.dart'; // navigatorKey için import

class AuthService {
  final ApiService _apiService = ApiService();
  final SecureStorageService _secureStorage = SecureStorageService();
  final TokenService _tokenService = TokenService();
  final BiometricService _biometricService = BiometricService();
  
  // API Endpoint
  static const String baseUrl = 'http://192.168.174.214:8080/v1/api';

  // SharedPreferences Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';

  // Kullanıcı adı ve şifre ile giriş (YENİ BACKEND)
  Future<TokenResponseDTO> login(String phone, String password) async {
    try {
      debugPrint('Login isteği gönderiliyor: $phone');
      final deviceInfo = await getDeviceInfo();
      final ipAddress = await getIpAddress();
      final appVersion = await getAppVersion();
      final platform = getPlatform();

      final response = await _apiService.post(
        '/auth/login',
        data: {
          'telephone': phone,
          'password': password,
          'deviceInfo': deviceInfo,
          'ipAddress': ipAddress,
          'appVersion': appVersion,
          'platform': platform,
        },
        useLoginDio: true,
      );

      if (response.statusCode == 200 && response.data != null) {
        // Yeni cihaz algılandı durumu kontrolü
        if (response.data['success'] == false && 
            response.data['message'] == "Yeni cihaz algılandı. Giriş için doğrulama kodu gönderildi.") {
          // SMS doğrulama ekranına yönlendirmek için özel bir exception fırlat
          throw Exception("SMS_VERIFICATION_REQUIRED");
        }
        
        // accessToken veya refreshToken yoksa hata mesajı göster
        if (response.data['accessToken'] == null || response.data['refreshToken'] == null) {
          final message = response.data['message'] ?? 'Giriş başarısız oldu.';
          throw Exception(message);
        }
        final tokenResponse = TokenResponseDTO.fromJson(response.data);
        // Token'ları güvenli depolamaya kaydet
        await _secureStorage.setAccessToken(tokenResponse.accessToken.token);
        await _secureStorage.setRefreshToken(tokenResponse.refreshToken.token);
        await _secureStorage.setAccessTokenExpiry(tokenResponse.accessToken.expiredAt.toIso8601String());
        await _secureStorage.setRefreshTokenExpiry(tokenResponse.refreshToken.expiredAt.toIso8601String());
        // Token interceptor'ı etkinleştir
        _apiService.setupTokenInterceptor();
        // Biyometrik izin sor
        await _askForBiometricPermission();
        return tokenResponse;
      } else {
        final message = response.data?['message'] ?? 'Giriş başarısız oldu.';
        debugPrint('Login başarısız: $message');
        throw Exception(message);
      }
    } on DioException catch (e) {
      debugPrint('Login DioException: \\${e.message}');
      debugPrint('Response data: \\${e.response?.data}');
      throw Exception(e.response?.data?['message'] ?? 'Giriş başarısız oldu');
    } catch (e) {
      debugPrint('Login beklenmeyen hata: $e');
      throw Exception('Beklenmeyen bir hata oluştu: $e');
    }
  }

  // Biyometrik doğrulama ile giriş
  Future<bool> loginWithBiometrics() async {
    try {
      debugPrint('Biyometrik giriş süreci başlatılıyor...');
      
      // Biyometrik doğrulama için uygun mu kontrol et
      final canAuthenticate = await _biometricService.canAuthenticate();
      if (!canAuthenticate) {
        debugPrint('Biyometrik doğrulama kullanılamıyor veya etkinleştirilmemiş');
        return false;
      }
      
      // Refresh token var mı kontrol et
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null) {
        debugPrint('Kayıtlı refresh token bulunamadı, normal giriş gerekiyor');
        return false;
      }

      // Refresh token süresi kontrolü
      final refreshTokenExpiry = await _secureStorage.getRefreshTokenExpiry();
      if (refreshTokenExpiry != null) {
        final expiry = DateTime.parse(refreshTokenExpiry);
        final now = DateTime.now();
        
        if (now.isAfter(expiry)) {
          debugPrint('Refresh token süresi dolmuş, yeniden giriş yapmanız gerekiyor');
          return false;
        }
        
        debugPrint('Refresh token geçerli, süresi: $expiry');
      }
      
      // Biyometrik doğrulama yap
      debugPrint('Biyometrik doğrulama isteği gönderiliyor...');
      final isAuthenticated = await _biometricService.authenticate(
        reason: 'Giriş yapmak için biyometrik doğrulama kullanın',
        description: 'Devam etmek için parmak izi veya yüz tanıma kullanın',
      );
      
      if (!isAuthenticated) {
        debugPrint('Biyometrik doğrulama başarısız veya kullanıcı tarafından iptal edildi');
        return false;
      }
      
      debugPrint('Biyometrik doğrulama başarılı, refresh token ile yeni access token alınıyor');
      
      // Token servisini ve API servisini yapılandır
      _apiService.setupTokenInterceptor();
      
      // Biyometrik doğrulama başarılıysa, refresh token ile yeni access token al
      final refreshSuccess = await _tokenService.refreshAccessToken();
      
      if (refreshSuccess) {
        debugPrint('Token yenileme başarılı, giriş yapılıyor');
        return true;
      } else {
        debugPrint('Token yenileme başarısız, yeni access token alınamadı');
        
        // Access token ve refresh token'ı kontrol et
        final accessToken = await _secureStorage.getAccessToken();
        final refreshTokenAgain = await _secureStorage.getRefreshToken();
        
        if (accessToken != null && refreshTokenAgain != null) {
          debugPrint('Mevcut token bilgileri hala geçerli, giriş işlemi devam ediyor');
          return true;
        }
        
        debugPrint('Token bilgileri geçersiz, normal giriş gerekiyor');
        return false;
      }
    } catch (e) {
      debugPrint('Biyometrik giriş hatası: $e');
      return false;
    }
  }

  // Kayıt API isteği
  Future<ResponseMessage> register(
    String firstName,
    String lastName,
    String telephone,
    String password,
  ) async {
    try {
      final requestBody = {
        'firstName': firstName,
        'lastName': lastName,
        'telephone': telephone,
        'password': password,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/user/sign-up'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return ResponseMessage.fromJson(data);
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        return ResponseMessage.error(
          errorData['message'] ?? 'Kayıt başarısız. Lütfen tekrar deneyin.',
        );
      }
    } catch (e) {
      return ResponseMessage.error('Bağlantı hatası: $e');
    }
  }

  // Cihaz bilgisini al
  Future<String> getDeviceInfo() async {
    try {
      // Gerçek cihaz bilgilerini almak için device_info_plus paketi kullanılabilir
      // Bu örnekte basit bir bilgi döndürüyoruz
      final deviceModel = Platform.isAndroid ? 'Android Device' : 
                         Platform.isIOS ? 'iOS Device' : 'Unknown Device';
      final osVersion = Platform.operatingSystemVersion;
      return '$deviceModel ($osVersion)';
    } catch (e) {
      debugPrint('Cihaz bilgisi alınamadı: $e');
      return 'Unknown Device';
    }
  }

  // IP adresini al
  Future<String> getIpAddress() async {
    try {
      // Gerçek IP adresi almak için harici bir servis kullanılabilir
      final response = await http.get(Uri.parse('https://api.ipify.org'));
      if (response.statusCode == 200) {
        return response.body.trim();
      }
      return '192.168.1.100'; // Varsayılan değer
    } catch (e) {
      debugPrint('IP adresi alınamadı: $e');
      return '192.168.1.100';
    }
  }
  
  // Uygulama sürümünü al
  Future<String> getAppVersion() async {
    try {
      // Gerçek uygulamada package_info_plus paketi kullanılabilir
      // Bu örnekte sabit bir değer dönüyoruz
      return '1.0.0';
    } catch (e) {
      debugPrint('Uygulama sürümü alınamadı: $e');
      return '1.0.0';
    }
  }
  
  // Platform bilgisini al
  String getPlatform() {
    try {
      return Platform.operatingSystem;
    } catch (e) {
      debugPrint('Platform bilgisi alınamadı: $e');
      return 'unknown';
    }
  }

  // Token ve kullanıcı bilgilerini kaydet
  Future<void> saveAuthData(AuthResponse authResponse) async {
    final prefs = await SharedPreferences.getInstance();

    if (authResponse.token != null) {
      await prefs.setString(tokenKey, authResponse.token!);
    }

    if (authResponse.refreshToken != null) {
      await prefs.setString(refreshTokenKey, authResponse.refreshToken!);
    }

    if (authResponse.user != null) {
      final userData = jsonEncode({
        'id': authResponse.user!.id,
        'firstName': authResponse.user!.firstName,
        'lastName': authResponse.user!.lastName,
        'telephone': authResponse.user!.telephone,
        'email': authResponse.user!.email,
      });

      await prefs.setString(userKey, userData);
    }
  }

  // Token bilgisini al
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  // Kullanıcı bilgisini al
  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(userKey);

    if (userData != null) {
      final Map<String, dynamic> userMap = jsonDecode(userData);
      return User.fromJson(userMap);
    }

    return null;
  }

  // Oturum kontrolü
  Future<bool> isLoggedIn() async {
    return await _tokenService.hasValidTokens();
  }

  // Çıkış yap
  Future<ResponseMessage> logout() async {
    try {
      // Kullanıcıyı logout et
      final response = await _apiService.post(
        '/auth/logout',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${await _secureStorage.getAccessToken()}',
          },
        ),
      );

      // Tüm yerel depolanmış verileri temizle
      await _secureStorage.clearAll();
      
      // Biyometrik ayarı sıfırla
      await _biometricService.disableBiometricAuthentication();

      if (response.statusCode == 200) {
        return ResponseMessage.fromJson(response.data);
      } else {
        // API çağrısı başarısız olsa bile, yerel verileri temizledik
        return ResponseMessage(
          success: true,
          message: 'Çıkış yapıldı, ancak sunucu yanıtı alınamadı.',
        );
      }
    } catch (e) {
      // Hata olsa bile, yerel verileri temizledik
      debugPrint('Logout hatası: $e');
      return ResponseMessage(
        success: true,
        message: 'Çıkış yapıldı, ancak bir hata oluştu: $e',
      );
    }
  }

  // Biyometrik doğrulama için izin iste
  Future<bool> _askForBiometricPermission() async {
    try {
      // Cihaz biyometrik doğrulamayı destekliyor mu?
      final isDeviceSupported = await _biometricService.isBiometricAvailable();
      if (!isDeviceSupported) {
        return false;
      }
      
      // Kullanıcı daha önce biyometrik doğrulamayı etkinleştirmiş mi?
      final isBiometricEnabled = await _biometricService.isBiometricEnabled();
      if (isBiometricEnabled) {
        return true; // Zaten etkinleştirilmiş
      }
      
      // Biyometrik doğrulamayı etkinleştir
      return await _biometricService.enableBiometricAuthentication();
    } catch (e) {
      debugPrint('Biyometrik izin hatası: $e');
      return false;
    }
  }

  // Biyometrik doğrulama kullanılabilir mi?
  Future<bool> canUseBiometricAuth() async {
    return await _biometricService.canAuthenticate();
  }

  // Biyometrik doğrulamayı devre dışı bırak
  Future<void> disableBiometricAuth() async {
    await _biometricService.disableBiometricAuthentication();
  }

  // Kullanıcı bilgilerini API'den al
  Future<User?> getUserDetails() async {
    try {
      final response = await _apiService.get('/user/profile');
      
      if (response.statusCode == 200 && response.data != null) {
        return User.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('Kullanıcı bilgileri getirme hatası: $e');
      return null;
    }
  }

  // Uygulama başlangıcında token kontrolü ve yenileme
  Future<bool> checkAndRefreshToken() async {
    try {
      // Refresh token kontrolü
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null) {
        debugPrint('Refresh token bulunamadı, yeniden giriş yapmanız gerekiyor');
        return false;
      }

      // Refresh token expiry kontrolü
      final refreshTokenExpiry = await _secureStorage.getRefreshTokenExpiry();
      if (refreshTokenExpiry != null) {
        final expiry = DateTime.parse(refreshTokenExpiry);
        final now = DateTime.now();
        
        if (now.isAfter(expiry)) {
          debugPrint('Refresh token süresi dolmuş, yeniden giriş yapmanız gerekiyor');
          return false;
        }
        
        debugPrint('Refresh token hala geçerli, süresi: $expiry');
      }

      // Access token kontrolü
      final isAboutToExpire = await _tokenService.isAccessTokenAboutToExpire();
      if (isAboutToExpire) {
        debugPrint('Access token süresi dolmuş veya dolmak üzere, yenileniyor...');
        
        // Token servisini kullanarak token yenileme
        final refreshed = await _tokenService.refreshAccessToken();
        if (!refreshed) {
          debugPrint('Token yenileme başarısız, yeniden giriş yapmanız gerekiyor');
          return false;
        }
        
        debugPrint('Token başarıyla yenilendi, oturum aktif');
      } else {
        debugPrint('Access token hala geçerli, yenileme gerekmiyor');
      }

      return true;
    } catch (e) {
      debugPrint('Token kontrolü ve yenileme hatası: $e');
      return false;
    }
  }

  // Token bilgilerini temizle (çıkış yap)
  Future<void> clearTokens() async {
    try {
      // Tüm yerel depolanmış verileri temizle
      await _secureStorage.clearAll();
      
      // Biyometrik ayarı sıfırla
      await _biometricService.disableBiometricAuthentication();
      
      debugPrint('Token bilgileri başarıyla temizlendi');
    } catch (e) {
      debugPrint('Token temizleme hatası: $e');
      // Hata olsa bile devam et, kullanıcı login sayfasına yönlendirilecek
      throw e;
    }
  }

  // Uygulama içinde token kontrolü ve geçersizse login sayfasına yönlendirme
  Future<bool> checkTokenAndRedirect() async {
    try {
      // Mevcut route kontrolü
      final currentRoute = getCurrentRoute();
      if (isTokenExemptRoute(currentRoute)) {
        debugPrint('Token kontrolünden muaf sayfa: $currentRoute, kontrol yapılmıyor');
        return true;
      }
      
      // Token servisinden token kontrolü yap
      final hasValidTokens = await _tokenService.hasValidTokens();
      
      if (!hasValidTokens) {
        // Sessizce token bilgilerini temizle
        await clearTokens();
        
        // Login sayfasına sessizce yönlendir
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (navigatorKey.currentContext != null) {
            Navigator.of(navigatorKey.currentContext!).pushNamedAndRemoveUntil('/login', (route) => false);
          }
        });
        
        return false;
      }
      
      return true;
    } catch (e) {
      // Hata durumunda da sessizce login sayfasına yönlendir
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigatorKey.currentContext != null) {
          Navigator.of(navigatorKey.currentContext!).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      });
      
      return false;
    }
  }

  // Telefon numarası doğrulama kodu kontrolü (TokenResponseDTO ile)
  Future<String> verifyPhoneNumber(String code) async {
    try {
      final response = await _apiService.post(
        '/user/verify/phone',
        data: {'code': code},
        useLoginDio: true,
      );

      if (response.statusCode == 200 && response.data != null) {
        if (response.data['success'] == true) {
          return response.data['message'] ?? 'Telefon numaranız başarıyla doğrulandı!';
        } else {
          final message = response.data['message'] ?? 'Doğrulama başarısız oldu.';
          throw Exception(message);
        }
      } else {
        final message = response.data?['message'] ?? 'Doğrulama başarısız oldu.';
        throw Exception(message);
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Bağlantı hatası');
    } catch (e) {
      throw Exception('Beklenmeyen bir hata oluştu: $e');
    }
  }

  // Yeniden doğrulama kodu gönder
  Future<ResponseMessage> resendVerificationCode(String phoneNumber) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/resend-code'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'phoneNumber': phoneNumber},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return ResponseMessage.fromJson(data);
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        return ResponseMessage.error(
          errorData['message'] ?? 'Kod gönderme işlemi başarısız oldu.',
        );
      }
    } catch (e) {
      return ResponseMessage.error('Bağlantı hatası: $e');
    }
  }
}
