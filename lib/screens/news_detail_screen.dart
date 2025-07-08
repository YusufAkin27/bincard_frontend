import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/news/user_news_dto.dart';
import '../models/news/news_type.dart';
import '../services/news_service.dart';
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
    
    final bool isImportant = news.priority.toString().contains('HIGH') || 
                            news.priority.toString().contains('URGENT');

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text('Haber Detayı'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Haberi paylaş
              Share.share(
                '${news.title}\n\n${news.content}\n\nBincard uygulamasından paylaşıldı.',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border),
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
            Container(
              height: 200,
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
                            size: 80,
                            color: AppTheme.primaryColor.withOpacity(0.5),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Icon(
                        _getCategoryIcon(news.type),
                        size: 80,
                        color: AppTheme.primaryColor.withOpacity(0.5),
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
}
