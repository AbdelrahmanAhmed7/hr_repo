import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

import 'location_errors.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final String? address;
  final double accuracy; // دقة الموقع بالمتر

  LocationData({
    required this.latitude,
    required this.longitude,
    this.address,
    required this.accuracy,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'accuracy': accuracy,
    };
  }
}

class OfficeConfig {
  static const double latitude = 30.052296;
  static const double longitude = 31.194384;
  static const double allowedRadius = 50.0;
}

class LocationException implements Exception {
  final LocationError error;
  LocationException(this.error);
}

class LocationService {
  // إحداثيات موقع العمل (يتم تحديدها من الإعدادات أو الباك اند)
  // مثال: مكتب في القاهرة
  static const double officeLatitude = 30.052296;
  static const double officeLongitude = 31.194384;
  static const double allowedRadius = 50.0;

  /// التحقق من أذونات الموقع وطلبها تلقائياً
  /// إرجاع: (hasPermission, isPermanentlyDenied)
  static Future<({bool hasPermission, bool isPermanentlyDenied})>
  checkAndRequestLocationPermission() async {
    final status = await Permission.locationWhenInUse.status;

    // الإذن موجود (granted أو limited مثل "allow once")
    if (status.isGranted || status.isLimited) {
      return (hasPermission: true, isPermanentlyDenied: false);
    }

    // نطلب الإذن في كل الحالات الأخرى (حتى لو كان permanently denied سابقاً، نحاول الطلب)
    // نترك للنظام قرار عرض الديالوج أم لا
    final result = await Permission.locationWhenInUse.request();

    if (result.isGranted || result.isLimited) {
      return (hasPermission: true, isPermanentlyDenied: false);
    }

    return (
      hasPermission: false,
      isPermanentlyDenied: result.isPermanentlyDenied,
    );
  }

  /// التحقق من أذونات الموقع (backward compatibility)
  static Future<bool> checkLocationPermission() async {
    final result = await checkAndRequestLocationPermission();
    return result.hasPermission;
  }

  /// التحقق من تفعيل GPS
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// فتح إعدادات GPS
  static Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// فتح إعدادات التطبيق (للأذونات)
  static Future<bool> openPermissionSettings() async {
    return await openAppSettings();
  }

  /// الحصول على الموقع الحالي
  static Future<LocationData> getCurrentLocation() async {
    final permissionResult = await checkAndRequestLocationPermission();

    if (!permissionResult.hasPermission) {
      throw LocationException(
        permissionResult.isPermanentlyDenied
            ? LocationError.permanentlyDenied
            : LocationError.permissionDenied,
      );
    }

    final isGpsEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isGpsEnabled) {
      throw LocationException(LocationError.gpsDisabled);
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      String? address;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          address = '${place.street}, ${place.locality}, ${place.country}';
        }
      } catch (_) {}

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        accuracy: position.accuracy,
      );
    } catch (e) {
      if (e is LocationException) rethrow;
      throw LocationException(LocationError.locationFailed);
    }
  }

  /// حساب المسافة بين موقعين بالمتر
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// التحقق من أن المستخدم في نطاق العمل
  static Future<bool> isWithinOfficeRange() async {
    try {
      final location = await getCurrentLocation();

      final distance = calculateDistance(
        location.latitude,
        location.longitude,
        officeLatitude,
        officeLongitude,
      );

      return distance <= allowedRadius;
    } catch (e) {
      return false;
    }
  }

  /// الحصول على المسافة من موقع العمل
  static Future<double?> getDistanceFromOffice() async {
    try {
      final location = await getCurrentLocation();

      return calculateDistance(
        location.latitude,
        location.longitude,
        officeLatitude,
        officeLongitude,
      );
    } catch (e) {
      return null;
    }
  }

  /// التحقق من الموقع مع إرجاع المسافة
  static Future<
    ({
      bool isWithinRange,
      double distance,
      LocationData? location,
      LocationError? error,
    })
  >
  checkLocationWithDistance() async {
    try {
      final location = await getCurrentLocation();

      final distance = calculateDistance(
        location.latitude,
        location.longitude,
        OfficeConfig.latitude,
        OfficeConfig.longitude,
      );

      return (
        isWithinRange: distance <= OfficeConfig.allowedRadius,
        distance: distance,
        location: location,
        error: null,
      );
    } on LocationException catch (e) {
      return (
        isWithinRange: false,
        distance: -1.0,
        location: null,
        error: e.error,
      );
    } catch (e) {
      return (
        isWithinRange: false,
        distance: -1.0,
        location: null,
        error: LocationError.locationFailed,
      );
    }
  }
}
