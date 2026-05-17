// ============================================================
// 🌾 FERTILIZATION SCREEN — REDESIGNED ELEGANT UI
// Flutter | Animated | Dark/Light | 58 Wilayas | Full Crop DB
// ============================================================

import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ==================== COLORS ====================
class AppColors {
  // Primary palette
  static const Color primaryDark    = Color(0xFF3D2F1E);
  static const Color primary        = Color(0xFF4A7A32);
  static const Color primaryLight   = Color(0xFF6BA348);
  static const Color primaryGlow    = Color(0xFF8DC96A);

  // Backgrounds
  static const Color backgroundSoft = Color(0xFFEDF4E0);
  static const Color backgroundCard = Color(0xFFF8FAF3);
  static const Color surfaceLight   = Color(0xFFFFFFFF);

  // Accents
  static const Color accent         = Color(0xFFD4C5A9);
  static const Color accentWarm     = Color(0xFFE8D5B0);
  static const Color accentGold     = Color(0xFFC8A96E);
  static const Color accentAmber    = Color(0xFFE5A530);

  // Text
  static const Color textDark       = Color(0xFF2A1F12);
  static const Color textMid        = Color(0xFF5C4A32);
  static const Color textLight      = Color(0xFFF5F0E8);
  static const Color textMuted      = Color(0xFF8B7355);

  // Status
  static const Color success        = Color(0xFF2E7D32);
  static const Color warning        = Color(0xFFE65100);
  static const Color info           = Color(0xFF1565C0);

  // Dark mode
  static const Color darkBg         = Color(0xFF0E1509);
  static const Color darkSurface    = Color(0xFF161E0E);
  static const Color darkCard       = Color(0xFF1E2A14);
  static const Color darkCardHover  = Color(0xFF253218);
  static const Color darkBorder     = Color(0xFF2E3D20);
  static const Color darkText       = Color(0xFFCFE3A8);
  static const Color darkTextMuted  = Color(0xFF7A9558);
}

// ==================== THEME ====================
ThemeData buildLightTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.primary,
    secondary: AppColors.accentGold,
    surface: AppColors.surfaceLight,
    background: AppColors.backgroundSoft,
  ),
  scaffoldBackgroundColor: AppColors.backgroundSoft,
  fontFamily: 'Cairo',
  cardTheme: CardThemeData(
    color: AppColors.surfaceLight,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
  ),
);

ThemeData buildDarkTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.primaryLight,
    secondary: AppColors.accentGold,
    surface: AppColors.darkCard,
    background: AppColors.darkBg,
  ),
  scaffoldBackgroundColor: AppColors.darkBg,
  fontFamily: 'Cairo',
  cardTheme: CardThemeData(
    color: AppColors.darkCard,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
  ),
);

// ==================== DATA MODELS (unchanged) ====================
class WilayaModel {
  final int code;
  final String name;
  final String soilType;
  final double lat;
  final double lon;
  WilayaModel({required this.code, required this.name, required this.soilType, required this.lat, required this.lon});
}

class SoilModel {
  final String texture;
  final double phMin, phMax;
  final String irrigation, fertilisation;
  final int N, P, K, Ca, Mg, S;
  final double efficacite;
  SoilModel({required this.texture, required this.phMin, required this.phMax,
    required this.irrigation, required this.fertilisation,
    required this.N, required this.P, required this.K, required this.Ca,
    required this.Mg, required this.S, required this.efficacite});
}

class CropStage {
  final String name;
  final int days, N, P, K, Ca, Mg, S;
  CropStage({required this.name, required this.days, required this.N, required this.P,
    required this.K, required this.Ca, required this.Mg, required this.S});
}

class CropModel {
  final String name, category, icon;
  final int cycleDays, tempMin, tempMax, waterMm;
  final List<CropStage> stages;
  CropModel({required this.name, required this.category, required this.icon,
    required this.cycleDays, required this.tempMin, required this.tempMax,
    required this.waterMm, required this.stages});
}

class FertilizerRec {
  final String name, icon, how, when;
  final double kgHa;
  FertilizerRec({required this.name, required this.icon, required this.kgHa,
    required this.how, required this.when});
}

class AnalysisResult {
  final String wilayaName, cropName, soilType, stageName, plantDate, analysisDate;
  final double area, stageProgress, totalKgHa;
  final int daysElapsed, totalDays, daysRemaining;
  final Map<String, Map<String, dynamic>> nutrients;
  final List<FertilizerRec> fertilizers;
  final List<String> alerts, warnings;
  final Map<String, dynamic>? weather;
  final Map<String, dynamic> irrigation;

  AnalysisResult({
    required this.wilayaName, required this.area, required this.cropName,
    required this.soilType, required this.stageName, required this.stageProgress,
    required this.daysElapsed, required this.totalDays, required this.daysRemaining,
    required this.totalKgHa, required this.nutrients, required this.fertilizers,
    required this.alerts, required this.warnings, required this.plantDate,
    required this.analysisDate, this.weather, required this.irrigation,
  });

  Map<String, dynamic> toJson() => {
    'wilayaName': wilayaName, 'area': area, 'cropName': cropName, 'soilType': soilType,
    'stageName': stageName, 'stageProgress': stageProgress, 'daysElapsed': daysElapsed,
    'totalDays': totalDays, 'daysRemaining': daysRemaining, 'totalKgHa': totalKgHa,
    'nutrients': nutrients, 'plantDate': plantDate, 'analysisDate': analysisDate,
    'alerts': alerts, 'warnings': warnings, 'irrigation': irrigation,
    'fertilizers': fertilizers.map((f) => {
      'name': f.name, 'icon': f.icon, 'kgHa': f.kgHa, 'how': f.how, 'when': f.when
    }).toList(),
  };
}

// ==================== 58 WILAYAS ====================
final List<WilayaModel> allWilayas = [
  WilayaModel(code:1,  name:'أدرار',           soilType:'Sols sableux (Erg)',          lat:27.87, lon:-0.28),
  WilayaModel(code:2,  name:'الشلف',            soilType:'Sols alluviaux',              lat:36.17, lon:1.33),
  WilayaModel(code:3,  name:'الأغواط',          soilType:'Sols sableux (Erg)',          lat:33.80, lon:2.86),
  WilayaModel(code:4,  name:'أم البواقي',       soilType:'Vertisols',                   lat:35.88, lon:7.11),
  WilayaModel(code:5,  name:'باتنة',            soilType:'Sols peu évolués d\'érosion', lat:35.57, lon:6.17),
  WilayaModel(code:6,  name:'بجاية',            soilType:'Sols bruns calcaires',        lat:36.75, lon:5.08),
  WilayaModel(code:7,  name:'بسكرة',            soilType:'Sols sableux (Erg)',          lat:34.85, lon:5.73),
  WilayaModel(code:8,  name:'بشار',             soilType:'Sols sableux (Erg)',          lat:31.62, lon:-2.22),
  WilayaModel(code:9,  name:'البليدة',          soilType:'Sols alluviaux',              lat:36.47, lon:2.83),
  WilayaModel(code:10, name:'البويرة',          soilType:'Sols bruns calcaires',        lat:36.38, lon:3.90),
  WilayaModel(code:11, name:'تمنراست',          soilType:'Sols minéraux bruts (Reg)',   lat:22.79, lon:5.52),
  WilayaModel(code:12, name:'تبسة',             soilType:'Sols bruns calcaires',        lat:35.40, lon:8.12),
  WilayaModel(code:13, name:'تلمسان',           soilType:'Sols bruns calcaires',        lat:34.88, lon:-1.32),
  WilayaModel(code:14, name:'تيارت',            soilType:'Sols bruns calcaires',        lat:35.37, lon:1.32),
  WilayaModel(code:15, name:'تيزي وزو',         soilType:'Sols peu évolués d\'érosion', lat:36.72, lon:4.05),
  WilayaModel(code:16, name:'الجزائر',          soilType:'Sols alluviaux',              lat:36.78, lon:3.06),
  WilayaModel(code:17, name:'الجلفة',           soilType:'Sols bruns calcaires',        lat:34.67, lon:3.25),
  WilayaModel(code:18, name:'جيجل',             soilType:'Sols bruns calcaires',        lat:36.82, lon:5.77),
  WilayaModel(code:19, name:'سطيف',             soilType:'Sols bruns calcaires',        lat:36.19, lon:5.41),
  WilayaModel(code:20, name:'سعيدة',            soilType:'Sols bruns calcaires',        lat:34.83, lon:0.15),
  WilayaModel(code:21, name:'سكيكدة',           soilType:'Sols bruns calcaires',        lat:36.87, lon:6.90),
  WilayaModel(code:22, name:'سيدي بلعباس',     soilType:'Sols bruns calcaires',        lat:35.19, lon:-0.64),
  WilayaModel(code:23, name:'عنابة',            soilType:'Sols alluviaux',              lat:36.90, lon:7.77),
  WilayaModel(code:24, name:'قالمة',            soilType:'Vertisols',                   lat:36.47, lon:7.43),
  WilayaModel(code:25, name:'قسنطينة',          soilType:'Vertisols',                   lat:36.37, lon:6.61),
  WilayaModel(code:26, name:'المدية',           soilType:'Sols bruns calcaires',        lat:36.27, lon:2.75),
  WilayaModel(code:27, name:'مستغانم',          soilType:'Sols bruns calcaires',        lat:35.93, lon:0.09),
  WilayaModel(code:28, name:'المسيلة',          soilType:'Sols bruns calcaires',        lat:35.71, lon:4.54),
  WilayaModel(code:29, name:'معسكر',            soilType:'Sols bruns calcaires',        lat:35.40, lon:0.13),
  WilayaModel(code:30, name:'ورقلة',            soilType:'Sols sableux (Erg)',          lat:31.95, lon:5.32),
  WilayaModel(code:31, name:'وهران',            soilType:'Sols bruns calcaires',        lat:35.70, lon:-0.63),
  WilayaModel(code:32, name:'البيض',            soilType:'Sols bruns calcaires',        lat:33.68, lon:1.02),
  WilayaModel(code:33, name:'إليزي',            soilType:'Sols minéraux bruts (Reg)',   lat:26.50, lon:8.42),
  WilayaModel(code:34, name:'برج بوعريريج',    soilType:'Sols bruns calcaires',        lat:36.07, lon:4.76),
  WilayaModel(code:35, name:'بومرداس',          soilType:'Sols bruns calcaires',        lat:36.76, lon:3.48),
  WilayaModel(code:36, name:'الطارف',           soilType:'Sols hydromorphes (Oasis)',   lat:36.77, lon:8.32),
  WilayaModel(code:37, name:'تندوف',            soilType:'Sols minéraux bruts (Reg)',   lat:27.67, lon:-8.13),
  WilayaModel(code:38, name:'تيسمسيلت',        soilType:'Sols bruns calcaires',        lat:35.60, lon:1.82),
  WilayaModel(code:39, name:'الوادي',           soilType:'Sols sableux (Erg)',          lat:33.37, lon:6.87),
  WilayaModel(code:40, name:'خنشلة',            soilType:'Sols bruns calcaires',        lat:35.43, lon:7.13),
  WilayaModel(code:41, name:'سوق أهراس',        soilType:'Sols bruns calcaires',        lat:36.28, lon:7.95),
  WilayaModel(code:42, name:'تيبازة',           soilType:'Sols alluviaux',              lat:36.59, lon:2.44),
  WilayaModel(code:43, name:'ميلة',             soilType:'Vertisols',                   lat:36.45, lon:6.27),
  WilayaModel(code:44, name:'عين الدفلى',       soilType:'Sols alluviaux',              lat:36.26, lon:1.97),
  WilayaModel(code:45, name:'النعامة',          soilType:'Sols bruns calcaires',        lat:33.27, lon:-0.32),
  WilayaModel(code:46, name:'عين تيموشنت',     soilType:'Sols bruns calcaires',        lat:35.30, lon:-1.13),
  WilayaModel(code:47, name:'غرداية',           soilType:'Sols hydromorphes (Oasis)',   lat:32.48, lon:3.67),
  WilayaModel(code:48, name:'غليزان',           soilType:'Sols bruns calcaires',        lat:35.74, lon:0.55),
  WilayaModel(code:49, name:'تيميمون',          soilType:'Sols sableux (Erg)',          lat:29.27, lon:0.23),
  WilayaModel(code:50, name:'برج باجي مختار',  soilType:'Sols minéraux bruts (Reg)',   lat:21.38, lon:0.95),
  WilayaModel(code:51, name:'أولاد جلال',       soilType:'Sols sableux (Erg)',          lat:34.43, lon:5.07),
  WilayaModel(code:52, name:'بني عباس',         soilType:'Sols sableux (Erg)',          lat:30.12, lon:-2.17),
  WilayaModel(code:53, name:'إن صالح',          soilType:'Sols minéraux bruts (Reg)',   lat:27.20, lon:2.48),
  WilayaModel(code:54, name:'إن قزام',          soilType:'Sols minéraux bruts (Reg)',   lat:19.57, lon:5.77),
  WilayaModel(code:55, name:'تقرت',             soilType:'Sols hydromorphes (Oasis)',   lat:33.10, lon:6.07),
  WilayaModel(code:56, name:'جانت',             soilType:'Sols minéraux bruts (Reg)',   lat:24.55, lon:9.48),
  WilayaModel(code:57, name:'المغير',           soilType:'Sols hydromorphes (Oasis)',   lat:33.95, lon:5.92),
  WilayaModel(code:58, name:'المنيعة',          soilType:'Sols sableux (Erg)',          lat:30.58, lon:2.88),
];

