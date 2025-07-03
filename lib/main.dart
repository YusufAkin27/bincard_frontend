import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'constants/app_constants.dart';
import 'theme/app_theme.dart';
import 'services/theme_service.dart';
import 'services/language_service.dart';
import 'routes.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'dart:async';
import 'services/secure_storage_service.dart';

// Global navigatorKey - token service gibi servislerden sayfalar arası geçiş için
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Route observer for debugging
class DebugRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    debugPrint('🔄 Route PUSH: ${route.settings.name} (from: ${previousRoute?.settings.name})');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    debugPrint('🔄 Route REPLACE: ${newRoute?.settings.name} (replaced: ${oldRoute?.settings.name})');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    debugPrint('🔄 Route POP: ${route.settings.name} (back to: ${previousRoute?.settings.name})');
  }
}

// Token kontrolünden muaf tutulacak sayfaların route isimleri
const List<String> tokenExemptRoutes = [
  AppRoutes.login,
  AppRoutes.refreshLogin,
  AppRoutes.register,
  AppRoutes.forgotPassword,
  AppRoutes.forgotPasswordSmsVerify,
  AppRoutes.loginSmsVerify,
  AppRoutes.resetPassword,
  AppRoutes.verification,
  '/splash',
];

// Mevcut route'un token kontrolünden muaf olup olmadığını kontrol et
bool isTokenExemptRoute(String? currentRoute) {
  if (currentRoute == null) return false;
  return tokenExemptRoutes.any((route) => currentRoute.startsWith(route));
}

// Mevcut route'u alma yardımcı fonksiyonu
String? getCurrentRoute() {
  if (navigatorKey.currentState != null && navigatorKey.currentState!.canPop()) {
    return ModalRoute.of(navigatorKey.currentContext!)?.settings.name;
  }
  return null;
}

