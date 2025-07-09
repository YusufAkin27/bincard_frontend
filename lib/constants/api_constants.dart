class ApiConstants {
  // Base URL for API requests
  // Mevcut API URL'sini kullanıyoruz
  static const String baseUrl = 'http://192.168.174.214:8080/v1/api';
  
  // Ortam değişkenleri
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // API endpoints
  // Auth endpoints
  static String get loginEndpoint => '/auth/login';
  static String get signUpEndpoint => '/user/sign-up';
  static String get refreshTokenEndpoint => '/auth/refresh';  // Updated to match actual usage
  static String get verifyCodeEndpoint => '/auth/verify-code';
  static String get resendCodeEndpoint => '/auth/resend-verify-code';
  static String get forgotPasswordEndpoint => '/auth/forgot-password';
  static String get resetPasswordEndpoint => '/auth/reset-password';
  static String get refreshLoginEndpoint => '/auth/refresh-login';
  static String get refreshLogin => '/auth/refresh-login'; // Backward compatibility
  
  // Password reset endpoints
  static String get passwordForgotEndpoint => '/user/password/forgot';
  static String get passwordVerifyCodeEndpoint => '/user/password/verify-code';
  static String get passwordResetEndpoint => '/user/password/reset';
  static String get passwordResendCodeEndpoint => '/user/password/resend-code';
  
  // User endpoints
  static String get userProfileEndpoint => '/user/profile';  // GET/PUT: Kullanıcı profilini al veya güncelle
  static String get updateUserEndpoint => '/user/update';
  static String get updateProfileEndpoint => '/user/profile';  // PUT: Profil bilgilerini güncelle
  static String get updateProfilePhotoEndpoint => '/user/profile/photo';  // PUT: Profil fotoğrafını güncelle
  static String get verifyPhoneEndpoint => '/user/verify-phone';
  static String get changePasswordEndpoint => '/user/password/change';
  
  // News endpoints
  static String get newsBaseEndpoint => '/news';
  static String get newsActiveEndpoint => '/news/active';
  static String get newsByCategoryEndpoint => '/news/by-category';
  static String get newsViewHistoryEndpoint => '/news/view-history';
  static String get newsSuggestedEndpoint => '/news/suggested';
  static String newsViewEndpoint(String newsId) => '/news/$newsId/view';
  
  // Content Type ve diğer header'lar
  static const String contentType = 'application/json';
  
  // API Headers
  static Map<String, String> get headers => {
    'Content-Type': contentType,
    'Accept': 'application/json',
  };
  
  // Add auth header with token
  static Map<String, String> getAuthHeaders(String token) {
    return {
      ...headers,
      'Authorization': 'Bearer $token',
    };
  }
}
