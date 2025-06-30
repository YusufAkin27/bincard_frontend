import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'token_service.dart';

class ApiService {
  late Dio _dio;
  
  // API endpoint'i
  static const String baseUrl = 'http://192.168.219.61:8080/v1/api';
  
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  
  factory ApiService() {
    return _instance;
  }
  
  ApiService._internal() {
    _initializeDio();
  }

  void _initializeDio() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      contentType: 'application/json',
      responseType: ResponseType.json,
    ));

    // Log interceptor ekle (sadece debug modunda)
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
      ));
    }
  }

  // Token interceptor'ı sonradan ekle (login işlemi için önemli)
  void setupTokenInterceptor() {
    try {
      // Önceki token interceptor'ı kaldır (eğer varsa)
      _dio.interceptors.removeWhere((interceptor) => 
        interceptor is InterceptorsWrapper && 
        interceptor.toString().contains('tokenInterceptor'));
      
      // Token interceptor ekle
      final tokenService = TokenService();
      _dio.interceptors.add(tokenService.tokenInterceptor);
      debugPrint('Token interceptor eklendi');
    } catch (e) {
      debugPrint('Token interceptor eklenirken hata: $e');
    }
  }
  
  // Token interceptor'ı kaldır
  void removeTokenInterceptor() {
    try {
      _dio.interceptors.removeWhere((interceptor) => 
        interceptor is InterceptorsWrapper && 
        interceptor.toString().contains('tokenInterceptor'));
      debugPrint('Token interceptor kaldırıldı');
    } catch (e) {
      debugPrint('Token interceptor kaldırılırken hata: $e');
    }
  }

  // Login işlemi için interceptor olmadan Dio instance'ı
  Dio get loginDio {
    // Yeni bir Dio instance'ı oluştur (interceptor'sız)
    final loginDio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      contentType: 'application/json',
      responseType: ResponseType.json,
    ));
    
    // Log interceptor ekle (sadece debug modunda)
    if (kDebugMode) {
      loginDio.interceptors.add(LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
      ));
    }
    
    return loginDio;
  }

  // Normal kullanım için Dio
  Dio get dio => _dio;

  // POST isteği
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool useLoginDio = false, // Login için özel Dio kullan
  }) async {
    try {
      final dio = useLoginDio ? loginDio : _dio;
      return await dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      rethrow;
    }
  }

  // GET isteği
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      rethrow;
    }
  }

  // PUT isteği
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      rethrow;
    }
  }

  // DELETE isteği
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      rethrow;
    }
  }
} 