// ==================== SOIL DATABASE ====================
final Map<String, SoilModel> soilDb = {
  'Sols alluviaux': SoilModel(
    texture:'طمي رملي طيني - ممتاز', phMin:6.8, phMax:7.5,
    irrigation:'معتدل (500-700مم/سنة)', fertilisation:'كمبوست 20-30 ط/ه + NPK متوازن',
    N:85, P:45, K:180, Ca:2500, Mg:350, S:25, efficacite:0.80),
  'Sols bruns calcaires': SoilModel(
    texture:'طمي طيني - جيري', phMin:7.2, phMax:8.0,
    irrigation:'تكميلي (400-600مم/سنة)', fertilisation:'فوسفات طبيعي + تسميد أخضر',
    N:55, P:25, K:150, Ca:3500, Mg:250, S:18, efficacite:0.75),
  'Vertisols': SoilModel(
    texture:'طيني ثقيل (40-60% طين)', phMin:7.0, phMax:8.2,
    irrigation:'مُدارة (600-800مم/سنة)', fertilisation:'سماد عضوي 15-20 ط/ه',
    N:70, P:35, K:200, Ca:2800, Mg:400, S:30, efficacite:0.85),
  "Sols peu évolués d'érosion": SoilModel(
    texture:'حجري إلى طمي', phMin:6.5, phMax:7.5,
    irrigation:'مطري (400-600مم/سنة)', fertilisation:'كمبوست 10-15 ط/ه + تغطية',
    N:25, P:10, K:80, Ca:1500, Mg:120, S:8, efficacite:0.55),
  'Sols sableux (Erg)': SoilModel(
    texture:'رملي (85-95% رمل)', phMin:7.5, phMax:8.5,
    irrigation:'مكثف بالتقطير (800-1200مم/سنة)', fertilisation:'تسميد موضعي + مادة عضوية كثيرة',
    N:12, P:6, K:45, Ca:800, Mg:60, S:5, efficacite:0.50),
  'Sols minéraux bruts (Reg)': SoilModel(
    texture:'حجري مع رمل', phMin:7.5, phMax:8.8,
    irrigation:'هيدروبونيك أو تقطير على ركيزة', fertilisation:'محلول غذائي كامل',
    N:5, P:2, K:25, Ca:500, Mg:30, S:2, efficacite:0.40),
  'Sols hydromorphes (Oasis)': SoilModel(
    texture:'طمي رملي', phMin:7.2, phMax:8.0,
    irrigation:'غمر (1000-1500مم/سنة)', fertilisation:'سماد واحات 40-60 ط/ه',
    N:40, P:20, K:110, Ca:1800, Mg:200, S:15, efficacite:0.65),
};

