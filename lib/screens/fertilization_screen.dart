// lib/screens/fertilization_screen.dart
// 🌿 AgriPal – مستشار التسميد الذكي
// ✅ Redesigned to match IrrigationPage design system: green-forward, modern, animated

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ============================================================
// 🎨 DESIGN SYSTEM  (mirrors AppColors from irrigation_page)
// ============================================================
class AppColors {
  static const Color forest         = Color(0xFF1E3A0F);
  static const Color sage           = Color(0xFF55833D);
  static const Color mint           = Color(0xFF7BAE68);
  static const Color olive          = Color(0xFF6B8C3A);
  static const Color cream          = Color(0xFFF5F1E8);
  static const Color sand           = Color(0xFFEDE4D0);
  static const Color clay           = Color(0xFFD4B896);
  static const Color bark           = Color(0xFF6B4C2E);
  static const Color earth          = Color(0xFF8B6914);
  static const Color wheat          = Color(0xFFC8A44A);
  static const Color backgroundSoft = Color(0xFFE3EED4);

  static const Color surface        = Color(0xFFFFFFFF);
  static const Color surfaceWarm    = Color(0xFFFAF7F0);
  static const Color border         = Color(0xFFE0D5C0);
  static const Color divider        = Color(0xFFEDE8DE);

  static const Color textPrimary    = Color(0xFF1A2B10);
  static const Color textSecond     = Color(0xFF5A6B4A);
  static const Color textLight      = Color(0xFFF5F1E8);
  static const Color textMuted      = Color(0xFF9EA88A);
  static const Color textWarm       = Color(0xFF7A5C3A);

  static const Color primary        = Color(0xFF55833D);
  static const Color primaryDark    = Color(0xFF3A6E1E);

  static const Color success        = Color(0xFF3D7A3D);
  static const Color warning        = Color(0xFFB8860B);
  static const Color danger         = Color(0xFFC0392B);
  static const Color info           = Color(0xFF1B6CA8);
  static const Color sky            = Color(0xFF5BA4CF);

  static Color riskColor(String level) {
    if (level.isEmpty) return success;
    final l = level.toLowerCase();
    if (l.contains('حرج') || l.contains('عالية') || l.contains('critique') ||
        l.contains('critical') || l.contains('high'))
      return danger;
    if (l.contains('متوسط') || l.contains('modérée') || l.contains('normale') ||
        l.contains('moderate') || l.contains('medium'))
      return warning;
    return success;
  }
}

// ============================================================
// 📍 DATA LISTS
// ============================================================
const List<String> _kWilayas = [
  'أدرار', 'الشلف', 'الأغواط', 'أم البواقي', 'باتنة', 'بجاية', 'بسكرة', 'بشار',
  'البليدة', 'البويرة', 'تمنراست', 'تبسة', 'تلمسان', 'تيارت', 'تيزي وزو', 'الجزائر',
  'الجلفة', 'جيجل', 'سطيف', 'سعيدة', 'سكيكدة', 'سيدي بلعباس', 'عنابة', 'قالمة',
  'قسنطينة', 'المدية', 'مستغانم', 'المسيلة', 'معسكر', 'ورقلة', 'وهران', 'البيض',
  'إليزي', 'برج بوعريريج', 'بومرداس', 'الطارف', 'تندوف', 'تيسمسيلت', 'الوادي',
  'خنشلة', 'سوق أهراس', 'تيبازة', 'ميلة', 'عين الدفلى', 'النعامة', 'عين تموشنت',
  'غرداية', 'غليزان', 'تيميمون', 'برج باجي مختار', 'أولاد جلال', 'بني عباس',
  'عين صالح', 'عين قزام', 'تقرت', 'جانت', 'المغير', 'المنيعة',
];

const Map<String, List<String>> _kCulturesByCategory = {
  'الحبوب':          ['قمح صلب', 'قمح لين', 'شعير', 'ذرة', 'سرغو', 'شوفان'],
  'الخضروات':        ['طماطم', 'بطاطس', 'بصل', 'ثوم', 'فلفل', 'كوسة', 'باذنجان', 'جزر', 'خس', 'بطيخ', 'قرع', 'فلفل حار', 'لفت', 'خرشوف'],
  'البقوليات':       ['حمص', 'عدس', 'فول', 'فاصوليا خضراء', 'بازلاء'],
  'الأشجار المثمرة': ['زيتون', 'نخيل التمر', 'تين', 'رمان', 'كرمة', 'لوز', 'مشمش', 'خوخ', 'برقوق', 'كرز', 'حمضيات (برتقال)', 'ليمون'],
  'الصناعية':        ['عباد الشمس', 'شمندر السكر', 'قطن', 'تبغ'],
};

// ============================================================
// 📦 MODELS
// ============================================================
class FertilizationResult {
  final bool success;
  final String? error;
  final String? wilaya, crop, stageName, soilType;
  final double? area, totalKg, totalKgHa, stageProgress, irrigationAmount;
  final int? daysElapsed, totalDays, daysRemaining;
  final Map<String, dynamic>? nutrients;
  final List<dynamic>? fertilizers, tips;
  final List<String>? alerts, warnings;
  final String? riskLevel;
  final Map<String, dynamic> raw;

  FertilizationResult({
    required this.success,
    this.error,
    this.wilaya,
    this.area,
    this.crop,
    this.totalKg,
    this.totalKgHa,
    this.stageProgress,
    this.stageName,
    this.daysElapsed,
    this.totalDays,
    this.daysRemaining,
    this.soilType,
    this.nutrients,
    this.fertilizers,
    this.alerts,
    this.warnings,
    this.tips,
    this.irrigationAmount,
    this.riskLevel,
    required this.raw,
  });

