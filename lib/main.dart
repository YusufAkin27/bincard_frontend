import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'constants/app_constants.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'theme/app_theme.dart';
import 'services/theme_service.dart';
import 'services/language_service.dart';
import 'routes.dart';
import 'services/api_service.dart';
import 'services/token_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'dart:async';

// Global navigatorKey - token service gibi servislerden sayfalar arası geçiş için
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Token kontrolünden muaf tutulacak sayfaların route isimleri
const List<String> tokenExemptRoutes = [
  '/login',
  '/register',
  '/forgot-password',
  '/verification',
  '/reset-password',
  '/login-sms-verify',
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
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Periyodik token kontrolü başlat (5 dakikada bir)
    startPeriodicTokenCheck(context);
    
    return Consumer2<ThemeService, LanguageService>(
      builder: (context, themeService, languageService, child) {
        return MaterialApp(
          title: 'BinCard',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
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
      
      debugPrint('Periyodik token kontrolü çalışıyor...');
      try {
        final authService = AuthService();
        final isValid = await authService.checkAndRefreshToken();
        
        if (!isValid) {
          debugPrint('Token geçersiz, kullanıcı login sayfasına yönlendiriliyor');
          // Login sayfasına yönlendir
          if (navigatorKey.currentContext != null) {
            Navigator.of(navigatorKey.currentContext!).pushNamedAndRemoveUntil('/login', (route) => false);
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
  const SplashScreen({Key? key}) : super(key: key);

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

      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Token kontrolü ve yenileme işlemi için zaman aşımı ekle
      final tokenValid = await authService.checkAndRefreshToken().timeout(
        const Duration(seconds: 10), // 10 saniye zaman aşımı
        onTimeout: () {
          debugPrint('Token kontrolü zaman aşımına uğradı, login sayfasına yönlendiriliyor...');
          return false; // Zaman aşımında token geçersiz kabul et
        },
      );

      if (mounted) {
        if (tokenValid) {
          debugPrint('Token geçerli, ana sayfaya yönlendiriliyor...');
          Navigator.pushReplacementNamed(context, '/');
        } else {
          debugPrint('Token geçersiz veya kontrol edilemedi, login sayfasına yönlendiriliyor...');
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      debugPrint('Splash ekranından yönlendirme hatası: $e');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
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
