import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const String apiKey = 'bf2d215f5emsh22a83cfb577b396p1b5974jsn9a0cbc709348';
  const String apiHost = 'edb-with-videos-and-images-by-ascendapi.p.rapidapi.com';
  const String baseUrl = 'https://\$apiHost/api/v1';

  final url = Uri.parse('\$baseUrl/exercises?limit=10'); // Small limit for testing
  
  try {
    final response = await http.get(
      url,
      headers: {
        'X-RapidAPI-Key': apiKey,
        'X-RapidAPI-Host': apiHost,
      },
    );

    print("Status code: \${response.statusCode}");
    if (response.statusCode == 200) {
      if (response.body.length > 200) {
        print("Success, body length: \${response.body.length}");
        print("Body sample: \${response.body.substring(0, 200)}...");
      } else {
        print("Body: \${response.body}");
      }
    } else {
      print("Error body: \${response.body}");
    }
  } catch (e) {
    print("Exception API: \${e.toString()}");
  }
}
