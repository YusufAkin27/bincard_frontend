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
        title: const Text('Haberler ve Duyurular'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(text: 'Tümü'),
            Tab(text: 'Önemli'),
            Tab(text: 'Duyurular'),
            Tab(text: 'Projeler'),
          ],
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
      child: _isLoading
          ? _buildLoadingIndicator()
          : newsList.isEmpty
              ? _buildEmptyList()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: newsList.length,
                  itemBuilder: (context, index) {
                    final news = newsList[index];
                    return _buildNewsCard(news);
                  },
                ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: CircularProgressIndicator(
        color: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildEmptyList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 80,
            color: AppTheme.textSecondaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Haber bulunamadı',
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

  Widget _buildNewsCard(UserNewsDTO news) {
    final bool isImportant = news.priority == NewsPriority.YUKSEK || 
                             news.priority == NewsPriority.COK_YUKSEK ||
                             news.priority == NewsPriority.KRITIK;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showNewsDetails(news),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Container(
                height: 160,
                width: double.infinity,
                color: AppTheme.primaryColor.withOpacity(0.1),
                child: _buildNewsMedia(news),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(news.type).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getCategoryName(news.type),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getCategoryColor(news.type),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeago.format(news.date, locale: 'tr'),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          news.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isImportant)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.star,
                            color: AppTheme.accentColor,
                            size: 24,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    news.summary ?? news.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => _showNewsDetails(news),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text('Devamını Oku'),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.share, color: AppTheme.primaryColor),
                        onPressed: () {
                          // Haberi paylaş - bu özellik gelecekte eklenecek
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.bookmark_border,
                          color: AppTheme.primaryColor,
                        ),
                        onPressed: () {
                          // Haberi kaydet - bu özellik gelecekte eklenecek
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewsDetails(UserNewsDTO news) {
    // Haber görüntüleme kaydını tut
    NewsService().recordNewsView(news.id);
    
    // Video içeren bir haber için, eğer thumbnail varsa, video oynatıcıyı açabiliriz
    if (news.videoUrl != null && news.videoUrl!.isNotEmpty && 
        news.thumbnailUrl != null && news.thumbnailUrl!.isNotEmpty) {
      _playVideo(news);
    } else {
      // Normal haber detay sayfasına git
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => NewsDetailScreen(news: news)),
      );
    }
  }
  
  void _playVideo(UserNewsDTO news) {
    // Kullanıcıya normal detay sayfası veya video oynatıcı seçeneği sun
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.article),
                title: const Text('Haber Detayını Görüntüle'),
                onTap: () {
                  Navigator.pop(context); // Sheet kapat
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NewsDetailScreen(news: news)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.play_circle_filled),
                title: const Text('Videoyu Oynat'),
                onTap: () {
                  Navigator.pop(context); // Sheet kapat
                  
                  // Video oynatıcıyı tam ekran olarak aç
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => Container(
                      height: MediaQuery.of(context).size.height * 0.75,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Column(
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
                          // Video başlığı
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              news.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
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
                        ],
                      ),
                    ),
                  );
                },
              ),
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
          children: [
            // Thumbnail göster
            Image.network(
              news.thumbnailUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 200,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('❌ Thumbnail yükleme hatası: $error');
                return Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.movie, size: 60, color: Colors.grey),
                  ),
                );
              },
            ),
            // Video play butonu overlay
            Positioned.fill(
              child: Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white.withOpacity(0.8),
                  size: 60,
                ),
              ),
            ),
            // Video etiketi
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_circle_filled,
                      color: Colors.white,
                      size: 16,
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
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_circle_filled,
                      color: Colors.white,
                      size: 16,
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
      );
    }
    
    // Ne video ne de resim varsa ikon göster
    debugPrint('🎯 Ne video ne resim var, ikon gösteriliyor');
    return Center(
      child: Icon(
        _getCategoryIcon(news.type),
        size: 60,
        color: AppTheme.primaryColor.withOpacity(0.5),
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
}
