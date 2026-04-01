import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gymdex/models/ejercicio.dart';

class ApiService {
  static const String _apiKey = 'bf2d215f5emsh22a83cfb577b396p1b5974jsn9a0cbc709348';
  static const String _apiHost = 'edb-with-videos-and-images-by-ascendapi.p.rapidapi.com';
  static const String _baseUrl = 'https://$_apiHost/api/v1';

  /// Obtiene todos los ejercicios disponibles (por default la API los pagina a 10, le ponemos un límite alto o usamos el de por defecto si no lo soporta)
  Future<List<Ejercicio>> fetchAllExercises() async {
    final url = Uri.parse('$_baseUrl/exercises?limit=1500'); // Solicitar todos
    
    try {
      final response = await http.get(
        url,
        headers: {
          'X-RapidAPI-Key': _apiKey,
          'X-RapidAPI-Host': _apiHost,
        },
      );

      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);
        List<dynamic> data = [];
        
        if (decodedData is Map<String, dynamic>) {
          if (decodedData.containsKey('data')) {
            data = decodedData['data'];
          } else if (decodedData.containsKey('results')) {
            data = decodedData['results'];
          } else if (decodedData.containsKey('exercises')) {
            data = decodedData['exercises'];
          } else {
            // Find the list in any of the map values
            for (var value in decodedData.values) {
              if (value is List) {
                data = value;
                break;
              }
            }
          }
        } else if (decodedData is List) {
          data = decodedData;
        }

        return data.map((json) => Ejercicio.fromJson(json)).toList();
      } else {
        print("Error fetching exercises: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print('Exception API: ${e.toString()}');
      return [];
    }
  }
}
