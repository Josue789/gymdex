import 'dart:convert' as convert;
import 'package:http/http.dart' as http;

class CloudService {
  Future<dynamic> getWeather(String city) async {
    try {
      // 1. Buscar coordenadas de la ciudad
      final geoUrl = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(city)}&count=1&language=es&format=json',
      );

      final geoResponse = await http.get(geoUrl);

      if (geoResponse.statusCode != 200) {
        return null;
      }

      final geoData = convert.jsonDecode(geoResponse.body);

      if (geoData['results'] == null || (geoData['results'] as List).isEmpty) {
        return null;
      }

      final location = geoData['results'][0];
      final latitude = location['latitude'];
      final longitude = location['longitude'];

      // 2. Obtener clima actual
      final weatherUrl = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$latitude'
        '&longitude=$longitude'
        '&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m'
        '&timezone=auto',
      );

      final weatherResponse = await http.get(weatherUrl);

      if (weatherResponse.statusCode != 200) {
        return null;
      }

      return convert.jsonDecode(weatherResponse.body);
    } catch (e) {
      return null;
    }
  }
}
