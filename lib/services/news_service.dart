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
        
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> newsItems = responseData['data'];
          debugPrint('🔍 NewsService: ${newsItems.length} haber bulundu');
          
          // Her haberin içeriğini logla
          for (var item in newsItems) {
            debugPrint('🔍 Haber JSON: $item');
            debugPrint('🔍 Haber başlık: ${item['title']}');
            debugPrint('🔍 Video alanları: videoUrl=${item['videoUrl']}, video_url=${item['video_url']}, video=${item['video']}, media=${item['media']}');
          }
          
          return newsItems.map((item) => UserNewsDTO.fromJson(item)).toList();
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
      // Demo haber oluştur (API çalışmadığında test için)
      return _createDemoNewsById(newsId);
    } catch (e) {
      debugPrint('ID\'ye göre haber getirme genel hatası: $e');
      // Demo haber oluştur (API çalışmadığında test için)
      return _createDemoNewsById(newsId);
    }
  }
  
  // Demo haber oluştur (API çalışmadığında test için)
  UserNewsDTO? _createDemoNewsById(int newsId) {
    // Geliştirme/test ortamı için örnek haberler
    final demoNewsList = _getDemoNewsWithVideo();
    
    // ID'ye göre haber bul
    try {
      return demoNewsList.firstWhere((news) => news.id == newsId);
    } catch (e) {
      // Belirtilen ID'de haber bulunamazsa, demo liste içinden rastgele bir haber döndür
      if (demoNewsList.isNotEmpty) {
        return demoNewsList.first;
      }
      return null;
    }
  }
  
  // Demo haberler listesi (video içeren) oluştur
  List<UserNewsDTO> _getDemoNewsWithVideo() {
    return [
      UserNewsDTO(
        id: 1,
        title: 'Demo Video Haber 1',
        content: 'Bu bir test video haberidir. Video içeriği test amaçlıdır.',
        image: 'https://res.cloudinary.com/demo/video/upload/v1688883315/samples/elephants.mp4',
        videoUrl: 'https://res.cloudinary.com/demo/video/upload/v1688883315/samples/elephants.mp4',
        thumbnailUrl: 'https://res.cloudinary.com/demo/image/upload/v1688883315/samples/elephants.jpg',
        likedByUser: false,
        viewedByUser: false,
        priority: NewsPriorityExtension.fromString('NORMAL'),
        type: NewsTypeExtension.fromString('DUYURU'),
        createdAt: DateTime.now(),
        summary: 'Video haber özeti',
      ),
      UserNewsDTO(
        id: 2,
        title: 'Demo Video Haber 2',
        content: 'Bu bir başka test video haberidir. Video içeriği test amaçlıdır.',
        image: 'https://res.cloudinary.com/demo/video/upload/v1688883315/samples/sea-turtle.mp4',
        videoUrl: 'https://res.cloudinary.com/demo/video/upload/v1688883315/samples/sea-turtle.mp4',
        thumbnailUrl: 'https://res.cloudinary.com/demo/image/upload/v1688883315/samples/sea-turtle.jpg',
        likedByUser: false,
        viewedByUser: false,
        priority: NewsPriorityExtension.fromString('NORMAL'),
        type: NewsTypeExtension.fromString('KAMPANYA'),
        createdAt: DateTime.now(),
        summary: 'Video haber özeti',
      ),
      UserNewsDTO(
        id: 3,
        title: 'Demo Görsel Haber',
        content: 'Bu bir test resim haberidir. Resim içeriği test amaçlıdır.',
        image: 'https://res.cloudinary.com/demo/image/upload/v1688883315/samples/landscapes/beach-boat.jpg',
        videoUrl: null,
        thumbnailUrl: null,
        likedByUser: false,
        viewedByUser: false,
        priority: NewsPriorityExtension.fromString('NORMAL'),
        type: NewsTypeExtension.fromString('BILGILENDIRME'),
        createdAt: DateTime.now(),
        summary: 'Resim haber özeti',
      ),
    ];
  }
}
