import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:timeago/timeago.dart' as timeago;

class NewsScreen extends StatefulWidget {
  const NewsScreen({Key? key}) : super(key: key);

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  // Örnek haber verileri
  final List<Map<String, dynamic>> _news = [
    {
      'id': '1',
      'title': '1 Aralık\'tan İtibaren Toplu Taşıma Ücretlerine Zam',
      'summary':
          'Belediye, artan maliyetler nedeniyle toplu taşıma ücretlerine %10 zam yapma kararı aldı.',
      'content':
          'Belediye Meclisi tarafından alınan karara göre, 1 Aralık 2023 tarihinden itibaren şehir içi toplu taşıma ücretlerine %10 zam yapılacak. Artan akaryakıt ve bakım maliyetleri nedeniyle alınan bu karar, tam bilet, öğrenci bileti ve aylık abonman kartlarını kapsayacak. Belediye Başkanı, "Bu zam kaçınılmazdı, ancak hala ülke genelindeki en uygun fiyatlı toplu taşıma hizmetini sunduğumuzu belirtmek isterim" açıklamasında bulundu.',
      'imageUrl': 'https://example.com/news1.jpg',
      'category': 'Duyuru',
      'date': DateTime.now().subtract(const Duration(hours: 6)),
      'isImportant': true,
    },
    {
      'id': '2',
      'title': 'Yeni Metro Hattı İçin Çalışmalar Başladı',
      'summary':
          'Uzun süredir planlanan yeni metro hattının inşaat çalışmaları başladı.',
      'content':
          'Şehir merkezini doğu bölgelerine bağlayacak olan yeni metro hattının inşaat çalışmaları dün düzenlenen törenle başladı. Toplam 14 kilometrelik hat üzerinde 9 istasyon bulunacak ve projenin 3 yıl içinde tamamlanması planlanıyor. Proje tamamlandığında günlük 320 bin yolcuya hizmet vermesi bekleniyor. Belediye Başkanı, "Bu proje şehrimizin ulaşım altyapısına yapılan en büyük yatırımlardan biri olacak ve trafik sorununu önemli ölçüde hafifletecek" dedi.',
      'imageUrl': 'https://example.com/news2.jpg',
      'category': 'Proje',
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'isImportant': false,
    },
    {
      'id': '3',
      'title': 'Otobüs Filosuna 50 Yeni Elektrikli Araç Ekleniyor',
      'summary':
          'Belediye, çevre dostu ulaşım için filosuna 50 yeni elektrikli otobüs ekliyor.',
      'content':
          'Belediye, karbon ayak izini azaltma projesi kapsamında toplu taşıma filosuna 50 adet yeni elektrikli otobüs ekleme kararı aldı. Tamamen elektrikle çalışan ve sıfır emisyona sahip bu araçlar, şehrin en yoğun hatlarında hizmet verecek. Yeni otobüsler engelli erişimine uygun, USB şarj noktaları ve ücretsiz Wi-Fi gibi modern özelliklerle donatılacak. Belediye Başkanı, "Bu yatırımla hem daha temiz bir çevreye katkıda bulunuyor hem de vatandaşlarımıza daha konforlu bir yolculuk deneyimi sunuyoruz" açıklamasında bulundu.',
      'imageUrl': 'https://example.com/news3.jpg',
      'category': 'Yatırım',
      'date': DateTime.now().subtract(const Duration(days: 5)),
      'isImportant': true,
    },
    {
      'id': '4',
      'title': 'Kartlı Ödeme Sistemi Yenileniyor',
      'summary':
          'Şehir kartları için yeni NFC tabanlı ödeme sistemi önümüzdeki ay devreye giriyor.',
      'content':
          'Belediye, toplu taşımada kullanılan kartlı ödeme sistemini yenileme çalışmalarını tamamladı. Yeni sistem, NFC teknolojisi sayesinde akıllı telefonlar ve temassız banka kartlarıyla da ödeme yapılmasına olanak sağlayacak. Kullanıcılar, özel bir mobil uygulama üzerinden bakiye yükleyebilecek ve kullanım geçmişlerini takip edebilecek. Sistem 15 Aralık\'tan itibaren kademeli olarak tüm hatlarda devreye girecek. Belediye, geçiş sürecinde yaşanabilecek sorunlara karşı 24 saat hizmet verecek bir yardım hattı kurduğunu da duyurdu.',
      'imageUrl': 'https://example.com/news4.jpg',
      'category': 'Teknoloji',
      'date': DateTime.now().subtract(const Duration(days: 7)),
      'isImportant': false,
    },
    {
      'id': '5',
      'title': 'Hafta Sonu Ulaşım Hatları Güçlendiriliyor',
      'summary': 'Artan talep üzerine hafta sonu otobüs seferleri artırılıyor.',
      'content':
          'Belediye, hafta sonları özellikle alışveriş merkezleri ve sahil bölgelerine yönelik artan yolcu talebini karşılamak amacıyla bazı hatlarda sefer sayılarını artırma kararı aldı. Cumartesi ve Pazar günleri 10:00-22:00 saatleri arasında sefer sıklığı 15 dakikadan 10 dakikaya indirilecek. Ayrıca, gece 23:00\'e kadar uzatılan ek seferler de hizmete sunulacak. Bu düzenleme, önümüzdeki hafta sonundan itibaren uygulanmaya başlayacak.',
      'imageUrl': 'https://example.com/news5.jpg',
      'category': 'Hizmet',
      'date': DateTime.now().subtract(const Duration(days: 10)),
      'isImportant': false,
    },
    {
      'id': '6',
      'title': '15-18 Aralık Tarihleri Arasında Planlı Bakım Çalışması',
      'summary':
          'Metro hattında yapılacak bakım çalışmaları nedeniyle bazı istasyonlar geçici olarak kapatılacak.',
      'content':
          'Belediye, 15-18 Aralık tarihleri arasında ana metro hattında planlı bakım ve yenileme çalışmaları yapılacağını duyurdu. Bu süre zarfında Merkez, Üniversite ve Hastane istasyonları hizmet vermeyecek. Yolcuların mağdur olmaması için alternatif ring seferleri düzenlenecek ve ek otobüs hatları devreye alınacak. Bakım çalışmasının amacı, rayların yenilenmesi ve sinyalizasyon sisteminin güncellenmesi olarak açıklandı. Çalışmalar 18 Aralık akşamı tamamlanacak ve normal sefer düzenine dönülecek.',
      'imageUrl': 'https://example.com/news6.jpg',
      'category': 'Duyuru',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'isImportant': true,
    },
  ];