  factory FertilizationResult.fromJson(Map<String, dynamic> json) {
    String risk = 'منخفضة';
    if (json['riskLevel'] != null)
      risk = json['riskLevel'].toString();
    else if (json['alerts'] != null && (json['alerts'] as List).isNotEmpty)
      risk = 'حرجة';
    else if (json['warnings'] != null && (json['warnings'] as List).isNotEmpty)
      risk = 'متوسطة';

    return FertilizationResult(
      success: json['success'] ?? true,
      error: json['error'],
      wilaya: json['wilaya'],
      area: (json['area'] as num?)?.toDouble(),
      crop: json['crop'],
      totalKg: (json['totalKg'] as num?)?.toDouble(),
      totalKgHa: (json['totalKgHa'] as num?)?.toDouble(),
      stageProgress: (json['stageProgress'] as num?)?.toDouble(),
      stageName: json['stageName'],
      daysElapsed: (json['daysElapsed'] as num?)?.toInt(),
      totalDays: (json['totalDays'] as num?)?.toInt(),
      daysRemaining: (json['daysRemaining'] as num?)?.toInt(),
      soilType: json['soilType'],
      nutrients: json['nutrients'] as Map<String, dynamic>?,
      fertilizers: json['fertilizers'] as List?,
      alerts: (json['alerts'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      warnings: (json['warnings'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      tips: json['tips'] as List?,
      irrigationAmount: (json['irrigation']?['amount'] as num?)?.toDouble(),
      riskLevel: risk,
      raw: json,
    );
  }
}

class FertilizationRecord {
  final String id, wilaya, culture, previousCulture, stageName, riskLevel;
  final DateTime datePlantation, dateCalcul;
  final double superficie, totalKg, totalKgHa;
  final int progression;
  final Map<String, dynamic> rawData;

  FertilizationRecord({
    required this.id,
    required this.wilaya,
    required this.culture,
    required this.previousCulture,
    required this.datePlantation,
    required this.superficie,
    required this.dateCalcul,
    required this.totalKg,
    required this.totalKgHa,
    required this.stageName,
    required this.progression,
    required this.riskLevel,
    required this.rawData,
  });

  factory FertilizationRecord.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return FertilizationRecord(
      id: doc.id,
      wilaya: d['wilaya'] ?? '',
      culture: d['culture'] ?? '',
      previousCulture: d['previous_culture'] ?? '',
      datePlantation: (d['date_plantation'] as Timestamp).toDate(),
      superficie: (d['superficie'] as num?)?.toDouble() ?? 0,
      dateCalcul: (d['date_calcul'] as Timestamp).toDate(),
      totalKg: (d['total_kg'] as num?)?.toDouble() ?? 0,
      totalKgHa: (d['total_kg_ha'] as num?)?.toDouble() ?? 0,
      stageName: d['stage_name'] ?? '',
      progression: (d['progression'] as num?)?.toInt() ?? 0,
      riskLevel: d['risk_level'] ?? '',
      rawData: Map<String, dynamic>.from(d['raw_data'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'wilaya': wilaya,
        'culture': culture,
        'previous_culture': previousCulture,
        'date_plantation': Timestamp.fromDate(datePlantation),
        'superficie': superficie,
        'date_calcul': Timestamp.fromDate(dateCalcul),
        'total_kg': totalKg,
        'total_kg_ha': totalKgHa,
        'stage_name': stageName,
        'progression': progression,
        'risk_level': riskLevel,
        'raw_data': rawData,
      };
}

// ============================================================
// 🚜 TRACTOR PAINTER – Fixed version with proper animations
// ============================================================
class TractorPainter extends CustomPainter {
  final double wheelAngle;
  final double smokeProgress;

  const TractorPainter({required this.wheelAngle, required this.smokeProgress});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 140, size.height / 100);
    _drawSmoke(canvas);
    _drawRearWheel(canvas);
    _drawFrontWheel(canvas);
    _drawBody(canvas);
  }

  void _drawSmoke(Canvas canvas) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Puff 1
    final alpha1 = (0.6 * (1 - smokeProgress)).clamp(0.0, 1.0);
    paint.color = Color.fromRGBO(184, 201, 168, alpha1);
    canvas.drawCircle(
      Offset(102 - smokeProgress * 12, 22 - smokeProgress * 18),
      5 * (1 + smokeProgress * 0.8),
      paint,
    );

    // Puff 2 (delayed)
    final delay = (smokeProgress + 0.5) % 1.0;
    final alpha2 = (0.4 * (1 - delay)).clamp(0.0, 1.0);
    paint.color = Color.fromRGBO(197, 212, 176, alpha2);
    canvas.drawCircle(
      Offset(98 - delay * 12, 18 - delay * 18),
      3.5 * (1 + delay * 0.8),
      paint,
    );
  }

  void _drawRearWheel(Canvas canvas) {
    canvas.save();
    canvas.translate(35, 70);
    canvas.rotate(wheelAngle);
    canvas.translate(-35, -70);

    final fill = Paint()..style = PaintingStyle.fill;

    fill.color = const Color(0xFF3A3A3A);
    canvas.drawCircle(const Offset(35, 70), 25, fill);
    fill.color = const Color(0xFF2D2D2D);
    canvas.drawCircle(const Offset(35, 70), 20, fill);
    fill.color = const Color(0xFFE8E4DC);
    canvas.drawCircle(const Offset(35, 70), 10, fill);
    fill.color = const Color(0xFF55833D);
    canvas.drawCircle(const Offset(35, 70), 5, fill);

    final spoke = Paint()
      ..color = const Color(0xFF444444)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(const Offset(35, 45), const Offset(35, 95), spoke);
    canvas.drawLine(const Offset(10, 70), const Offset(60, 70), spoke);
    spoke.strokeWidth = 2;
    canvas.drawLine(const Offset(18, 52), const Offset(52, 88), spoke);
    canvas.drawLine(const Offset(52, 52), const Offset(18, 88), spoke);

    canvas.restore();
  }

  void _drawFrontWheel(Canvas canvas) {
    canvas.save();
    canvas.translate(105, 70);
    canvas.rotate(wheelAngle);
    canvas.translate(-105, -70);

    final fill = Paint()..style = PaintingStyle.fill;

    fill.color = const Color(0xFF3A3A3A);
    canvas.drawCircle(const Offset(105, 70), 16, fill);
    fill.color = const Color(0xFF2D2D2D);
    canvas.drawCircle(const Offset(105, 70), 12, fill);
    fill.color = const Color(0xFFE8E4DC);
    canvas.drawCircle(const Offset(105, 70), 6, fill);
    fill.color = const Color(0xFF55833D);
    canvas.drawCircle(const Offset(105, 70), 3, fill);

    final spoke = Paint()
      ..color = const Color(0xFF444444)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(const Offset(105, 54), const Offset(105, 86), spoke);
    canvas.drawLine(const Offset(89, 70), const Offset(121, 70), spoke);

    canvas.restore();
  }

  void _drawBody(Canvas canvas) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Main body
    paint.color = const Color(0xFF55833D);
    final body = Path()
      ..moveTo(55, 70)
      ..lineTo(55, 52)
      ..quadraticBezierTo(55, 44, 63, 44)
      ..lineTo(95, 44)
      ..quadraticBezierTo(112, 44, 112, 60)
      ..lineTo(112, 70)
      ..close();
    canvas.drawPath(body, paint);

    // Cabin
    paint.color = const Color(0xFF4A7535);
    final cabin = Path()
      ..moveTo(57, 44)
      ..lineTo(57, 24)
      ..quadraticBezierTo(57, 16, 67, 16)
      ..lineTo(88, 16)
      ..quadraticBezierTo(96, 16, 96, 24)
      ..lineTo(96, 44)
      ..close();
    canvas.drawPath(cabin, paint);

    // Window (main glass)
    paint.color = const Color(0xD9C8DFF0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(61, 20, 30, 20), const Radius.circular(3)),
      paint,
    );
    // Window reflection
    paint.color = const Color(0xB3A8CBEA);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(63, 22, 12, 16), const Radius.circular(2)),
      paint,
    );