// ==================== CROPS DATABASE ====================
final List<CropModel> allCrops = [
  CropModel(name:'قمح صلب', category:'حبوب', icon:'🌾', cycleDays:180, tempMin:12, tempMax:25, waterMm:450, stages:[
    CropStage(name:'الإنبات', days:15, N:25, P:40, K:30, Ca:10, Mg:5, S:5),
    CropStage(name:'التفريخ', days:55, N:70, P:35, K:55, Ca:15, Mg:8, S:8),
    CropStage(name:'الاستطالة', days:30, N:60, P:25, K:45, Ca:12, Mg:6, S:6),
    CropStage(name:'التسنبل والإزهار', days:40, N:45, P:20, K:50, Ca:10, Mg:5, S:5),
    CropStage(name:'النضج', days:40, N:10, P:15, K:20, Ca:5, Mg:3, S:3),
  ]),
  CropModel(name:'قمح لين', category:'حبوب', icon:'🌾', cycleDays:170, tempMin:10, tempMax:24, waterMm:420, stages:[
    CropStage(name:'الإنبات', days:14, N:22, P:38, K:28, Ca:10, Mg:5, S:5),
    CropStage(name:'التفريخ', days:50, N:65, P:32, K:50, Ca:14, Mg:7, S:7),
    CropStage(name:'الاستطالة', days:28, N:55, P:22, K:42, Ca:11, Mg:6, S:6),
    CropStage(name:'الإزهار', days:38, N:40, P:18, K:45, Ca:9, Mg:4, S:4),
    CropStage(name:'النضج', days:40, N:8, P:12, K:18, Ca:4, Mg:3, S:3),
  ]),
  CropModel(name:'شعير', category:'حبوب', icon:'🌾', cycleDays:150, tempMin:10, tempMax:28, waterMm:380, stages:[
    CropStage(name:'الإنبات', days:12, N:20, P:35, K:25, Ca:8, Mg:4, S:4),
    CropStage(name:'التفريخ', days:45, N:55, P:28, K:42, Ca:12, Mg:6, S:6),
    CropStage(name:'الاستطالة', days:25, N:48, P:20, K:38, Ca:10, Mg:5, S:5),
    CropStage(name:'التسنبل', days:35, N:35, P:15, K:40, Ca:8, Mg:4, S:4),
    CropStage(name:'النضج', days:33, N:5, P:10, K:14, Ca:4, Mg:2, S:2),
  ]),
  CropModel(name:'ذرة', category:'حبوب', icon:'🌽', cycleDays:130, tempMin:18, tempMax:32, waterMm:550, stages:[
    CropStage(name:'الإنبات', days:10, N:30, P:45, K:28, Ca:12, Mg:7, S:6),
    CropStage(name:'النمو الخضري', days:40, N:75, P:32, K:48, Ca:22, Mg:14, S:11),
    CropStage(name:'الإزهار', days:25, N:50, P:40, K:68, Ca:28, Mg:17, S:14),
    CropStage(name:'النضج', days:55, N:18, P:18, K:38, Ca:18, Mg:9, S:7),
  ]),
  CropModel(name:'طماطم', category:'خضروات', icon:'🍅', cycleDays:120, tempMin:18, tempMax:30, waterMm:600, stages:[
    CropStage(name:'الشتلات', days:25, N:30, P:50, K:40, Ca:20, Mg:10, S:8),
    CropStage(name:'النمو الخضري', days:35, N:65, P:35, K:55, Ca:30, Mg:14, S:12),
    CropStage(name:'الإزهار', days:20, N:40, P:55, K:75, Ca:38, Mg:19, S:16),
    CropStage(name:'الإثمار', days:40, N:35, P:32, K:70, Ca:32, Mg:16, S:11),
  ]),
  CropModel(name:'بطاطس', category:'خضروات', icon:'🥔', cycleDays:100, tempMin:14, tempMax:24, waterMm:500, stages:[
    CropStage(name:'الإنبات', days:20, N:25, P:45, K:40, Ca:18, Mg:9, S:8),
    CropStage(name:'النمو الخضري', days:30, N:52, P:28, K:48, Ca:28, Mg:14, S:11),
    CropStage(name:'تكوين الدرنات', days:30, N:32, P:33, K:68, Ca:24, Mg:19, S:14),
    CropStage(name:'النضج', days:20, N:8, P:13, K:22, Ca:13, Mg:9, S:5),
  ]),
  CropModel(name:'بصل', category:'خضروات', icon:'🧅', cycleDays:150, tempMin:12, tempMax:26, waterMm:420, stages:[
    CropStage(name:'الإنبات', days:15, N:30, P:50, K:30, Ca:10, Mg:5, S:8),
    CropStage(name:'النمو الخضري', days:60, N:60, P:40, K:50, Ca:20, Mg:10, S:15),
    CropStage(name:'تكوين البصلة', days:50, N:30, P:50, K:80, Ca:25, Mg:15, S:20),
    CropStage(name:'النضج', days:25, N:0, P:20, K:40, Ca:15, Mg:8, S:10),
  ]),
  CropModel(name:'ثوم', category:'خضروات', icon:'🧄', cycleDays:180, tempMin:10, tempMax:24, waterMm:380, stages:[
    CropStage(name:'الإنبات', days:20, N:25, P:45, K:30, Ca:12, Mg:6, S:10),
    CropStage(name:'النمو الخضري', days:80, N:55, P:35, K:45, Ca:18, Mg:10, S:18),
    CropStage(name:'تكوين الفصوص', days:50, N:25, P:45, K:70, Ca:22, Mg:13, S:22),
    CropStage(name:'النضج', days:30, N:0, P:15, K:30, Ca:10, Mg:6, S:8),
  ]),
  CropModel(name:'جزر', category:'خضروات', icon:'🥕', cycleDays:90, tempMin:12, tempMax:24, waterMm:350, stages:[
    CropStage(name:'الإنبات', days:15, N:20, P:40, K:25, Ca:10, Mg:5, S:5),
    CropStage(name:'النمو الخضري', days:35, N:45, P:28, K:42, Ca:18, Mg:9, S:8),
    CropStage(name:'تكوين الجذر', days:30, N:18, P:30, K:60, Ca:20, Mg:12, S:10),
    CropStage(name:'النضج', days:10, N:5, P:10, K:20, Ca:8, Mg:5, S:4),
  ]),
  CropModel(name:'فلفل', category:'خضروات', icon:'🫑', cycleDays:120, tempMin:18, tempMax:32, waterMm:520, stages:[
    CropStage(name:'الشتلات', days:25, N:28, P:48, K:38, Ca:18, Mg:9, S:7),
    CropStage(name:'النمو الخضري', days:35, N:60, P:32, K:52, Ca:28, Mg:13, S:11),
    CropStage(name:'الإزهار', days:25, N:38, P:52, K:72, Ca:35, Mg:18, S:15),
    CropStage(name:'الإثمار', days:35, N:32, P:30, K:65, Ca:30, Mg:15, S:10),
  ]),
  CropModel(name:'باذنجان', category:'خضروات', icon:'🍆', cycleDays:130, tempMin:20, tempMax:32, waterMm:500, stages:[
    CropStage(name:'الشتلات', days:25, N:25, P:45, K:35, Ca:16, Mg:8, S:6),
    CropStage(name:'النمو الخضري', days:40, N:58, P:30, K:50, Ca:26, Mg:12, S:10),
    CropStage(name:'الإزهار', days:30, N:35, P:50, K:68, Ca:32, Mg:17, S:14),
    CropStage(name:'الإثمار', days:35, N:30, P:28, K:62, Ca:28, Mg:14, S:9),
  ]),
  CropModel(name:'بطيخ أحمر', category:'خضروات', icon:'🍉', cycleDays:90, tempMin:22, tempMax:36, waterMm:550, stages:[
    CropStage(name:'الإنبات', days:12, N:22, P:42, K:30, Ca:12, Mg:6, S:5),
    CropStage(name:'النمو الخضري', days:28, N:55, P:28, K:45, Ca:22, Mg:11, S:9),
    CropStage(name:'الإزهار والعقد', days:20, N:35, P:45, K:65, Ca:30, Mg:16, S:13),
    CropStage(name:'نضج الثمار', days:30, N:15, P:25, K:55, Ca:22, Mg:12, S:8),
  ]),
  CropModel(name:'شمام', category:'خضروات', icon:'🍈', cycleDays:85, tempMin:20, tempMax:34, waterMm:500, stages:[
    CropStage(name:'الإنبات', days:10, N:20, P:40, K:28, Ca:10, Mg:5, S:4),
    CropStage(name:'النمو الخضري', days:28, N:50, P:26, K:42, Ca:20, Mg:10, S:8),
    CropStage(name:'الإزهار والعقد', days:20, N:32, P:42, K:62, Ca:28, Mg:15, S:12),
    CropStage(name:'نضج الثمار', days:27, N:12, P:22, K:50, Ca:20, Mg:10, S:7),
  ]),
  CropModel(name:'حمص', category:'بقوليات', icon:'🫘', cycleDays:100, tempMin:10, tempMax:28, waterMm:300, stages:[
    CropStage(name:'الإنبات', days:15, N:15, P:40, K:25, Ca:12, Mg:5, S:5),
    CropStage(name:'النمو الخضري', days:40, N:30, P:28, K:38, Ca:20, Mg:8, S:7),
    CropStage(name:'الإزهار والتعقد', days:25, N:20, P:38, K:55, Ca:28, Mg:12, S:10),
    CropStage(name:'النضج', days:20, N:5, P:15, K:25, Ca:15, Mg:7, S:5),
  ]),
  CropModel(name:'عدس', category:'بقوليات', icon:'🫘', cycleDays:110, tempMin:10, tempMax:26, waterMm:280, stages:[
    CropStage(name:'الإنبات', days:14, N:12, P:38, K:22, Ca:10, Mg:4, S:4),
    CropStage(name:'النمو الخضري', days:45, N:28, P:26, K:35, Ca:18, Mg:7, S:6),
    CropStage(name:'الإزهار', days:28, N:18, P:35, K:52, Ca:25, Mg:11, S:9),
    CropStage(name:'النضج', days:23, N:4, P:12, K:22, Ca:13, Mg:6, S:4),
  ]),
  CropModel(name:'فول', category:'بقوليات', icon:'🫘', cycleDays:130, tempMin:8, tempMax:25, waterMm:350, stages:[
    CropStage(name:'الإنبات', days:18, N:18, P:42, K:28, Ca:14, Mg:6, S:6),
    CropStage(name:'النمو الخضري', days:52, N:35, P:30, K:42, Ca:22, Mg:9, S:8),
    CropStage(name:'الإزهار', days:32, N:22, P:40, K:58, Ca:30, Mg:13, S:11),
    CropStage(name:'النضج', days:28, N:5, P:14, K:25, Ca:16, Mg:7, S:5),
  ]),
  CropModel(name:'نخيل التمر', category:'أشجار مثمرة', icon:'🌴', cycleDays:365, tempMin:20, tempMax:45, waterMm:900, stages:[
    CropStage(name:'النمو الخضري', days:180, N:95, P:75, K:115, Ca:38, Mg:24, S:19),
    CropStage(name:'الإزهار', days:60, N:58, P:95, K:145, Ca:48, Mg:29, S:24),
    CropStage(name:'نمو الثمار', days:90, N:38, P:58, K:175, Ca:43, Mg:33, S:28),
    CropStage(name:'النضج', days:35, N:18, P:28, K:96, Ca:28, Mg:19, S:14),
  ]),
  CropModel(name:'زيتون', category:'أشجار مثمرة', icon:'🫒', cycleDays:365, tempMin:10, tempMax:38, waterMm:600, stages:[
    CropStage(name:'النمو الخضري', days:150, N:48, P:38, K:48, Ca:28, Mg:14, S:9),
    CropStage(name:'الإزهار', days:30, N:28, P:48, K:58, Ca:33, Mg:19, S:11),
    CropStage(name:'العقد', days:60, N:18, P:38, K:68, Ca:38, Mg:21, S:14),
    CropStage(name:'النضج', days:125, N:9, P:18, K:38, Ca:23, Mg:11, S:7),
  ]),
  CropModel(name:'تفاح', category:'أشجار مثمرة', icon:'🍎', cycleDays:365, tempMin:5, tempMax:28, waterMm:700, stages:[
    CropStage(name:'السكون الشتوي', days:90, N:20, P:30, K:40, Ca:25, Mg:12, S:8),
    CropStage(name:'النمو الخضري', days:90, N:60, P:45, K:65, Ca:40, Mg:18, S:12),
    CropStage(name:'الإزهار والعقد', days:60, N:35, P:55, K:80, Ca:50, Mg:22, S:15),
    CropStage(name:'نضج الثمار', days:125, N:15, P:25, K:55, Ca:35, Mg:15, S:9),
  ]),
  CropModel(name:'عنب', category:'أشجار مثمرة', icon:'🍇', cycleDays:180, tempMin:12, tempMax:36, waterMm:600, stages:[
    CropStage(name:'التفتح', days:30, N:25, P:35, K:40, Ca:20, Mg:10, S:8),
    CropStage(name:'النمو الخضري', days:60, N:60, P:40, K:55, Ca:30, Mg:15, S:12),
    CropStage(name:'الإزهار والعقد', days:30, N:30, P:50, K:75, Ca:40, Mg:20, S:15),
    CropStage(name:'نضج العنب', days:60, N:10, P:25, K:60, Ca:28, Mg:15, S:8),
  ]),
  CropModel(name:'رمان', category:'أشجار مثمرة', icon:'🍎', cycleDays:365, tempMin:15, tempMax:38, waterMm:550, stages:[
    CropStage(name:'النمو الخضري', days:150, N:45, P:35, K:50, Ca:30, Mg:15, S:10),
    CropStage(name:'الإزهار', days:45, N:28, P:45, K:62, Ca:38, Mg:20, S:13),
    CropStage(name:'نمو الثمار', days:120, N:20, P:30, K:75, Ca:42, Mg:22, S:15),
    CropStage(name:'النضج', days:50, N:8, P:18, K:42, Ca:28, Mg:13, S:8),
  ]),
  CropModel(name:'نعناع', category:'أعشاب عطرية', icon:'🌿', cycleDays:60, tempMin:12, tempMax:26, waterMm:300, stages:[
    CropStage(name:'الإنبات', days:12, N:18, P:30, K:22, Ca:8, Mg:4, S:5),
    CropStage(name:'النمو الخضري', days:30, N:42, P:22, K:35, Ca:15, Mg:8, S:10),
    CropStage(name:'النضج', days:18, N:12, P:15, K:28, Ca:10, Mg:5, S:7),
  ]),
  CropModel(name:'إكليل الجبل', category:'أعشاب عطرية', icon:'🌿', cycleDays:90, tempMin:10, tempMax:28, waterMm:250, stages:[
    CropStage(name:'الإنبات', days:20, N:12, P:25, K:18, Ca:8, Mg:4, S:4),
    CropStage(name:'النمو', days:45, N:30, P:18, K:28, Ca:12, Mg:6, S:7),
    CropStage(name:'النضج', days:25, N:8, P:12, K:22, Ca:8, Mg:4, S:5),
  ]),
  CropModel(name:'زعتر', category:'أعشاب عطرية', icon:'🌿', cycleDays:90, tempMin:10, tempMax:28, waterMm:220, stages:[
    CropStage(name:'الإنبات', days:18, N:10, P:22, K:16, Ca:6, Mg:3, S:3),
    CropStage(name:'النمو', days:48, N:28, P:16, K:26, Ca:10, Mg:5, S:6),
    CropStage(name:'النضج', days:24, N:6, P:10, K:20, Ca:7, Mg:3, S:4),
  ]),
  CropModel(name:'برسيم', category:'أعلاف', icon:'🌿', cycleDays:365, tempMin:10, tempMax:30, waterMm:800, stages:[
    CropStage(name:'الإنبات', days:15, N:20, P:35, K:25, Ca:15, Mg:7, S:6),
    CropStage(name:'النمو الخضري', days:180, N:50, P:28, K:42, Ca:30, Mg:15, S:12),
    CropStage(name:'الإزهار والقطع', days:120, N:30, P:20, K:35, Ca:22, Mg:10, S:8),
    CropStage(name:'الراحة', days:50, N:10, P:10, K:18, Ca:10, Mg:5, S:4),
  ]),
  CropModel(name:'عباد الشمس', category:'محاصيل صناعية', icon:'🌻', cycleDays:120, tempMin:18, tempMax:32, waterMm:450, stages:[
    CropStage(name:'الإنبات', days:12, N:22, P:38, K:28, Ca:10, Mg:6, S:6),
    CropStage(name:'النمو الخضري', days:45, N:60, P:30, K:48, Ca:20, Mg:12, S:10),
    CropStage(name:'الإزهار', days:28, N:35, P:42, K:65, Ca:28, Mg:16, S:13),
    CropStage(name:'نضج البذور', days:35, N:12, P:22, K:40, Ca:18, Mg:10, S:7),
  ]),
  CropModel(name:'بنجر السكر', category:'محاصيل صناعية', icon:'🌱', cycleDays:180, tempMin:12, tempMax:26, waterMm:550, stages:[
    CropStage(name:'الإنبات', days:20, N:25, P:42, K:35, Ca:15, Mg:7, S:7),
    CropStage(name:'النمو الخضري', days:70, N:65, P:32, K:55, Ca:25, Mg:13, S:11),
    CropStage(name:'تراكم السكر', days:60, N:20, P:38, K:80, Ca:30, Mg:17, S:14),
    CropStage(name:'النضج', days:30, N:5, P:18, K:42, Ca:18, Mg:9, S:6),
  ]),
];

