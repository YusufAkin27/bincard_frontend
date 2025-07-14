import 'package:flutter/material.dart';
import '../models/payment_point_model.dart';
import '../services/payment_point_service.dart';
import 'payment_point_detail_screen.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart'; // kaldırıldı
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'map_location_picker_screen.dart';

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
  double? _radiusKm;
  bool _showNearby = false;

  final List<String> _allPaymentMethods = [
    'CASH', 'CREDIT_CARD', 'DEBIT_CARD', 'QR_CODE'
  ];

  List<PaymentPoint> _lastFetchedPoints = [];
  // GoogleMapController? _mapController; // kaldırıldı

  @override
  void initState() {
    super.initState();
    _paymentPointsFuture = PaymentPointService().getAllPaymentPoints();
  }

  void _search() {
    setState(() {
      _paymentPointsFuture = PaymentPointService().searchPaymentPoints(
        name: _name,
        city: _city,
        district: _district,
        paymentMethods: _selectedPaymentMethods.isNotEmpty ? _selectedPaymentMethods : null,
        active: _active,
        workingHours: _workingHours,
        latitude: _latitude,
        longitude: _longitude,
        radiusKm: _radiusKm,
      );
    });
  }

  void _getNearby() {
    if (_latitude != null && _longitude != null) {
      setState(() {
        _paymentPointsFuture = PaymentPointService().getNearbyPaymentPoints(
          latitude: _latitude!,
          longitude: _longitude!,
          radiusKm: _radiusKm ?? 10.0,
        );
      });
    }
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
        width: 40,
        height: 40,
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
          child: const Icon(Icons.location_on, color: Colors.red, size: 36),
        ),
      );
    }).toList(growable: false);
  }

  latlng.LatLng _initialMapCenter() {
    if (_lastFetchedPoints.isNotEmpty) {
      final first = _lastFetchedPoints.first.location;
      return latlng.LatLng(first.latitude, first.longitude);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödeme Noktaları'),
      ),
      body: Column(
        children: [
          // OpenStreetMap Harita Bölümü
          SizedBox(
            height: 260,
            child: FutureBuilder<List<PaymentPoint>>(
              future: _paymentPointsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Hata: \\${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Haritada gösterilecek ödeme noktası yok.'));
                }
                final points = snapshot.data!;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_lastFetchedPoints != points) {
                    _updateLastFetchedPoints(points);
                  }
                });
                return FlutterMap(
                  options: MapOptions(
                    center: _initialMapCenter(),
                    zoom: 7.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.example.city_card.city_card',
                    ),
                    MarkerLayer(markers: _buildMarkers()),
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
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
                        Padding(
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
                                      child: TextFormField(
                                        decoration: const InputDecoration(labelText: 'Çalışma Saatleri', isDense: true),
                                        onChanged: (v) => _workingHours = v.isEmpty ? null : v,
                                      ),
                                    ),
                                  ],
                                ),
                                DropdownButtonFormField<bool>(
                                  decoration: const InputDecoration(labelText: 'Aktif mi?', isDense: true),
                                  items: const [
                                    DropdownMenuItem(value: null, child: Text('Hepsi')),
                                    DropdownMenuItem(value: true, child: Text('Aktif')),
                                    DropdownMenuItem(value: false, child: Text('Pasif')),
                                  ],
                                  onChanged: (v) => _active = v,
                                  value: _active,
                                ),
                                Wrap(
                                  spacing: 8,
                                  children: _allPaymentMethods.map((method) {
                                    return FilterChip(
                                      label: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(_paymentMethodIcon(method), size: 16),
                                          const SizedBox(width: 4),
                                          Text(method),
                                        ],
                                      ),
                                      selected: _selectedPaymentMethods.contains(method),
                                      onSelected: (selected) {
                                        setState(() {
                                          if (selected) {
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
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        decoration: const InputDecoration(labelText: 'Enlem (latitude)', isDense: true),
                                        keyboardType: TextInputType.number,
                                        controller: TextEditingController(text: _latitude?.toString() ?? ''),
                                        onChanged: (v) => _latitude = double.tryParse(v),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextFormField(
                                        decoration: const InputDecoration(labelText: 'Boylam (longitude)', isDense: true),
                                        keyboardType: TextInputType.number,
                                        controller: TextEditingController(text: _longitude?.toString() ?? ''),
                                        onChanged: (v) => _longitude = double.tryParse(v),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextFormField(
                                        decoration: const InputDecoration(labelText: 'Yarıçap (km)', isDense: true),
                                        keyboardType: TextInputType.number,
                                        onChanged: (v) => _radiusKm = double.tryParse(v),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: _getCurrentLocation,
                                      icon: const Icon(Icons.my_location),
                                      label: const Text('Konumumu Kullan'),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: _selectLocationOnMap,
                                      icon: const Icon(Icons.map),
                                      label: const Text('Haritadan Seç'),
                                    ),
                                  ],
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
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: _getNearby,
                                      icon: const Icon(Icons.location_on_outlined),
                                      label: const Text('Yakındakiler'),
                                      style: OutlinedButton.styleFrom(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Liste bölümü
                FutureBuilder<List<PaymentPoint>>(
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
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
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
                                            _buildStatusChip(point.active),
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
                                              child: Icon(_paymentMethodIcon(m), size: 18, color: Colors.blueGrey),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
} 