    // Exhaust pipe body
    paint.color = const Color(0xFF524133);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(97, 28, 4, 16), const Radius.circular(2)),
      paint,
    );
    // Exhaust pipe cap
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(97, 25, 6, 5), const Radius.circular(3)),
      paint,
    );

    // Grill panel
    paint.color = const Color(0xFF3D6B2B);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(100, 50, 10, 18), const Radius.circular(2)),
      paint,
    );
    // Grill lines
    final grill = Paint()
      ..color = const Color(0xB3E3EED4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(101, 54), const Offset(109, 54), grill);
    canvas.drawLine(const Offset(101, 58), const Offset(109, 58), grill);
    canvas.drawLine(const Offset(101, 62), const Offset(109, 62), grill);

    // Headlight
    paint.color = const Color(0xFFDDA811);
    canvas.drawCircle(const Offset(110, 47), 3.5, paint);
    paint.color = const Color(0x80FFFFFF);
    canvas.drawCircle(const Offset(110, 47), 1.5, paint);

    // Ground shadow line
    final ground = Paint()
      ..color = const Color(0x663D6B2B)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final groundPath = Path()
      ..moveTo(58, 68)
      ..quadraticBezierTo(46, 75, 22, 75);
    canvas.drawPath(groundPath, ground);
  }

  @override
  bool shouldRepaint(TractorPainter old) =>
      old.wheelAngle != wheelAngle || old.smokeProgress != smokeProgress;
}

// ============================================================
// 🔵 ANIMATED DOTS TEXT
// ============================================================
class _AnimatedDotsText extends StatefulWidget {
  final String text;
  final Color color;
  const _AnimatedDotsText({required this.text, required this.color});
  @override
  State<_AnimatedDotsText> createState() => _AnimatedDotsTextState();
}

