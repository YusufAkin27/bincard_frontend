import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/news/user_news_dto.dart';
import '../models/news/news_type.dart';
import '../models/news/news_priority.dart';
import '../services/news_service.dart';
import '../widgets/video_player_widget.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import for locale initialization
import 'package:share_plus/share_plus.dart';

class NewsDetailScreen extends StatelessWidget {
  final UserNewsDTO news;

  const NewsDetailScreen({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    // Initialize the date formatting for Turkish locale
    initializeDateFormatting('tr_TR', null);
    
    final bool isImportant = news.priority == NewsPriority.YUKSEK || 
                            news.priority == NewsPriority.COK_YUKSEK ||
                            news.priority == NewsPriority.KRITIK;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text('Haber Detayı', style: TextStyle(color: Colors.white)),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // Geri dönme butonu beyaz
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // Haberi paylaş
              Share.share(
                '${news.title}\n\n${news.content}\n\nBincard uygulamasından paylaşıldı.',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: Colors.white),
            onPressed: () {
              // Haberi kaydet - gelecekte eklenecek
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bu özellik yakında eklenecek!'),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media alanı - video için dinamik boyut
            _buildNewsDetailMediaContainer(context, news),
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
                      if (isImportant) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: 12,
                                color: AppTheme.accentColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Önemli',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.accentColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        _formatDate(DateTime.now()), // Gerçek tarih yoksa şu anki tarihi göster
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    news.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    news.content,
                    style: const TextStyle(fontSize: 16, height: 1.6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final DateFormat formatter = DateFormat('dd MMMM yyyy', 'tr_TR');
    return formatter.format(date);
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

  Widget _buildNewsDetailMediaContainer(BuildContext context, UserNewsDTO news) {
    // Video varsa dinamik boyutlu container, resim varsa sabit boyutlu
    if (news.videoUrl != null && news.videoUrl!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: _buildNewsDetailMedia(context, news),
      );
    } else {
      // Resim için sabit boyutlu container
      return Container(
        height: 200,
        width: double.infinity,
        color: AppTheme.primaryColor.withOpacity(0.1),
        child: _buildNewsDetailMedia(context, news),
      );
    }
  }

  Widget _buildNewsDetailMedia(BuildContext context, UserNewsDTO news) {
    // Video varsa video player göster
    if (news.videoUrl != null && news.videoUrl!.isNotEmpty) {
      // Video player ile birlikte thumbnail kullanımı
      return Column(
        children: [
          // Varsa thumbnail göster
          if (news.thumbnailUrl != null && news.thumbnailUrl!.isNotEmpty)
            Stack(
              alignment: Alignment.center,
              children: [
                // Thumbnail image
                Image.network(
                  news.thumbnailUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 200,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                      ),
                    );
                  },
                ),
                // Play butonu overlay
                IconButton(
                  icon: const Icon(
                    Icons.play_circle_fill,
                    size: 60,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    // Video player'a geçiş yap
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
            )
          else
            // Thumbnail yoksa direkt video player göster
            VideoPlayerWidget(
              videoUrl: news.videoUrl!,
              autoPlay: false,
              looping: false,
              showControls: true,
              fitToScreen: true,
              maxHeight: MediaQuery.of(context).size.height * 0.5, // Ekranın max %50'si
              minHeight: 200, // Minimum 200px
            ),
        ],
      );
    }
    
    // Video yoksa resim göster
    if (news.image != null && news.image!.isNotEmpty) {
      return Image.network(
        news.image!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Icon(
              _getCategoryIcon(news.type),
              size: 80,
              color: AppTheme.primaryColor.withOpacity(0.5),
            ),
          );
        },
      );
    }
    
    // Ne video ne de resim varsa ikon göster
    return Center(
      child: Icon(
        _getCategoryIcon(news.type),
        size: 80,
        color: AppTheme.primaryColor.withOpacity(0.5),
      ),
    );
  }
}
