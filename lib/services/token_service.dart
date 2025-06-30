import 'dart:convert';
import 'dart:io';
import 'dart:math' as Math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:dio/dio.dart';
import 'secure_storage_service.dart';
import '../models/auth_model.dart';
import 'package:http/http.dart' as http;
import '../main.dart'; // navigatorKey için ekledik

class TokenService {
  final SecureStorageService _secureStorage = SecureStorageService();
  final Dio _dio = Dio();
  
  // API endpoint'leri
  static const String baseUrl = 'http://192.168.219.61:8080/v1/api'; // API URL'nizi buraya girin
  static const String refreshEndpoint = '/auth/refresh';
  
  // Otomatik token yenileme için threshold (saniye)
  static const int _tokenRenewalThreshold = 30;
  
  // Singleton pattern
  static final TokenService _instance = TokenService._internal();
  
  factory TokenService() {
    return _instance;
  }
  
  TokenService._internal();
  
  // Login sayfasına yönlendirme metodu
  void _navigateToLogin() {
    // BuildContext'e ihtiyaç duymadan global yönlendirme için
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigatorKey.currentContext != null) {
        debugPrint('Kullanıcı login sayfasına yönlendiriliyor...');
        Navigator.of(navigatorKey.currentContext!).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    });
  }
  
  // Access token süresi doluyor mu kontrolü (tokenın %75'i dolduğunda yenileme yap)
  Future<bool> isAccessTokenExpiringSoon() async {
    final accessToken = await _secureStorage.getAccessToken();
    
    if (accessToken == null) {
      return true; // Token yoksa, süresi dolmuş kabul et
    }
    
    try {
      final decodedToken = JwtDecoder.decode(accessToken);
      
      // Token'ın süresini kontrol et
      if (JwtDecoder.isExpired(accessToken)) {
        return true; // Token süresi dolmuş
      }
      
      // Token'ın kalan süresini hesapla
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(decodedToken['exp'] * 1000);
      final currentDate = DateTime.now();
      final remainingTime = expiryDate.difference(currentDate).inSeconds;
      
      // Token süresinin son %25'indeyse yakında dolacak kabul et
      final totalTime = decodedToken['exp'] - decodedToken['iat'];
      final expiryThreshold = totalTime * 0.25; // Son %25
      
      return remainingTime < expiryThreshold;
    } catch (e) {
      debugPrint('Token süresi kontrol edilirken hata: $e');
      return true; // Hata durumunda, süresi dolmuş kabul et
    }
  }
  
  // Access token'ı yenile
  Future<bool> refreshAccessToken() async {
    try {
      // Refresh token'ı al
      final refreshToken = await _secureStorage.getRefreshToken();
      
      if (refreshToken == null) {
        debugPrint('Refresh token bulunamadı, yenileme yapılamıyor');
        return false;
      }

      // Refresh token'ın süresi dolmuş mu kontrol et
      final refreshTokenExpiry = await _secureStorage.getRefreshTokenExpiry();
      if (refreshTokenExpiry != null) {
        final expiry = DateTime.parse(refreshTokenExpiry);
        final now = DateTime.now();
        
        if (now.isAfter(expiry)) {
          debugPrint('Refresh token süresi dolmuş, yenileme yapılamıyor');
          _navigateToLogin();
          return false;
        }
      }

      debugPrint('Token yenileme isteği hazırlanıyor...');
      
      final options = Options(
        headers: {
          'Content-Type': 'application/json',
        },
        validateStatus: (status) {
          return status! < 500; // 500'den küçük tüm durum kodlarını kabul et
        },
      );
      
      // Yeni API yapısına göre request body hazırla
      final requestBody = {
        'refreshToken': refreshToken
      };
      
      // Token yenileme isteği
      final response = await _dio.post(
        '$baseUrl/auth/refresh',
        data: requestBody,
        options: options,
      );

      debugPrint('Token yenileme yanıtı alındı: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data != null) {
        debugPrint('Token yenileme başarılı, yanıt: ${response.data}');
        
        try {
          // Yeni API formatına göre yanıtı işle
          final accessToken = TokenDTO(
            token: response.data['token'],
            expiredAt: DateTime.parse(response.data['expiresAt']),
          );
          
          debugPrint('Alınan Access Token: ${accessToken.token.substring(0, Math.min(20, accessToken.token.length))}...');
          debugPrint('Alınan Access Token Süresi: ${accessToken.expiredAt}');
          
          // Yeni access token'ı kaydet
          await _secureStorage.setAccessToken(accessToken.token);
          await _secureStorage.setAccessTokenExpiry(accessToken.expiredAt.toIso8601String());
          
          debugPrint('Token başarıyla yenilendi, süresi: ${accessToken.expiredAt}');
          return true;
        } catch (e) {
          debugPrint('Token yanıtını işlerken hata: $e');
          return false;
        }
      } else {
        // Hata durumunu logla
        final statusCode = response.statusCode;
        final responseData = response.data;
        
        debugPrint('Token yenileme başarısız: Durum kodu: $statusCode');
        debugPrint('Yanıt: $responseData');
        
        // Token bulunamadı hatası veya 401/403 için tüm tokenları temizle ve login sayfasına yönlendir
        if (statusCode == 401 || statusCode == 403) {
          debugPrint('Yetkilendirme hatası, tokenlar temizleniyor...');
          await _secureStorage.clearTokens();
          
          // Login sayfasına yönlendir
          _navigateToLogin();
        }
        
        return false;
      }
    } on DioException catch (e) {
      debugPrint('Token yenileme DioException: ${e.message}');
      if (e.response != null) {
        debugPrint('Durum kodu: ${e.response?.statusCode}');
        debugPrint('Yanıt: ${e.response?.data}');
        
        // 401 veya 403 hata kodları için tokenları temizleyelim
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          debugPrint('Yetkilendirme hatası, tokenlar temizleniyor...');
          await _secureStorage.clearTokens();
          
          // Login sayfasına yönlendir
          _navigateToLogin();
        }
      }
      return false;
    } catch (e) {
      debugPrint('Token yenileme hatası: $e');
      return false;
    }
  }
  
  // Access token'ın süresi dolmak üzere mi kontrol et
  Future<bool> isAccessTokenAboutToExpire() async {
    try {
      // Access token'ı doğrudan al
      final accessToken = await _secureStorage.getAccessToken();
      
      if (accessToken == null) {
        debugPrint('Access token bulunamadı, yenileme gerekiyor');
        return true; // Eğer token yoksa, yenileme yapmalıyız
      }
      
      // JWT token'ı decode et ve süresi dolmuş mu kontrol et
      try {
        // Önce token'ın süresi dolmuş mu kontrol et
        if (JwtDecoder.isExpired(accessToken)) {
          debugPrint('Access token süresi dolmuş, yenileme gerekiyor');
          return true;
        }
        
        // Token'ın süresinin dolmasına kalan süreyi hesapla
        final decoded = JwtDecoder.decode(accessToken);
        final expiryTime = DateTime.fromMillisecondsSinceEpoch(decoded['exp'] * 1000);
        final now = DateTime.now();
        
        // Token'ın süresinin dolmasına kalan süre (saniye cinsinden)
        final remainingSeconds = expiryTime.difference(now).inSeconds;
        
        debugPrint('Access token süresinin dolmasına $remainingSeconds saniye kaldı');
        
        // Eğer kalan süre 30 saniyeden azsa, token'ı yenilememiz gerekiyor
        return remainingSeconds <= 30;
      } catch (e) {
        debugPrint('JWT token decode hatası: $e');
        return true; // Hata durumunda güvenli tarafta kal ve yenileme yap
      }
    } catch (e) {
      debugPrint('Token süresi kontrolü hatası: $e');
      return true; // Hata durumunda güvenli tarafta kal ve yenileme yap
    }
  }
  
  // Access token'ın süresi dolmuş mu kontrol et
  Future<bool> isAccessTokenExpired() async {
    try {
      // Access token expiry tarihini al
      final expiryStr = await _secureStorage.getAccessTokenExpiry();
      
      if (expiryStr == null) {
        return true; // Eğer expiry bilgisi yoksa, token süresi dolmuş sayılır
      }
      
      final expiry = DateTime.parse(expiryStr);
      final now = DateTime.now();
      
      // Token süresi dolmuş mu?
      return now.isAfter(expiry);
    } catch (e) {
      debugPrint('Token expiry kontrolü hatası: $e');
      return true; // Hata durumunda güvenli tarafta kal
    }
  }

  // Refresh token'ın süresi dolmuş mu kontrol et
  Future<bool> isRefreshTokenExpired() async {
    try {
      // Refresh token expiry tarihini al
      final expiryStr = await _secureStorage.getRefreshTokenExpiry();
      
      if (expiryStr == null) {
        return true; // Eğer expiry bilgisi yoksa, token süresi dolmuş sayılır
      }
      
      final expiry = DateTime.parse(expiryStr);
      final now = DateTime.now();
      
      // Token süresi dolmuş mu?
      return now.isAfter(expiry);
    } catch (e) {
      debugPrint('Refresh token expiry kontrolü hatası: $e');
      return true; // Hata durumunda güvenli tarafta kal
    }
  }
  
  // Cihaz bilgisi al
  Future<String> _getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        return 'Android ${Platform.operatingSystemVersion}';
      } else if (Platform.isIOS) {
        return 'iOS ${Platform.operatingSystemVersion}';
      } else {
        return 'Flutter ${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
      }
    } catch (e) {
      return 'Flutter App';
    }
  }
  
  // IP adresi al
  Future<String> _getIpAddress() async {
    try {
      final response = await http.get(Uri.parse('https://api.ipify.org'));
      if (response.statusCode == 200) {
        return response.body;
      }
    } catch (e) {
      debugPrint('IP adresi alınamadı: $e');
    }
    return '127.0.0.1';
  }
  
  // API istekleri için interceptor oluştur
  Interceptor get tokenInterceptor => InterceptorsWrapper(
    onRequest: (options, handler) async {
      // Login ve token yenileme istekleri için token kontrolü yapma
      if (options.path.contains('/auth/login') || options.path.contains('/auth/refresh')) {
        debugPrint('Login veya refresh isteği, token kontrolü yapılmıyor: ${options.path}');
        return handler.next(options);
      }
      
      // Mevcut rota kontrolü yap ve muaf sayfalar için token kontrolünü atla
      final currentRoute = getCurrentRoute();
      if (isTokenExemptRoute(currentRoute)) {
        debugPrint('Token kontrolünden muaf sayfa: $currentRoute, token kontrolü yapılmıyor');
        return handler.next(options);
      }
      
      try {
        // Access token kontrolü
        final accessToken = await _secureStorage.getAccessToken();
        if (accessToken == null) {
          // Sessizce login sayfasına yönlendir, hata gösterme
          _navigateToLogin();
          return handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
            ),
          );
        }
        
        // Access token'ın süresi dolmak üzere mi kontrol et
        final isAboutToExpire = await isAccessTokenAboutToExpire();
        
        if (isAboutToExpire) {
          debugPrint('Access token süresi dolmak üzere, yenileniyor...');
          // Token'ı yenile
          final refreshed = await refreshAccessToken();
          
          if (!refreshed) {
            // Sessizce login sayfasına yönlendir, hata gösterme
            _navigateToLogin();
            return handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.cancel,
              ),
            );
          }
          
          debugPrint('Token başarıyla yenilendi, isteğe devam ediliyor');
        }
        
        // İsteğe access token ekle
        final updatedAccessToken = await _secureStorage.getAccessToken();
        if (updatedAccessToken != null) {
          options.headers['Authorization'] = 'Bearer $updatedAccessToken';
          debugPrint('İsteğe access token eklendi');
        } else {
          // Sessizce login sayfasına yönlendir, hata gösterme
          _navigateToLogin();
          return handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
            ),
          );
        }
        
        return handler.next(options);
      } catch (e) {
        // Sessizce login sayfasına yönlendir, hata gösterme
        _navigateToLogin();
        return handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
          ),
        );
      }
    },
    onError: (error, handler) async {
      // 401 hatası alındıysa token yenilemeyi dene
      if (error.response?.statusCode == 401 || error.response?.statusCode == 403) {
        // Login ve refresh istekleri için yenileme yapma
        if (error.requestOptions.path.contains('/auth/login') || 
            error.requestOptions.path.contains('/auth/refresh')) {
          debugPrint('Login veya refresh isteği için token yenileme yapılmıyor');
          return handler.next(error);
        }
        
        debugPrint('${error.response?.statusCode} hatası alındı, token yenileniyor...');
        
        try {
          // Token'ı yenile
          final refreshed = await refreshAccessToken();
          
          if (refreshed) {
            // Yeni token ile isteği tekrar gönder
            final accessToken = await _secureStorage.getAccessToken();
            if (accessToken == null) {
              // Sessizce login sayfasına yönlendir, hata gösterme
              _navigateToLogin();
              return handler.reject(
                DioException(
                  requestOptions: error.requestOptions,
                  type: DioExceptionType.cancel,
                ),
              );
            }
            
            error.requestOptions.headers['Authorization'] = 'Bearer $accessToken';
            
            // İsteği tekrar oluştur
            final opts = Options(
              method: error.requestOptions.method,
              headers: error.requestOptions.headers,
            );
            
            debugPrint('İstek yeni token ile tekrar gönderiliyor...');
            
            try {
              final response = await _dio.request(
                error.requestOptions.path,
                options: opts,
                data: error.requestOptions.data,
                queryParameters: error.requestOptions.queryParameters,
              );
              
              debugPrint('İstek başarıyla yeniden gönderildi');
              return handler.resolve(response);
            } catch (retryError) {
              // Sessizce login sayfasına yönlendir, hata gösterme
              _navigateToLogin();
              return handler.reject(
                DioException(
                  requestOptions: error.requestOptions,
                  type: DioExceptionType.cancel,
                ),
              );
            }
          } else {
            // Sessizce login sayfasına yönlendir, hata gösterme
            _navigateToLogin();
            return handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                type: DioExceptionType.cancel,
              ),
            );
          }
        } catch (e) {
          // Sessizce login sayfasına yönlendir, hata gösterme
          _navigateToLogin();
          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              type: DioExceptionType.cancel,
            ),
          );
        }
      }
      
      return handler.next(error);
    },
  );
  
  // Geçerli bir token var mı kontrolü
  Future<bool> hasValidTokens() async {
    try {
      final accessToken = await _secureStorage.getAccessToken();
      final refreshToken = await _secureStorage.getRefreshToken();
      
      if (accessToken == null || refreshToken == null) {
        debugPrint('Token bulunamadı (Access: ${accessToken != null}, Refresh: ${refreshToken != null})');
        return false;
      }
      
      // JWT token'ların geçerliliğini kontrol et
      try {
        // Access token geçerli mi kontrol et
        final isAccessTokenExpired = JwtDecoder.isExpired(accessToken);
        
        if (!isAccessTokenExpired) {
          debugPrint('Access token geçerli, oturum aktif');
          return true; // Access token geçerli
        }
        
        // Access token süresi dolmuş, refresh token geçerli mi kontrol et
        final isRefreshTokenExpired = JwtDecoder.isExpired(refreshToken);
        
        if (isRefreshTokenExpired) {
          debugPrint('Refresh token süresi dolmuş, yeniden giriş gerekiyor');
          return false; // Her iki token da geçersiz
        }
        
        debugPrint('Access token süresi dolmuş, refresh token geçerli, token yenileniyor');
        // Refresh token geçerli, yeni access token almayı dene
        return await refreshAccessToken();
      } catch (e) {
        debugPrint('JWT token decode hatası: $e');
        return false; // JWT decode hatası, güvenli tarafta kal
      }
    } catch (e) {
      debugPrint('Token kontrolü hatası: $e');
      return false; // Genel bir hata, güvenli tarafta kal
    }
  }
  
  // Token'dan user ID bilgisini alma
  Future<int?> getUserIdFromToken() async {
    final accessToken = await _secureStorage.getAccessToken();
    
    if (accessToken == null) {
      return null;
    }
    
    try {
      final decodedToken = JwtDecoder.decode(accessToken);
      return decodedToken['userId'];
    } catch (e) {
      debugPrint('Token decode hatası: $e');
      return null;
    }
  }
  
  // Token'dan kullanıcı rollerini alma
  Future<List<String>> getUserRolesFromToken() async {
    final accessToken = await _secureStorage.getAccessToken();
    
    if (accessToken == null) {
      return [];
    }
    
    try {
      final decodedToken = JwtDecoder.decode(accessToken);
      final roles = decodedToken['roles'];
      
      if (roles is List) {
        return roles.cast<String>();
      }
      
      return [];
    } catch (e) {
      debugPrint('Token decode hatası: $e');
      return [];
    }
  }
  
  // Tokenleri temizle (çıkış yapma durumunda)
  Future<void> clearTokens() async {
    await _secureStorage.clearTokens();
  }

  /// Access token'ın süresi dolmasına 1 dakika kala otomatik yenileme
  Future<void> refreshAccessTokenIfNeeded() async {
    final expiryStr = await _secureStorage.getAccessTokenExpiry();
    if (expiryStr == null) return;

    final expiry = DateTime.parse(expiryStr);
    final now = DateTime.now();
    final difference = expiry.difference(now);

    if (difference.inSeconds < 60) { // 1 dakika kala
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null) return;

      try {
        final response = await Dio().post(
          '$baseUrl/auth/refresh',
          data: {'refreshToken': refreshToken},
          options: Options(headers: {'Content-Type': 'application/json'}),
        );

        if (response.statusCode == 200 && response.data != null) {
          final newAccessToken = response.data['token'];
          final newExpiresAt = response.data['expiresAt'];
          if (newAccessToken != null && newExpiresAt != null) {
            await _secureStorage.setAccessToken(newAccessToken);
            await _secureStorage.setAccessTokenExpiry(newExpiresAt);
            debugPrint('Yeni access token otomatik olarak kaydedildi.');
          }
        }
      } catch (e) {
        debugPrint('Access token otomatik yenileme hatası: $e');
      }
    }
  }

  /// Sade http ile access token yenileme fonksiyonu
  Future<void> refreshAccessTokenSimple() async {
    final refreshToken = await _secureStorage.getRefreshToken();
    if (refreshToken == null) return;

    // Refresh token'ın süresi dolmuş mu kontrol et
    final refreshTokenExpiry = await _secureStorage.getRefreshTokenExpiry();
    if (refreshTokenExpiry != null) {
      final expiry = DateTime.parse(refreshTokenExpiry);
      final now = DateTime.now();
      
      if (now.isAfter(expiry)) {
        debugPrint('Refresh token süresi dolmuş, yenileme yapılamıyor');
        _navigateToLogin();
        return;
      }
    }

    final response = await http.post(
      Uri.parse('$baseUrl/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "refreshToken": refreshToken
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _secureStorage.setAccessToken(data['token']);
      await _secureStorage.setAccessTokenExpiry(data['expiresAt']);
      debugPrint('Access token başarıyla yenilendi');
    } else {
      debugPrint("Token yenileme başarısız: ${response.body}");
      
      // 401 veya 403 hata kodları için tokenları temizleyelim
      if (response.statusCode == 401 || response.statusCode == 403) {
        debugPrint('Yetkilendirme hatası, tokenlar temizleniyor...');
        await _secureStorage.clearTokens();
        
        // Login sayfasına yönlendir
        _navigateToLogin();
      }
    }
  }
} 