class _AnimatedDotsTextState extends State<_AnimatedDotsText>
    with TickerProviderStateMixin {
  late List<AnimationController> _ctrl;
  late List<Animation<double>> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = List.generate(
      3,
      (i) => AnimationController(
        duration: const Duration(milliseconds: 1200),
        vsync: this,
      ),
    );
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) _ctrl[i].repeat(reverse: true);
      });
    }
    _anim = _ctrl
        .map((c) => Tween<double>(begin: 0.2, end: 1.0)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _ctrl) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.text,
          style: TextStyle(
            fontSize: 14,
            color: widget.color,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(width: 2),
        ...List.generate(
          3,
          (i) => AnimatedBuilder(
            animation: _anim[i],
            builder: (_, __) => Opacity(
              opacity: _anim[i].value,
              child: Text(
                '.',
                style: TextStyle(
                  fontSize: 16,
                  color: widget.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// 🎨 BACKGROUND TEXTURE
// ============================================================
class _BgTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.sage.withOpacity(0.025)
      ..style = PaintingStyle.fill;
    final rng = Random(99);
    for (int i = 0; i < 18; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = 20.0 + rng.nextDouble() * 80;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ============================================================
// 🏗️ FERTILIZATION SCREEN
// ============================================================
class FertilizationScreen extends StatefulWidget {
  const FertilizationScreen({super.key});
  @override
  State<FertilizationScreen> createState() => _FertilizationScreenState();
}

class _FertilizationScreenState extends State<FertilizationScreen>
    with TickerProviderStateMixin {

  int _tabIndex = 0;

  // -- Form --
  String   _selectedWilaya          = 'الجزائر';
  String   _selectedPreviousCulture = 'قمح صلب';
  String   _selectedCurrentCulture  = 'طماطم';
  DateTime _datePlantation          = DateTime.now().subtract(const Duration(days: 30));
  final    _superficieCtrl          = TextEditingController(text: '1.0');
  final    _superficieFocus         = FocusNode();

  // -- API --
  static const String _apiBase = 'https://fertilizer-api-a5j7.onrender.com';
  FertilizationResult? _result;
  bool   _loading = false;
  String _error   = '';

  // -- Firebase --
  final _firestore = FirebaseFirestore.instance;
  final _auth      = FirebaseAuth.instance;
  List<FertilizationRecord> _history = [];
  bool _loadingHistory = false;

  // -- Entrance animations --
  late AnimationController _entranceCtrl;
  late AnimationController _resultCtrl;
  late Animation<double>   _entranceFade;
  late Animation<Offset>   _entranceSlide;
  late Animation<double>   _resultFade;

  // -- Tractor loading animations (FIXED - same as IrrigationPage) --
  late AnimationController _floatCtrl;
  late AnimationController _wheelCtrl;
  late AnimationController _smokeCtrl;
  late AnimationController _progressCtrl;
  late Animation<double>   _floatAnim;
  late Animation<double>   _wheelAnim;
  late Animation<double>   _smokeAnim;
  late Animation<double>   _progressAnim;

  String? get _farmerId => _auth.currentUser?.uid;

  @override
  void initState() {
    super.initState();

    // Entrance animations
    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _resultCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _entranceFade  = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _entranceSlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut));
    _resultFade = CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOut);
    _entranceCtrl.forward();

    // ✅ TRACTOR ANIMATIONS (FIXED - same as IrrigationPage)
    _floatCtrl = AnimationController(
        vsync: this, 
        duration: const Duration(milliseconds: 1800)
      )..repeat(reverse: true);
      
    _wheelCtrl = AnimationController(
        vsync: this, 
        duration: const Duration(milliseconds: 900)
      )..repeat();
    
    _smokeCtrl = AnimationController(
        vsync: this, 
        duration: const Duration(milliseconds: 1000)
      )..repeat();
      
    _progressCtrl = AnimationController(
        vsync: this, 
        duration: const Duration(seconds: 22)
      );

    _floatAnim = Tween<double>(begin: 0, end: -12)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
        
    _wheelAnim = Tween<double>(begin: 0, end: 2 * pi)
        .animate(CurvedAnimation(parent: _wheelCtrl, curve: Curves.linear));
        
    _smokeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _smokeCtrl, curve: Curves.easeOut));
        
    _progressAnim = Tween<double>(begin: 0, end: 0.9)
        .animate(CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOut));

    _loadHistory();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _resultCtrl.dispose();
    // ✅ Dispose tractor controllers
    _floatCtrl.dispose();
    _wheelCtrl.dispose();
    _smokeCtrl.dispose();
    _progressCtrl.dispose();
    _superficieCtrl.dispose();
    _superficieFocus.dispose();
    super.dispose();
  }

  // ---- Firestore: load history ----
  Future<void> _loadHistory() async {
    if (_farmerId == null) return;
    setState(() => _loadingHistory = true);
    try {
      final snap = await _firestore
          .collection('farmers')
          .doc(_farmerId)
          .collection('fertilization_history')
          .orderBy('date_calcul', descending: true)
          .limit(50)
          .get();
      setState(() =>
          _history = snap.docs.map(FertilizationRecord.fromFirestore).toList());
    } catch (e) {
      debugPrint('Firestore load error: $e');
    }
    setState(() => _loadingHistory = false);
  }

  // ---- Firestore: save ----
  Future<void> _saveToFirestore(FertilizationResult res) async {
    if (_farmerId == null || res.totalKg == null) return;
    try {
      await _firestore
          .collection('farmers')
          .doc(_farmerId)
          .collection('fertilization_history')
          .add({
        'wilaya':            _selectedWilaya,
        'culture':           _selectedCurrentCulture,
        'previous_culture':  _selectedPreviousCulture,
        'date_plantation':   _datePlantation,
        'superficie':        double.tryParse(_superficieCtrl.text) ?? 0,
        'date_calcul':       FieldValue.serverTimestamp(),
        'total_kg':          res.totalKg,
        'total_kg_ha':       res.totalKgHa,
        'stage_name':        res.stageName,
        'progression':       res.stageProgress?.round() ?? 0,
        'risk_level':        res.riskLevel,
        'raw_data':          res.raw,
      });
      await _loadHistory();
    } catch (e) {
      debugPrint('Firestore save error: $e');
    }
  }

  // ---- API Call ----
  Future<void> _calculate() async {
    if (_loading) return;
    final superficie = double.tryParse(_superficieCtrl.text);
    if (superficie == null || superficie <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('الرجاء إدخال مساحة صحيحة'),
        backgroundColor: AppColors.warning,
      ));
      return;
    }

    setState(() { _loading = true; _error = ''; _result = null; });
    _resultCtrl.reset();
    _progressCtrl.reset();
    _progressCtrl.forward();

    final dateStr = DateFormat('yyyy-MM-dd').format(_datePlantation);
    final payload = {
      'wilaya':       _selectedWilaya,
      'area':         superficie,
      'crop':         _selectedCurrentCulture,
      'plantDate':    dateStr,
      'previousCrop': _selectedPreviousCulture,
    };

    try {
      final res = await http
          .post(
            Uri.parse('$_apiBase/api/fertilizer/calculate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 60));

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (data['success'] == false) {
        setState(() { _error = data['error'] ?? 'حدث خطأ غير معروف'; });
      } else {
        final result = FertilizationResult.fromJson(data);
        setState(() { _result = result; });
        _resultCtrl.forward();
        await _saveToFirestore(result);
        setState(() => _tabIndex = 1);
      }
    } catch (e) {
      String errMsg = e.toString();
      if (errMsg.contains('Timeout'))
        errMsg = 'الخادم بطيء (Cold Start). انتظر دقيقة وأعد المحاولة.';
      else if (errMsg.contains('SocketException'))
        errMsg = 'لا يوجد اتصال بالإنترنت.';
      setState(() => _error = errMsg);
    }

    _progressCtrl.animateTo(1.0,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    setState(() => _loading = false);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _datePlantation,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.sage,
            onPrimary: Colors.white,
            surface: AppColors.cream,
            onSurface: AppColors.textPrimary,
          ),
          dialogBackgroundColor: AppColors.cream,
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _datePlantation = picked);
  }

  Future<void> _pickCulture(bool isCurrent) async {
    final current =
        isCurrent ? _selectedCurrentCulture : _selectedPreviousCulture;
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CulturePickerSheet(
        selected: current,
        categories: _kCulturesByCategory,
      ),
    );
    if (result != null) {
      setState(() {
        if (isCurrent) _selectedCurrentCulture = result;
        else _selectedPreviousCulture = result;
      });
    }
  }

  // ============================================================
  // 🏗️ BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSoft,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _BgTexturePainter())),
          Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: _buildCurrentTab(),
                ),
              ),
            ],
          ),
          if (_loading) _buildTractorOverlay(),
        ],
      ),
    );
  }

  // ============================================================
  // 🚜 TRACTOR LOADING OVERLAY (FIXED - same as IrrigationPage)
  // ============================================================
  Widget _buildTractorOverlay() {
    return Positioned.fill(
      child: Container(
        color: const Color(0xFF0F1A0F).withOpacity(0.88),
        child: Stack(
          children: [
            Positioned(
              top: -80, right: -80,
              child: Container(
                width: 300, height: 300,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x0F55833D),
                ),
              ),
            ),
            Positioned(
              bottom: -60, left: -60,
              child: Container(
                width: 200, height: 200,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x0D55833D),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ✅ Moving tractor with float animation
                  AnimatedBuilder(
                    animation: _floatCtrl,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(0, _floatAnim.value), 
                      child: child,
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 200, 
                          height: 130,
                          child: AnimatedBuilder(
                            animation: Listenable.merge([_wheelCtrl, _smokeCtrl]),
                            builder: (_, __) => CustomPaint(
                              painter: TractorPainter(
                                wheelAngle: _wheelAnim.value,
                                smokeProgress: _smokeAnim.value,
                              ),
                            ),
                          ),
                        ),
                        // Animated shadow
                        AnimatedBuilder(
                          animation: _floatCtrl,
                          builder: (_, __) {
                            final t = _floatCtrl.value;
                            return Transform.scale(
                              scaleX: 1.0 - t * 0.25,
                              child: Opacity(
                                opacity: (0.5 - t * 0.25).clamp(0.1, 0.5),
                                child: Container(
                                  width: 130, 
                                  height: 10,
                                  margin: const EdgeInsets.only(top: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF55833D),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: 220,
                    child: Column(
                      children: [
                        _AnimatedDotsText(
                          text: 'جاري التحليل',
                          color: AppColors.sage,
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: AnimatedBuilder(
                            animation: _progressCtrl,
                            builder: (_, __) => LinearProgressIndicator(
                              value: _progressAnim.value,
                              minHeight: 6,
                              backgroundColor: const Color(0x2655833D),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.sage),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 🔷 HEADER
  // ============================================================
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.sage, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          )
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.mint.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.mint.withOpacity(0.3)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.textLight),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'التسميد',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textLight,
                    ),
                  ),
                  Text(
                    'مستشار التسميد الذكي',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.mint.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 🔘 TAB BAR
  // ============================================================
  Widget _buildTabBar() {
    final tabs = [
      (Icons.edit_note_rounded,    'الإدخال'),
      (Icons.science_outlined,     'النتيجة'),
      (Icons.history_rounded,      'السجل'),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 251, 251, 251),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = _tabIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (i == 2 && _farmerId != null) _loadHistory();
                setState(() => _tabIndex = i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tabs[i].$1,
                      size: 17,
                      color: active ? AppColors.textLight : AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tabs[i].$2,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            active ? FontWeight.w700 : FontWeight.w500,
                        color:
                            active ? AppColors.textLight : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_tabIndex) {
      case 0:  return _buildInputTab();
      case 1:  return _buildResultTab();
      case 2:  return _buildHistoryTab();
      default: return _buildInputTab();
    }
  }

  // ============================================================
  // 📋 TAB 1 – Input
  // ============================================================
  Widget _buildInputTab() {
    return SlideTransition(
      position: _entranceSlide,
      child: FadeTransition(
        opacity: _entranceFade,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 20),
            _buildInputGroup(),
            const SizedBox(height: 24),
            _buildMainButton(),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildErrorBanner(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.sage, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.sage.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مرحباً بك، فلاح',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'أدخل معلومات قطعتك\nلنحسب لك خطة التسميد المثلى',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputGroup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, right: 4),
          child: const Text(
            'معلومات القطعة',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),

        // Wilaya
        _buildFormCard(
          label: 'الولاية',
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedWilaya,
              isExpanded: true,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              dropdownColor: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              icon: const Icon(Icons.expand_more_rounded, color: AppColors.sage),
              items: _kWilayas
                  .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedWilaya = v!),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Previous crop
        _buildFormCard(
          label: 'المحصول السابق',
          child: InkWell(
            onTap: () => _pickCulture(false),
            child: Row(children: [
              Expanded(
                child: Text(
                  _selectedPreviousCulture,
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                ),
              ),
              const Icon(Icons.expand_more_rounded, color: AppColors.sage),
            ]),
          ),
        ),
        const SizedBox(height: 10),

        // Current crop
        _buildFormCard(
          label: 'المحصول المراد زراعته',
          child: InkWell(
            onTap: () => _pickCulture(true),
            child: Row(children: [
              Expanded(
                child: Text(
                  _selectedCurrentCulture,
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                ),
              ),
              const Icon(Icons.expand_more_rounded, color: AppColors.sage),
            ]),
          ),
        ),
        const SizedBox(height: 10),

        // Date
        _buildFormCard(
          label: 'تاريخ الزراعة',
          child: InkWell(
            onTap: _pickDate,
            child: Row(children: [
              Expanded(
                child: Text(
                  DateFormat('dd MMMM yyyy', 'fr').format(_datePlantation),
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                ),
              ),
              const Icon(Icons.calendar_month_outlined,
                  color: AppColors.sage, size: 18),
            ]),
          ),
        ),
        const SizedBox(height: 10),

        // Area
        _buildFormCard(
          label: 'المساحة',
          trailing: _buildAreaBadge(),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _superficieCtrl,
                focusNode: _superficieFocus,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintText: 'مثال: 2.5',
                  hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.sage.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'هكتار',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.sage,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _buildAreaBadge() {
    final ha = double.tryParse(_superficieCtrl.text) ?? 0;
    return Text(
      '${(ha * 10000).toStringAsFixed(0)} م²',
      style: const TextStyle(
        fontSize: 11,
        color: AppColors.sage,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildFormCard({
    required String label,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.backgroundSoft),
        boxShadow: [
          BoxShadow(
            color: AppColors.forest.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.8,
              ),
            ),
            if (trailing != null) ...[const Spacer(), trailing],
          ]),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _buildMainButton() {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.sage, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.forest.withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _loading ? null : _calculate,
          borderRadius: BorderRadius.circular(18),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.science_outlined, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Text(
                  'احسب توصية التسميد',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withOpacity(0.2)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _error,
            style: const TextStyle(fontSize: 12, color: AppColors.danger),
          ),
        ),
      ]),
    );
  }

  // ============================================================
  // 🌿 TAB 2 – Result
  // ============================================================
  Widget _buildResultTab() {
    if (_result == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.mint.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(
                  child: Icon(Icons.science_outlined,
                      size: 40, color: AppColors.sage)),
            ),
            const SizedBox(height: 20),
            const Text(
              'لا توجد نتائج بعد',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecond,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'أدخل معلوماتك واضغط احسب',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => setState(() => _tabIndex = 0),
              icon: const Icon(Icons.edit_note_rounded, color: AppColors.sage),
              label: const Text(
                'اذهب للإدخال',
                style: TextStyle(
                    color: AppColors.sage, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    final r          = _result!;
    final riskColor  = AppColors.riskColor(r.riskLevel ?? '');
    final superficie = double.tryParse(_superficieCtrl.text) ?? 1.0;

    return FadeTransition(
      opacity: _resultFade,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        children: [
          _buildResultBanner(r, riskColor),
          const SizedBox(height: 14),
          _buildQuantityCard(r, riskColor, superficie),
          const SizedBox(height: 12),
          _buildStageCard(r),
          const SizedBox(height: 12),
          if (r.nutrients != null && r.nutrients!.isNotEmpty) ...[
            _buildNutrientsCard(r),
            const SizedBox(height: 12),
          ],
          if (r.fertilizers != null && r.fertilizers!.isNotEmpty) ...[
            _buildFertilizersCard(r),
            const SizedBox(height: 12),
          ],
          if (r.irrigationAmount != null) ...[
            _buildIrrigationCard(r),
            const SizedBox(height: 12),
          ],
          if (r.alerts != null && r.alerts!.isNotEmpty) ...[
            _buildAlertsCard(r),
            const SizedBox(height: 12),
          ],
          if (r.tips != null && r.tips!.isNotEmpty) ...[
            _buildTipsCard(r),
          ],
        ],
      ),
    );
  }

  Widget _buildResultBanner(FertilizationResult r, Color riskColor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 14,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                r.riskLevel?.isEmpty ?? true ? 'تحليل مكتمل' : r.riskLevel!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const Spacer(),
            Text(
              DateFormat('dd MMM yyyy', 'fr').format(DateTime.now()),
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ]),
          const SizedBox(height: 14),
          Text(
            r.crop ?? _selectedCurrentCulture,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              fontFamily: 'Georgia',
            ),
          ),
          const SizedBox(height: 5),
          Row(children: [
            const Icon(Icons.location_on, color: Colors.white60, size: 14),
            const SizedBox(width: 3),
            Text(
              r.wilaya ?? _selectedWilaya,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildQuantityCard(
      FertilizationResult r, Color riskColor, double superficie) {
    return _ResultCard(
      title: 'الكمية الموصى بها',
      icon: Icons.science_outlined,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: riskColor.withOpacity(0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: riskColor.withOpacity(0.15)),
          ),
          child: Row(children: [
            Expanded(
              child: Column(children: [
                Text(
                  r.totalKgHa?.toStringAsFixed(1) ?? '—',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: riskColor,
                    fontFamily: 'Georgia',
                    height: 1,
                  ),
                ),
                Text(
                  'كغ/هكتار',
                  style: TextStyle(
                      fontSize: 12, color: riskColor.withOpacity(0.7)),
                ),
              ]),
            ),
            Container(
                width: 1, height: 55, color: riskColor.withOpacity(0.2)),
            Expanded(
              child: Column(children: [
                Text(
                  '${r.totalKg?.toStringAsFixed(1) ?? '—'} كغ',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: riskColor,
                    fontFamily: 'Georgia',
                    height: 1,
                  ),
                ),
                Text(
                  'المجموع (${superficie.toStringAsFixed(1)} هك)',
                  style: TextStyle(
                      fontSize: 11, color: riskColor.withOpacity(0.7)),
                ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildStageCard(FertilizationResult r) {
    final prog = r.stageProgress ?? 0;
    return _ResultCard(
      title: 'مرحلة النمو',
      icon: Icons.grass_outlined,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(
              r.stageName ?? '—',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
          ),
          Text(
            '${prog.toStringAsFixed(0)}%',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.sage),
          ),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: prog / 100,
            minHeight: 9,
            backgroundColor: AppColors.backgroundSoft,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.sage),
          ),
        ),
        const SizedBox(height: 12),
        if (r.daysElapsed != null)
          _InfoRow(
              label: 'الأيام المنقضية',
              value: '${r.daysElapsed} يوم',
              icon: Icons.calendar_today_outlined),
        if (r.daysRemaining != null)
          _InfoRow(
              label: 'الأيام المتبقية',
              value: '${r.daysRemaining} يوم',
              icon: Icons.hourglass_bottom_rounded),
        if (r.soilType != null)
          _InfoRow(
              label: 'نوع التربة',
              value: r.soilType!,
              icon: Icons.layers_outlined),
      ]),
    );
  }

  Widget _buildNutrientsCard(FertilizationResult r) {
    return _ResultCard(
      title: 'الاحتياجات الغذائية',
      icon: Icons.biotech_outlined,
      child: Column(
        children: r.nutrients!.entries.map((e) {
          final val       = e.value as Map;
          final need      = val['need'] ?? 0;
          final available = val['available'] ?? 0;
          final isOk      = val['ok'] ?? false;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Expanded(
                  flex: 2,
                  child: Text(e.key,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary))),
              Expanded(
                  child: Text('${(need as num).toInt()}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecond))),
              Expanded(
                  child: Text('${(available as num).toInt()}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isOk ? AppColors.success : AppColors.warning))),
              Icon(
                isOk ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                color: isOk ? AppColors.success : AppColors.warning,
                size: 16,
              ),
            ]),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFertilizersCard(FertilizationResult r) {
    return _ResultCard(
      title: 'الأسمدة المقترحة',
      icon: Icons.opacity_outlined,
      child: Column(
        children: r.fertilizers!.map((f) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.backgroundSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(f['name'] ?? '',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.sage.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${f['kgHa']} كغ/هك',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.sage),
                    ),
                  ),
                ]),
                if (f['how'] != null) ...[
                  const SizedBox(height: 6),
                  _InfoRow(
                      label: 'الطريقة',
                      value: f['how'].toString(),
                      icon: Icons.water_drop_outlined),
                ],
                if (f['when'] != null)
                  _InfoRow(
                      label: 'التوقيت',
                      value: f['when'].toString(),
                      icon: Icons.schedule_outlined),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildIrrigationCard(FertilizationResult r) {
    return _ResultCard(
      title: 'توصية الري',
      icon: Icons.water_drop_rounded,
      child: _InfoRow(
        label: 'الكمية اليومية',
        value: '${r.irrigationAmount} مم/يوم',
        icon: Icons.water_drop_outlined,
      ),
    );
  }

  Widget _buildAlertsCard(FertilizationResult r) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.danger.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.danger, size: 18),
            const SizedBox(width: 8),
            const Text('تنبيهات',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.danger)),
          ]),
          const SizedBox(height: 10),
          ...r.alerts!.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Container(
                      margin: const EdgeInsets.only(top: 5),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: AppColors.danger, shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(a,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              height: 1.5))),
                ]),
              )),
        ],
      ),
    );
  }

  Widget _buildTipsCard(FertilizationResult r) {
    return _ResultCard(
      title: 'نصائح زراعية',
      icon: Icons.lightbulb_outline_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: r.tips!.map((tip) {
          final title = tip['title']?.toString() ?? 'نصيحة';
          final desc  = tip['description']?.toString() ?? tip.toString();
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  margin: const EdgeInsets.only(top: 5),
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                      color: AppColors.mint, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  if (desc.isNotEmpty)
                    Text(desc,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecond,
                            fontStyle: FontStyle.italic,
                            height: 1.5)),
                ]),
              ),
            ]),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // 📜 TAB 3 – History
  // ============================================================
  Widget _buildHistoryTab() {
    if (_farmerId == null) {
      return const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.lock_outline_rounded, size: 52, color: AppColors.textMuted),
          SizedBox(height: 16),
          Text('تسجيل الدخول مطلوب',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecond)),
          SizedBox(height: 8),
          Text('سجّل دخولك لرؤية السجل',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ]),
      );
    }

    return RefreshIndicator(
      color: AppColors.sage,
      onRefresh: _loadHistory,
      child: _loadingHistory
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.sage))
          : _history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: const BoxDecoration(
                            color: AppColors.sand, shape: BoxShape.circle),
                        child: const Center(
                            child: Icon(Icons.history_rounded,
                                size: 40, color: AppColors.textMuted)),
                      ),
                      const SizedBox(height: 18),
                      const Text('لا يوجد سجل بعد',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecond)),
                      const SizedBox(height: 8),
                      const Text('سيتم الحفظ تلقائياً بعد كل حساب',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  children: [
                    const SizedBox(height: 8),
                    ..._history.map((r) => _HistoryCard(
                          record: r,
                          onTap: () => _showHistoryDetail(r),
                          onDelete: () => _deleteHistoryRecord(r.id),
                        )),
                  ],
                ),
    );
  }

  void _showHistoryDetail(FertilizationRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HistoryDetailSheet(record: record),
    );
  }

  Future<void> _deleteHistoryRecord(String recordId) async {
    if (_farmerId == null) return;
    try {
      await _firestore
          .collection('farmers')
          .doc(_farmerId)
          .collection('fertilization_history')
          .doc(recordId)
          .delete();
      if (!mounted) return;
      setState(() => _history.removeWhere((r) => r.id == recordId));
    } catch (e) {
      debugPrint('Firestore delete error: $e');
    }
  }
}

