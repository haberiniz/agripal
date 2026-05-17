import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:agripal/models/weather_model.dart';

class WeatherService {
  static const apiKey = '3bd015115660091719e9545a0d7f5202';

  static Future<List<WeatherForecast>> getWeekForecast(double lat, double lon) async {
    final url = 'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=ar&cnt=40';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) throw Exception('فشل جلب الطقس');

    final data = json.decode(response.body);
    final list = data['list'] as List;

    // تجميع حسب اليوم
    final Map<String, List> daily = {};
    for (var item in list) {
      final date = DateTime.fromMillisecondsSinceEpoch((item['dt'] as int) * 1000);
      final key = DateFormat('yyyy-MM-dd').format(date);
      daily.putIfAbsent(key, () => []).add(item);
    }

    final forecasts = <WeatherForecast>[];
    for (var entry in daily.entries.take(7)) {
      final items = entry.value;
      double maxTemp = -99, minTemp = 99, totalRain = 0, totalHumidity = 0, totalWind = 0;
      String desc = '', icon = '';
      for (var item in items) {
        final main = item['main'];
        final temp = (main['temp'] as num).toDouble();
        if (temp > maxTemp) maxTemp = temp;
        if (temp < minTemp) minTemp = temp;
        totalHumidity += (main['humidity'] as num).toDouble();
        totalWind += (item['wind']['speed'] as num).toDouble();
        totalRain += (item['rain']?['3h'] as num? ?? 0).toDouble();
        if (desc.isEmpty) {
          desc = item['weather'][0]['description'] ?? '';
          icon = item['weather'][0]['icon'] ?? '';
        }
      }
      forecasts.add(WeatherForecast(
        date: DateTime.parse(entry.key),
        maxTemp: maxTemp,
        minTemp: minTemp,
        rain: totalRain,
        humidity: totalHumidity / items.length,
        windSpeed: totalWind / items.length,
        description: desc,
        icon: icon,
      ));
    }
    return forecasts;
  }
}