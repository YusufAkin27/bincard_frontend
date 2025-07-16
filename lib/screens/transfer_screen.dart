import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';
import '../services/secure_storage_service.dart';
import 'package:dio/dio.dart';
import '../routes.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  int _selectedTransferMethod = 0; // 0: NFC, 1: QR Kod
  int _selectedCardIndex = 0;
  final List<Map<String, dynamic>> _myCards = [
    {
      'name': 'Şehir Kartı',
      'number': '5312 **** **** 3456',
      'balance': '257,50 ₺',
      'color': AppTheme.blueGradient,
    },
    {
      'name': 'İkinci Kartım',
      'number': '4728 **** **** 9012',
      'balance': '125,75 ₺',
      'color': AppTheme.greenGradient,
    },
  ];
  Map<String, dynamic>? _walletData;
  String? _walletError;
  final TextEditingController _receiverController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchWallet();
  }

  Future<void> _fetchWallet() async {
    setState(() { _walletError = null; });
    try {
      final api = ApiService();
      final accessToken = await SecureStorageService().getAccessToken();
      final response = await api.get(
        ApiConstants.myWalletEndpoint,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      if (response.data['success'] == false && response.data['message'] != null) {
        setState(() {
          _walletData = null;
          _walletError = response.data['message'];
        });
      } else {
        setState(() {
          _walletData = response.data;
          _walletError = null;
        });
      }
    } catch (e) {
      setState(() {
        _walletData = null;
        _walletError = 'Cüzdan bilgisi alınamadı';
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _receiverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          'Para Transferi',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTransferMethodSelector(),
              const SizedBox(height: 24),
              _buildSectionTitle('Gönderen Kart'),
              const SizedBox(height: 12),
              _buildCardSelector(),
              const SizedBox(height: 24),
              _buildSectionTitle('Transfer Detayları'),
              const SizedBox(height: 12),
              _buildTransferDetails(),
              const SizedBox(height: 32),
              _buildTransferButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransferMethodSelector() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMethodButton(
              icon: Icons.nfc,
              title: 'NFC ile Transfer',
              isSelected: _selectedTransferMethod == 0,
              onTap: () {
                setState(() {
                  _selectedTransferMethod = 0;
                });
              },
            ),
          ),
          Expanded(
            child: _buildMethodButton(
              icon: Icons.qr_code,
              title: 'QR Kod ile Transfer',
              isSelected: _selectedTransferMethod == 1,
              onTap: () {
                setState(() {
                  _selectedTransferMethod = 1;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodButton({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  color:
                      isSelected ? Colors.white : AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimaryColor,
      ),
    );
  }

  Widget _buildCardSelector() {
    // Gerçek cüzdan bilgisi gösterilecek
    if (_walletError != null) {
      return Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(_walletError!, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchWallet,
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }
    if (_walletData == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Card(
      elevation: 8,
      shadowColor: AppTheme.primaryColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withOpacity(0.8),
              AppTheme.accentColor,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Toplam Bakiye', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  (_walletData!['balance'] ?? 0).toString(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 4),
                Text('₺', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Text('Son Güncelleme: ' + (_walletData!['lastUpdated'] ?? ''), style: const TextStyle(color: Colors.white, fontSize: 14)),
            if (_walletData!['wiban'] != null) ...[
              const SizedBox(height: 8),
              Text('WIBAN: ' + _walletData!['wiban'], style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransferDetails() {
    return Column(
      children: [
        _buildSelectedTransferMethodContent(),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _receiverController,
          label: 'Alıcı Telefonu veya WIBAN',
          hint: '5331000001 veya WIBAN',
          prefixIcon: Icons.person,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Alıcı bilgisi zorunlu';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _amountController,
          label: 'Transfer Tutarı',
          hint: '0.00',
          prefixIcon: Icons.money,
          suffixText: '₺',
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Lütfen bir tutar girin';
            }
            try {
              double amount = double.parse(value.replaceAll(',', '.'));
              if (amount <= 0) {
                return 'Tutar 0\'dan büyük olmalıdır';
              }
            } catch (e) {
              return 'Geçerli bir tutar girin';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _noteController,
          label: 'Açıklama (İsteğe bağlı)',
          hint: 'Transfer için bir açıklama ekleyin',
          prefixIcon: Icons.note,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildSelectedTransferMethodContent() {
    if (_selectedTransferMethod == 0) {
      // NFC Transfer
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.nfc, size: 48, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              'NFC ile Transfer',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Transfer için, cihazınızı diğer NFC destekli karta veya cihaza yaklaştırın.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    } else {
      // QR Code Transfer
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildQrOption(
                    icon: Icons.qr_code_scanner,
                    title: 'QR Kod Tara',
                    description: 'Alıcının QR kodunu tarayın',
                    onTap: () {
                      // QR kodu tarama işlevi
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQrOption(
                    icon: Icons.qr_code,
                    title: 'QR Kod Oluştur',
                    description: 'Transfer için QR kod oluşturun',
                    onTap: () {
                      // QR kodu oluşturma işlevi
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget _buildQrOption({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    String? suffixText,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixText: suffixText,
          suffixStyle: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          prefixIcon: Icon(prefixIcon, color: AppTheme.primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildTransferButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _handleTransfer,
        icon: const Icon(Icons.sync_alt),
        label: const Text('Transferi Gönder'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Future<void> _handleTransfer() async {
    if (!_formKey.currentState!.validate()) return;
    final api = ApiService();
    final accessToken = await SecureStorageService().getAccessToken();
    final double amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    final body = {
      'receiverIdentifier': _receiverController.text.trim(),
      'amount': amount,
      'description': _noteController.text.trim(),
    };
    try {
      final response = await api.post(
        ApiConstants.transferWalletEndpoint,
        data: body,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      if (response.data['success'] == true) {
        _showSuccessDialog();
      } else {
        _showErrorDialog(response.data['message'] ?? 'Transfer başarısız.');
      }
    } catch (e) {
      _showErrorDialog('Transfer sırasında hata oluştu.');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Başarılı'),
        content: const Text('Transfer işlemi başarıyla tamamlandı.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hata'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}
