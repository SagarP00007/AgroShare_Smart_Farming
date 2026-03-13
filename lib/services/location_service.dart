import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Service to handle fast location fetching for the map.
class LocationService {
  // Singleton
  static final LocationService instance = LocationService._();
  LocationService._();

  // Default fallback: Angondhalli, Karnataka
  static const double defaultLat = 13.0700;
  static const double defaultLng = 77.7500;

  LatLng? _cachedLocation;

  /// Fetches the user's location with extreme priority on speed.
  /// 
  /// 1. Tries `getLastKnownPosition()` first (instant).
  /// 2. If null, tries `getCurrentPosition()` with low accuracy and 3s timeout.
  /// 3. If timeout or error, returns the default coordinates.
  Future<LatLng> getFastLocation() async {
    if (_cachedLocation != null) return _cachedLocation!;

    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return _fallback();
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return _fallback();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return _fallback();
      }

      // 1. Try last known
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        _cachedLocation = LatLng(lastKnown.latitude, lastKnown.longitude);
        return _cachedLocation!;
      }

      // 2. Try current with low accuracy and 3s timeout
      final current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      ).timeout(const Duration(seconds: 3));

      _cachedLocation = LatLng(current.latitude, current.longitude);
      return _cachedLocation!;
    } catch (e) {
      debugPrint('Location fetch failed/timed out: $e');
      return _fallback();
    }
  }

  LatLng _fallback() {
    _cachedLocation = const LatLng(defaultLat, defaultLng);
    return _cachedLocation!;
  }
}
