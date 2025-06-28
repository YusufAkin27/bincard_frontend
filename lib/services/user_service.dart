import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/auth_model.dart';
import 'token_service.dart';
import 'secure_storage_service.dart';

class UserService {
  final Dio _dio = Dio();
  final TokenService _tokenService = TokenService();
  final SecureStorageService _secureStorage = SecureStorageService();
  
  // API endpoint
  static const String baseUrl = 'http://192.168.219.61:8080/v1/api';
  
  // Singleton pattern
  static final UserService _instance = UserService._internal();
  
  factory UserService() {
    return _instance;
  }
  
  UserService._internal() {
    _dio.interceptors.add(_tokenService.tokenInterceptor);
  }
  
  // Kullanıcı kaydı (sign-up)
  Future<ResponseMessage> signUp(String firstName, String lastName, String phoneNumber, String password) async {
    try {
      final createUserRequest = {
        'firstName': firstName,
        'lastName': lastName,
        'telephone': phoneNumber,
        'password': password
      };
      
      debugPrint('Kullanıcı kaydı yapılıyor: $phoneNumber');
      
      final response = await _dio.post(
        '$baseUrl/user/sign-up',
        data: createUserRequest,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Kullanıcı kaydı başarılı: ${response.data}');
        return ResponseMessage.fromJson(response.data);
      } else {
        debugPrint('Kullanıcı kaydı başarısız: ${response.statusCode} - ${response.data}');
        return ResponseMessage.error('Kayıt işlemi başarısız: ${response.data['message'] ?? 'Bilinmeyen hata'}');
      }
    } on DioException catch (e) {
      debugPrint('Kullanıcı kaydı DioException: ${e.message}');
      debugPrint('Response: ${e.response?.data}');
      return ResponseMessage.error(e.response?.data?['message'] ?? 'Bağlantı hatası');
    } catch (e) {
      debugPrint('Kullanıcı kaydı hatası: $e');
      return ResponseMessage.error('Beklenmeyen bir hata oluştu: $e');
    }
  }
  
  // Telefon numarası doğrulama
  Future<ResponseMessage> verifyPhoneNumber(String code) async {
    try {
      debugPrint('Telefon doğrulama kodu gönderiliyor: $code');
      
      final formData = FormData.fromMap({
        'code': code,
      });
      
      final response = await _dio.post(
        '$baseUrl/user/verify-phone',
        data: formData,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
      );
      
      if (response.statusCode == 200) {
        debugPrint('Telefon doğrulama başarılı: ${response.data}');
        return ResponseMessage.fromJson(response.data);
      } else {
        debugPrint('Telefon doğrulama başarısız: ${response.statusCode} - ${response.data}');
        return ResponseMessage.error('Doğrulama başarısız: ${response.data['message'] ?? 'Bilinmeyen hata'}');
      }
    } on DioException catch (e) {
      debugPrint('Telefon doğrulama DioException: ${e.message}');
      debugPrint('Response: ${e.response?.data}');
      return ResponseMessage.error(e.response?.data?['message'] ?? 'Bağlantı hatası');
    } catch (e) {
      debugPrint('Telefon doğrulama hatası: $e');
      return ResponseMessage.error('Beklenmeyen bir hata oluştu: $e');
    }
  }
  
  // Doğrulama kodunu yeniden gönder
  Future<ResponseMessage> resendCode(String phoneNumber) async {
    try {
      debugPrint('Doğrulama kodu yeniden isteniyor: $phoneNumber');
      
      final formData = FormData.fromMap({
        'phoneNumber': phoneNumber,
      });
      
      final response = await _dio.post(
        '$baseUrl/user/resend-code',
        data: formData,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
      );
      
      if (response.statusCode == 200) {
        debugPrint('Kod yeniden gönderme başarılı: ${response.data}');
        return ResponseMessage.fromJson(response.data);
      } else {
        debugPrint('Kod yeniden gönderme başarısız: ${response.statusCode} - ${response.data}');
        return ResponseMessage.error('Kod gönderme başarısız: ${response.data['message'] ?? 'Bilinmeyen hata'}');
      }
    } on DioException catch (e) {
      debugPrint('Kod yeniden gönderme DioException: ${e.message}');
      debugPrint('Response: ${e.response?.data}');
      return ResponseMessage.error(e.response?.data?['message'] ?? 'Bağlantı hatası');
    } catch (e) {
      debugPrint('Kod yeniden gönderme hatası: $e');
      return ResponseMessage.error('Beklenmeyen bir hata oluştu: $e');
    }
  }
  
