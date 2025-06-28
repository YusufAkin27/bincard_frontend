import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../constants/app_constants.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  // Demo bildirimler
  final List<Map<String, dynamic>> _allNotifications = [];
  List<Map<String, dynamic>> _displayedNotifications = [];

  // Bildirim türleri
  final Map<String, IconData> _notificationIcons = {
    'info': Icons.info_outline,
    'transaction': Icons.payment,
    'promo': Icons.local_offer_outlined,
    'warning': Icons.warning_amber_outlined,
    'success': Icons.check_circle_outline,
  };

  final Map<String, Color> _notificationColors = {
    'info': Colors.blue,
    'transaction': Colors.green,
    'promo': Colors.purple,
    'warning': Colors.orange,
    'success': Colors.teal,
  };

  final Map<String, String> _tabTitles = {
    'all': 'Tümü',
    'transaction': 'İşlemler',
    'promo': 'Kampanyalar',
    'info': 'Duyurular',
  };

  String _currentTab = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _generateDemoNotifications();
    _loadInitialData();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;

      setState(() {
        switch (_tabController.index) {
          case 0:
            _currentTab = 'all';
            break;
          case 1:
            _currentTab = 'transaction';
            break;
          case 2:
            _currentTab = 'promo';
            break;
          case 3:
            _currentTab = 'info';
            break;
        }
        _loadInitialData();
      });
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _loadMoreData();
      }
    });

    // Türkçe çeviriler için timeago'yu yapılandır
    timeago.setLocaleMessages('tr', timeago.TrMessages());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _generateDemoNotifications() {
    // Demo bildirimler oluştur - gerçek uygulamada silinecek
    final List<Map<String, dynamic>> templates = [
      {
        'type': 'transaction',
        'title': 'Bakiye Güncelleme',
        'messages': [
          'Kartınıza 50₺ bakiye yükleme işlemi gerçekleştirildi.',
          'Kartınızdan otobüs geçişi için 7,5₺ ücret tahsil edildi.',
          'Kartınızdan metro geçişi için 7,5₺ ücret tahsil edildi.',
          'Kartınıza 100₺ bakiye yükleme işlemi gerçekleştirildi.',
          'Otomatik yükleme ile kartınıza 20₺ bakiye eklendi.',
        ],
      },
      {
        'type': 'promo',
        'title': 'Kampanya',
        'messages': [
          'Hafta sonu metroda %10 indirim fırsatını kaçırmayın!',
          'Yeni kullanıcıya özel: İlk yüklemede %15 bonus!',
          'Şehir Hatları Vapurlarında 3 al 2 öde kampanyası başladı.',
          'Öğrencilere özel: Aylık abonelik %20 indirimli!',
          'Bu ay içinde 50 kez kart kullanımına özel 15₺ bonus!',
        ],
      },
      {
        'type': 'info',
        'title': 'Bilgilendirme',
        'messages': [
          'Şehir kartı sistemi güncellendi. Yeni özellikler eklendi.',
          'Metro seferlerinde geçici değişiklik yapılmıştır. Detaylar için tıklayın.',
          'Kart kullanım koşulları güncellenmiştir. İncelemek için tıklayın.',
          'Uygulamanın yeni sürümü yayınlandı. Güncelleyin!',
          'Havaalanı otobüsleri için yeni hat açıldı.',
        ],
      },
      {
        'type': 'warning',
        'title': 'Uyarı',
        'messages': [
          'Kartınızın bakiyesi 10₺\'nin altına düştü. Lütfen yükleme yapın.',
          'Kartınızın kullanım süresi 30 gün içinde dolacak.',
          'Kart işlemlerinizde olağandışı aktivite tespit edildi.',
          'Şifreniz 3 ay içinde güncellenmedi. Lütfen şifrenizi değiştirin.',
          'Bugün için planlanan bakım nedeniyle sistem geçici olarak yavaşlayabilir.',
        ],
      },
      {
        'type': 'success',
        'title': 'Başarılı İşlem',
        'messages': [
          'Kart yenileme talebiniz onaylandı. Kartınız hazırlanıyor.',
          'Abonelik işleminiz başarıyla tamamlandı.',
          'Otomatik yükleme talimatınız başarıyla oluşturuldu.',
          'İade talebiniz onaylandı. 3 iş günü içinde hesabınıza aktarılacaktır.',
          'Kart bilgileriniz başarıyla güncellendi.',
        ],
      },
    ];

    // Son 30 gün için rastgele bildirimler oluştur
    final now = DateTime.now();
    for (int i = 0; i < 50; i++) {
      final daysAgo = i ~/ 2; // Her iki bildirimi bir gün önceye ayarla
      final randomMinutes = (i * 17) % 60;
      final randomHour = (i * 3) % 24;

      final notificationDate = now.subtract(
        Duration(days: daysAgo, hours: randomHour, minutes: randomMinutes),
      );

      final templateIndex = i % templates.length;
      final template = templates[templateIndex];
      final messageIndex = i % template['messages'].length;

      _allNotifications.add({
        'id': i,
        'type': template['type'],
        'title': template['title'],
        'message': template['messages'][messageIndex],
        'date': notificationDate,
        'isRead': daysAgo > 3, // 3 günden eski bildirimler okunmuş olsun
      });
    }

    // Tarihe göre sırala (en yeni en üstte)
    _allNotifications.sort((a, b) => b['date'].compareTo(a['date']));
  }

  void _loadInitialData() {
    setState(() {
      _currentPage = 1;
      _applyFilter();
    });
  }

  void _loadMoreData() {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    // API çağrısını simüle et
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _currentPage++;
          _applyFilter();
          _isLoading = false;
        });
      }
    });
  }

  void _applyFilter() {
    final filteredList =
        _currentTab == 'all'
            ? _allNotifications
            : _allNotifications
                .where((notification) => notification['type'] == _currentTab)
                .toList();

    final endIndex = _currentPage * _itemsPerPage;

    if (endIndex <= filteredList.length) {
      _displayedNotifications = filteredList.sublist(0, endIndex);
    } else {
      _displayedNotifications = filteredList;
    }
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _allNotifications) {
        notification['isRead'] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _allNotifications.where((n) => !n['isRead']).length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Bildirimler',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all),
              label: const Text('Tümünü Okundu İşaretle'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
        ],
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          isScrollable: true,
          tabs: [
            _buildTabWithBadge('Tümü', _currentTab == 'all' ? unreadCount : 0),
            _buildTabWithBadge(
              'İşlemler',
              _currentTab == 'all'
                  ? _allNotifications
                      .where((n) => !n['isRead'] && n['type'] == 'transaction')
                      .length
                  : 0,
            ),
            _buildTabWithBadge(
              'Kampanyalar',
              _currentTab == 'all'
                  ? _allNotifications
                      .where((n) => !n['isRead'] && n['type'] == 'promo')
                      .length
                  : 0,
            ),
            _buildTabWithBadge(
              'Duyurular',
              _currentTab == 'all'
                  ? _allNotifications
                      .where((n) => !n['isRead'] && n['type'] == 'info')
                      .length
                  : 0,
            ),
          ],
        ),
      ),
      body:
          _displayedNotifications.isEmpty
              ? _buildEmptyState()
              : _buildNotificationsList(),
    );
  }

  Widget _buildTabWithBadge(String title, int count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _displayedNotifications.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _displayedNotifications.length) {
          return _buildLoadingIndicator();
        }

        final notification = _displayedNotifications[index];
        return _buildNotificationItem(notification);
      },
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final type = notification['type'];
    final color = _notificationColors[type] ?? Colors.grey;
    final icon = _notificationIcons[type] ?? Icons.notifications_none;
    final isRead = notification['isRead'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          // Bildirimi okundu olarak işaretle
          setState(() {
            notification['isRead'] = true;
          });

          // Bildirim detaylarını göster
          _showNotificationDetails(notification);
        },
        child: Container(
          decoration: BoxDecoration(
            color: isRead ? Colors.white : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color:
                    isRead
                        ? Colors.black.withOpacity(0.05)
                        : color.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isRead ? Colors.transparent : color.withOpacity(0.3),
              width: isRead ? 0 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification['title'],
                              style: TextStyle(
                                fontWeight:
                                    isRead ? FontWeight.w600 : FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification['message'],
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 14,
                          fontWeight:
                              isRead ? FontWeight.normal : FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        timeago.format(notification['date'], locale: 'tr'),
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor.withOpacity(0.7),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationDetails(Map<String, dynamic> notification) {
    final type = notification['type'];
    final color = _notificationColors[type] ?? Colors.grey;
    final icon = _notificationIcons[type] ?? Icons.notifications_none;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification['title'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timeago.format(notification['date'], locale: 'tr'),
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor.withOpacity(
                                0.7,
                              ),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  notification['message'],
                  style: TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                if (notification['type'] == 'transaction' ||
                    notification['type'] == 'success') ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // İşlem detaylarına yönlendir
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text('Detayları Görüntüle'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      foregroundColor: AppTheme.primaryColor,
                      side: BorderSide(color: AppTheme.primaryColor),
                    ),
                  ),
                ] else if (notification['type'] == 'promo') ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Kampanya detaylarına yönlendir
                    },
                    icon: const Icon(Icons.card_giftcard),
                    label: const Text('Kampanyaya Git'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: AppTheme.primaryColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Bildirim Bulunamadı',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Bu kategoride henüz bildirim yok. Yeni bildirimler geldiğinde burada görüntülenecektir.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
          ),
        ],
      ),
    );
  }
}
