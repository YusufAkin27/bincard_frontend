import 'package:flutter/material.dart';
import '../models/payment_point_model.dart';
import '../services/payment_point_service.dart';
import 'payment_point_detail_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'map_location_picker_screen.dart';
import '../services/map_service.dart';
import '../constants/api_constants.dart';
import '../services/user_service.dart';

class PaymentPointsScreen extends StatefulWidget {
  const PaymentPointsScreen({Key? key}) : super(key: key);

  @override
  State<PaymentPointsScreen> createState() => _PaymentPointsScreenState();
}

class _PaymentPointsScreenState extends State<PaymentPointsScreen> {
  late Future<List<PaymentPoint>> _paymentPointsFuture;
  final _formKey = GlobalKey<FormState>();

  // Filtre alanları
  String? _name;
  String? _city;
  String? _district;
  String? _workingHours;
  bool? _active;
  List<String> _selectedPaymentMethods = [];
  double? _latitude;
  double? _longitude;
  double _radiusKm = 5.0; // Default 5 km
  bool _showNearby = false;
  double _mapZoom = 13.0;

  final List<String> _allPaymentMethods = [
    'CASH', 'CREDIT_CARD', 'DEBIT_CARD', 'QR_CODE'
  ];

  List<PaymentPoint> _lastFetchedPoints = [];

  // Yeni: Hızlı şehir ve ödeme yöntemi filtreleme için controllerlar
  final TextEditingController _cityFilterController = TextEditingController();
  String? _quickCity;
  String? _quickPaymentMethod;

  void _filterByCity() {
    if (_quickCity != null && _quickCity!.isNotEmpty) {
      setState(() {
        _paymentPointsFuture = PaymentPointService().getByCity(_quickCity!);
      });
    }
  }

