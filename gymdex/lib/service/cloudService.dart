import 'dart:convert' as convert;
import 'package:http/http.dart' as http;

class Cloudservice {
  final urlBase = "https://goweather.xyz/weather/";

  Future<dynamic> getWeather(String city) async {
    // Construir URL
    final url = Uri.https('goweather.xyz', '/weather/$city');

    try {
      // Hacer peticion GET
      final response = await http.get(url);

      // Verificar que no haya error
      if (response.statusCode != 200) {
        return null;
      }

      // Convertir a JSON
      var data = convert.jsonDecode(response.body);

      // Devolver datos
      return data;
    } catch (e) {
      return null;
    }
  }
}
