import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

/// Service for map location: fast initial load and real-time refresh from backend (device GPS).
class LocationService {
  static final LocationService instance = LocationService._();
  LocationService._();

  static const double defaultLat = 13.0700;
  static const double defaultLng = 77.7500;

  LatLng? _cachedLocation;

  /// Invalidates cached location so the next fetch gets fresh GPS data.
  void invalidateCache() {
    _cachedLocation = null;
  }

  /// Fast location for initial map load: last known or current with short timeout.
  Future<LatLng> getFastLocation() async {
    if (_cachedLocation != null) return _cachedLocation!;
    return _fetchLocation(
      useLastKnown: true,
      accuracy: LocationAccuracy.low,
      timeoutSeconds: 4,
    );
  }

  /// Real-time location: forces fresh GPS fix for "My location" and map refresh.
  /// Use this when the user requests current position (e.g. taps My Location).
  Future<LatLng> getCurrentLocationRealtime() async {
    _cachedLocation = null;
    return _fetchLocation(
      useLastKnown: false,
      accuracy: LocationAccuracy.high,
      timeoutSeconds: 10,
    );
  }

  Future<LatLng> _fetchLocation({
    required bool useLastKnown,
    required LocationAccuracy accuracy,
    required int timeoutSeconds,
  }) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return _fallback();

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return _fallback();
      }
      if (permission == LocationPermission.deniedForever) return _fallback();

      if (useLastKnown) {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          _cachedLocation = LatLng(lastKnown.latitude, lastKnown.longitude);
          return _cachedLocation!;
        }
      }

      final current = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: accuracy),
      ).timeout(Duration(seconds: timeoutSeconds));

      _cachedLocation = LatLng(current.latitude, current.longitude);
      return _cachedLocation!;
    } catch (e) {
      debugPrint('LocationService: $e');
      return _fallback();
    }
  }

  LatLng _fallback() {
    _cachedLocation = const LatLng(defaultLat, defaultLng);
    return _cachedLocation!;
  }

  /// Returns a formatted address string from coordinates
  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = <String>[];
        if (place.locality != null && place.locality!.isNotEmpty) {
          parts.add(place.locality!);
        }
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          parts.add(place.administrativeArea!);
        }
        if (parts.isNotEmpty) return parts.join(', ');

        // Fallback
        return '${place.name ?? ''}, ${place.country ?? ''}';
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
    }
    return null;
  }
}