  void _filterByPaymentMethod() {
    if (_quickPaymentMethod != null && _quickPaymentMethod!.isNotEmpty) {
      setState(() {
        _paymentPointsFuture = PaymentPointService().getByPaymentMethod(_quickPaymentMethod!);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _paymentPointsFuture = PaymentPointService().getAllPaymentPoints();
  }

  void _search() async {
    final mapService = MapService();
    final hasPermission = await mapService.checkLocationPermission();
    if (!hasPermission) {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await mapService.openLocationSettings();
      }
      return;
    }
    final pos = await mapService.getCurrentLocation();
    if (pos == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konum alınamadı.')));
      }
      return;
    }
    setState(() {
      _latitude = pos.latitude;
      _longitude = pos.longitude;
      _radiusKm = 5.0;
      _paymentPointsFuture = PaymentPointService().getNearbyPaymentPoints(
        latitude: pos.latitude,
        longitude: pos.longitude,
        radiusKm: _radiusKm,
        page: 0,
        size: 10,
      );
    });
  }

  void _getNearby() async {
    final mapService = MapService();
    final hasPermission = await mapService.checkLocationPermission();
    if (!hasPermission) {
      // Konum servisleri kapalıysa doğrudan ayarları aç
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await mapService.openLocationSettings();
      }
      // Diğer durumlarda (izin reddi vs.) hiçbir şey gösterilmez
      return;
    }
    final pos = await mapService.getCurrentLocation();
    if (pos == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konum alınamadı.')));
      }
      return;
    }
    setState(() {
      _latitude = pos.latitude;
      _longitude = pos.longitude;
      _radiusKm = 5.0; // Yakındakiler butonunda daima 5 km
      _mapZoom = 16.0; // Yakınlaştır
      _paymentPointsFuture = PaymentPointService().getNearbyPaymentPoints(
        latitude: pos.latitude,
        longitude: pos.longitude,
        radiusKm: _radiusKm,
        page: 0,
        size: 10,
      );
    });
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konum servisleri kapalı.')));
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konum izni reddedildi.')));
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konum izni kalıcı olarak reddedildi.')));
      return;
    }
    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _latitude = pos.latitude;
      _longitude = pos.longitude;
    });
  }

  Future<void> _selectLocationOnMap() async {
    final latlng.LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationPickerScreen(
          initialLat: _latitude,
          initialLng: _longitude,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
      });
    }
  }

  void _updateLastFetchedPoints(List<PaymentPoint> points) {
    setState(() {
      _lastFetchedPoints = points;
    });
  }

  List<Marker> _buildMarkers() {
    return _lastFetchedPoints.map((point) {
      return Marker(
        width: 48,
        height: 48,
        point: latlng.LatLng(point.location.latitude, point.location.longitude),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentPointDetailScreen(paymentPointId: point.id),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.shade600,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.store_mall_directory, color: Colors.white, size: 28),
            ),
          ),
        ),
      );
    }).toList(growable: false);
  }

  latlng.LatLng _initialMapCenter() {
    if (_lastFetchedPoints.isNotEmpty) {
      final first = _lastFetchedPoints.first.location;
      return latlng.LatLng(first.latitude, first.longitude);
    }
    if (_latitude != null && _longitude != null) {
      return latlng.LatLng(_latitude!, _longitude!);
    }
    return latlng.LatLng(39.925533, 32.866287); // Türkiye merkez
  }

  Widget _buildStatusChip(bool active) {
    return Chip(
      label: Text(active ? 'Aktif' : 'Pasif', style: const TextStyle(color: Colors.white)),
      backgroundColor: active ? Colors.green : Colors.red,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    );
  }

  IconData _paymentMethodIcon(String method) {
    switch (method) {
      case 'CASH':
        return Icons.attach_money;
      case 'CREDIT_CARD':
        return Icons.credit_card;
      case 'DEBIT_CARD':
        return Icons.account_balance_wallet;
      case 'QR_CODE':
        return Icons.qr_code;
      default:
        return Icons.payment;
    }
  }

  Color _paymentMethodSelectedColor(BuildContext context, String method) {
    switch (method) {
      case 'CASH':
        return Colors.green;
      case 'CREDIT_CARD':
        return Colors.blue;
      case 'DEBIT_CARD':
        return Colors.redAccent.shade100;
      case 'QR_CODE':
        return Theme.of(context).primaryColor;
      default:
        return Theme.of(context).chipTheme.selectedColor ?? Colors.grey.shade200;
    }
  }

  Color _paymentMethodIconColor(BuildContext context, String method) {
    switch (method) {
      case 'CASH':
        return Colors.green;
      case 'CREDIT_CARD':
        return Colors.blue;
      case 'DEBIT_CARD':
        return Colors.redAccent.shade100;
      case 'QR_CODE':
        return Theme.of(context).primaryColor;
      default:
        return Colors.blueGrey;
    }
  }

  String _paymentMethodLabel(String method) {
    switch (method) {
      case 'CASH':
        return 'Nakit';
      case 'CREDIT_CARD':
        return 'Kredi Kartı';
      case 'DEBIT_CARD':
        return 'Banka Kartı';
      case 'QR_CODE':
        return 'QR Kod';
      default:
        return method;
    }
  }

  Future<Widget> _buildUserLocationMarker() async {
    final userService = UserService();
    try {
      final profile = await userService.getUserProfile();
      if (profile.profileUrl != null && profile.profileUrl!.isNotEmpty) {
        return Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.network(
              profile.profileUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.person_pin_circle, color: Colors.blue, size: 32),
            ),
          ),
        );
      }
    } catch (_) {}
    // Profil fotoğrafı yoksa mavi ikon
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue.shade700,
        border: Border.all(color: Colors.white, width: 5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.person_pin_circle, color: Colors.white, size: 32),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödeme Noktaları'),
      ),
      body: Column(
        children: [
          // Harita sabit
          SizedBox(
            height: 260,
            child: FutureBuilder<List<PaymentPoint>>(
              future: _paymentPointsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Hata: \\${snapshot.error}'));
                }
                final points = snapshot.data ?? [];
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_lastFetchedPoints != points) {
                    _updateLastFetchedPoints(points);
                  }
                });
                return FlutterMap(
                  options: MapOptions(
                    center: _initialMapCenter(),
                    zoom: _mapZoom,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.example.city_card.city_card',
                    ),
                    MarkerLayer(markers: [
                      ..._buildMarkers(),
                      if (_latitude != null && _longitude != null)
                        Marker(
                          width: 54,
                          height: 54,
                          point: latlng.LatLng(_latitude!, _longitude!),
                          child: FutureBuilder<Widget>(
                            future: _buildUserLocationMarker(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                                return snapshot.data!;
                              } else {
                                return Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.blue.shade700,
                                    border: Border.all(color: Colors.white, width: 5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.25),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.person_pin_circle, color: Colors.white, size: 32),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                    ]),
                  ],
                );
              },
            ),
          ),
          // Filtreleme barı sabit
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                title: Row(
                  children: const [
                    Icon(Icons.filter_alt_outlined),
                    SizedBox(width: 8),
                    Text('Filtrele / Ara', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.65,
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
                        child: Form(
                          key: _formKey,
                          child: Wrap(
                            runSpacing: 8,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      decoration: const InputDecoration(labelText: 'İsim', isDense: true),
                                      onChanged: (v) => _name = v.isEmpty ? null : v,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      decoration: const InputDecoration(labelText: 'Şehir', isDense: true),
                                      onChanged: (v) => _city = v.isEmpty ? null : v,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      decoration: const InputDecoration(labelText: 'İlçe', isDense: true),
                                      onChanged: (v) => _district = v.isEmpty ? null : v,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      decoration: const InputDecoration(labelText: 'Çalışma Saatleri', isDense: true),
                                      value: _workingHours,
                                      items: const [
                                        DropdownMenuItem(value: null, child: Text('Hepsi')),
                                        DropdownMenuItem(value: '07:00-12:00', child: Text('07:00-12:00')),
                                        DropdownMenuItem(value: '12:00-17:00', child: Text('12:00-17:00')),
                                        DropdownMenuItem(value: '17:00-22:00', child: Text('17:00-22:00')),
                                      ],
                                      onChanged: (v) => setState(() => _workingHours = v),
                                    ),
                                  ),
                                ],
                              ),
                              Wrap(
                                spacing: 8,
                                children: _allPaymentMethods.map((method) {
                                  final selected = _selectedPaymentMethods.contains(method);
                                  return FilterChip(
                                    label: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(_paymentMethodIcon(method), size: 16, color: selected ? Colors.white : Colors.black54),
                                        const SizedBox(width: 4),
                                        Text(_paymentMethodLabel(method), style: TextStyle(color: selected ? Colors.white : Colors.black87)),
                                      ],
                                    ),
                                    selected: selected,
                                    selectedColor: _paymentMethodSelectedColor(context, method),
                                    checkmarkColor: Colors.white,
                                    showCheckmark: false,
                                    onSelected: (isSelected) {
                                      setState(() {
                                        if (isSelected) {
                                          _selectedPaymentMethods.add(method);
                                        } else {
                                          _selectedPaymentMethods.remove(method);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _search,
                                    icon: const Icon(Icons.search),
                                    label: const Text('Ara'),
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Sadece liste kaydırılabilir
          Expanded(
            child: FutureBuilder<List<PaymentPoint>>(
              future: _paymentPointsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Hata: \\${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Ödeme noktası bulunamadı.'));
                }
                final points = snapshot.data!;
                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: points.length,
                  itemBuilder: (context, index) {
                    final point = points[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentPointDetailScreen(paymentPointId: point.id),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.location_on, color: Theme.of(context).primaryColor, size: 32),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            point.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      point.address.street,
                                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                                    ),
                                    Text(
                                      point.address.district + ', ' + point.address.city,
                                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(point.workingHours, style: const TextStyle(fontSize: 13)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        ...point.paymentMethods.map((m) => Padding(
                                          padding: const EdgeInsets.only(right: 6),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(_paymentMethodIcon(m), size: 18, color: _paymentMethodIconColor(context, m)),
                                              const SizedBox(width: 4),
                                              Text(_paymentMethodLabel(m), style: TextStyle(color: _paymentMethodIconColor(context, m))),
                                            ],
                                          ),
                                        )),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 