  // Filtrelenmiş haber listeleri
  List<Map<String, dynamic>> get _allNews => _news;
  List<Map<String, dynamic>> get _importantNews =>
      _news.where((news) => news['isImportant'] == true).toList();
  List<Map<String, dynamic>> get _announcements =>
      _news.where((news) => news['category'] == 'Duyuru').toList();
  List<Map<String, dynamic>> get _projects =>
      _news.where((news) => news['category'] == 'Proje').toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Türkçe zaman formatı için
    timeago.setLocaleMessages('tr', timeago.TrMessages());
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

    // Simüle edilmiş veri yenileme
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });
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

  Widget _buildNewsList(List<Map<String, dynamic>> newsList) {
    return RefreshIndicator(
      onRefresh: _refreshNews,
      child:
          newsList.isEmpty
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

  Widget _buildNewsCard(Map<String, dynamic> news) {
    final bool isImportant = news['isImportant'] ?? false;
    final DateTime date = news['date'] as DateTime;

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
                child: Center(
                  child: Icon(
                    _getCategoryIcon(news['category']),
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
                          color: _getCategoryColor(
                            news['category'],
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          news['category'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getCategoryColor(news['category']),
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
                        timeago.format(date, locale: 'tr'),
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
                          news['title'],
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
                    news['summary'],
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
                          // Haberi paylaş
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.bookmark_border,
                          color: AppTheme.primaryColor,
                        ),
                        onPressed: () {
                          // Haberi kaydet
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

  void _showNewsDetails(Map<String, dynamic> news) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NewsDetailScreen(news: news)),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Duyuru':
        return Icons.campaign;
      case 'Proje':
        return Icons.engineering;
      case 'Yatırım':
        return Icons.trending_up;
      case 'Teknoloji':
        return Icons.devices;
      case 'Hizmet':
        return Icons.support_agent;
      default:
        return Icons.article;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Duyuru':
        return AppTheme.primaryColor;
      case 'Proje':
        return AppTheme.infoColor;
      case 'Yatırım':
        return AppTheme.successColor;
      case 'Teknoloji':
        return AppTheme.accentColor;
      case 'Hizmet':
        return Colors.purple;
      default:
        return AppTheme.textSecondaryColor;
    }
  }
}

class NewsDetailScreen extends StatelessWidget {
  final Map<String, dynamic> news;

  const NewsDetailScreen({Key? key, required this.news}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DateTime date = news['date'] as DateTime;
    final bool isImportant = news['isImportant'] ?? false;

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
            },
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {
              // Haberi kaydet
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
              child: Center(
                child: Icon(
                  _getCategoryIcon(news['category']),
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
                          color: _getCategoryColor(
                            news['category'],
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          news['category'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getCategoryColor(news['category']),
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
                        _formatDate(date),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    news['title'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundVariant1,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      news['summary'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    news['content'],
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
    List<String> months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Duyuru':
        return Icons.campaign;
      case 'Proje':
        return Icons.engineering;
      case 'Yatırım':
        return Icons.trending_up;
      case 'Teknoloji':
        return Icons.devices;
      case 'Hizmet':
        return Icons.support_agent;
      default:
        return Icons.article;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Duyuru':
        return AppTheme.primaryColor;
      case 'Proje':
        return AppTheme.infoColor;
      case 'Yatırım':
        return AppTheme.successColor;
      case 'Teknoloji':
        return AppTheme.accentColor;
      case 'Hizmet':
        return Colors.purple;
      default:
        return AppTheme.textSecondaryColor;
    }
  }
}
