import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tenfo/utilities/shared_preferences_keys.dart';

enum LocationServicePermissionStatus {
  loading,
  permitted,
  notPermitted,
  serviceDisabled,
}

class LocationServicePosition {
  double latitude;
  double longitude;

  LocationServicePosition(this.latitude, this.longitude);
}

class LocationService {
  LocationServicePosition? _currentPosition;
  DateTime? _lastLocationUpdate;

  Future<LocationServicePermissionStatus> verificarUbicacion() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationServicePermissionStatus.serviceDisabled;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return LocationServicePermissionStatus.notPermitted;
    }

    return LocationServicePermissionStatus.permitted;
  }

  /// Antes de usar esta funcion, usar verificarUbicacion().
  Future<LocationServicePosition?> obtenerUbicacion() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    double? latitude = prefs.getDouble(SharedPreferencesKeys.locationLatitude);
    double? longitude = prefs.getDouble(SharedPreferencesKeys.locationLongitude);
    DateTime? lastUpdate = DateTime.tryParse(prefs.getString(SharedPreferencesKeys.locationLastDateTime) ?? '');

    bool updateLocation = false;

    if (latitude != null && longitude != null && lastUpdate != null) {

      _currentPosition = LocationServicePosition(latitude, longitude);
      _lastLocationUpdate = lastUpdate;

      DateTime now = DateTime.now().toUtc();

      if (now.difference(_lastLocationUpdate!).inMinutes >= 15) {
        updateLocation = true;
      }

    } else {
      updateLocation = true;
    }


    if(updateLocation){
      try {
        Position position = await Geolocator.getCurrentPosition();
        DateTime now = DateTime.now().toUtc();

        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setDouble(SharedPreferencesKeys.locationLatitude, position.latitude);
        prefs.setDouble(SharedPreferencesKeys.locationLongitude, position.longitude);
        prefs.setString(SharedPreferencesKeys.locationLastDateTime, now.toIso8601String());

        _currentPosition = LocationServicePosition(position.latitude, position.longitude);
        _lastLocationUpdate = now;
      } catch(e){
        //
      }
    }

    return _currentPosition;
  }
}