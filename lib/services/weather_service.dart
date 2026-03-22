import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final String apiKey = "3bd015115660091719e9545a0d7f5202";

  Future<Map<String, dynamic>> getWeather(double lat, double lon) async {
    final url = Uri.parse(
        "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to load weather");
    }
  }
}