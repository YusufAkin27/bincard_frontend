import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/news/user_news_dto.dart';
import '../models/news/news_type.dart';
import '../models/news/platform_type.dart';
import '../services/news_service.dart';
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
      .where((news) => news.priority.toString().contains('HIGH') || 
                        news.priority.toString().contains('URGENT'))
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
      
      setState(() {
        _allNews = news;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Haberler yüklenirken hata: $e');
      setState(() {
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
        title: const Text('Haberler ve Duyurular', style: TextStyle(color: Colors.white)),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          unselectedLabelColor: Colors.white70,
          labelColor: Colors.white,
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
    final bool isImportant = news.priority.toString().contains('HIGH') || 
                             news.priority.toString().contains('URGENT');

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
                child: news.image != null && news.image!.isNotEmpty
                    ? Image.network(
                        news.image!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              _getCategoryIcon(news.type),
                              size: 60,
                              color: AppTheme.primaryColor.withOpacity(0.5),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Icon(
                          _getCategoryIcon(news.type),
                          size: 60,
                          color: AppTheme.primaryColor.withOpacity(0.5),
                        ),
                      ),
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
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NewsDetailScreen(news: news)),
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
}
