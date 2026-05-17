// ══════════════════════════════════════════════════════════════════
//  crop_data.dart — بيانات جميع المحاصيل المدعومة
//  أضف محصولاً جديداً بإضافة CropInfo جديد في allCrops فقط
// ══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

// ─── نموذج مرحلة النمو ────────────────────────────────────────────
class GrowthStage {
  final String name;
  final int startDay;
  final int endDay;
  final Color color;

  const GrowthStage({
    required this.name,
    required this.startDay,
    required this.endDay,
    required this.color,
  });
}

// ─── نموذج معلومات المحصول ────────────────────────────────────────
class CropInfo {
  final String name;           // الاسم بالعربية
  final String emoji;          // رمز تعبيري للعرض
  final int cycleDays;         // طول الدورة الزراعية بالأيام
  final List<GrowthStage> stages; // مراحل النمو

  const CropInfo({
    required this.name,
    required this.emoji,
    required this.cycleDays,
    required this.stages,
  });

  /// يُعيد مرحلة النمو الحالية بناءً على رقم اليوم
  GrowthStage stageForDay(int day) {
    for (final s in stages) {
      if (day >= s.startDay && day <= s.endDay) return s;
    }
    return stages.last;
  }
}

// ══════════════════════════════════════════════════════════════════
//  قاعدة بيانات المحاصيل
//  لإضافة محصول جديد: انسخ أحد الكتل أدناه وعدّل القيم فقط
// ══════════════════════════════════════════════════════════════════
final Map<String, CropInfo> allCrops = {

  // ── البطاطا ─────────────────────────────────────────────────────
  'البطاطا': CropInfo(
    name: 'البطاطا',
    emoji: '🥔',
    cycleDays: 120,
    stages: [
      GrowthStage(name: 'إنبات',      startDay: 1,   endDay: 20,  color: Color(0xFF4A90C8)),
      GrowthStage(name: 'نمو خضري',   startDay: 21,  endDay: 50,  color: Color(0xFF55AA66)),
      GrowthStage(name: 'تكوين درنات',startDay: 51,  endDay: 85,  color: Colors.orange),
      GrowthStage(name: 'نضج',        startDay: 86,  endDay: 120, color: Colors.purple),
    ],
  ),

  // ── الطماطم ─────────────────────────────────────────────────────
  'الطماطم': CropInfo(
    name: 'الطماطم',
    emoji: '🍅',
    cycleDays: 110,
    stages: [
      GrowthStage(name: 'شتلة',       startDay: 1,  endDay: 25,  color: Color(0xFF4A90C8)),
      GrowthStage(name: 'نمو خضري',   startDay: 26, endDay: 55,  color: Color(0xFF55AA66)),
      GrowthStage(name: 'إزهار',      startDay: 56, endDay: 80,  color: Colors.pink),
      GrowthStage(name: 'إثمار',      startDay: 81, endDay: 110, color: Colors.red),
    ],
  ),

  // ── الفلفل ──────────────────────────────────────────────────────
  'الفلفل': CropInfo(
    name: 'الفلفل',
    emoji: '🌶️',
    cycleDays: 130,
    stages: [
      GrowthStage(name: 'شتلة',       startDay: 1,  endDay: 30,  color: Color(0xFF4A90C8)),
      GrowthStage(name: 'نمو خضري',   startDay: 31, endDay: 65,  color: Color(0xFF55AA66)),
      GrowthStage(name: 'إزهار',      startDay: 66, endDay: 95,  color: Colors.orange),
      GrowthStage(name: 'إثمار',      startDay: 96, endDay: 130, color: Colors.red),
    ],
  ),

  // ── الجزر ───────────────────────────────────────────────────────
  'الجزر': CropInfo(
    name: 'الجزر',
    emoji: '🥕',
    cycleDays: 90,
    stages: [
      GrowthStage(name: 'إنبات',      startDay: 1,  endDay: 15,  color: Color(0xFF4A90C8)),
      GrowthStage(name: 'نمو خضري',   startDay: 16, endDay: 45,  color: Color(0xFF55AA66)),
      GrowthStage(name: 'تضخم جذر',   startDay: 46, endDay: 75,  color: Colors.orange),
      GrowthStage(name: 'نضج',        startDay: 76, endDay: 90,  color: Colors.deepOrange),
    ],
  ),

  // ── البصل ───────────────────────────────────────────────────────
  'البصل': CropInfo(
    name: 'البصل',
    emoji: '🧅',
    cycleDays: 150,
    stages: [
      GrowthStage(name: 'إنبات',      startDay: 1,   endDay: 20,  color: Color(0xFF4A90C8)),
      GrowthStage(name: 'نمو خضري',   startDay: 21,  endDay: 70,  color: Color(0xFF55AA66)),
      GrowthStage(name: 'تكوين بصلة', startDay: 71,  endDay: 120, color: Colors.purple),
      GrowthStage(name: 'نضج',        startDay: 121, endDay: 150, color: Colors.brown),
    ],
  ),

  // ── الخس ────────────────────────────────────────────────────────
  'الخس': CropInfo(
    name: 'الخس',
    emoji: '🥬',
    cycleDays: 60,
    stages: [
      GrowthStage(name: 'إنبات',      startDay: 1,  endDay: 10, color: Color(0xFF4A90C8)),
      GrowthStage(name: 'نمو مبكر',   startDay: 11, endDay: 30, color: Color(0xFF55AA66)),
      GrowthStage(name: 'تكوين رأس',  startDay: 31, endDay: 50, color: Color(0xFF2E7D32)),
      GrowthStage(name: 'نضج',        startDay: 51, endDay: 60, color: Colors.teal),
    ],
  ),

  // ── القمح ───────────────────────────────────────────────────────
  'القمح': CropInfo(
    name: 'القمح',
    emoji: '🌾',
    cycleDays: 180,
    stages: [
      GrowthStage(name: 'إنبات',      startDay: 1,   endDay: 30,  color: Color(0xFF4A90C8)),
      GrowthStage(name: 'تفريع',      startDay: 31,  endDay: 80,  color: Color(0xFF55AA66)),
      GrowthStage(name: 'سنبلة',      startDay: 81,  endDay: 130, color: Colors.amber),
      GrowthStage(name: 'نضج حبة',    startDay: 131, endDay: 180, color: Colors.brown),
    ],
  ),

  // ── الذرة ───────────────────────────────────────────────────────
  'الذرة': CropInfo(
    name: 'الذرة',
    emoji: '🌽',
    cycleDays: 130,
    stages: [
      GrowthStage(name: 'إنبات',      startDay: 1,  endDay: 20,  color: Color(0xFF4A90C8)),
      GrowthStage(name: 'نمو خضري',   startDay: 21, endDay: 70,  color: Color(0xFF55AA66)),
      GrowthStage(name: 'تلقيح',      startDay: 71, endDay: 95,  color: Colors.amber),
      GrowthStage(name: 'تكوين كوز',  startDay: 96, endDay: 130, color: Colors.orange),
    ],
  ),

};

/// يُعيد CropInfo للمحصول، أو يُعيد البطاطا كقيمة افتراضية
CropInfo getCropInfo(String cropName) =>
    allCrops[cropName] ?? allCrops['البطاطا']!;