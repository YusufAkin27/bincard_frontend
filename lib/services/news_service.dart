import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../models/news/news_type.dart';
import '../models/news/news_priority.dart';
import '../models/news/platform_type.dart';
import '../models/news/user_news_dto.dart';
import '../models/news/news_history_dto.dart';
import '../models/news/news_page.dart';
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
  Future<NewsPage> getActiveNews({PlatformType? platform, NewsType? type, int page = 0, int size = 20}) async {
    try {
      Map<String, dynamic> queryParams = {
        'page': page,
        'size': size
      };
      
      // Platform parametresi zorunlu
      if (platform != null) {
        queryParams['platform'] = platform.toString().split('.').last;
      } else {
        // Default olarak MOBILE kullan
        queryParams['platform'] = 'MOBILE';
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
        
        // API paginated response döndürüyor
        if (responseData is Map<String, dynamic>) {
          return NewsPage.fromJson(responseData);
        }
        
        // Legacy destek - eğer direkt liste dönerse
        if (responseData is List) {
          debugPrint('🔍 NewsService: ${responseData.length} haber bulundu (eski format)');
          final newsList = responseData.map((item) => UserNewsDTO.fromJson(item)).toList();
          return NewsPage(
            content: newsList,
            pageNumber: 0,
            pageSize: newsList.length,
            totalElements: newsList.length,
            totalPages: 1,
            isFirst: true,
            isLast: true,
          );
        }
      }
      
      return NewsPage.empty();
    } on DioException catch (e) {
      debugPrint('Haber getirme hatası: ${e.message}');
      return NewsPage.empty();
    } catch (e) {
      debugPrint('Haber getirme genel hatası: $e');
      return NewsPage.empty();
    }
  }

  // Get news by category
  Future<NewsPage> getNewsByCategory(NewsType category, {PlatformType? platform, int page = 0, int size = 20}) async {
    try {
      Map<String, dynamic> queryParams = {
        'category': category.toString().split('.').last,
        'page': page,
        'size': size
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
        
        // Check for paginated response
        if (responseData is Map<String, dynamic> && responseData.containsKey('content')) {
          return NewsPage.fromJson(responseData);
        }
        
        // Legacy format support
        if (responseData is Map<String, dynamic> && responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> newsItems = responseData['data'];
          final newsList = newsItems.map((item) => UserNewsDTO.fromJson(item)).toList();
          return NewsPage(
            content: newsList,
            pageNumber: 0,
            pageSize: newsList.length,
            totalElements: newsList.length,
            totalPages: 1,
            isFirst: true,
            isLast: true,
          );
        }
      }
      
      return NewsPage.empty();
    } on DioException catch (e) {
      debugPrint('Kategoriye göre haber getirme hatası: ${e.message}');
      return NewsPage.empty();
    } catch (e) {
      debugPrint('Kategoriye göre haber getirme genel hatası: $e');
      return NewsPage.empty();
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
  Future<NewsPage> getSuggestedNews({PlatformType? platform, int page = 0, int size = 20}) async {
    try {
      Map<String, dynamic> queryParams = {
        'page': page,
        'size': size
      };
      
      if (platform != null) {
        queryParams['platform'] = platform.toString().split('.').last;
      }
      
      final response = await _apiService.get(
        ApiConstants.newsSuggestedEndpoint,
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;
        
        // Check for paginated response
        if (responseData is Map<String, dynamic> && responseData.containsKey('content')) {
          return NewsPage.fromJson(responseData);
        }
        
        // Legacy format support
        if (responseData is Map<String, dynamic> && responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> newsItems = responseData['data'];
          final newsList = newsItems.map((item) => UserNewsDTO.fromJson(item)).toList();
          return NewsPage(
            content: newsList,
            pageNumber: 0,
            pageSize: newsList.length,
            totalElements: newsList.length,
            totalPages: 1,
            isFirst: true,
            isLast: true,
          );
        }
      }
      
      return NewsPage.empty();
    } on DioException catch (e) {
      debugPrint('Önerilen haberler getirme hatası: ${e.message}');
      return NewsPage.empty();
    } catch (e) {
      debugPrint('Önerilen haberler getirme genel hatası: $e');
      return NewsPage.empty();
    }
  }

  // Get user specific news
  Future<NewsPage> getUserNews({required String userId, PlatformType? platform, int page = 0, int size = 20}) async {
    try {
      Map<String, dynamic> queryParams = {
        'userId': userId,
        'page': page,
        'size': size
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
        
        // Check for paginated response
        if (responseData is Map<String, dynamic> && responseData.containsKey('content')) {
          return NewsPage.fromJson(responseData);
        }
        
        // Legacy format support
        if (responseData is Map<String, dynamic> && responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> newsItems = responseData['data'];
          final newsList = newsItems.map((item) => UserNewsDTO.fromJson(item)).toList();
          return NewsPage(
            content: newsList,
            pageNumber: 0,
            pageSize: newsList.length,
            totalElements: newsList.length,
            totalPages: 1,
            isFirst: true,
            isLast: true,
          );
        }
      }
      
      return NewsPage.empty();
    } on DioException catch (e) {
      debugPrint('Kullanıcı haber getirme hatası: ${e.message}');
      return NewsPage.empty();
    } catch (e) {
      debugPrint('Kullanıcı haber getirme genel hatası: $e');
      return NewsPage.empty();
    }
  }

  // ID'ye göre haber getir (deep link için)
  Future<UserNewsDTO?> getNewsById(int newsId) async {
    try {
      _apiService.setupTokenInterceptor(); // Token interceptor her zaman eklensin
      final response = await _apiService.get(
        ApiConstants.newsDetailWithPlatformEndpoint(newsId.toString()),
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;
        debugPrint('🔍 NewsService API Response (getNewsById): $responseData');
        
        // API direkt haber objesini döndürüyor, success wrapper yok
        return UserNewsDTO.fromJson(responseData);
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

  /// Haberi beğen
  Future<bool> likeNews(int newsId) async {
    try {
      final response = await _apiService.post(
        ApiConstants.newsLikeEndpoint(newsId.toString()),
      );
      if (response.statusCode == 200 && response.data != null && response.data['success'] == true) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Haber beğenme hatası: $e');
      return false;
    }
  }

  /// Haber beğenisini kaldır
  Future<bool> unlikeNews(int newsId) async {
    try {
      final response = await _apiService.delete(
        ApiConstants.newsUnlikeEndpoint(newsId.toString()),
      );
      if (response.statusCode == 200 && response.data != null && response.data['success'] == true) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Haber beğeni kaldırma hatası: $e');
      return false;
    }
  }

  /// Beğendiğim haberleri getir
  Future<List<UserNewsDTO>> getLikedNews() async {
    try {
      final response = await _apiService.get(
        ApiConstants.newsLikedEndpoint,
      );
      if (response.statusCode == 200 && response.data != null) {
        // API paginated response: content anahtarı ile geliyor
        if (response.data is Map<String, dynamic> && response.data.containsKey('content')) {
          final List<dynamic> newsList = response.data['content'];
          return newsList.map((item) => UserNewsDTO.fromJson(item)).toList();
        }
        // Legacy: success/data
        if (response.data['success'] == true && response.data['data'] != null) {
          final List<dynamic> newsList = response.data['data'];
          return newsList.map((item) => UserNewsDTO.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Beğenilen haberleri getirme hatası: $e');
      return [];
    }
  }
}
