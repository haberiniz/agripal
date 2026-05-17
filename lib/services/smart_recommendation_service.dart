import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SmartRecommendationService {
  static List<dynamic>? _potatoData;
  
  // تحميل بيانات البطاطا من JSON
  static Future<void> loadPotatoData() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/potato_daily_tracking_data.json');
      _potatoData = json.decode(jsonString);
      print('✅ تم تحميل ${_potatoData?.length} يوم من بيانات البطاطا');
    } catch (e) {
      print('❌ خطأ في تحميل بيانات البطاطا: $e');
      _potatoData = _getDefaultPotatoData();
    }
  }
  
  // بيانات افتراضية للبطاطا (بدون أخطاء)
  static List<dynamic> _getDefaultPotatoData() {
    List<dynamic> data = [];
    for (int i = 1; i <= 120; i++) {
      String stage;
      double waterAmount;
      String frequency;
      
      if (i <= 20) {
        stage = "تطور البراعم الأولي";
        waterAmount = 0.5;
        frequency = "يومي";
      } else if (i <= 50) {
        stage = "النمو الخضري";
        waterAmount = 1.0;
        frequency = "يومي";
      } else if (i <= 85) {
        stage = "تكوين الدرنات";
        waterAmount = 1.5;
        frequency = "يومي";
      } else {
        stage = "نضج الدرنات";
        waterAmount = 0.7;
        frequency = "كل 2-3 أيام";
      }
      
      data.add({
        'day': i,
        'growth_stage': stage,
        'irrigation': {
          'quantity_liters_per_plant': waterAmount,
          'frequency': frequency,
          'method': 'تنقيط',
          'notes': ''
        },
        'fertilization': (i == 1 || i == 33 || i == 56 || i == 70 || i == 91) ? {
          'type': i <= 50 ? 'نيتروجين عالٍ (NPK 20-20-20)' : 'بوتاسيوم عالٍ (NPK 13-13-40)',
          'quantity_kg_per_hectare': '150-200',
          'method': 'مع مياه الري (Fertigation)',
          'notes': ''
        } : {
          'type': null,
          'quantity_kg_per_hectare': null,
          'method': null,
          'notes': ''
        },
        'weather_alerts': [],
        'pest_disease_warnings': [],
        'soil_management': {'notes': ''},
        'general_notes': ''
      });
    }
    return data;
  }
  
  // حساب اليوم الحالي من تاريخ الزراعة
  static int calculateCurrentDay(DateTime plantingDate) {
    final now = DateTime.now();
    final difference = now.difference(plantingDate);
    int day = difference.inDays + 1;
    if (day < 1) day = 1;
    if (day > 120) day = 120;
    return day;
  }
  
  // جلب بيانات اليوم الحالي (مع التحقق من الأمان)
  static Map<String, dynamic>? getTodayData(DateTime plantingDate) {
    if (_potatoData == null) return null;
    final day = calculateCurrentDay(plantingDate);
    try {
      final result = _potatoData!.firstWhere(
        (item) => item['day'] == day,
        orElse: () => _potatoData!.last,
      );
      return Map<String, dynamic>.from(result);
    } catch (e) {
      print('❌ خطأ في جلب بيانات اليوم $day: $e');
      return null;
    }
  }
  
  // حساب التقدم (%)
  static int calculateProgress(int day) {
    return ((day / 120) * 100).toInt();
  }
  
  // جلب توصيات الري (مع التحقق من الأمان)
  static Map<String, dynamic> getIrrigationRecommendation(
    DateTime plantingDate,
    String irrigationType,
    double farmArea,
    String soilType,
  ) {
    final todayData = getTodayData(plantingDate);
    final day = calculateCurrentDay(plantingDate);
    
    double baseQuantity = 1.0;
    String frequency = "يومي";
    String method = "تنقيط";
    String notes = "";
    
    if (todayData != null && todayData['irrigation'] != null) {
      final irrigation = todayData['irrigation'] as Map<String, dynamic>;
      // ✅ التحقق من أن القيمة رقمية
      final qty = irrigation['quantity_liters_per_plant'];
      if (qty is num) {
        baseQuantity = qty.toDouble();
      } else if (qty is String) {
        baseQuantity = double.tryParse(qty) ?? 1.0;
      }
      frequency = irrigation['frequency']?.toString() ?? "يومي";
      method = irrigation['method']?.toString() ?? "تنقيط";
      notes = irrigation['notes']?.toString() ?? "";
    }
    
    // معاملات التصحيح
    double soilFactor = 1.0;
    if (soilType.contains('رملية')) soilFactor = 1.3;
    else if (soilType.contains('طينية')) soilFactor = 0.8;
    
    double irrigationFactor = 1.0;
    if (irrigationType == 'بالتنقيط') irrigationFactor = 1.0;
    else if (irrigationType == 'بالرش') irrigationFactor = 1.2;
    else if (irrigationType == 'بالغمر') irrigationFactor = 1.5;
    else if (irrigationType == 'رش محوري') irrigationFactor = 1.3;
    else irrigationFactor = 1.1;
    
    double weatherFactor = 1.0;
    double adjustedQuantity = baseQuantity * soilFactor * irrigationFactor * weatherFactor;
    
    return {
      'base_quantity_L': baseQuantity.toStringAsFixed(1),
      'adjusted_quantity_L': adjustedQuantity.toStringAsFixed(1),
      'split_recommended': adjustedQuantity > 2.0,
      'method': method,
      'frequency': frequency,
      'notes': notes,
      'factors': {
        'soil': soilFactor.toStringAsFixed(2),
        'irrigation': irrigationFactor.toStringAsFixed(2),
        'weather': weatherFactor.toStringAsFixed(2),
        'combined': (soilFactor * irrigationFactor * weatherFactor).toStringAsFixed(2),
      }
    };
  }
  
  // جلب توصيات الأسمدة
  static Map<String, dynamic> getFertilizationRecommendation(DateTime plantingDate) {
    final todayData = getTodayData(plantingDate);
    if (todayData == null || todayData['fertilization'] == null) {
      return {'needed_today': false};
    }
    
    final fert = todayData['fertilization'] as Map<String, dynamic>;
    final type = fert['type'];
    final needed = type != null && type.toString().isNotEmpty;
    
    return {
      'needed_today': needed,
      'type': needed ? type.toString() : null,
      'quantity_kg_per_hectare': fert['quantity_kg_per_hectare']?.toString(),
      'method': fert['method']?.toString(),
      'notes': fert['notes']?.toString() ?? '',
    };
  }
  
  // جلب اسم مرحلة النمو
  static String getStageName(int day) {
    if (day <= 20) return 'تطور البراعم الأولي';
    if (day <= 50) return 'النمو الخضري';
    if (day <= 85) return 'تكوين الدرنات';
    return 'نضج الدرنات';
  }
  
  // جلب ملخص اليوم
  static String getSummaryMessage(int day, double waterAmount, bool fertNeeded) {
    if (day <= 20) {
      return '💧 مرحلة الإنبات: حافظ على رطوبة التربة لتشجيع ظهور البراعم';
    } else if (day <= 50) {
      return '🌱 مرحلة النمو الخضري: زود النبات بالنيتروجين لدعم النمو';
    } else if (day <= 85) {
      return '🥔 مرحلة تكوين الدرنات: الري المنتظم مهم جداً لجودة المحصول';
    } else {
      return '🌾 مرحلة النضج: قلل الري تدريجياً استعداداً للحصاد';
    }
  }
  
  // تحديث التوصية في Firestore
  static Future<void> updateRecommendation(
    String userId,
    DateTime plantingDate,
    String irrigationType,
    double farmArea,
    String soilType,
  ) async {
    try {
      final day = calculateCurrentDay(plantingDate);
      final todayData = getTodayData(plantingDate);
      final progress = calculateProgress(day);
      final harvestIn = day >= 120 ? 0 : (120 - day);
      
      final irrigation = getIrrigationRecommendation(plantingDate, irrigationType, farmArea, soilType);
      final fertilization = getFertilizationRecommendation(plantingDate);
      
      String growthStage = getStageName(day);
      String generalNotes = "";
      List<dynamic> weatherAlerts = [];
      List<dynamic> pestWarnings = [];
      String soilMgmt = "";
      
      if (todayData != null) {
        growthStage = todayData['growth_stage']?.toString() ?? growthStage;
        generalNotes = todayData['general_notes']?.toString() ?? "";
        weatherAlerts = todayData['weather_alerts'] as List<dynamic>? ?? [];
        pestWarnings = todayData['pest_disease_warnings'] as List<dynamic>? ?? [];
        final soilMgmtMap = todayData['soil_management'] as Map<String, dynamic>?;
        soilMgmt = soilMgmtMap?['notes']?.toString() ?? "";
      }
      
      final adjustedQty = double.tryParse(irrigation['adjusted_quantity_L']) ?? 0.0;
      
      final recommendationData = {
        'crop_type': 'البطاطا',
        'day': day,
        'cycle_days': 120,
        'growth_stage': growthStage,
        'progress_pct': progress,
        'harvest_in_days': harvestIn,
        'irrigation': irrigation,
        'fertilization': fertilization,
        'alerts': weatherAlerts,
        'pest_disease_warnings': pestWarnings,
        'soil_management': soilMgmt,
        'general_notes': generalNotes,
        'summary': {
          'irrigation_msg': getSummaryMessage(day, adjustedQty, fertilization['needed_today']),
          'soil_context': soilType,
        },
        'updatedAt': FieldValue.serverTimestamp(),
        'plantingDate': plantingDate.toIso8601String(),
      };
      
      await FirebaseFirestore.instance
          .collection('farmers')
          .doc(userId)
          .collection('recommendations')
          .doc('latest')
          .set(recommendationData, SetOptions(merge: true));
      
      print('✅ تم تحديث التوصية لليوم $day');
    } catch (e) {
      print('❌ خطأ في تحديث التوصية: $e');
    }
  }
  
  // بدء التحديث التلقائي
  static void startAutoUpdate(String userId, DateTime plantingDate, String irrigationType, double farmArea, String soilType) {
    updateRecommendation(userId, plantingDate, irrigationType, farmArea, soilType);
    Future.delayed(const Duration(hours: 24), () {
      startAutoUpdate(userId, plantingDate, irrigationType, farmArea, soilType);
    });
  }
}