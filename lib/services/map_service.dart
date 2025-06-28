import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class MapService {
  static final MapService _instance = MapService._internal();
  factory MapService() => _instance;
  MapService._internal();

  // Konum izni kontrolü
  Future<bool> checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Konum servisi açık mı kontrol et
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Konum servisleri devre dışı.');
      return false;
    }

    // Konum izni var mı kontrol et
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // İzin iste
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Konum izinleri reddedildi.');
        return false;
      }
    }

    // Kalıcı olarak reddedildi mi kontrol et
    if (permission == LocationPermission.deniedForever) {
      debugPrint(
        'Konum izinleri kalıcı olarak reddedildi, ayarlardan açılması gerekiyor.',
      );
      return false;
    }

    return true;
  }

  // Mevcut konumu al
  Future<Position?> getCurrentLocation() async {
    try {
      if (!await checkLocationPermission()) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Konum alınamadı: $e');
      return null;
    }
  }

  // Mevcut konum LatLng tipinde
  Future<LatLng?> getCurrentLatLng() async {
    final position = await getCurrentLocation();
    if (position == null) return null;

    return LatLng(position.latitude, position.longitude);
  }

  // İki konum arasındaki mesafeyi hesapla (metre cinsinden)
  double calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  // Haritada gösterilecek marker'ları oluştur
  Set<Marker> createMarkers(List<Map<String, dynamic>> points) {
    final Set<Marker> markers = {};

    for (final point in points) {
      final id = point['id'] as String;
      final position = point['position'] as LatLng;
      final title = point['title'] as String;
      final snippet = point['snippet'] as String?;
      final icon = point['icon'] as BitmapDescriptor?;

      markers.add(
        Marker(
          markerId: MarkerId(id),
          position: position,
          infoWindow: InfoWindow(title: title, snippet: snippet),
          icon: icon ?? BitmapDescriptor.defaultMarker,
        ),
      );
    }

    return markers;
  }

  // Konum ayarlarını açma
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  // Uygulama ayarlarını açma
  Future<bool> openSettings() async {
    return await openAppSettings();
  }
}
