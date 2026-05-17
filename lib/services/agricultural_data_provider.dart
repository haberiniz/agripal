// ai_data_provider.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

/// مصدر البيانات الزراعية – بدون أي API خارجي (غير OpenWeather)
class AgriculturalDataProvider {
  final String cropName; // 'potato'
  Map<String, dynamic>? _cropData;
  
  AgriculturalDataProvider({required this.cropName});
  
  /// تحميل ملف JSON الخاص بالمحصول
  Future<void> loadCropData() async {
    try {
      // يمكن تغيير المسار حسب المحصول: assets/data/potato.json
      final jsonString = await rootBundle.loadString('assets/data/$cropName.json');
      _cropData = json.decode(jsonString);
    } catch (e) {
      print('خطأ في تحميل بيانات المحصول: $e');
    }
  }
  
  /// جلب التوصيات لمرحلة معينة ويوم معين من ملف JSON
  Map<String, dynamic>? getRecommendationForDay(int day) {
    if (_cropData == null) return null;
    final tracking = _cropData!['daily_tracking'] as List<dynamic>?;
    if (tracking == null) return null;
    
    // البحث عن اليوم (index يبدأ من 0)
    final dayData = tracking.firstWhere(
      (d) => d['day'] == day,
      orElse: () => null,
    );
    return dayData;
  }
  
  /// حساب وقت الري المطلوب بناءً على الكمية ونوع الري
  static double calculateIrrigationDuration({
    required double quantityLitersPerPlant,
    required String irrigationType,
    required double flowRateLPerHour, // لتر/ساعة للنقطة الواحدة
    required int plantsCount, // عدد النباتات في المساحة
  }) {
    // التنقيط: 2 لتر/ساعة للنقطة، الرش: 1000 لتر/ساعة للهكتار
    double totalWaterNeeded = quantityLitersPerPlant * plantsCount;
    double durationHours = totalWaterNeeded / flowRateLPerHour;
    return durationHours;
  }
  
  /// حساب توقيت الري الأمثل حسب درجة الحرارة
  static String getOptimalIrrigationTime(double maxTemp) {
    if (maxTemp > 35) return '06:00 و 19:00'; // جلستان
    if (maxTemp > 30) return '06:30 و 18:30';
    if (maxTemp < 20) return '08:00';
    return '07:00';
  }
  
  /// تعديل كمية الري حسب الطقس الحالي
  static double adjustWaterByWeather(double baseLiters, double maxTemp, double humidity, double rain) {
    double adjusted = baseLiters;
    
    if (maxTemp > 35) adjusted *= 1.4;
    else if (maxTemp > 30) adjusted *= 1.2;
    else if (maxTemp < 20) adjusted *= 0.8;
    
    if (humidity > 75) adjusted *= 0.9;
    
    if (rain > 3) adjusted = 0; // لو المطر كافي، ما تحتاجش ري
    
    return adjusted;
  }
}

/// جلب الطقس الحقيقي من OpenWeather
class WeatherService {
  static const _apiKey = '3bd015115660091719e9545a0d7f5202';
  
  Future<Map<String, dynamic>> fetchCurrentWeather(double lat, double lon) async {
    final response = await http.get(Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=ar'
    ));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('فشل جلب الطقس');
  }
  
  Future<List<Map<String, dynamic>>> fetchWeekForecast(double lat, double lon) async {
    final response = await http.get(Uri.parse(
      'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=ar&cnt=40'
    ));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final list = data['list'] as List;
      
      // تجميع حسب اليوم
      final Map<String, List> byDay = {};
      for (final item in list) {
        final date = DateTime.fromMillisecondsSinceEpoch((item['dt'] as int) * 1000);
        final key = DateFormat('yyyy-MM-dd').format(date);
        byDay.putIfAbsent(key, () => []).add(item);
      }
      
      final forecasts = <Map<String, dynamic>>[];
      final keys = byDay.keys.toList()..sort();
      for (final key in keys.take(7)) {
        final items = byDay[key]!;
        double maxTemp = -99, minTemp = 99, totalRain = 0, totalHumidity = 0;
        String description = '', icon = '';
        for (final item in items) {
          final main = item['main'];
          final temp = (main['temp'] as num).toDouble();
          if (temp > maxTemp) maxTemp = temp;
          if (temp < minTemp) minTemp = temp;
          totalHumidity += (main['humidity'] as num).toDouble();
          totalRain += (item['rain']?['3h'] as num? ?? 0).toDouble();
          if (description.isEmpty) {
            description = item['weather'][0]['description'];
            icon = item['weather'][0]['icon'];
          }
        }
        forecasts.add({
          'date': key,
          'max_temp': maxTemp,
          'min_temp': minTemp,
          'rain': totalRain,
          'humidity': totalHumidity / items.length,
          'description': description,
          'icon': icon,
        });
      }
      return forecasts;
    }
    throw Exception('فشل جلب التوقعات');
  }
}