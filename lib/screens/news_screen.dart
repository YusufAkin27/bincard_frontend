import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/news/user_news_dto.dart';
import '../models/news/news_type.dart';
import '../models/news/news_priority.dart';
import '../models/news/platform_type.dart';
import '../services/news_service.dart';
import '../widgets/video_player_widget.dart';
import 'news_detail_screen.dart';
import 'package:share_plus/share_plus.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<UserNewsDTO> _allNews = [];
  
  // Filtrelenmiş haber listeleri için getter'lar
  List<UserNewsDTO> get _importantNews => _allNews
      .where((news) => news.priority == NewsPriority.YUKSEK || 
                        news.priority == NewsPriority.COK_YUKSEK ||
                        news.priority == NewsPriority.KRITIK)
      .toList();
  List<UserNewsDTO> get _announcements => _allNews
      .where((news) => news.type == NewsType.DUYURU)
      .toList();
  List<UserNewsDTO> get _projects => _allNews
      .where((news) => news.type == NewsType.KAMPANYA || news.type == NewsType.ETKINLIK)
      .toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Türkçe zaman formatı için
    timeago.setLocaleMessages('tr', timeago.TrMessages());
    
    // Haberleri yükle
    _loadNews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshNews() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _loadNews();
    } catch (e) {
      debugPrint('Haberleri yenileme hatası: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadNews() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final newsService = NewsService();
      final news = await newsService.getActiveNews(platform: PlatformType.MOBILE);
      
      debugPrint('📰 API\'dan gelen haber sayısı: ${news.length}');
      for (var newsItem in news) {
        debugPrint('📰 Haber: ${newsItem.title} - Video: ${newsItem.videoUrl}');
      }
      
      // API'dan veri gelmediyse demo veri ekle
      if (news.isEmpty) {
        debugPrint('📰 API\'dan veri gelmedi, demo data kullanılıyor');
        final demoNews = _getDemoNewsWithVideo();
        debugPrint('📰 Demo haber sayısı: ${demoNews.length}');
        setState(() {
          _allNews = demoNews;
          _isLoading = false;
        });
      } else {
        debugPrint('📰 API\'dan gelen veriler kullanılıyor');
        setState(() {
          _allNews = news;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Haberler yüklenirken hata: $e');
      // Hata durumunda demo veri göster
      debugPrint('📰 Hata nedeniyle demo data kullanılıyor');
      final demoNews = _getDemoNewsWithVideo();
      setState(() {
        _allNews = demoNews;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // Geri dönme butonu beyaz
        title: const Text(
          'Haberler ve Duyurular',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.7),
              tabs: const [
                Tab(text: 'Tümü'),
                Tab(text: 'Önemli'),
                Tab(text: 'Duyurular'),
                Tab(text: 'Projeler'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNewsList(_allNews),
          _buildNewsList(_importantNews),
          _buildNewsList(_announcements),
          _buildNewsList(_projects),
        ],
      ),
    );
  }

  Widget _buildNewsList(List<UserNewsDTO> newsList) {
    return RefreshIndicator(
      onRefresh: _refreshNews,
      color: AppTheme.primaryColor,
      backgroundColor: Colors.white,
      displacement: 40.0,
      strokeWidth: 3.0,
      child: _isLoading
          ? _buildLoadingIndicator()
          : newsList.isEmpty
              ? _buildEmptyList()
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 16, bottom: 24, left: 16, right: 16),
                  itemCount: newsList.length,
                  itemBuilder: (context, index) {
                    final news = newsList[index];
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.only(bottom: 20),
                      child: _buildNewsCard(news),
                    );
                  },
                ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppTheme.primaryColor,
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          Text(
            'Haberler yükleniyor...',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.dividerColor.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.article_outlined,
              size: 80,
              color: AppTheme.primaryColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Haber bulunamadı',
            style: TextStyle(
              fontSize: 20,
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Şu anda görüntülenecek haber bulunmuyor. Lütfen daha sonra tekrar kontrol edin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshNews,
            icon: const Icon(Icons.refresh),
            label: const Text('Yenile'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(UserNewsDTO news) {
    final bool isImportant = news.priority == NewsPriority.YUKSEK || 
                             news.priority == NewsPriority.COK_YUKSEK ||
                             news.priority == NewsPriority.KRITIK;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showNewsDetails(news),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Medya kısmı
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      child: _buildNewsMedia(news),
                    ),
                  ),
                  
                  // Önemli haber ise üst köşeye etiket ekle
                  if (isImportant)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.star, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Önemli',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              
              // İçerik kısmı
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kategori ve Tarih
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(news.type).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getCategoryIcon(news.type),
                                size: 14,
                                color: _getCategoryColor(news.type),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _getCategoryName(news.type),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _getCategoryColor(news.type),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: AppTheme.textSecondaryColor.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeago.format(news.date, locale: 'tr'),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 14),
                    
                    // Başlık
                    Text(
                      news.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Özet
                    Text(
                      news.summary ?? news.content,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Alt butonlar
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.remove_red_eye, size: 18),
                            label: const Text('Detaylar'),
                            onPressed: () => _showNewsDetails(news),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.share_rounded),
                          onPressed: () => _shareNews(news),
                          style: IconButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: AppTheme.dividerColor,
                              ),
                            ),
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.favorite_border_rounded),
                          onPressed: () {
                            // Beğenme işlemi - gelecekte eklenecek
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Beğenme özelliği yakında eklenecek'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: IconButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: AppTheme.dividerColor,
                              ),
                            ),
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNewsDetails(UserNewsDTO news) {
    // Haber görüntüleme kaydını tut
    NewsService().recordNewsView(news.id);
    
    // Direkt olarak haber detay sayfasına git
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NewsDetailScreen(news: news)),
    );
  }
  
  void _playVideo(UserNewsDTO news) {
    // Kullanıcıya normal detay sayfası veya video oynatıcı seçeneği sun
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Kapatma çubuğu
              Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Video veya detay görüntüleme',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.article_rounded, 
                    color: AppTheme.primaryColor,
                  ),
                ),
                title: const Text('Haber Detayını Görüntüle'),
                subtitle: const Text('Haberin tam metnini ve içeriğini okuyun'),
                onTap: () {
                  Navigator.pop(context); // Sheet kapat
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NewsDetailScreen(news: news)),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_circle_filled_rounded, 
                    color: Colors.red,
                  ),
                ),
                title: const Text('Videoyu Oynat'),
                subtitle: const Text('Video içeriğini tam ekran izleyin'),
                onTap: () {
                  Navigator.pop(context); // Sheet kapat
                  
                  // Video oynatıcıyı tam ekran olarak aç
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => Container(
                      height: MediaQuery.of(context).size.height * 0.85,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Column(
                        children: [
                          // Kapatma çubuğu
                          Container(
                            width: 50,
                            height: 5,
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.grey[500],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          // Video başlığı
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              news.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          // Video player
                          Expanded(
                            child: VideoPlayerWidget(
                              videoUrl: news.videoUrl!,
                              autoPlay: true,
                              looping: false,
                              showControls: true,
                              fitToScreen: true,
                            ),
                          ),
                          // Video altındaki açıklama
                          if (news.summary != null && news.summary!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              width: double.infinity,
                              color: Colors.black,
                              child: Text(
                                news.summary!,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          // Alt butonlar
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.share_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  onPressed: () => _shareNews(news),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.text_snippet_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => NewsDetailScreen(news: news)),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon(NewsType type) {
    switch (type) {
      case NewsType.DUYURU:
        return Icons.campaign;
      case NewsType.KAMPANYA:
        return Icons.engineering;
      case NewsType.BAKIM:
        return Icons.trending_up;
      case NewsType.BILGILENDIRME:
        return Icons.devices;
      case NewsType.GUNCELLEME:
        return Icons.support_agent;
      default:
        return Icons.article;
    }
  }

  Color _getCategoryColor(NewsType type) {
    switch (type) {
      case NewsType.DUYURU:
        return AppTheme.primaryColor;
      case NewsType.KAMPANYA:
        return AppTheme.infoColor;
      case NewsType.BAKIM:
        return AppTheme.successColor;
      case NewsType.BILGILENDIRME:
        return AppTheme.accentColor;
      case NewsType.GUNCELLEME:
        return Colors.purple;
      default:
        return AppTheme.textSecondaryColor;
    }
  }
  
  String _getCategoryName(NewsType type) {
    return type.name;
  }

  Widget _buildNewsMedia(UserNewsDTO news) {
    // Debug: Video URL'sini konsola yazdır
    debugPrint('📹 News ID: ${news.id}, Title: ${news.title}');
    debugPrint('📹 Video URL: ${news.videoUrl}');
    debugPrint('📹 Image URL: ${news.image}');
    debugPrint('📹 Thumbnail URL: ${news.thumbnailUrl}');
    
    // Video varsa thumbnail veya video player göster
    if (news.videoUrl != null && news.videoUrl!.isNotEmpty) {
      // Thumbnail varsa göster, yoksa video player göster
      if (news.thumbnailUrl != null && news.thumbnailUrl!.isNotEmpty) {
        debugPrint('🖼️ Video thumbnail gösteriliyor: ${news.thumbnailUrl}');
        return Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail göster
            Image.network(
              news.thumbnailUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('❌ Thumbnail yükleme hatası: $error');
                return Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.movie, size: 60, color: Colors.grey),
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[100],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                );
              },
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                ),
              ),
            ),
            // Video play butonu overlay
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
            // Video etiketi
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_circle_filled_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Video',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      } else {
        // Thumbnail yoksa video player göster
        debugPrint('📹 Video player gösteriliyor: ${news.videoUrl}');
        return Stack(
          children: [
            VideoPlayerWidget(
              videoUrl: news.videoUrl!,
              autoPlay: false,
              looping: false,
              showControls: true,
              fitToScreen: true,
              maxHeight: 250, // Liste için maksimum yükseklik
              minHeight: 150, // Liste için minimum yükseklik
            ),
            // Video işaret overlay'ı
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_circle_filled_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Video',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }
    }
    
    // Video yoksa resim göster
    if (news.image != null && news.image!.isNotEmpty) {
      debugPrint('📷 Resim gösteriliyor: ${news.image}');
      return Image.network(
        news.image!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('❌ Resim yükleme hatası: $error');
          return Center(
            child: Icon(
              _getCategoryIcon(news.type),
              size: 60,
              color: AppTheme.primaryColor.withOpacity(0.5),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[100],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: AppTheme.primaryColor,
              ),
            ),
          );
        },
      );
    }
    
    // Ne video ne de resim varsa ikon göster
    debugPrint('🎯 Ne video ne resim var, ikon gösteriliyor');
    return Container(
      color: AppTheme.backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getCategoryIcon(news.type),
              size: 64,
              color: AppTheme.primaryColor.withOpacity(0.3),
            ),
            const SizedBox(height: 8),
            Text(
              _getCategoryName(news.type),
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<UserNewsDTO> _getDemoNewsWithVideo() {
    return [
      // Kullanıcının eklediği "deneme haber" video haberi
      UserNewsDTO(
        id: 0,
        title: 'deneme haber',
        content: 'video deneme',
        image: null,
        videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        thumbnailUrl: 'https://storage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg',
        likedByUser: false,
        viewedByUser: false,
        priority: NewsPriority.YUKSEK,
        type: NewsType.DUYURU,
        createdAt: DateTime.now(),
        summary: 'Video deneme haberi',
      ),
      
      // Video içeren haber
      UserNewsDTO(
        id: 1,
        title: 'Şehir Kartı Tanıtım Videosu',
        content: 'Şehir kartınızı nasıl kullanacağınızı anlatan detaylı video rehberimizi izleyebilirsiniz. Bu videoda kart yükleme, otobüs kullanımı ve mobil uygulamanın tüm özelliklerini öğreneceksiniz.',
        image: null,
        videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
        thumbnailUrl: 'https://storage.googleapis.com/gtv-videos-bucket/sample/images/ElephantsDream.jpg',
        likedByUser: false,
        viewedByUser: false,
        priority: NewsPriority.YUKSEK,
        type: NewsType.DUYURU,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        summary: 'Şehir kartı kullanım rehberi videosu',
      ),
      
      // Resim içeren haber
      UserNewsDTO(
        id: 2,
        title: 'Yeni Otobüs Hatları Açıldı',
        content: 'Şehrimizde toplu taşıma ağını genişletmek amacıyla 5 yeni otobüs hattı hizmete açılmıştır. Bu hatlar ile daha fazla mahallimize ulaşım sağlanacaktır.',
        image: 'https://picsum.photos/400/200?random=1',
        videoUrl: null,
        likedByUser: true,
        viewedByUser: true,
        priority: NewsPriority.NORMAL,
        type: NewsType.DUYURU,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        summary: 'Yeni otobüs hatları',
      ),
      
      // Video içeren kampanya haberi
      UserNewsDTO(
        id: 3,
        title: 'Yaz Kampanyası Tanıtımı',
        content: 'Bu yaz için özel kampanyamızı tanıtan video içeriğimizi izleyerek avantajlardan yararlanabilirsiniz. Kampanya detayları ve nasıl katılacağınız videoda anlatılıyor.',
        image: null,
        videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
        thumbnailUrl: 'https://storage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerFun.jpg',
        likedByUser: false,
        viewedByUser: false,
        priority: NewsPriority.YUKSEK,
        type: NewsType.KAMPANYA,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        summary: 'Yaz kampanyası video tanıtımı',
      ),
      
      // Sadece metin içeren haber
      UserNewsDTO(
        id: 4,
        title: 'Sistem Bakım Duyurusu',
        content: 'Sistem altyapısını iyileştirmek amacıyla 15 Temmuz 2025 tarihi saat 02:00-06:00 arasında planlı bakım yapılacaktır. Bu süreçte kart yükleme işlemleri etkilenebilir.',
        image: null,
        videoUrl: null,
        likedByUser: false,
        viewedByUser: true,
        priority: NewsPriority.KRITIK,
        type: NewsType.DUYURU,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        summary: 'Planlı sistem bakımı',
      ),
      
      // Video ve resim içeren karma haber
      UserNewsDTO(
        id: 5,
        title: 'Etkinlik Tanıtımı - Video İçerik',
        content: 'Şehrimizde düzenlenecek olan büyük etkinliğin tanıtım videosunu izleyerek detaylı bilgi alabilirsiniz. Etkinlik programı, katılım koşulları ve ödüller hakkında her şey videoda!',
        image: 'https://picsum.photos/400/200?random=2',
        videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
        thumbnailUrl: 'https://storage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerBlazes.jpg',
        likedByUser: true,
        viewedByUser: false,
        priority: NewsPriority.NORMAL,
        type: NewsType.ETKINLIK,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        summary: 'Etkinlik tanıtım videosu',
      ),
    ];
  }

  // Haberi paylaşma fonksiyonu
  void _shareNews(UserNewsDTO news) {
    // Paylaşım içeriğini hazırla
    String shareContent = """
${news.title}

${news.summary ?? news.content}
""";

    // Uygulama deep link URL'i oluştur (news-detail sayfasına yönlendiren)
    final String appDeepLink = "bincard://news-detail?id=${news.id}";

    // Deep link bilgisini ekle
    shareContent += "\n\nHaberi uygulamada görüntülemek için tıklayın: $appDeepLink";

    // Alternatif olarak web sayfası linki (Web uygulaması varsa)
    final String webUrl = "https://bincard.com/news/${news.id}";
    shareContent += "\nveya web sitesinde görüntüleyin: $webUrl";

    // Uygulama bilgisi ekle
    shareContent += "\n\nBincard uygulamasından paylaşıldı.";

    // Paylaşım seçeneklerini göster
    Share.share(
      shareContent,
      subject: news.title,
    ).then((result) {
      // Paylaşım tamamlandığında analytics veya diğer işlemler için
      debugPrint('📤 Haber paylaşıldı: ${news.title}');
    }).catchError((error) {
      debugPrint('❌ Paylaşım hatası: $error');
      // Hata durumunda kullanıcıya bilgi ver
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paylaşım sırasında bir hata oluştu.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }
}
