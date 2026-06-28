import 'package:geolocator/geolocator.dart';

class LocationService {
  // Verifica permisos y obtiene la ubicación actual
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('El GPS está desactivado');
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Permiso de ubicación denegado');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permiso de ubicación denegado permanentemente');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}