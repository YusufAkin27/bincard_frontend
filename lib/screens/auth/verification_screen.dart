import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/secure_storage_service.dart';
import '../../services/api_service.dart';
import 'login_screen.dart';
import 'reset_password_screen.dart';

class VerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final bool isPasswordReset;

  const VerificationScreen({
    Key? key, 
    required this.phoneNumber,
    this.isPasswordReset = false
  }) : super(key: key);

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final _authService = AuthService();
  final _userService = UserService();
  final _secureStorage = SecureStorageService();
  final _apiService = ApiService();
  
  // Tüm kutularda rakam olup olmadığını kontrol eden değişken
  bool _isCodeComplete = false;

  bool _isLoading = false;
  String _errorMessage = '';
  int _remainingTime = 180; // 3 dakika (180 saniye)
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    
    // Her kod girişinde kontrol et
    for (int i = 0; i < _controllers.length; i++) {
      _controllers[i].addListener(() {
        _checkCodeCompletion();
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  // Tüm kutularda rakam olup olmadığını kontrol et
  void _checkCodeCompletion() {
    bool isComplete = _controllers.every((controller) => controller.text.isNotEmpty);
    
    if (isComplete != _isCodeComplete) {
      setState(() {
        _isCodeComplete = isComplete;
      });
      
      // Tüm kutular doluysa otomatik doğrula
      if (isComplete) {
        // Klavyeyi kapat ve kısa bir gecikme ile doğrula
        FocusScope.of(context).unfocus();
        Future.delayed(const Duration(milliseconds: 300), () {
          _verifyCode();
        });
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        _timer?.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Tüm kod kutularını temizle
  void _clearAllFields() {
    for (var controller in _controllers) {
      controller.clear();
    }
    setState(() {
      _isCodeComplete = false;
    });
    // İlk kutucuğa odaklan
    FocusScope.of(context).requestFocus(_focusNodes[0]);
  }

  Future<void> _verifyCode() async {
    // Hala doğrulama işlemi devam ediyorsa tekrar başlatma
    if (_isLoading) return;
    
    // Tüm kodları birleştir
    final code = _controllers.map((c) => c.text).join();

    if (code.length != 6) {
      setState(() {
        _errorMessage = 'Lütfen 6 haneli doğrulama kodunu giriniz';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final message = await _authService.verifyPhoneNumber(code);
      if (!mounted) return;
      setState(() {
        _errorMessage = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
      if (widget.isPasswordReset) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(
              phoneNumber: widget.phoneNumber,
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const LoginScreen())
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isCodeComplete = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendCode() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _canResend = false;
    });

    try {
      // UserService kullanarak kodu yeniden gönder
      final response = await _userService.resendCode(widget.phoneNumber);

      if (response.success) {
        // Zamanı sıfırla (3 dakika) ve timeri başlat
        setState(() {
          _remainingTime = 180; // 3 dakika
        });
        _startTimer();

        // Kod kutularını temizle
        _clearAllFields();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Yeni doğrulama kodu gönderildi'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Kod gönderme işlemi başarısız oldu.';
          _canResend = true;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Beklenmeyen bir hata oluştu: $e';
        _canResend = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Telefon Doğrulama'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: GestureDetector(
        // Ekranın herhangi bir yerine tıklandığında klavyeyi kapat
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                Center(
                  child: Icon(
                    Icons.verified_user_rounded,
                    size: 60,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    widget.isPasswordReset 
                        ? 'Şifre Sıfırlama Kodu'
                        : 'Telefon Numaranızı Doğrulayın',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    '+90 ${widget.phoneNumber} numaralı telefonunuza gönderilen 6 haneli doğrulama kodunu giriniz.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                _buildVerificationCodeInput(),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _clearAllFields,
                    child: Text(
                      "Kodu Temizle",
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildResendCodeSection(),
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildErrorMessage(),
                ],
                const SizedBox(height: 24),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationCodeInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        6,
        (index) => SizedBox(
          width: 45,
          child: RawKeyboardListener(
            focusNode: FocusNode(),
            onKey: (event) {
              if (event is RawKeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.backspace) {
                  // Eğer mevcut kutu boşsa ve ilk kutu değilse, bir önceki kutuya git
                  if (_controllers[index].text.isEmpty && index > 0) {
                    _controllers[index - 1].clear(); // Önceki kutuyu temizle
                    FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
                  }
                }
              }
            },
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
              decoration: InputDecoration(
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(1),
              ],
              onChanged: (value) {
                // Değer girince sonraki kutuya geç
                if (value.isNotEmpty && index < 5) {
                  FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResendCodeSection() {
    return Column(
      children: [
        Text(
          'Doğrulama kodunuz gelmedi mi?',
          style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14),
        ),
        const SizedBox(height: 12),
        _canResend
            ? TextButton(
                onPressed: _resendCode,
                child: Text(
                  'Yeniden Kod Gönder',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Yeni kod: ',
                    style: TextStyle(color: AppTheme.textSecondaryColor),
                  ),
                  Text(
                    _formatTime(_remainingTime),
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _verifyCode,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isCodeComplete ? Colors.green : AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          disabledBackgroundColor: Colors.grey.shade400,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : Text(
                _isCodeComplete ? 'Doğrulanıyor...' : 'Doğrula',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}