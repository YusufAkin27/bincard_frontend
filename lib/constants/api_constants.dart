import 'package:flutter/foundation.dart';

class ApiConstants {
  // Base URL for API requests
  // Mevcut API URL'sini kullanıyoruz
  static const String baseUrl = 'http://192.168.174.214:8080/v1/api';
  
  // Ortam değişkenleri
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // API endpoints
  // Auth endpoints
  static String get loginEndpoint => '/auth/login';
  static String get signUpEndpoint => '/user/sign-up';
  static String get refreshTokenEndpoint => '/auth/refresh-token';
  static String get verifyCodeEndpoint => '/auth/verify-code';
  static String get resendCodeEndpoint => '/auth/resend-code';
  static String get forgotPasswordEndpoint => '/auth/forgot-password';
  static String get resetPasswordEndpoint => '/auth/reset-password';
  
  // User endpoints
  static String get userProfileEndpoint => '/user/profile';
  static String get updateUserEndpoint => '/user/update';
  static String get changePasswordEndpoint => '/user/change-password';
  
  // Content Type ve diğer header'lar
  static const String contentType = 'application/json';
  
  // API Headers
  static Map<String, String> get headers => {
    'Content-Type': contentType,
    'Accept': 'application/json',
  };
  
  // Add auth header with token
  static Map<String, String> getAuthHeaders(String token) {
    return {
      ...headers,
      'Authorization': 'Bearer $token',
    };
  }
}