// ==================== ANIMATED WIDGETS ====================

/// Shimmer-loading animation placeholder
class ShimmerBox extends StatefulWidget {
  final double width, height, radius;
  const ShimmerBox({super.key, this.width = double.infinity, this.height = 48, this.radius = 12});
  @override State<ShimmerBox> createState() => _ShimmerBoxState();
}
class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _anim = Tween<double>(begin: -1, end: 2).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width, height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0), end: Alignment(_anim.value, 0),
            colors: [const Color(0xFFE8EFD8), const Color(0xFFF5FAF0), const Color(0xFFE8EFD8)],
          ),
        ),
      ),
    );
  }
}

/// Fade + slide up animation wrapper
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const FadeSlideIn({super.key, required this.child, this.delay = Duration.zero});
  @override State<FadeSlideIn> createState() => _FadeSlideInState();
}
class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
      .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(widget.delay, () { if (mounted) _ctrl.forward(); });
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => SlideTransition(
    position: _slide, child: FadeTransition(opacity: _fade, child: widget.child));
}

/// Animated progress bar
class AnimatedProgressBar extends StatefulWidget {
  final double value;
  final Color color;
  final double height;
  const AnimatedProgressBar({super.key, required this.value, required this.color, this.height = 8});
  @override State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}
class _AnimatedProgressBarState extends State<AnimatedProgressBar> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = Tween<double>(begin: 0, end: widget.value).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 300), () { if (mounted) _ctrl.forward(); });
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => LayoutBuilder(builder: (ctx, c) => Stack(children: [
      Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(widget.height),
        ),
      ),
      Container(
        height: widget.height,
        width: c.maxWidth * _anim.value.clamp(0.0, 1.0),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(widget.height),
        ),
      ),
    ])),
  );
}

/// Animated counter text
class AnimatedCounter extends StatefulWidget {
  final double value;
  final String suffix;
  final TextStyle style;
  const AnimatedCounter({super.key, required this.value, this.suffix = '', required this.style});
  @override State<AnimatedCounter> createState() => _AnimatedCounterState();
}
class _AnimatedCounterState extends State<AnimatedCounter> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _anim = Tween<double>(begin: 0, end: widget.value)
      .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutExpo));
    Future.delayed(const Duration(milliseconds: 200), () { if (mounted) _ctrl.forward(); });
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Text(
      '${_anim.value.toStringAsFixed(1)}${widget.suffix}',
      style: widget.style,
    ),
  );
}

// ==================== MAIN SCREEN ====================
class FertilizationScreen extends StatefulWidget {
  const FertilizationScreen({super.key});
  @override State<FertilizationScreen> createState() => _FertilizationScreenState();
}