// ============================================================
// 🔷 SHARED WIDGETS
// ============================================================
class _ResultCard extends StatelessWidget {
  final String   title;
  final IconData icon;
  final Widget   child;
  const _ResultCard(
      {required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.backgroundSoft),
        boxShadow: [
          BoxShadow(
            color: AppColors.forest.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.sage.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                Icon(icon, size: 16, color: AppColors.sage),
          ),
          const SizedBox(width: 10),
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
        ]),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String  label;
  final String  value;
  final IconData icon;
  const _InfoRow(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 14, color: AppColors.sage),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecond)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
      ]),
    );
  }
}

// ============================================================
// 📜 HISTORY CARD
// ============================================================
class _HistoryCard extends StatelessWidget {
  final FertilizationRecord record;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _HistoryCard(
      {required this.record, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final riskColor =
        AppColors.riskColor(record.riskLevel);
    final dateStr =
        DateFormat('dd MMM yyyy – HH:mm', 'fr').format(record.dateCalcul);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.backgroundSoft),
          boxShadow: [
            BoxShadow(
              color: AppColors.forest.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(children: [
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: riskColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(
                    record.culture,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${record.totalKg.toStringAsFixed(1)} كغ',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary),
                    ),
                  ),
                ]),
                const SizedBox(height: 5),
                Row(children: [
                  const Icon(Icons.location_on_outlined,
                      size: 11, color: AppColors.textMuted),
                  const SizedBox(width: 2),
                  Text(record.wilaya,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(width: 10),
                  const Icon(Icons.crop_square_outlined,
                      size: 11, color: AppColors.textMuted),
                  const SizedBox(width: 2),
                  Text('${record.superficie.toStringAsFixed(1)} هك',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                ]),
                const SizedBox(height: 4),
                Text(dateStr,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: Colors.redAccent, size: 18),
            onPressed: onDelete,
          ),
          const Icon(Icons.chevron_right,
              color: AppColors.textMuted, size: 18),
        ]),
      ),
    );
  }
}

