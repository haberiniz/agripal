// lib/services/knowledge_service.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class KnowledgeService {
  static Map<String, dynamic>? _knowledgeData;
  static bool _isLoaded = false;

  /// تحميل ملف المعرفة مرة واحدة عند بداية التطبيق
  static Future<void> load() async {
    if (_isLoaded) return;
    
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/agriculture_knowledge.json'
      );
      _knowledgeData = jsonDecode(jsonString);
      _isLoaded = true;
      print('✅ تم تحميل قاعدة المعرفة بنجاح');
    } catch (e) {
      print('❌ خطأ في تحميل المعرفة: $e');
      _knowledgeData = {};
    }
  }

  /// البحث عن محصول بالاسم
  static Map<String, dynamic>? getCrop(String cropName) {
    final crops = _knowledgeData?['crops'] as Map<String, dynamic>?;
    return crops?[cropName];
  }

  /// البحث عن ولاية
  static Map<String, dynamic>? getWilaya(String wilayaName) {
    final regions = _knowledgeData?['regions'] as Map<String, dynamic>?;
    return regions?[wilayaName];
  }

  /// بحث بسيط بالكلمة المفتاحية
  static List<Map<String, String>> search(String query, {String language = 'ar'}) {
    final results = <Map<String, String>>[];
    if (!_isLoaded || _knowledgeData == null) return results;

    final lowerQuery = query.toLowerCase();
    final crops = _knowledgeData?['crops'] as Map<String, dynamic>? ?? {};

    for (var entry in crops.entries) {
      final crop = entry.value as Map<String, dynamic>?;
      if (crop == null) continue;

      final name = crop['local_name']?.toString().toLowerCase() ?? '';
      final category = crop['category']?.toString().toLowerCase() ?? '';

      if (name.contains(lowerQuery) || category.contains(lowerQuery)) {
        results.add({
          'type': 'crop',
          'name': crop['local_name'] ?? entry.key,
          'category': category,
          'yield': crop['yield_ton_per_ha']?.toString() ?? 'غير متوفر',
        });
      }
    }
    return results;
  }

  static bool get isLoaded => _isLoaded;
}