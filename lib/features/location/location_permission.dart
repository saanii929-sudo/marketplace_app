import 'package:geolocator/geolocator.dart';

/// Checks location services + permission, requesting permission if not yet
/// granted/denied-once. Returns false if services are off, permission is
/// denied/deniedForever, or anything else prevents a location fix.
Future<bool> ensureLocationPermission() async {
  if (!await Geolocator.isLocationServiceEnabled()) return false;
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
}

/// Matches the backend's `decimal_places=6` cap on lat/lng fields — raw GPS
/// doubles have far more precision than that and get rejected without this.
double round6dp(double value) => (value * 1000000).round() / 1000000;

/// Best-effort current position, rounded to 6dp. Returns null on any
/// failure (permission denied, services off, GPS timeout, etc.) — callers
/// decide how to react (silent fallback vs. surfacing an error toast).
Future<(double, double)?> getCurrentLatLngRounded() async {
  if (!await ensureLocationPermission()) return null;
  try {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return (round6dp(position.latitude), round6dp(position.longitude));
  } catch (_) {
    return null;
  }
}
