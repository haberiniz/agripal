// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ⚠️ غيري الـ IP حسب جهازك:
  // - Android Emulator: 10.0.2.2
  // - iOS Simulator: localhost
  // - جهاز حقيقي: عنوان الـ WiFi الخاص بالكمبيوتر (مثلاً: 192.168.1.100)
static const String baseUrl = 'http://192.168.1.100:8000';

  /// إرسال سؤال للبوت واستقبال الرد
  static Future<Map<String, dynamic>> sendChatMessage({
    required String message,
    String? region,
    String? cropHint,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'region': region,
          'crop_hint': cropHint,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('خطأ في السيرفر: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ خطأ في الاتصال: $e');
      // ✅ Fallback: رد محلي في حال فشل الاتصال
      return {
        'reply': 'عذراً، ما نقدرش نربط بالسيرفر حالياً. جربي لاحقاً. 🌱',
        'source': 'fallback',
        'confidence': 0.0,
      };
    }
  }
}