  // Kullanıcı profil bilgilerini getir
  Future<UserProfile> getUserProfile() async {
    try {
      // Access token al
      final accessToken = await _secureStorage.getAccessToken();
      
      if (accessToken == null) {
        throw Exception('Access token bulunamadı');
      }
      
      debugPrint('Profil bilgileri getiriliyor...');
      
      final response = await _dio.get(
        '$baseUrl/user/profile',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );
      
      if (response.statusCode == 200 && response.data != null) {
        debugPrint('Profil bilgileri başarıyla alındı: ${response.data}');
        return UserProfile.fromJson(response.data);
      } else {
        throw Exception('Profil bilgileri alınamadı');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        debugPrint('Token süresi dolmuş, yenileniyor...');
        // Token yenileme işlemi tokenInterceptor tarafından otomatik yapılacak
        // Bu noktada yeniden deneme yapabiliriz
        return await _retryGetUserProfile();
      }
      
      debugPrint('Profil getirme hatası (DioException): ${e.message}');
      debugPrint('Response: ${e.response?.data}');
      throw Exception('Profil bilgileri alınamadı: ${e.message}');
    } catch (e) {
      debugPrint('Profil getirme hatası: $e');
      throw Exception('Profil bilgileri alınamadı: $e');
    }
  }
  
  // Profil bilgilerini almayı yeniden dene (token yenilendikten sonra)
  Future<UserProfile> _retryGetUserProfile() async {
    try {
      // Refresh token ile yeni access token al
      final refreshSuccess = await _tokenService.refreshAccessToken();
      
      if (!refreshSuccess) {
        throw Exception('Token yenilenemedi');
      }
      
      final newAccessToken = await _secureStorage.getAccessToken();
      
      if (newAccessToken == null) {
        throw Exception('Yeni access token alınamadı');
      }
      
      debugPrint('Token yenilendi, profil bilgileri tekrar getiriliyor...');
      
      final response = await _dio.get(
        '$baseUrl/user/profile',
        options: Options(
          headers: {
            'Authorization': 'Bearer $newAccessToken',
          },
        ),
      );
      
      if (response.statusCode == 200 && response.data != null) {
        debugPrint('Profil bilgileri başarıyla alındı: ${response.data}');
        return UserProfile.fromJson(response.data);
      } else {
        throw Exception('Profil bilgileri alınamadı');
      }
    } catch (e) {
      debugPrint('Profil bilgilerini yeniden getirme hatası: $e');
      throw Exception('Profil bilgileri alınamadı: $e');
    }
  }
  
  // Kullanıcı profil bilgilerini güncelle (MultipartForm destekli)
  Future<ResponseMessage> updateUserProfile(UpdateUserRequest updateRequest, File? profilePhoto) async {
    try {
      final accessToken = await _secureStorage.getAccessToken();
      
      if (accessToken == null) {
        throw Exception('Access token bulunamadı');
      }
      
      // MultipartFormData oluştur
      final formData = FormData();
      
      // JSON verisini ekle
      formData.fields.add(MapEntry('data', updateRequest.toJson().toString()));
      
      // Profil fotoğrafı varsa ekle
      if (profilePhoto != null) {
        final fileName = profilePhoto.path.split('/').last;
        formData.files.add(
          MapEntry(
            'profilePhoto',
            await MultipartFile.fromFile(
              profilePhoto.path,
              filename: fileName,
            ),
          ),
        );
      }
      
      final response = await _dio.put(
        '$baseUrl/user/update-profile',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        debugPrint('Profil güncelleme başarılı: ${response.data}');
        return ResponseMessage.fromJson(response.data);
      } else {
        debugPrint('Profil güncelleme başarısız: ${response.statusCode} - ${response.data}');
        return ResponseMessage.error('Güncelleme başarısız: ${response.data['message'] ?? 'Bilinmeyen hata'}');
      }
    } on DioException catch (e) {
      debugPrint('Profil güncelleme DioException: ${e.message}');
      debugPrint('Response: ${e.response?.data}');
      return ResponseMessage.error(e.response?.data?['message'] ?? 'Bağlantı hatası');
    } catch (e) {
      debugPrint('Profil güncelleme hatası: $e');
      return ResponseMessage.error('Beklenmeyen bir hata oluştu: $e');
    }
  }
}

// Profil güncelleme için request modeli
class UpdateUserRequest {
  final String? firstName;
  final String? lastName;
  final String? email;
  
  UpdateUserRequest({
    this.firstName,
    this.lastName,
    this.email,
  });
  
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (firstName != null) data['firstName'] = firstName;
    if (lastName != null) data['lastName'] = lastName;
    if (email != null) data['email'] = email;
    return data;
  }
} 