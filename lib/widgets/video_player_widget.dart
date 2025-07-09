import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_theme.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool looping;
  final bool showControls;
  final double? aspectRatio;
  final double? maxHeight;
  final double? minHeight;
  final bool fitToScreen;
  final bool showThumbnail;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.autoPlay = false,
    this.looping = false,
    this.showControls = true,
    this.aspectRatio,
    this.maxHeight,
    this.minHeight,
    this.fitToScreen = true,
    this.showThumbnail = false,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isPlaying = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      String videoUrl = widget.videoUrl;
      
      // Cloudinary URL'sini video player için optimize et
      if (videoUrl.contains('cloudinary.com') && videoUrl.contains('/video/upload/')) {
        // Cloudinary video URL'sini doğru formata çevir
        videoUrl = videoUrl.replaceAll('/video/upload/', '/video/upload/f_mp4,q_auto/');
        debugPrint('🎥 Cloudinary URL optimize edildi: $videoUrl');
      }
      
      debugPrint('🎥 Video yükleniyor: $videoUrl');
      
      // Video URL'sine göre controller oluştur
      if (videoUrl.startsWith('http') || videoUrl.startsWith('https')) {
        // Network video
        _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      } else {
        // Asset video
        _controller = VideoPlayerController.asset(videoUrl);
      }

      // Controller'ı başlat
      await _controller.initialize();

      // Ayarları uygula
      _controller.setLooping(widget.looping);
      
      if (widget.autoPlay) {
        await _controller.play();
        _isPlaying = true;
      }

      // Listener ekle
      _controller.addListener(_videoListener);

      setState(() {
        _isInitialized = true;
      });
      
      debugPrint('✅ Video başarıyla yüklendi');
      debugPrint('🎥 Video çözünürlüğü: ${_controller.value.size}');
      debugPrint('🎥 Video aspect ratio: ${_controller.value.aspectRatio}');
      debugPrint('🎥 Optimal height: ${_getOptimalHeight()}');
      
      // Video yüklendikten sonra widget'ı yeniden boyutlandır
      if (mounted) {
        setState(() {
          // Boyut hesaplamaları için tekrar render tetikle
        });
      }
    } catch (e) {
      debugPrint('❌ Video yükleme hatası: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Video yüklenirken hata oluştu: $e';
      });
    }
  }

  // Video çözünürlüğüne göre optimal aspect ratio hesapla
  double _getOptimalAspectRatio() {
    if (!_isInitialized) {
      return widget.aspectRatio ?? 16 / 9; // Default aspect ratio
    }
    
    final videoSize = _controller.value.size;
    final videoAspectRatio = _controller.value.aspectRatio;
    
    debugPrint('🎥 Video boyutu: ${videoSize.width}x${videoSize.height}');
    debugPrint('🎥 Video aspect ratio: $videoAspectRatio');
    
    // Eğer widget'ta specific aspect ratio belirtilmişse onu kullan
    if (widget.aspectRatio != null) {
      return widget.aspectRatio!;
    }
    
    // Video aspect ratio geçersizse default kullan
    if (videoAspectRatio <= 0 || videoAspectRatio.isNaN || videoAspectRatio.isInfinite) {
      return 16 / 9;
    }
    
    return videoAspectRatio;
  }

  // Video çözünürlüğüne göre container height hesapla
  double _getOptimalHeight() {
    if (!_isInitialized || !mounted) {
      return widget.minHeight ?? 200; // Default height
    }
    
    // Eğer fitToScreen false ise, sadece aspect ratio kullan
    if (!widget.fitToScreen) {
      final screenWidth = MediaQuery.of(context).size.width - 32;
      final aspectRatio = _getOptimalAspectRatio();
      return screenWidth / aspectRatio;
    }
    
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width - 32; // Padding çıkarılmış
    final screenHeight = screenSize.height;
    final aspectRatio = _getOptimalAspectRatio();
    
    // Aspect ratio'ya göre height hesapla
    double calculatedHeight = screenWidth / aspectRatio;
    
    // Widget parametrelerinden limitler al, yoksa ekran boyutuna göre dinamik limitler
    final maxHeight = widget.maxHeight ?? (screenHeight * 0.4); // Ekranın %40'ı
    final minHeight = widget.minHeight ?? (screenHeight * 0.15); // Ekranın %15'i
    
    // Video çözünürlüğüne göre optimal boyut ayarı
    final videoSize = _controller.value.size;
    if (videoSize.width > 0 && videoSize.height > 0) {
      // Yüksek çözünürlüklü videolar için daha büyük alan
      if (videoSize.width >= 1920 || videoSize.height >= 1080) {
        calculatedHeight = calculatedHeight.clamp(minHeight * 1.2, maxHeight);
      } 
      // Orta çözünürlüklü videolar
      else if (videoSize.width >= 1280 || videoSize.height >= 720) {
        calculatedHeight = calculatedHeight.clamp(minHeight, maxHeight * 0.8);
      }
      // Düşük çözünürlüklü videolar
      else {
        calculatedHeight = calculatedHeight.clamp(minHeight * 0.8, maxHeight * 0.6);
      }
    } else {
      // Video boyutu alınamazsa genel sınırları uygula
      calculatedHeight = calculatedHeight.clamp(minHeight, maxHeight);
    }
    
    debugPrint('🎥 Hesaplanan video yüksekliği: $calculatedHeight');
    debugPrint('🎥 Min: $minHeight, Max: $maxHeight');
    
    return calculatedHeight;
  }

  void _videoListener() {
    if (mounted) {
      setState(() {
        _isPlaying = _controller.value.isPlaying;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  // Thumbnail'dan video player'a geçiş
  void _switchToVideoPlayer() {
    if (widget.showThumbnail) {
      setState(() {
        // Video kontrolcüsünü yükle
        _isInitialized = false;
      });
      
      // Video player'ı başlat
      _initializeVideoPlayer().then((_) {
        if (mounted) {
          setState(() {
            // Thumbnail modunu kapat
            // Bu setState VideoPlayerWidget'ın build metodunu yeniden çalıştırır
            // ve _buildVideoPlayer() metodunun normal video player'ı oluşturmasını sağlar
          });
          
          // Videoyu oynat
          _controller.play();
          _isPlaying = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorWidget();
    }

    if (!_isInitialized) {
      return _buildLoadingWidget();
    }

    return _buildVideoPlayer();
  }

  Widget _buildErrorWidget() {
    // Error durumunda da widget parametrelerine uygun height kullan
    final screenHeight = MediaQuery.of(context).size.height;
    final defaultHeight = widget.minHeight ?? (screenHeight * 0.25); // Ekranın %25'i
    final maxHeight = widget.maxHeight ?? (screenHeight * 0.4);
    
    return Container(
      height: defaultHeight.clamp(150, maxHeight),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: AppTheme.errorColor,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Video Hatası',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    // Loading durumunda da widget parametrelerine uygun height kullan
    final screenHeight = MediaQuery.of(context).size.height;
    final defaultHeight = widget.minHeight ?? (screenHeight * 0.25); // Ekranın %25'i
    final maxHeight = widget.maxHeight ?? (screenHeight * 0.4);
    
    return Container(
      height: defaultHeight.clamp(150, maxHeight),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Video yükleniyor...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    // Video çözünürlüğüne göre dinamik aspect ratio hesapla
    final aspectRatio = _getOptimalAspectRatio();
    final height = _getOptimalHeight();
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        height: height,
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Stack(
            children: [
              // Video player
              VideoPlayer(_controller),
              
              // Kontroller overlay
              if (widget.showControls)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _toggleControls,
                    child: AnimatedOpacity(
                      opacity: _showControls ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.3),
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                            ],
                          ),
                        ),
                        child: _buildVideoControls(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoControls() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Üst kontroller (başlık alanı - isteğe bağlı)
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Boş alan (gelecekte başlık eklenebilir)
              const SizedBox(),
              // Tam ekran butonu (gelecekte eklenebilir)
              IconButton(
                icon: const Icon(Icons.fullscreen, color: Colors.white),
                onPressed: () {
                  // Tam ekran fonksiyonu eklenebilir
                },
              ),
            ],
          ),
        ),
        
        // Orta kontroller (play/pause)
        Center(
          child: IconButton(
            iconSize: 64,
            icon: Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: Colors.white,
            ),
            onPressed: _togglePlayPause,
          ),
        ),
        
        // Alt kontroller (progress bar ve zaman)
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Progress bar
              VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: AppTheme.primaryColor,
                  bufferedColor: Colors.white.withOpacity(0.3),
                  backgroundColor: Colors.white.withOpacity(0.1),
                ),
              ),
              const SizedBox(height: 8),
              // Zaman bilgisi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(_controller.value.position),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    _formatDuration(_controller.value.duration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