class _FertilizationScreenState extends State<FertilizationScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentTab = 0;
  bool _isLoading = false;
  String _loadingMsg = '🤖 الذكاء الاصطناعي يحلل...';
  bool _isDark = false;

  // Form
  WilayaModel? _selectedWilaya;
  CropModel? _selectedCrop;
  final _areaCtrl = TextEditingController();
  final _phCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  DateTime _plantDate = DateTime.now().subtract(const Duration(days: 30));
  String _prevCrop = '';
  String _irrigation = 'ري_تقطير';
  String _season = 'خريف';
  List<WilayaModel> _filteredWilayas = allWilayas;

  // Results
  AnalysisResult? _result;
  List<AnalysisResult> _savedRecords = [];
  Map<String, dynamic>? _weatherData;

  // Animation controllers
  late AnimationController _fabCtrl;
  late Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTab = _tabController.index;
        if (_currentTab == 2) _loadRecords();
      });
    });
    _fabCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fabScale = CurvedAnimation(parent: _fabCtrl, curve: Curves.elasticOut);
    _loadRecords();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _areaCtrl.dispose();
    _phCtrl.dispose();
    _searchCtrl.dispose();
    _fabCtrl.dispose();
    super.dispose();
  }

  // ==================== LOGIC ====================
  void _filterWilayas(String query) {
    setState(() {
      _filteredWilayas = allWilayas.where((w) =>
        w.name.contains(query) || w.code.toString().contains(query)
      ).toList();
    });
  }

  Future<void> _fetchWeather(WilayaModel wilaya) async {
    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=${wilaya.lat}&longitude=${wilaya.lon}'
        '&current_weather=true&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,'
        'relative_humidity_2m_mean&timezone=Africa/Algiers&forecast_days=3'
      );
      final res = await http.get(url).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final d = json.decode(res.body);
        setState(() {
          _weatherData = {
            'temp': (d['current_weather']['temperature'] as num?)?.round() ?? 22,
            'tempMax': (d['daily']['temperature_2m_max'][0] as num?)?.round() ?? 28,
            'tempMin': (d['daily']['temperature_2m_min'][0] as num?)?.round() ?? 12,
            'rain': (d['daily']['precipitation_sum'][0] as num?)?.toDouble() ?? 0.0,
            'humidity': (d['daily']['relative_humidity_2m_mean'][0] as num?)?.round() ?? 55,
          };
        });
      }
    } catch (_) {}
  }

  void _calculate() async {
    if (_selectedWilaya == null) { _snack('⚠️ اختر الولاية أولاً'); return; }
    if (_selectedCrop == null)   { _snack('⚠️ اختر المحصول أولاً'); return; }
    final areaText = _areaCtrl.text.trim();
    if (areaText.isEmpty) { _snack('⚠️ أدخل مساحة الحقل'); return; }
    final area = double.tryParse(areaText);
    if (area == null || area <= 0) { _snack('⚠️ أدخل مساحة صحيحة (رقم موجب)'); return; }

    setState(() { _isLoading = true; _loadingMsg = '🌍 جاري تحليل التربة والمناخ...'; });
    await Future.delayed(const Duration(milliseconds: 700));

    setState(() => _loadingMsg = '🧬 حساب الاحتياجات الغذائية...');
    await Future.delayed(const Duration(milliseconds: 600));

    setState(() => _loadingMsg = '🤖 الذكاء الاصطناعي يولّد التوصيات...');
    await Future.delayed(const Duration(milliseconds: 600));

    final soil = soilDb[_selectedWilaya!.soilType]!;
    final crop = _selectedCrop!;

    final daysElapsed = DateTime.now().difference(_plantDate).inDays.clamp(0, crop.cycleDays);
    int daysCum = 0;
    CropStage? curStage;
    for (int i = 0; i < crop.stages.length; i++) {
      final s = crop.stages[i];
      if (daysElapsed < daysCum + s.days) { curStage = s; break; }
      daysCum += s.days;
    }
    curStage ??= crop.stages.last;
    final daysInStage = (daysElapsed - daysCum).clamp(0, curStage.days);
    final progress = (daysInStage / curStage.days * 100).clamp(0.0, 100.0);
    final remaining = (curStage.days - daysInStage).clamp(0, curStage.days);

    double phFactor = 1.0;
    final userPh = double.tryParse(_phCtrl.text.trim());
    if (userPh != null) {
      if (userPh > soil.phMax + 0.5) phFactor = 1.2;
      else if (userPh < soil.phMin - 0.5) phFactor = 0.9;
    }

    double weatherFactor = 1.0;
    if (_weatherData != null) {
      final temp = _weatherData!['temp'] as int;
      final rain = _weatherData!['rain'] as double;
      if (temp > 35) weatherFactor *= 1.12;
      else if (temp > 30) weatherFactor *= 1.06;
      if (rain > 20) weatherFactor *= 1.15;
      else if (rain > 10) weatherFactor *= 1.08;
    }

    double nBonus = 0;
    if (['حمص','عدس','فول','برسيم'].contains(_prevCrop)) nBonus = 15;

    Map<String, Map<String, dynamic>> nutrients = {};
    double totalKgHa = 0;
    for (final entry in {
      'N': {'need': curStage.N.toDouble(), 'avail': soil.N.toDouble() - nBonus},
      'P': {'need': curStage.P.toDouble(), 'avail': soil.P.toDouble()},
      'K': {'need': curStage.K.toDouble(), 'avail': soil.K.toDouble()},
      'Ca': {'need': curStage.Ca.toDouble(), 'avail': soil.Ca.toDouble() / 100},
      'Mg': {'need': curStage.Mg.toDouble(), 'avail': soil.Mg.toDouble() / 10},
      'S':  {'need': curStage.S.toDouble(), 'avail': soil.S.toDouble()},
    }.entries) {
      final need = entry.value['need']! * phFactor * weatherFactor;
      final avail = (entry.value['avail']! * soil.efficacite).clamp(0.0, double.infinity);
      final deficit = (need - avail).clamp(0.0, need);
      final required = deficit > 0 ? deficit / soil.efficacite : 0.0;
      totalKgHa += required;
      nutrients[entry.key] = {
        'need': need, 'avail': avail, 'deficit': deficit, 'required': required, 'ok': deficit <= 3,
      };
    }

    List<FertilizerRec> ferts = [];
    final nDef = nutrients['N']!['deficit'] as double;
    final pDef = nutrients['P']!['deficit'] as double;
    final kDef = nutrients['K']!['deficit'] as double;
    final caDef = nutrients['Ca']!['deficit'] as double;
    final mgDef = nutrients['Mg']!['deficit'] as double;

    if (nDef > 5) ferts.add(FertilizerRec(name:'يوريا (46% N)', icon:'🧪', kgHa:(nDef/0.46).roundToDouble(),
      how:'ينثر على السطح ثم يُروى فوراً أو يُخلط بالتربة', when:'مطلع المرحلة الحالية - صباحاً أو مساءً'));
    if (pDef > 4) ferts.add(FertilizerRec(name:'سوبر فوسفات ثلاثي (46% P₂O₅)', icon:'⚪', kgHa:(pDef/0.46).roundToDouble(),
      how:'يُخلط مع التربة قبل الزراعة أو عند الحرثة', when:'قبل الزراعة أو بداية الموسم'));
    if (kDef > 5) ferts.add(FertilizerRec(name:'سلفات البوتاسيوم (50% K₂O)', icon:'🧂', kgHa:(kDef/0.50).roundToDouble(),
      how:'يُذاب في ماء الري أو ينثر ويُروى', when:'خلال مرحلة الإزهار أو تكوين الثمار'));
    if (caDef > 3) ferts.add(FertilizerRec(name:'نترات الكالسيوم (19% Ca)', icon:'🔬', kgHa:(caDef/0.19).roundToDouble(),
      how:'رش ورقي أو إضافة للري التقطيري', when:'خلال مراحل النمو السريع'));
    if (mgDef > 3) ferts.add(FertilizerRec(name:'سلفات المغنيسيوم (16% Mg)', icon:'💎', kgHa:(mgDef/0.16).roundToDouble(),
      how:'رش ورقي بتركيز 1-2% أو ري تقطيري', when:'عند ظهور علامات الإصفرار البيني'));
    if (ferts.isEmpty) ferts.add(FertilizerRec(name:'سماد عضوي كمبوست', icon:'🌿', kgHa:200,
      how:'يُنثر بالتساوي على السطح ويُحرث', when:'قبل الزراعة أو مطلع الموسم'));

    List<String> alerts = [], warnings = [];
    if (totalKgHa < 20) alerts.add('⚠️ كمية السماد منخفضة جداً — قد يؤثر على الإنتاج');
    if (_irrigation == 'بعلية' && crop.waterMm > 500)
      alerts.add('🌧️ المحصول يحتاج ري إضافي — لا يكفي المطر وحده');
    if (_weatherData != null) {
      final temp = _weatherData!['temp'] as int;
      if (temp > crop.tempMax) alerts.add('🌡️ درجة الحرارة ${temp}°C تتجاوز الحد الأقصى للمحصول (${crop.tempMax}°C)');
      else if (temp < crop.tempMin) alerts.add('❄️ درجة الحرارة ${temp}°C أقل من الحد الأدنى للمحصول (${crop.tempMin}°C)');
    }
    if (nBonus > 0) warnings.add('✅ المحصول السابق (${_prevCrop}) أضاف نيتروجين للتربة — خُفِّضت جرعة N');
    if (soil.phMin > 7.5) warnings.add('⚠️ تربة قلوية — قد يقل امتصاص الحديد والزنك');

    final irrFactor = _irrigation == 'ري_تقطير' ? 0.7 : (_irrigation == 'ري_كامل' ? 1.0 : 1.3);
    final daily = crop.waterMm / crop.cycleDays * irrFactor;

    final result = AnalysisResult(
      wilayaName: _selectedWilaya!.name, area: area, cropName: crop.name,
      soilType: _selectedWilaya!.soilType, stageName: curStage.name,
      stageProgress: progress, daysElapsed: daysElapsed, totalDays: crop.cycleDays,
      daysRemaining: remaining, totalKgHa: totalKgHa, nutrients: nutrients,
      fertilizers: ferts, alerts: alerts, warnings: warnings,
      plantDate: DateFormat('yyyy-MM-dd').format(_plantDate),
      analysisDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      weather: _weatherData,
      irrigation: {
        'type': _irrigation, 'daily': daily.toStringAsFixed(1),
        'freq': _irrigation == 'ري_تقطير' ? 'يومياً أو كل يومين' :
                _irrigation == 'ري_كامل' ? 'كل 2-4 أيام' : 'أسبوعياً أو حسب الأمطار',
      },
    );

    setState(() {
      _result = result;
      _isLoading = false;
      _currentTab = 1;
      _tabController.animateTo(1);
    });
    _fabCtrl.forward(from: 0);
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
      backgroundColor: AppColors.primaryDark,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));

  Future<void> _loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('agri_records_v3');
    if (raw != null) {
      final list = json.decode(raw) as List;
      setState(() => _savedRecords = list.map((e) => _resultFromJson(e)).toList());
    }
  }

  AnalysisResult _resultFromJson(Map<String, dynamic> j) => AnalysisResult(
    wilayaName: j['wilayaName'] ?? '', area: (j['area'] as num?)?.toDouble() ?? 0,
    cropName: j['cropName'] ?? '', soilType: j['soilType'] ?? 'Sols bruns calcaires',
    stageName: j['stageName'] ?? '', stageProgress: (j['stageProgress'] as num?)?.toDouble() ?? 0,
    daysElapsed: j['daysElapsed'] ?? 0, totalDays: j['totalDays'] ?? 0, daysRemaining: j['daysRemaining'] ?? 0,
    totalKgHa: (j['totalKgHa'] as num?)?.toDouble() ?? 0,
    nutrients: (j['nutrients'] as Map?)?.map((k, v) => MapEntry(k.toString(), Map<String, dynamic>.from(v))) ?? {},
    fertilizers: (j['fertilizers'] as List?)?.map((f) => FertilizerRec(
      name: f['name'] ?? '', icon: f['icon'] ?? '🌿',
      kgHa: (f['kgHa'] as num?)?.toDouble() ?? 0, how: f['how'] ?? '', when: f['when'] ?? '',
    )).toList() ?? [],
    alerts: List<String>.from(j['alerts'] ?? []), warnings: List<String>.from(j['warnings'] ?? []),
    plantDate: j['plantDate'] ?? '', analysisDate: j['analysisDate'] ?? '',
    weather: j['weather'] != null ? Map<String, dynamic>.from(j['weather']) : null,
    irrigation: Map<String, dynamic>.from(j['irrigation'] ?? {}),
  );

  Future<void> _saveRecord() async {
    if (_result == null) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('agri_records_v3');
    final records = raw != null ? json.decode(raw) as List : [];
    records.insert(0, _result!.toJson());
    if (records.length > 50) records.removeRange(50, records.length);
    await prefs.setString('agri_records_v3', json.encode(records));
    _loadRecords();
    _snack('✅ تم حفظ الخطة بنجاح');
  }

  Future<void> _deleteRecord(int idx) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('agri_records_v3');
    if (raw != null) {
      final records = json.decode(raw) as List;
      records.removeAt(idx);
      await prefs.setString('agri_records_v3', json.encode(records));
      _loadRecords();
    }
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    final isDark = _isDark;
    return Theme(
      data: isDark ? buildDarkTheme() : buildLightTheme(),
      child: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Scaffold(
          backgroundColor: isDark ? AppColors.darkBg : AppColors.backgroundSoft,
          appBar: _buildAppBar(isDark),
          body: Stack(children: [
            IndexedStack(index: _currentTab, children: [
              _buildFormTab(isDark),
              _buildResultTab(isDark),
              _buildRecordsTab(isDark),
            ]),
            if (_isLoading) _buildLoadingOverlay(isDark),
          ]),
          floatingActionButton: _currentTab == 1 && _result != null
            ? ScaleTransition(
                scale: _fabScale,
                child: FloatingActionButton.extended(
                  onPressed: _saveRecord,
                  backgroundColor: AppColors.primary,
                  elevation: 8,
                  icon: const Icon(Icons.bookmark_add_rounded, color: Colors.white),
                  label: const Text('حفظ الخطة',
                    style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              )
            : null,
        ),
      ),
    );
  }

  // ==================== APP BAR ====================
  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.primaryDark,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      title: Row(children: [
        // Logo badge
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: Text('🌾', style: TextStyle(fontSize: 20))),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('نظام التسميد الذكي',
            style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white,
              fontFamily: 'Cairo', letterSpacing: -0.3,
            )),
          Text('AI Fertilization System',
            style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5), letterSpacing: 0.5)),
        ]),
        const Spacer(),
        // Dark mode toggle
        GestureDetector(
          onTap: () => setState(() => _isDark = !_isDark),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(children: [
              Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, size: 16, color: Colors.white70),
              const SizedBox(width: 4),
              Text(isDark ? 'فاتح' : 'داكن',
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.white70)),
            ]),
          ),
        ),
      ]),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: Container(
          color: isDark ? AppColors.darkSurface : AppColors.primaryDark,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(11),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(3),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.45),
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, fontFamily: 'Cairo'),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: '📋 النموذج'),
                Tab(text: '📊 النتائج'),
                Tab(text: '📁 السجل'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== LOADING OVERLAY ====================
  Widget _buildLoadingOverlay(bool isDark) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(40),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Animated leaves ring
            SizedBox(
              width: 72, height: 72,
              child: _LoadingRing(),
            ),
            const SizedBox(height: 20),
            Text(_loadingMsg,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 14,
                color: isDark ? AppColors.darkText : AppColors.textDark,
              )),
            const SizedBox(height: 8),
            Text('يُرجى الانتظار...',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: isDark ? AppColors.darkTextMuted : AppColors.textMuted)),
          ]),
        ),
      ),
    );
  }

  // ==================== FORM TAB ====================
  Widget _buildFormTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      child: Column(children: [

        // === SECTION 1: LOCATION ===
        FadeSlideIn(
          delay: const Duration(milliseconds: 50),
          child: _buildSectionCard(
            isDark: isDark,
            icon: '📍',
            title: 'الولاية والموقع',
            child: Column(children: [
              // Search
              _buildTextField(
                controller: _searchCtrl,
                hint: 'ابحث عن ولاية بالاسم أو الرقم...',
                icon: Icons.search_rounded,
                isDark: isDark,
                onChanged: _filterWilayas,
              ),
              const SizedBox(height: 12),
              // Wilaya list
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBg : AppColors.backgroundSoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.accent.withOpacity(0.6)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ListView.builder(
                    itemCount: _filteredWilayas.length,
                    itemBuilder: (ctx, i) {
                      final w = _filteredWilayas[i];
                      final selected = _selectedWilaya?.code == w.code;
                      return _buildWilayaItem(w, selected, isDark);
                    },
                  ),
                ),
              ),
              // Weather
              if (_weatherData != null && _selectedWilaya != null) ...[
                const SizedBox(height: 12),
                _buildWeatherCard(isDark),
              ],
              // Soil preview
              if (_selectedWilaya != null) ...[
                const SizedBox(height: 12),
                _buildSoilPreview(isDark),
              ],
            ]),
          ),
        ),
        const SizedBox(height: 14),

        // === SECTION 2: FIELD INFO ===
        FadeSlideIn(
          delay: const Duration(milliseconds: 100),
          child: _buildSectionCard(
            isDark: isDark,
            icon: '🏡',
            title: 'معلومات الحقل',
            child: Column(children: [
              // Area + pH
              Row(children: [
                Expanded(child: _buildTextField(
                  controller: _areaCtrl,
                  hint: 'المساحة (هكتار)',
                  icon: Icons.crop_square_rounded,
                  isDark: isDark,
                  keyboardType: TextInputType.number,
                )),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField(
                  controller: _phCtrl,
                  hint: 'درجة pH (اختياري)',
                  icon: Icons.science_rounded,
                  isDark: isDark,
                  keyboardType: TextInputType.number,
                )),
              ]),
              const SizedBox(height: 16),
              // Previous crop
              _buildDropdown(
                label: 'المحصول السابق',
                value: _prevCrop.isEmpty ? null : _prevCrop,
                icon: Icons.history_rounded,
                items: ['', 'حمص', 'عدس', 'فول', 'برسيم', 'قمح صلب', 'شعير', 'ذرة', 'طماطم', 'بطاطس', 'بصل', 'ثوم', 'بطيخ أحمر', 'عباد الشمس', 'أرض بور'],
                onChanged: (v) => setState(() => _prevCrop = v ?? ''),
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              // Irrigation
              _buildLabel('💧 نظام الري', isDark),
              const SizedBox(height: 8),
              Row(children: [
                _buildOptionChip('ري_تقطير', '💧', 'تقطير', isDark),
                const SizedBox(width: 8),
                _buildOptionChip('ري_كامل', '💦', 'ري كامل', isDark),
                const SizedBox(width: 8),
                _buildOptionChip('بعلية', '🌧️', 'بعلية', isDark),
              ]),
              const SizedBox(height: 16),
              // Season
              _buildLabel('📅 الموسم الزراعي', isDark),
              const SizedBox(height: 8),
              Row(children: [
                _buildSeasonChip('ربيع', '🌸', isDark),
                const SizedBox(width: 6),
                _buildSeasonChip('صيف', '☀️', isDark),
                const SizedBox(width: 6),
                _buildSeasonChip('خريف', '🍂', isDark),
                const SizedBox(width: 6),
                _buildSeasonChip('شتاء', '❄️', isDark),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 14),

        // === SECTION 3: CROP ===
        FadeSlideIn(
          delay: const Duration(milliseconds: 150),
          child: _buildSectionCard(
            isDark: isDark,
            icon: '🌱',
            title: 'المحصول والتاريخ',
            child: Column(children: [
              // Categories
              ...(['حبوب', 'خضروات', 'بقوليات', 'أشجار مثمرة', 'أعشاب عطرية', 'محاصيل صناعية', 'أعلاف']).map((cat) {
                final catCrops = allCrops.where((c) => c.category == cat).toList();
                if (catCrops.isEmpty) return const SizedBox.shrink();
                return _buildCropCategory(cat, catCrops, isDark);
              }),
              const SizedBox(height: 4),
              Divider(color: isDark ? AppColors.darkBorder : AppColors.accent.withOpacity(0.5), height: 24),
              // Plant date
              _buildDatePicker(isDark),
              if (_selectedCrop != null) ...[
                const SizedBox(height: 12),
                _buildCropStats(isDark),
              ],
            ]),
          ),
        ),
        const SizedBox(height: 24),

        // === CALCULATE BUTTON ===
        FadeSlideIn(
          delay: const Duration(milliseconds: 200),
          child: _buildCalculateButton(isDark),
        ),
      ]),
    );
  }

  // ==================== RESULT TAB ====================
  Widget _buildResultTab(bool isDark) {
    if (_result == null) {
      return _buildEmptyState(
        '📊', 'لا توجد نتائج بعد',
        'قم بملء النموذج واضغط على زر الحساب', isDark,
      );
    }
    final r = _result!;
    final cropIcon = allCrops.firstWhere((c) => c.name == r.cropName, orElse: () => allCrops.first).icon;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      child: Column(children: [

        // --- Hero Card ---
        FadeSlideIn(
          child: _buildHeroResultCard(r, cropIcon, isDark),
        ),
        const SizedBox(height: 14),

        // --- Quick stats row ---
        FadeSlideIn(
          delay: const Duration(milliseconds: 80),
          child: Row(children: [
            _buildMiniStat('🏜️', 'التربة', _soilShortName(r.soilType), isDark),
            const SizedBox(width: 8),
            _buildMiniStat('⏳', 'المتبقي', '${r.daysRemaining} يوم', isDark),
            const SizedBox(width: 8),
            _buildMiniStat('📅', 'تاريخ الزراعة', r.plantDate.substring(5), isDark),
          ]),
        ),
        const SizedBox(height: 14),

        // --- Weather ---
        if (r.weather != null) ...[
          FadeSlideIn(
            delay: const Duration(milliseconds: 120),
            child: _buildSectionCard(
              isDark: isDark, icon: '☀️', title: 'الطقس الحالي',
              child: Row(children: [
                _buildWeatherStat('🌡️', '${r.weather!['temp']}°C', 'الحرارة', isDark),
                _buildWeatherStat('↕️', '${r.weather!['tempMax']}°/${r.weather!['tempMin']}°', 'نطاق', isDark),
                _buildWeatherStat('🌧️', '${r.weather!['rain']}مم', 'أمطار', isDark),
                _buildWeatherStat('💧', '${r.weather!['humidity']}%', 'رطوبة', isDark),
              ]),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // --- Nutrients ---
        FadeSlideIn(
          delay: const Duration(milliseconds: 160),
          child: _buildSectionCard(
            isDark: isDark, icon: '🧪', title: 'تحليل العناصر الغذائية',
            child: Column(children: [
              ...r.nutrients.entries.map((e) => _buildNutrientRow(e.key, e.value, isDark)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('إجمالي ما يُضاف',
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkText : AppColors.textDark)),
                  AnimatedCounter(
                    value: r.totalKgHa,
                    suffix: ' كغ/هـ',
                    style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800,
                      fontSize: 18, color: AppColors.primary),
                  ),
                ]),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 14),

        // --- Fertilizers ---
        FadeSlideIn(
          delay: const Duration(milliseconds: 200),
          child: _buildSectionCard(
            isDark: isDark, icon: '📦', title: 'الأسمدة الموصى بها',
            child: Column(
              children: r.fertilizers.asMap().entries.map((entry) =>
                FadeSlideIn(
                  delay: Duration(milliseconds: 80 * entry.key),
                  child: _buildFertCard(entry.value, r.area, isDark),
                )
              ).toList(),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // --- Alerts ---
        if (r.alerts.isNotEmpty || r.warnings.isNotEmpty)
          FadeSlideIn(
            delay: const Duration(milliseconds: 240),
            child: _buildSectionCard(
              isDark: isDark, icon: '⚠️', title: 'تحذيرات وملاحظات',
              child: Column(children: [
                ...r.alerts.map((a) => _buildAlertItem(a, true, isDark)),
                ...r.warnings.map((w) => _buildAlertItem(w, false, isDark)),
              ]),
            ),
          )
        else
          FadeSlideIn(
            delay: const Duration(milliseconds: 240),
            child: _buildSuccessBox(isDark),
          ),
        const SizedBox(height: 14),

        // --- Irrigation ---
        FadeSlideIn(
          delay: const Duration(milliseconds: 280),
          child: _buildSectionCard(
            isDark: isDark, icon: '💧', title: 'توصيات الري',
            child: Column(children: [
              _buildInfoRow('💧', 'الكمية اليومية', '${r.irrigation['daily']} مم', isDark),
              _buildInfoRow('🔁', 'تكرار الري', '${r.irrigation['freq']}', isDark),
              _buildInfoRow('🌿', 'نظام الري', '${r.irrigation['type']}', isDark),
            ]),
          ),
        ),
        const SizedBox(height: 90),
      ]),
    );
  }

  // ==================== RECORDS TAB ====================
  Widget _buildRecordsTab(bool isDark) {
    if (_savedRecords.isEmpty) {
      return _buildEmptyState('📁', 'لا توجد خطط محفوظة', 'قم بحساب خطة وحفظها', isDark);
    }
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 16, 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${_savedRecords.length} خطة محفوظة',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 15,
              color: isDark ? AppColors.darkText : AppColors.textDark)),
          TextButton.icon(
            onPressed: () async {
              final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Text('حذف الكل', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
                content: const Text('هل تريد حذف جميع السجلات؟', style: TextStyle(fontFamily: 'Cairo')),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
                  TextButton(onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('حذف', style: TextStyle(color: Colors.red, fontFamily: 'Cairo', fontWeight: FontWeight.w700))),
                ],
              ));
              if (ok == true) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('agri_records_v3');
                _loadRecords();
              }
            },
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red, size: 18),
            label: const Text('حذف الكل', style: TextStyle(color: Colors.red, fontFamily: 'Cairo', fontSize: 13)),
          ),
        ]),
      ),
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        itemCount: _savedRecords.length,
        itemBuilder: (ctx, i) {
          final r = _savedRecords[i];
          final cropIcon = allCrops.firstWhere((c) => c.name == r.cropName, orElse: () => allCrops.first).icon;
          return FadeSlideIn(
            delay: Duration(milliseconds: 40 * i),
            child: _buildRecordCard(r, cropIcon, i, isDark),
          );
        },
      )),
    ]);
  }

  // ==================== WIDGET BUILDERS ====================

  Widget _buildSectionCard({
    required bool isDark, required String icon, required String title, required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.backgroundSoft.withOpacity(0), width: 0),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : AppColors.primary.withOpacity(0.06),
            blurRadius: 20, offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(
            fontFamily: 'Cairo', fontWeight: FontWeight.w800, fontSize: 15,
            color: isDark ? AppColors.darkText : AppColors.textDark,
          )),
        ]),
        const SizedBox(height: 16),
        child,
      ]),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: TextStyle(fontFamily: 'Cairo', fontSize: 14,
        color: isDark ? AppColors.darkText : AppColors.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 13,
          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
        prefixIcon: Icon(icon, size: 18, color: isDark ? AppColors.darkTextMuted : AppColors.primary),
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : AppColors.backgroundSoft,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.accent.withOpacity(0.5), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
    );
  }

  Widget _buildDropdown({
    required String label, required String? value, required IconData icon,
    required List<String> items, required void Function(String?) onChanged, required bool isDark,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 13,
          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
        prefixIcon: Icon(icon, size: 18, color: isDark ? AppColors.darkTextMuted : AppColors.primary),
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : AppColors.backgroundSoft,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.accent.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
      style: TextStyle(fontFamily: 'Cairo', color: isDark ? AppColors.darkText : AppColors.textDark),
      dropdownColor: isDark ? AppColors.darkCard : Colors.white,
      borderRadius: BorderRadius.circular(14),
      items: items.map((i) => DropdownMenuItem(
        value: i.isEmpty ? null : i,
        child: Text(i.isEmpty ? '— بدون محصول سابق —' : i,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
      )).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildLabel(String text, bool isDark) => Text(text,
    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 13,
      color: isDark ? AppColors.darkText : AppColors.textDark));

  Widget _buildOptionChip(String value, String emoji, String label, bool isDark) {
    final sel = _irrigation == value;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _irrigation = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: sel ? AppColors.primary : (isDark ? AppColors.darkSurface : AppColors.backgroundSoft),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: sel ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.accent.withOpacity(0.6)),
            width: sel ? 2 : 1,
          ),
        ),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(
            fontFamily: 'Cairo', fontSize: 10, fontWeight: FontWeight.w700,
            color: sel ? Colors.white : (isDark ? AppColors.darkText : AppColors.textDark),
          )),
        ]),
      ),
    ));
  }

  Widget _buildSeasonChip(String season, String emoji, bool isDark) {
    final sel = _season == season;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _season = season),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: sel ? AppColors.primaryDark : (isDark ? AppColors.darkSurface : AppColors.backgroundSoft),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: sel ? AppColors.primaryDark : (isDark ? AppColors.darkBorder : AppColors.accent.withOpacity(0.6)),
            width: sel ? 2 : 1,
          ),
        ),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 2),
          Text(season, style: TextStyle(
            fontFamily: 'Cairo', fontSize: 10, fontWeight: FontWeight.w700,
            color: sel ? Colors.white : (isDark ? AppColors.darkText : AppColors.textDark),
          )),
        ]),
      ),
    ));
  }

  Widget _buildCropCategory(String cat, List<CropModel> crops, bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        margin: const EdgeInsets.only(bottom: 8, top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(cat, style: TextStyle(
          fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 11,
          color: isDark ? AppColors.primaryGlow : AppColors.primary,
        )),
      ),
      Wrap(spacing: 6, runSpacing: 6, children: crops.map((crop) {
        final selected = _selectedCrop?.name == crop.name;
        return GestureDetector(
          onTap: () => setState(() => _selectedCrop = crop),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : (isDark ? AppColors.darkSurface : AppColors.backgroundSoft),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.accent.withOpacity(0.7)),
                width: selected ? 2 : 1,
              ),
              boxShadow: selected ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))] : [],
            ),
            child: Text('${crop.icon} ${crop.name}', style: TextStyle(
              fontFamily: 'Cairo', fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : (isDark ? AppColors.darkText : AppColors.textDark),
            )),
          ),
        );
      }).toList()),
      const SizedBox(height: 10),
    ]);
  }

  Widget _buildDatePicker(bool isDark) {
    return GestureDetector(
      onTap: () async {
        final d = await showDatePicker(
          context: context, initialDate: _plantDate,
          firstDate: DateTime(2020), lastDate: DateTime.now(),
          builder: (ctx, child) => Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(primary: AppColors.primary, onPrimary: Colors.white),
              dialogBackgroundColor: Colors.white,
            ),
            child: child!,
          ),
        );
        if (d != null) setState(() => _plantDate = d);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.backgroundSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.accent.withOpacity(0.5)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('تاريخ الزراعة', style: TextStyle(fontFamily: 'Cairo', fontSize: 11,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted)),
            Text(DateFormat('yyyy/MM/dd').format(_plantDate),
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 14,
                color: isDark ? AppColors.darkText : AppColors.textDark)),
          ]),
          const Spacer(),
          Icon(Icons.edit_rounded, size: 16, color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
        ]),
      ),
    );
  }

  Widget _buildCropStats(bool isDark) {
    final c = _selectedCrop!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(children: [
        _buildCropStat('⏱️', '${c.cycleDays}', 'يوم', isDark),
        _buildCropStat('🌡️', '${c.tempMin}-${c.tempMax}', '°C', isDark),
        _buildCropStat('💧', '${c.waterMm}', 'مم', isDark),
        _buildCropStat('📊', '${c.stages.length}', 'مراحل', isDark),
      ]),
    );
  }

  Widget _buildCropStat(String emoji, String val, String unit, bool isDark) => Expanded(child: Column(children: [
    Text(emoji, style: const TextStyle(fontSize: 16)),
    const SizedBox(height: 2),
    Text(val, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800, fontSize: 13,
      color: isDark ? AppColors.darkText : AppColors.primary)),
    Text(unit, style: TextStyle(fontFamily: 'Cairo', fontSize: 9,
      color: isDark ? AppColors.darkTextMuted : AppColors.textMuted)),
  ]));

  Widget _buildCalculateButton(bool isDark) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.centerRight, end: Alignment.centerLeft,
        ),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.45), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _calculate,
          borderRadius: BorderRadius.circular(20),
          child: const Center(
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('🤖', style: TextStyle(fontSize: 22)),
              SizedBox(width: 10),
              Text('احسب خطة التسميد الذكية',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Cairo', color: Colors.white, letterSpacing: -0.3)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildWilayaItem(WilayaModel w, bool selected, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      color: selected
        ? AppColors.primary.withOpacity(isDark ? 0.25 : 0.12)
        : Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() => _selectedWilaya = w);
          _fetchWeather(w);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.accent.withOpacity(0.4)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Text('${w.code}', style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800,
                color: selected ? Colors.white : (isDark ? AppColors.darkText : AppColors.textDark),
                fontFamily: 'Cairo',
              ))),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(w.name, style: TextStyle(
                fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 13,
                color: selected ? AppColors.primary : (isDark ? AppColors.darkText : AppColors.textDark),
              )),
              Text(_soilShortName(w.soilType), style: TextStyle(
                fontSize: 10, fontFamily: 'Cairo',
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              )),
            ])),
            if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
          ]),
        ),
      ),
    );
  }

  Widget _buildWeatherCard(bool isDark) {
    final wd = _weatherData!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : const Color(0xFFE8F5E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${wd['temp']}°C',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 28, fontWeight: FontWeight.w900,
              color: isDark ? AppColors.darkText : AppColors.primary)),
          Text('↑${wd['tempMax']}° ↓${wd['tempMin']}°',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: isDark ? AppColors.darkTextMuted : AppColors.textMuted)),
        ]),
        const SizedBox(width: 20),
        Expanded(child: Row(children: [
          _buildWeatherBadge('🌧️', '${wd['rain']}مم', 'أمطار', isDark),
          const SizedBox(width: 8),
          _buildWeatherBadge('💧', '${wd['humidity']}%', 'رطوبة', isDark),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
          child: const Text('اليوم', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  Widget _buildWeatherBadge(String emoji, String val, String label, bool isDark) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
    decoration: BoxDecoration(
      color: isDark ? AppColors.darkCard : Colors.white.withOpacity(0.7),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 14)),
      Text(val, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 12,
        color: isDark ? AppColors.darkText : AppColors.textDark)),
      Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 9, color: isDark ? AppColors.darkTextMuted : AppColors.textMuted)),
    ]),
  ));

  Widget _buildSoilPreview(bool isDark) {
    final soil = soilDb[_selectedWilaya!.soilType];
    if (soil == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.accentWarm.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accentGold.withOpacity(0.4)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.accentGold.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
          child: const Text('🏜️', style: TextStyle(fontSize: 18)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_soilShortName(_selectedWilaya!.soilType),
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 13,
              color: isDark ? AppColors.darkText : AppColors.textDark)),
          Text('pH ${soil.phMin}–${soil.phMax} | كفاءة ${(soil.efficacite * 100).toInt()}%',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: isDark ? AppColors.darkTextMuted : AppColors.textMuted)),
        ])),
      ]),
    );
  }

  // Result tab helpers

  Widget _buildHeroResultCard(AnalysisResult r, String cropIcon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D5A1B), Color(0xFF4A7A32), Color(0xFF3D2F1E)],
          begin: Alignment.topRight, end: Alignment.bottomLeft,
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2D5A1B).withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
            child: Text(cropIcon, style: const TextStyle(fontSize: 32)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.cropName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22, fontFamily: 'Cairo')),
            Text('${r.wilayaName} • ${r.area} هكتار',
              style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12, fontFamily: 'Cairo')),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            AnimatedCounter(
              value: r.totalKgHa,
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, fontFamily: 'Cairo'),
            ),
            const Text('كغ/هكتار', style: TextStyle(color: Colors.white60, fontSize: 11, fontFamily: 'Cairo')),
          ]),
        ]),
        const SizedBox(height: 18),
        // Stage progress
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('المرحلة', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, fontFamily: 'Cairo')),
                ),
                const SizedBox(width: 8),
                Text(r.stageName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontFamily: 'Cairo', fontSize: 14)),
              ]),
              Text('${r.stageProgress.toStringAsFixed(0)}%',
                style: const TextStyle(color: Color(0xFFA8E87A), fontWeight: FontWeight.w900, fontSize: 16)),
            ]),
            const SizedBox(height: 10),
            AnimatedProgressBar(value: r.stageProgress / 100, color: const Color(0xFFA8E87A)),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('اليوم ${r.daysElapsed} من ${r.totalDays}',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontFamily: 'Cairo')),
              Text('المجموع: ${(r.totalKgHa * r.area).toStringAsFixed(0)} كغ',
                style: const TextStyle(color: Color(0xFFA8E87A), fontSize: 11, fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _buildMiniStat(String emoji, String label, String value, bool isDark) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 8)],
      ),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800, fontSize: 11,
          color: isDark ? AppColors.darkText : AppColors.textDark), textAlign: TextAlign.center),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 9,
          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted)),
      ]),
    ),
  );

  Widget _buildWeatherStat(String emoji, String value, String label, bool isDark) => Expanded(
    child: Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 18)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 12,
        color: isDark ? AppColors.darkText : AppColors.textDark), textAlign: TextAlign.center),
      Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 9,
        color: isDark ? AppColors.darkTextMuted : AppColors.textMuted)),
    ]),
  );

  Widget _buildNutrientRow(String nut, Map<String, dynamic> d, bool isDark) {
    final ok = d['ok'] as bool;
    final deficit = (d['deficit'] as num).toDouble();
    final required = (d['required'] as num).toDouble();
    final need = (d['need'] as num).toDouble();
    final avail = (d['avail'] as num).toDouble();
    final pct = need > 0 ? (avail / need).clamp(0.0, 1.0) : 1.0;
    final color = ok ? AppColors.success : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : (ok ? AppColors.backgroundSoft : const Color(0xFFFFF8F0)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ok
          ? (isDark ? AppColors.darkBorder : AppColors.accent.withOpacity(0.4))
          : AppColors.warning.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(nut, style: TextStyle(
              fontWeight: FontWeight.w900, fontSize: 13, color: color))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('الحاجة: ${need.toStringAsFixed(0)}',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 11,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted)),
              const SizedBox(width: 12),
              Text('المتاح: ${avail.toStringAsFixed(0)}',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 11,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted)),
            ]),
            if (!ok)
              Text('نقص: ${deficit.toStringAsFixed(0)} ← يضاف: ${required.toStringAsFixed(0)} كغ/هـ',
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 11,
                  color: AppColors.warning, fontWeight: FontWeight.w700)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Text(ok ? '✓ كافٍ' : '+ أضف',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ),
        ]),
        const SizedBox(height: 8),
        AnimatedProgressBar(value: pct, color: color, height: 5),
      ]),
    );
  }

  Widget _buildFertCard(FertilizerRec f, double area, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.backgroundSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.accent.withOpacity(0.5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(f.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(child: Text(f.name, style: TextStyle(
            fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 13,
            color: isDark ? AppColors.darkText : AppColors.textDark))),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${(f.kgHa * area).toStringAsFixed(0)} كغ',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary)),
            Text('(${f.kgHa.toStringAsFixed(0)} كغ/هـ)',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: AppColors.textMuted)),
          ]),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.construction_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(child: Text(f.how, style: TextStyle(fontFamily: 'Cairo', fontSize: 11,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted))),
            ]),
            const SizedBox(height: 6),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.access_time_rounded, size: 14, color: AppColors.accentGold),
              const SizedBox(width: 6),
              Expanded(child: Text(f.when, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11,
                color: AppColors.accentGold, fontWeight: FontWeight.w600))),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _buildAlertItem(String text, bool isAlert, bool isDark) {
    final color = isAlert ? Colors.red : Colors.orange;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(isAlert ? Icons.warning_amber_rounded : Icons.info_outline_rounded, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontFamily: 'Cairo', fontSize: 12,
          color: isDark ? AppColors.darkText : AppColors.textDark))),
      ]),
    );
  }

  Widget _buildSuccessBox(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.success.withOpacity(0.15), shape: BoxShape.circle),
          child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('التسميد متوازن ومثالي', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.success)),
          Text('لا توجد نقائص أو تحذيرات في هذه المرحلة', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.success)),
        ])),
      ]),
    );
  }

  Widget _buildInfoRow(String emoji, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 13,
          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted)),
        const Spacer(),
        Text(value, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 13,
          color: isDark ? AppColors.darkText : AppColors.textDark)),
      ]),
    );
  }

  Widget _buildRecordCard(AnalysisResult r, String cropIcon, int idx, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: Text(cropIcon, style: const TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.cropName, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800, fontSize: 14,
              color: isDark ? AppColors.darkText : AppColors.textDark)),
            const SizedBox(height: 2),
            Text('📍 ${r.wilayaName} • ${r.area} هكتار',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: isDark ? AppColors.darkTextMuted : AppColors.textMuted)),
            Text('🌱 ${r.stageName} • ${r.totalKgHa.toStringAsFixed(1)} كغ/هـ',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700)),
            Text('📅 ${r.analysisDate}',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: isDark ? AppColors.darkTextMuted : AppColors.textMuted)),
          ])),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22),
            onPressed: () => _deleteRecord(idx),
          ),
        ]),
      ),
    );
  }

  Widget _buildEmptyState(String emoji, String title, String sub, bool isDark) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 44)),
      ),
      const SizedBox(height: 20),
      Text(title, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800, fontSize: 17,
        color: isDark ? AppColors.darkText : AppColors.textDark)),
      const SizedBox(height: 8),
      Text(sub, style: TextStyle(fontFamily: 'Cairo', fontSize: 13,
        color: isDark ? AppColors.darkTextMuted : AppColors.textMuted)),
    ]));
  }

  String _soilShortName(String soilType) {
    const map = {
      'Sols alluviaux': 'طمي (جيد جداً)',
      'Sols bruns calcaires': 'بني جيري',
      'Vertisols': 'فيرتيسول (طيني)',
      "Sols peu évolués d'érosion": 'هش منحوت',
      'Sols sableux (Erg)': 'رملي (ارج)',
      'Sols minéraux bruts (Reg)': 'معدني (رڤ)',
      'Sols hydromorphes (Oasis)': 'هيدرومورف (واحة)',
    };
    return map[soilType] ?? soilType;
  }
}

// ==================== LOADING RING ANIMATION ====================
class _LoadingRing extends StatefulWidget {
  @override State<_LoadingRing> createState() => _LoadingRingState();
}
class _LoadingRingState extends State<_LoadingRing> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => CustomPaint(
      painter: _RingPainter(_ctrl.value),
      size: const Size(72, 72),
    ),
  );
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Background ring
    canvas.drawCircle(center, radius,
      Paint()..color = AppColors.primary.withOpacity(0.15)
        ..style = PaintingStyle.stroke..strokeWidth = 4);

    // Arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -math.pi / 2 + progress * 2 * math.pi, math.pi * 1.2,
      false,
      Paint()..color = AppColors.primary
        ..style = PaintingStyle.stroke..strokeWidth = 4
        ..strokeCap = StrokeCap.round);

    // Leaf dots
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 + progress * 2 * math.pi;
      final x = center.dx + (radius + 6) * math.cos(angle);
      final y = center.dy + (radius + 6) * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 2.5,
        Paint()..color = AppColors.primaryGlow.withOpacity(0.5 + 0.5 * math.sin(angle + progress * math.pi)));
    }
  }

  @override bool shouldRepaint(_RingPainter old) => true;
}