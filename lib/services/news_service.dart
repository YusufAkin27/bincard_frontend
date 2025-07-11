import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../models/news/news_type.dart';
import '../models/news/news_priority.dart';
import '../models/news/platform_type.dart';
import '../models/news/user_news_dto.dart';
import '../models/news/news_history_dto.dart';
import 'api_service.dart';
import 'secure_storage_service.dart';

class NewsService {
  final ApiService _apiService;
  final SecureStorageService _secureStorage;

  NewsService({
    ApiService? apiService,
    SecureStorageService? secureStorage,
  }) : 
    _apiService = apiService ?? ApiService(),
    _secureStorage = secureStorage ?? SecureStorageService();

  // Get active news
  Future<List<UserNewsDTO>> getActiveNews({PlatformType? platform, NewsType? type}) async {
    try {
      Map<String, dynamic> queryParams = {};
      
      if (platform != null) {
        queryParams['platform'] = platform.toString().split('.').last;
      }
      
      if (type != null) {
        queryParams['type'] = type.toString().split('.').last;
      }
      
      final response = await _apiService.get(
        ApiConstants.newsActiveEndpoint,
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;
        debugPrint('🔍 NewsService API Response: $responseData');
        
        // Direkt liste olarak geliyor mu kontrol et
        if (responseData is List) {
          debugPrint('🔍 NewsService: ${responseData.length} haber bulundu (doğrudan liste)');
          return responseData.map((item) => UserNewsDTO.fromJson(item)).toList();
        } 
        // Obje içinde data array'i olarak geliyor mu kontrol et
        else if (responseData is Map && responseData['data'] != null && responseData['data'] is List) {
          final List<dynamic> newsItems = responseData['data'];
          debugPrint('🔍 NewsService: ${newsItems.length} haber bulundu (data içinde)');
          return newsItems.map((item) => UserNewsDTO.fromJson(item)).toList();
        }
        // Sadece array olarak geliyor mu kontrol et
        else if (responseData is Map && responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> newsItems = responseData['data'];
          debugPrint('🔍 NewsService: ${newsItems.length} haber bulundu (success içinde)');
          return newsItems.map((item) => UserNewsDTO.fromJson(item)).toList();
        }
        
        // Her durumda haberleri logla
        if (responseData is List) {
          for (var item in responseData) {
            debugPrint('🔍 Haber JSON: $item');
            debugPrint('🔍 Haber başlık: ${item['title']}');
          }
        }
      }
      
      return [];
    } on DioException catch (e) {
      debugPrint('Haber getirme hatası: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('Haber getirme genel hatası: $e');
      return [];
    }
  }

  // Get news by category
  Future<List<UserNewsDTO>> getNewsByCategory(NewsType category, {PlatformType? platform}) async {
    try {
      Map<String, dynamic> queryParams = {
        'category': category.toString().split('.').last,
      };
      
      if (platform != null) {
        queryParams['platform'] = platform.toString().split('.').last;
      }
      
      final response = await _apiService.get(
        ApiConstants.newsByCategoryEndpoint,
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> newsItems = responseData['data'];
          return newsItems.map((item) => UserNewsDTO.fromJson(item)).toList();
        }
      }
      
      return [];
    } on DioException catch (e) {
      debugPrint('Kategoriye göre haber getirme hatası: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('Kategoriye göre haber getirme genel hatası: $e');
      return [];
    }
  }

  // Get news view history
  Future<List<NewsHistoryDTO>> getNewsViewHistory({PlatformType? platform}) async {
    try {
      Map<String, dynamic> queryParams = {};
      
      if (platform != null) {
        queryParams['platform'] = platform.toString().split('.').last;
      }
      
      final response = await _apiService.get(
        ApiConstants.newsViewHistoryEndpoint,
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> historyItems = responseData['data'];
          return historyItems.map((item) => NewsHistoryDTO.fromJson(item)).toList();
        }
      }
      
      return [];
    } on DioException catch (e) {
      debugPrint('Haber geçmişi getirme hatası: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('Haber geçmişi getirme genel hatası: $e');
      return [];
    }
  }

  // Record news view
  Future<bool> recordNewsView(int newsId) async {
    try {
      final response = await _apiService.post(
        ApiConstants.newsViewEndpoint(newsId.toString()),
      );
      
      return response.statusCode == 200;
    } on DioException catch (e) {
      debugPrint('Haber görüntüleme kayıt hatası: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Haber görüntüleme kayıt genel hatası: $e');
      return false;
    }
  }
  
  // Increment view count locally (to avoid waiting for server refresh)
  UserNewsDTO incrementLocalViewCount(UserNewsDTO news) {
    // This is a helper method to update the UI instantly while the server processes the view
    return UserNewsDTO(
      id: news.id,
      title: news.title,
      content: news.content,
      image: news.image,
      videoUrl: news.videoUrl,
      thumbnailUrl: news.thumbnailUrl,
      likedByUser: news.likedByUser,
      viewedByUser: true, // Mark as viewed
      priority: news.priority,
      type: news.type,
      createdAt: news.createdAt,
      summary: news.summary,
      viewCount: news.viewCount + 1, // Increment the view count
      likeCount: news.likeCount,
    );
  }

  // Get suggested news
  Future<List<UserNewsDTO>> getSuggestedNews({PlatformType? platform}) async {
    try {
      Map<String, dynamic> queryParams = {};
      
      if (platform != null) {
        queryParams['platform'] = platform.toString().split('.').last;
      }
      
      final response = await _apiService.get(
        ApiConstants.newsSuggestedEndpoint,
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> newsItems = responseData['data'];
          return newsItems.map((item) => UserNewsDTO.fromJson(item)).toList();
        }
      }
      
      return [];
    } on DioException catch (e) {
      debugPrint('Önerilen haberler getirme hatası: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('Önerilen haberler getirme genel hatası: $e');
      return [];
    }
  }

  // Get user specific news
  Future<List<UserNewsDTO>> getUserNews({required String userId, PlatformType? platform}) async {
    try {
      Map<String, dynamic> queryParams = {
        'userId': userId,
      };
      
      if (platform != null) {
        queryParams['platform'] = platform.toString().split('.').last;
      }
      
      final response = await _apiService.get(
        ApiConstants.newsActiveEndpoint, // Şimdilik active endpointi kullanıyoruz, gerekirse değişecek
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> newsItems = responseData['data'];
          return newsItems.map((item) => UserNewsDTO.fromJson(item)).toList();
        }
      }
      
      return [];
    } on DioException catch (e) {
      debugPrint('Kullanıcı haber getirme hatası: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('Kullanıcı haber getirme genel hatası: $e');
      return [];
    }
  }

  // ID'ye göre haber getir (deep link için)
  Future<UserNewsDTO?> getNewsById(int newsId) async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.newsBaseEndpoint}/$newsId',
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;
        debugPrint('🔍 NewsService API Response (getNewsById): $responseData');
        
        if (responseData['success'] == true && responseData['data'] != null) {
          // API'den gelen veriyi UserNewsDTO'ya dönüştür
          final newsData = responseData['data'];
          return UserNewsDTO.fromJson(newsData);
        }
      }
      
      return null;
    } on DioException catch (e) {
      debugPrint('ID\'ye göre haber getirme hatası: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('ID\'ye göre haber getirme genel hatası: $e');
      return null;
    }
  }
}