// ============================================================
// 📋 HISTORY DETAIL SHEET
// ============================================================
class _HistoryDetailSheet extends StatelessWidget {
  final FertilizationRecord record;
  const _HistoryDetailSheet({required this.record});

  @override
  Widget build(BuildContext context) {
    final riskColor = AppColors.riskColor(record.riskLevel);

    return Container(
      height: MediaQuery.of(context).size.height * 0.86,
      decoration: const BoxDecoration(
        color: AppColors.backgroundSoft,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          width: 38,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.75)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(record.culture,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Georgia')),
                  const SizedBox(height: 5),
                  Text(
                    record.riskLevel.isEmpty ? '—' : record.riskLevel,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMMM yyyy – HH:mm', 'fr')
                        .format(record.dateCalcul),
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              _DetailSection(title: 'الكمية الموصى بها', rows: [
                ('الكمية الإجمالية',
                    '${record.totalKg.toStringAsFixed(1)} كغ'),
                ('كغ لكل هكتار',
                    '${record.totalKgHa.toStringAsFixed(1)} كغ/هك'),
              ]),
              const SizedBox(height: 10),
              _DetailSection(title: 'معلومات القطعة', rows: [
                ('الولاية', record.wilaya),
                ('المحصول الحالي', record.culture),
                ('المحصول السابق', record.previousCulture),
                ('المساحة',
                    '${record.superficie.toStringAsFixed(2)} هكتار'),
                ('تاريخ الزراعة',
                    DateFormat('dd/MM/yyyy').format(record.datePlantation)),
              ]),
              const SizedBox(height: 10),
              _DetailSection(title: 'مرحلة النمو', rows: [
                ('المرحلة', record.stageName),
                ('التقدم', '${record.progression}%'),
              ]),
            ],
          ),
        ),
      ]),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String                   title;
  final List<(String, String)>   rows;
  const _DetailSection({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.backgroundSoft),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        ...rows.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(children: [
                Expanded(
                    child: Text(r.$1,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecond))),
                Text(r.$2,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ]),
            )),
      ]),
    );
  }
}