void main() async {
  // Bağımlılıkların başlatılması için
  WidgetsFlutterBinding.ensureInitialized();
  
  // Durum çubuğunu ve sistem gezinti çubuğunu yapılandır
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Uygulama yönünü dikey olarak kilitle
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Tema ve dil servislerini başlat
  final themeService = ThemeService();
  await themeService.initialize();
  
  final languageService = LanguageService();
  await languageService.initialize();
  
  // Auth ve API servislerini başlat
  final apiService = ApiService();
  final authService = AuthService();
  
  // Token kontrolü yap
  bool tokenValid = false;
  try {
    tokenValid = await authService.checkAndRefreshToken();
    
    // Token geçerliyse, token interceptor'ı etkinleştir
    if (tokenValid) {
      apiService.setupTokenInterceptor();
      debugPrint('Token geçerli, interceptor etkinleştirildi');
    } else {
      debugPrint('Token geçerli değil veya bulunamadı');
    }
  } catch (e) {
    debugPrint('Token kontrolü sırasında hata: $e');
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeService>.value(value: themeService),
        ChangeNotifierProvider<LanguageService>.value(value: languageService),
        Provider<AuthService>.value(value: authService),
        Provider<ApiService>.value(value: apiService),
        Provider<UserService>(create: (_) => UserService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Periyodik token kontrolü başlat (5 dakikada bir) - Geçici olarak devre dışı
    startPeriodicTokenCheck(context);
    debugPrint('⚠️ Periodic token check geçici olarak devre dışı bırakıldı');
    
    return Consumer2<ThemeService, LanguageService>(
      builder: (context, themeService, languageService, child) {
        return MaterialApp(
          title: 'BinCard',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          navigatorObservers: [
            // Route değişikliklerini log'la
            DebugRouteObserver(),
          ],
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeService.themeMode,
          locale: languageService.locale,
          initialRoute: '/splash', // Uygulama her zaman Splash Screen'den başlayacak
          routes: {
            ...AppRoutes.routes,
            '/splash': (context) => const SplashScreen(), // Splash Screen'i routes'a ekle
          },
          onGenerateRoute: AppRoutes.generateRoute,
          onUnknownRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Sayfa Bulunamadı')),
                body: const Center(child: Text('404 - Sayfa Bulunamadı')),
              ),
            );
          },
        );
      },
    );
  }
  
  // Periyodik token kontrolü için background timer
  void startPeriodicTokenCheck(BuildContext context) {
    // Her 5 dakikada bir token kontrolü yap (300 saniye)
    const duration = Duration(seconds: 300);
    
    debugPrint('Periyodik token kontrolü başlatıldı (5 dakikada bir)');
    
    Timer.periodic(duration, (timer) async {
      // Mevcut route'u kontrol et
      final currentRoute = getCurrentRoute();
      if (isTokenExemptRoute(currentRoute)) {
        debugPrint('Token kontrolünden muaf sayfa: $currentRoute, periyodik kontrol atlanıyor');
        return;
      }
      
      // Refresh login sayfasındaysak, token kontrolü yapma
      if (currentRoute == AppRoutes.refreshLogin) {
        debugPrint('Refresh login sayfasında, periyodik token kontrolü atlanıyor');
        return;
      }
      
      debugPrint('Periyodik token kontrolü çalışıyor...');
      try {
        final authService = AuthService();
        final secureStorage = SecureStorageService();
        
        // Access token kontrolü
        final isValid = await authService.checkAndRefreshToken();
        
        if (!isValid) {
          // Refresh token kontrolü
          final refreshToken = await secureStorage.getRefreshToken();
          final refreshTokenExpiry = await secureStorage.getRefreshTokenExpiry();
          
          bool refreshTokenValid = false;
          if (refreshToken != null && refreshTokenExpiry != null) {
            final expiry = DateTime.parse(refreshTokenExpiry);
            refreshTokenValid = DateTime.now().isBefore(expiry);
          }
          
          if (navigatorKey.currentContext != null) {
            if (refreshTokenValid) {
              // Refresh token geçerliyse refresh login sayfasına yönlendir
              debugPrint('Access token geçersiz, refresh token geçerli, refresh login sayfasına yönlendiriliyor');
              Navigator.of(navigatorKey.currentContext!).pushNamedAndRemoveUntil(
                AppRoutes.refreshLogin, (route) => false);
            } else {
              // Refresh token da geçersizse login sayfasına yönlendir
              debugPrint('Token ve refresh token geçersiz, login sayfasına yönlendiriliyor');
              Navigator.of(navigatorKey.currentContext!).pushNamedAndRemoveUntil(
                AppRoutes.login, (route) => false);
            }
          }
        } else {
          debugPrint('Token kontrolü başarılı, oturum aktif');
        }
      } catch (e) {
        debugPrint('Periyodik token kontrolü hatası: $e');
      }
    });
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTokenAndNavigate();
    });
  }

  Future<void> _checkTokenAndNavigate() async {
    try {
      // Small delay to show the splash screen
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return; // Widget'ın hala ağaçta olup olmadığını kontrol et

      // Refresh token ve access token kontrolü
      final secureStorage = SecureStorageService();
      final refreshToken = await secureStorage.getRefreshToken();
      final refreshTokenExpiry = await secureStorage.getRefreshTokenExpiry();
      final accessToken = await secureStorage.getAccessToken();

      // Refresh token geçerlilik kontrolü
      bool refreshTokenValid = false;
      if (refreshToken != null && refreshTokenExpiry != null) {
        final expiry = DateTime.parse(refreshTokenExpiry);
        refreshTokenValid = DateTime.now().isBefore(expiry);
        debugPrint('Refresh token geçerli mi: $refreshTokenValid, sona erme: $expiry');
      }
      
      if (!refreshTokenValid || refreshToken == null) {
        // Refresh token yoksa veya geçersizse direkt login sayfasına yönlendir
        debugPrint('Refresh token yok veya geçersiz, login sayfasına yönlendiriliyor');
        Navigator.pushReplacementNamed(context, AppRoutes.login);
        return;
      }
      
      if (accessToken == null) {
        // Access token yok ama refresh token geçerliyse, önce backend'de geçerli mi kontrol et
        debugPrint('Access token yok, refresh token\'ı backend\'de test ediliyor...');
        
        final authService = Provider.of<AuthService>(context, listen: false);
        try {
          // Dummy password ile test yapmak yerine, sadece refresh token'ın geçerliliğini kontrol et
          // Bu, gerçek bir refresh login denemesi yapmadan token'ın backend'de var olup olmadığını kontrol eder
          final tokenValid = await authService.checkAndRefreshToken().timeout(
            const Duration(seconds: 10),
            onTimeout: () => false,
          );
          
          if (tokenValid) {
            debugPrint('Token geçerli, ana sayfaya yönlendiriliyor...');
            Navigator.pushReplacementNamed(context, AppRoutes.home);
          } else {
            debugPrint('Refresh token backend\'de geçersiz, refresh login sayfasına yönlendiriliyor');
            Navigator.pushReplacementNamed(context, AppRoutes.refreshLogin);
          }
        } catch (e) {
          debugPrint('Token test hatası: $e');
          // Eğer "Token bulunamadı" hatası alırsak, direkt login sayfasına yönlendir
          if (e.toString().contains('Token bulunamadı') || e.toString().contains('Token not found')) {
            debugPrint('Backend\'de token bulunamadı, tüm tokenler temizleniyor...');
            await secureStorage.clearTokens();
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          } else {
            Navigator.pushReplacementNamed(context, AppRoutes.refreshLogin);
          }
        }
        return;
      }

      final authService = Provider.of<AuthService>(context, listen: false);
      // Token kontrolü ve yenileme işlemi için zaman aşımı ekle
      final tokenValid = await authService.checkAndRefreshToken().timeout(
        const Duration(seconds: 10), // 10 saniye zaman aşımı
        onTimeout: () {
          debugPrint('Token kontrolü zaman aşımına uğradı, refresh login sayfasına yönlendiriliyor...');
          return false; // Zaman aşımında token geçersiz kabul et
        },
      );

      if (mounted) {
        if (tokenValid) {
          debugPrint('Token geçerli, ana sayfaya yönlendiriliyor...');
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        } else {
          // Token geçersiz ama refresh token geçerliyse, refresh login sayfasına yönlendir
          if (refreshTokenValid) {
            debugPrint('Token geçersiz, refresh login sayfasına yönlendiriliyor...');
            Navigator.pushReplacementNamed(context, AppRoutes.refreshLogin);
          } else {
            debugPrint('Token ve refresh token geçersiz, login sayfasına yönlendiriliyor...');
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          }
        }
      }
    } catch (e) {
      debugPrint('Splash ekranından yönlendirme hatası: $e');
      if (mounted) {
        // Hata durumunda normal login sayfasına yönlendir
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.credit_card, size: 80, color: Colors.white),
            const SizedBox(height: 24),
            Text(
              AppConstants.appName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
