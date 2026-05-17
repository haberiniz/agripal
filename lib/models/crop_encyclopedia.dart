import 'dart:convert';
import 'package:flutter/services.dart';

class GrowthStage {
  final String stage;
  final int startDay;
  final int endDay;
  final double kc;
  final String description;
  final Map<String, dynamic> irrigation;
  final Map<String, dynamic> nutrition;

  GrowthStage({
    required this.stage,
    required this.startDay,
    required this.endDay,
    required this.kc,
    required this.description,
    required this.irrigation,
    required this.nutrition,
  });

  bool isWithin(int day) => day >= startDay && day <= endDay;
}

class CropEncyclopedia {
  final String id;
  final String nameAr;
  final String scientificName;
  final List<GrowthStage> stages;
  final Map<String, dynamic> soilScience;
  final List<Map<String, dynamic>> pests;

  CropEncyclopedia({
    required this.id,
    required this.nameAr,
    required this.scientificName,
    required this.stages,
    required this.soilScience,
    required this.pests,
  });

  GrowthStage? getStageForDay(int day) {
    for (var stage in stages) {
      if (stage.isWithin(day)) return stage;
    }
    return stages.isNotEmpty ? stages.last : null;
  }

  double getKcForDay(int day) {
    final stage = getStageForDay(day);
    return stage?.kc ?? 0.75;
  }

  // ✅ تحميل من ملف JSON مع معالجة Null
  static Future<CropEncyclopedia> load(String cropId) async {
    try {
      final String path = 'assets/data/${cropId}_encyclopedia_dz.json';
      final String jsonString = await rootBundle.loadString(path);
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      
      // ✅ معالجة آمنة للبيانات
      final metadata = jsonMap['crop_metadata'] as Map<String, dynamic>? ?? {};
      final botanical = jsonMap['botanical_profile'] as Map<String, dynamic>? ?? {};
      final stagesRaw = jsonMap['growth_stages_detailed'] as List? ?? [];
      
      final stages = stagesRaw.map((s) {
        final sMap = s as Map<String, dynamic>;
        final daysStr = sMap['days'] as String? ?? '1 - 20';
        final parts = daysStr.split(' - ');
        final startDay = int.tryParse(parts[0].trim()) ?? 1;
        final endDay = int.tryParse(parts[1].trim()) ?? 120;
        
        return GrowthStage(
          stage: sMap['stage'] as String? ?? 'مرحلة غير معروفة',
          startDay: startDay,
          endDay: endDay,
          kc: (sMap['kc'] as num?)?.toDouble() ?? 0.75,
          description: sMap['description'] as String? ?? '',
          irrigation: (sMap['irrigation'] as Map<String, dynamic>?) ?? {},
          nutrition: (sMap['nutrition'] as Map<String, dynamic>?) ?? {},
        );
      }).toList();
      
      return CropEncyclopedia(
        id: metadata['id'] as String? ?? cropId,
        nameAr: botanical['name_ar'] as String? ?? 'البطاطا',
        scientificName: botanical['scientific_name'] as String? ?? 'Solanum tuberosum',
        stages: stages,
        soilScience: jsonMap['soil_science_dz'] as Map<String, dynamic>? ?? {},
        pests: (jsonMap['comprehensive_pest_control'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      );
    } catch (e) {
      print('Error loading JSON, using default data: $e');
      return _getDefaultData();
    }
  }
  
  // ✅ بيانات افتراضية في حالة فشل التحميل
  static CropEncyclopedia _getDefaultData() {
    return CropEncyclopedia(
      id: 'potato',
      nameAr: 'البطاطا',
      scientificName: 'Solanum tuberosum',
      stages: [
        GrowthStage(
          stage: 'الإنبات',
          startDay: 1,
          endDay: 20,
          kc: 0.45,
          description: 'تطور البراعم من الدرنة',
          irrigation: {'strategy': 'ري خفيف'},
          nutrition: {'NPK_ratio': '1:3:1', 'dosage': '150 كغ/هكتار'},
        ),
        GrowthStage(
          stage: 'النمو الخضري',
          startDay: 21,
          endDay: 45,
          kc: 0.75,
          description: 'بناء المجموع الخضري',
          irrigation: {'strategy': 'ري متوسط'},
          nutrition: {'NPK_ratio': '3:1:1', 'dosage': '200 كغ/هكتار'},
        ),
        GrowthStage(
          stage: 'التدرن',
          startDay: 46,
          endDay: 65,
          kc: 1.15,
          description: 'تكوين الدرنات',
          irrigation: {'strategy': 'ري ثابت'},
          nutrition: {'NPK_ratio': '1:1:2', 'dosage': '100 كغ/هكتار'},
        ),
        GrowthStage(
          stage: 'التحجيم',
          startDay: 66,
          endDay: 100,
          kc: 1.25,
          description: 'زيادة حجم الدرنات',
          irrigation: {'strategy': 'ري غزير'},
          nutrition: {'NPK_ratio': '1:1:4', 'dosage': '300 كغ/هكتار'},
        ),
        GrowthStage(
          stage: 'النضج',
          startDay: 101,
          endDay: 120,
          kc: 0.70,
          description: 'نضج المحصول',
          irrigation: {'strategy': 'إيقاف الري'},
          nutrition: {'NPK_ratio': '0:0:0', 'dosage': '0'},
        ),
      ],
      soilScience: {},
      pests: [],
    );
  }
}