// ============================================================
// 🌿 CULTURE PICKER SHEET
// ============================================================
class _CulturePickerSheet extends StatefulWidget {
  final String                    selected;
  final Map<String, List<String>> categories;
  const _CulturePickerSheet(
      {required this.selected, required this.categories});
  @override
  State<_CulturePickerSheet> createState() => _CulturePickerSheetState();
}

class _CulturePickerSheetState extends State<_CulturePickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = <String, List<String>>{};
    for (final e in widget.categories.entries) {
      final items = e.value
          .where((c) => c.toLowerCase().contains(_search.toLowerCase()))
          .toList();
      if (items.isNotEmpty) filtered[e.key] = items;
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppColors.backgroundSoft,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          width: 38,
          height: 4,
          decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2)),
        ),
        const Text('اختر المحصول',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.backgroundSoft),
            ),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'ابحث عن محصول...',
                hintStyle: TextStyle(color: AppColors.textMuted),
                prefixIcon:
                    Icon(Icons.search, color: AppColors.sage, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: filtered.entries.map((e) {
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(e.key,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.sage,
                              letterSpacing: 0.5)),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: e.value.map((c) {
                        final isSelected = c == widget.selected;
                        return GestureDetector(
                          onTap: () => Navigator.pop(context, c),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? const LinearGradient(
                                      colors: [
                                        AppColors.sage,
                                        AppColors.primaryDark,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isSelected ? null : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.sage
                                    : AppColors.backgroundSoft,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.sage.withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Text(
                              c,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 6),
                  ]);
            }).toList(),
          ),
        ),
      ]),
    );
  }
}