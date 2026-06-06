import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// ═══════════════════════════════════════════════════════════════════
// 🎨 DESIGN SYSTEM (مطابق لصفحة الري والتسميد)
// ═══════════════════════════════════════════════════════════════════

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
  static const Color border         = Color(0xFFE0D5C0);
  static const Color textPrimary    = Color(0xFF1A2B10);
  static const Color textSecond     = Color(0xFF5A6B4A);
  static const Color textLight      = Color(0xFFF5F1E8);
  static const Color textMuted      = Color(0xFF9EA88A);
  static const Color primary        = Color(0xFF55833D);
  static const Color primaryDark    = Color(0xFF3A6E1E);
  static const Color success        = Color(0xFF3D7A3D);
  static const Color warning        = Color(0xFFB8860B);
  static const Color danger         = Color(0xFFC0392B);
  static const Color info           = Color(0xFF1B6CA8);
  static const Color gold           = Color(0xFFDDA811);
}

// ═══════════════════════════════════════════════════════════════════
// 🚜 TRACTOR PAINTER (نفس المستخدم في الري والتسميد)
// ═══════════════════════════════════════════════════════════════════

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
    final alpha1 = (0.6 * (1 - smokeProgress)).clamp(0.0, 1.0);
    paint.color = Color.fromRGBO(184, 201, 168, alpha1);
    canvas.drawCircle(
      Offset(102 - smokeProgress * 12, 22 - smokeProgress * 18),
      5 * (1 + smokeProgress * 0.8),
      paint,
    );
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
    paint.color = const Color(0xFF55833D);
    final body = Path()
      ..moveTo(55, 70)..lineTo(55, 52)
      ..quadraticBezierTo(55, 44, 63, 44)
      ..lineTo(95, 44)..quadraticBezierTo(112, 44, 112, 60)
      ..lineTo(112, 70)..close();
    canvas.drawPath(body, paint);
    paint.color = const Color(0xFF4A7535);
    final cabin = Path()
      ..moveTo(57, 44)..lineTo(57, 24)
      ..quadraticBezierTo(57, 16, 67, 16)
      ..lineTo(88, 16)..quadraticBezierTo(96, 16, 96, 24)
      ..lineTo(96, 44)..close();
    canvas.drawPath(cabin, paint);
    paint.color = const Color(0xD9C8DFF0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(61, 20, 30, 20), const Radius.circular(3)),
      paint,
    );
    paint.color = const Color(0xB3A8CBEA);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(63, 22, 12, 16), const Radius.circular(2)),
      paint,
    );
    paint.color = const Color(0xFF524133);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(97, 28, 4, 16), const Radius.circular(2)),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(97, 25, 6, 5), const Radius.circular(3)),
      paint,
    );
    paint.color = const Color(0xFF3D6B2B);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(100, 50, 10, 18), const Radius.circular(2)),
      paint,
    );
    final grill = Paint()
      ..color = const Color(0xB3E3EED4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(101, 54), const Offset(109, 54), grill);
    canvas.drawLine(const Offset(101, 58), const Offset(109, 58), grill);
    canvas.drawLine(const Offset(101, 62), const Offset(109, 62), grill);
    paint.color = const Color(0xFFDDA811);
    canvas.drawCircle(const Offset(110, 47), 3.5, paint);
    paint.color = const Color(0x80FFFFFF);
    canvas.drawCircle(const Offset(110, 47), 1.5, paint);
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

// ═══════════════════════════════════════════════════════════════════
// 🔵 ANIMATED DOTS TEXT
// ═══════════════════════════════════════════════════════════════════

class _AnimatedDotsText extends StatefulWidget {
  final String text;
  final Color color;
  const _AnimatedDotsText({required this.text, required this.color});

  @override
  State<_AnimatedDotsText> createState() => _AnimatedDotsTextState();
}

class _AnimatedDotsTextState extends State<_AnimatedDotsText>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) => AnimationController(
      duration: const Duration(milliseconds: 1200), vsync: this,
    ));
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
    _animations = _controllers.map((c) => Tween<double>(begin: 0.2, end: 1.0)
        .animate(CurvedAnimation(parent: c, curve: Curves.easeInOut))).toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.text, style: TextStyle(
          fontSize: 14, color: widget.color, fontWeight: FontWeight.w600, letterSpacing: 0.3,
        )),
        const SizedBox(width: 2),
        ...List.generate(3, (i) => AnimatedBuilder(
          animation: _animations[i],
          builder: (_, __) => Opacity(
            opacity: _animations[i].value,
            child: Text('.', style: TextStyle(fontSize: 16, color: widget.color, fontWeight: FontWeight.w700)),
          ),
        )),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// 📊 DATA MODELS
// ═══════════════════════════════════════════════════════════════════

class Wilaya {
  final String name, region, soil, rainfall;
  final int code;
  Wilaya({required this.name, required this.code, required this.region, required this.soil, required this.rainfall});
  factory Wilaya.fromJson(Map<String, dynamic> j) => Wilaya(
    name: j['name'], code: j['code'], region: j['region'], soil: j['soil'], rainfall: j['rainfall']);
}

class CropRecommendation {
  final String name, category, difficulty, waterNeed, plantMonth, harvestMonth, timingType, timingMsg, timingIcon;
  final int score, ruleScore, mlScore, cycleDays, resolveYear, pricePerTon;
  final double yieldTotal, yieldPerHa;
  final bool exportable, soilMatch, rotationValid;
  final String rotationMsg;
  final List<String> diseases;
  final List<Map<String, String>> explanation;
  final Map<String, int> breakdown;

  CropRecommendation({
    required this.name, required this.score, required this.ruleScore, required this.mlScore,
    required this.yieldTotal, required this.yieldPerHa, required this.cycleDays,
    required this.category, required this.difficulty, required this.waterNeed,
    required this.plantMonth, required this.harvestMonth, required this.resolveYear,
    required this.timingType, required this.timingMsg, required this.timingIcon,
    required this.rotationValid, required this.rotationMsg, required this.diseases,
    required this.exportable, required this.pricePerTon, required this.soilMatch,
    required this.explanation, required this.breakdown,
  });
}

// ═══════════════════════════════════════════════════════════════════
// 🏗️ CROP PREDICTION SCREEN
// ═══════════════════════════════════════════════════════════════════

class CropPredictionScreen extends StatefulWidget {
  const CropPredictionScreen({super.key});

  @override
  State<CropPredictionScreen> createState() => _CropPredictionScreenState();
}

class _CropPredictionScreenState extends State<CropPredictionScreen>
    with TickerProviderStateMixin {

  // Form state
  String? _selectedWilaya;
  double _area = 1.0;
  DateTime? _selectedDate;
  String? _prevCrop;
  String? _category;
  String _waterLevel = 'متوسطة';
  String _goal = 'متوازن';
  String _experience = 'متوسط';

  List<Wilaya> _wilayas = [];
  List<String> _crops = [];
  List<CropRecommendation> _recommendations = [];
  Map<String, dynamic>? _resultMeta;
  bool _loading = false;
  bool _hasResults = false;
  bool _saving = false;
  String? _errorMsg;

  // Tractor animations
  late AnimationController _floatCtrl, _wheelCtrl, _smokeCtrl, _progressCtrl;
  late Animation<double> _floatAnim, _wheelAnim, _smokeAnim, _progressAnim;

  final List<String> _categories = ['حبوب', 'خضروات', 'بقوليات', 'فاكهة', 'صناعية', 'أعلاف', 'توابل'];
  final List<String> _months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadData();
    _selectedDate = DateTime.now();
  }

  void _initAnimations() {
    _floatCtrl = AnimationController(duration: const Duration(milliseconds: 1800), vsync: this)..repeat(reverse: true);
    _wheelCtrl = AnimationController(duration: const Duration(milliseconds: 900), vsync: this)..repeat();
    _smokeCtrl = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this)..repeat();
    _progressCtrl = AnimationController(duration: const Duration(seconds: 22), vsync: this);
    _floatAnim = Tween<double>(begin: 0, end: -12).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
    _wheelAnim = Tween<double>(begin: 0, end: 2 * pi).animate(CurvedAnimation(parent: _wheelCtrl, curve: Curves.linear));
    _smokeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _smokeCtrl, curve: Curves.easeOut));
    _progressAnim = Tween<double>(begin: 0, end: 0.9).animate(CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOut));
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _errorMsg = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final results = await Future.wait([
        http.get(Uri.parse('https://recommandation.onrender.com/wilayas')),
        http.get(Uri.parse('https://recommandation.onrender.com/crops')),
      ]);
      if (results[0].statusCode == 200) {
        _wilayas = (json.decode(results[0].body) as List).map((j) => Wilaya.fromJson(j)).toList();
      }
      if (results[1].statusCode == 200) {
        _crops = List<String>.from(json.decode(results[1].body));
      }
      _selectedWilaya = prefs.getString('last_wilaya') ?? (_wilayas.isNotEmpty ? _wilayas.first.name : null);
      _area = prefs.getDouble('last_area') ?? 1.0;
      setState(() { _loading = false; });
    } catch (e) {
      setState(() { _loading = false; _errorMsg = e.toString(); });
    }
  }

  Future<void> _generateRecommendations() async {
    if (_selectedWilaya == null) {
      _showSnackBar('الرجاء اختيار الولاية', error: true);
      return;
    }
    if (_area <= 0) {
      _showSnackBar('المساحة غير صحيحة', error: true);
      return;
    }
    if (_selectedDate == null) {
      _showSnackBar('الرجاء اختيار تاريخ الزراعة', error: true);
      return;
    }

    setState(() { _loading = true; _hasResults = false; });
    _progressCtrl.forward();

    try {
      final response = await http.post(
        Uri.parse('https://recommandation.onrender.com/recommend'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'wilaya': _selectedWilaya,
          'area': _area,
          'plant_month': _selectedDate!.month - 1,
          'prev_crop': _prevCrop ?? '',
          'category': _category ?? '',
          'water': _waterLevel,
          'goal': _goal,
          'experience': _experience,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _resultMeta = {
          'wilaya': data['wilaya'], 'region': data['region'], 'soil': data['soil'],
          'rainfall': data['rainfall'], 'plant_month_name': data['plant_month_name'],
          'area': _area, 'water': _waterLevel, 'goal': _goal, 'experience': _experience,
          'prev_crop': _prevCrop ?? '',
        };
        _recommendations = (data['top_crops'] as List).map((c) => CropRecommendation(
          name: c['name'], score: c['score'], ruleScore: c['rule_score'], mlScore: c['ml_score'],
          yieldTotal: (c['yield_total'] as num).toDouble(), yieldPerHa: (c['yield_per_ha'] as num).toDouble(),
          cycleDays: c['cycle_days'], category: c['category'], difficulty: c['difficulty'],
          waterNeed: c['water_need'], plantMonth: c['plant_month'], harvestMonth: c['harvest_month'],
          resolveYear: c['resolve_year'], timingType: c['timing']['type'], timingMsg: c['timing']['msg'],
          timingIcon: c['timing']['icon'], rotationValid: c['rotation']['valid'], rotationMsg: c['rotation']['msg'],
          diseases: List<String>.from(c['diseases'] ?? []), exportable: c['exportable'] ?? false,
          pricePerTon: c['price_dzd_per_ton'] ?? 0, soilMatch: c['soil_match'] ?? false,
          explanation: (c['explanation'] as List).map((e) => {'type': e['type'].toString(), 'text': e['text'].toString()}).toList(),
          breakdown: Map<String, int>.from(c['breakdown']),
        )).toList();
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_wilaya', _selectedWilaya!);
        await prefs.setDouble('last_area', _area);
        
        setState(() { _loading = false; _hasResults = true; });
      } else {
        throw Exception('خطأ في الخادم: ${response.statusCode}');
      }
    } catch (e) {
      setState(() { _loading = false; _errorMsg = e.toString(); });
      _showSnackBar(e.toString(), error: true);
    }
    _progressCtrl.animateTo(1.0);
  }

  Future<void> _saveCropToFirestore(CropRecommendation crop) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('يرجى تسجيل الدخول أولاً', error: true);
      return;
    }

    setState(() { _saving = true; });

    try {
      final prefs = await SharedPreferences.getInstance();
      final farmLat = prefs.getDouble('farm_lat') ?? 36.9;
      final farmLng = prefs.getDouble('farm_lng') ?? 7.76;
      final locationName = prefs.getString('farm_location_name') ?? _selectedWilaya ?? 'غير محدد';
      final cropDocId = DateTime.now().millisecondsSinceEpoch.toString();

      final cropDoc = {
        'crop_id': 'ai_recommended_${crop.name.replaceAll(' ', '_').toLowerCase()}',
        'crop_type': crop.name,
        'category': crop.category,
        'location_name': locationName,
        'farm_lat': farmLat,
        'farm_lng': farmLng,
        'farm_area': _area,
        'planting_date': _selectedDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'plant_month': crop.plantMonth,
        'harvest_month': crop.harvestMonth,
        'soil_type': _resultMeta?['soil'] ?? 'طينية',
        'irrigation_type': _waterLevel == 'عالية' ? 'بالتنقيط' : (_waterLevel == 'منخفضة' ? 'سطحي' : 'متنوع'),
        'cycle_days': crop.cycleDays,
        'score': crop.score,
        'yield_per_ha': crop.yieldPerHa,
        'expected_yield': crop.yieldTotal,
        'difficulty': crop.difficulty,
        'water_need': crop.waterNeed,
        'exportable': crop.exportable,
        'price_per_ton': crop.pricePerTon,
        'setup_completed': false,
        'is_active': false,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'source': 'ai_recommendation',
        'wilaya': _selectedWilaya,
        'goal': _goal,
        'experience': _experience,
      };

      await FirebaseFirestore.instance
          .collection('farmers')
          .doc(user.uid)
          .collection('crops')
          .doc(cropDocId)
          .set(cropDoc);

      setState(() { _saving = false; });
      
      if (mounted) {
        _showSnackBar('✅ تم حفظ "${crop.name}" في مزرعتك بنجاح!');
        
        final goHome = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: AppColors.surface,
            title: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.check_circle, color: AppColors.success, size: 24),
                ),
                const SizedBox(width: 12),
                const Text('تم الحفظ بنجاح', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
            content: Text(
              'تم إضافة "${crop.name}" إلى مزرعتك بنجاح 🌾\n\nيمكنك الآن رؤيته في الصفحة الرئيسية.',
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('البقاء هنا', style: TextStyle(color: AppColors.textMuted)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('الذهاب للرئيسية'),
              ),
            ],
          ),
        );
        
        if (goHome == true && mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() { _saving = false; });
      _showSnackBar('❌ خطأ في الحفظ: $e', error: true);
    }
  }

  void _showSnackBar(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.danger : AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

  void _reset() {
    setState(() {
      _hasResults = false;
      _recommendations = [];
      _selectedDate = DateTime.now();
      _prevCrop = null;
      _category = null;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('ar', 'DZ'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.sage,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
            dialogBackgroundColor: AppColors.cream,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _floatCtrl.dispose(); _wheelCtrl.dispose(); _smokeCtrl.dispose(); _progressCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSoft, // ✅ خلفية خضراء فاتحة
      body: Stack(
        children: [
          if (_loading || _saving) _buildTractorOverlay(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _hasResults ? _buildResultsTab() : _buildInputForm(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppColors.sage, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32),
        ),
        boxShadow: [BoxShadow(color: Color(0x30000000), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppColors.mint.withOpacity(0.18),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.mint.withOpacity(0.3)),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textLight),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('التوصيات الذكية',
                    style: TextStyle(fontFamily: 'Georgia', fontSize: 20,
                        fontWeight: FontWeight.w700, color: AppColors.textLight)),
                Text('أفضل المحاصيل حسب ظروفك',
                    style: TextStyle(fontSize: 12, color: AppColors.mint.withOpacity(0.85))),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildTractorOverlay() {
    return Positioned.fill(
      child: Container(
        color: const Color(0xFF0F1A0F).withOpacity(0.88),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _floatCtrl,
                builder: (_, child) => Transform.translate(offset: Offset(0, _floatAnim.value), child: child),
                child: Column(
                  children: [
                    SizedBox(
                      width: 200, height: 130,
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
                    AnimatedBuilder(
                      animation: _floatCtrl,
                      builder: (_, __) {
                        final t = _floatCtrl.value;
                        return Transform.scale(
                          scaleX: 1.0 - t * 0.25,
                          child: Opacity(
                            opacity: (0.5 - t * 0.25).clamp(0.1, 0.5),
                            child: Container(
                              width: 130, height: 10,
                              decoration: BoxDecoration(
                                color: AppColors.sage,
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
                      text: _saving ? 'جاري حفظ المحصول...' : 'جاري تحليل البيانات',
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
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.sage),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Column(
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 20),
          _buildInfoCard(),
          const SizedBox(height: 24),
          _buildCalculateButton(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.sage, AppColors.primaryDark],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.sage.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('مرحباً بك، فلاح',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 5),
                Text('أجب على الأسئلة التالية\nلنحسب لك أفضل 5 محاصيل تناسب ظروفك',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.forest.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          _buildFormItem(
            icon: Icons.location_on_outlined,
            title: 'الولاية',
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedWilaya,
                isExpanded: true,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                dropdownColor: AppColors.surface,
                icon: const Icon(Icons.expand_more_rounded, color: AppColors.sage),
                items: _wilayas.map((w) => DropdownMenuItem(value: w.name, child: Text(w.name))).toList(),
                onChanged: (v) => setState(() => _selectedWilaya = v),
              ),
            ),
          ),
          _buildDivider(),
          _buildFormItem(
            icon: Icons.category_outlined,
            title: 'فئة المحصول',
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _category,
                hint: const Text('جميع الفئات', style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
                isExpanded: true,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                dropdownColor: AppColors.surface,
                icon: const Icon(Icons.expand_more_rounded, color: AppColors.sage),
                items: [
                  const DropdownMenuItem(value: null, child: Text('جميع الفئات')),
                  ..._categories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                ],
                onChanged: (v) => setState(() => _category = v),
              ),
            ),
          ),
          _buildDivider(),
          _buildFormItem(
            icon: Icons.history_toggle_off,
            title: 'المحصول السابق',
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _prevCrop,
                hint: const Text('لا يوجد', style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
                isExpanded: true,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                dropdownColor: AppColors.surface,
                icon: const Icon(Icons.expand_more_rounded, color: AppColors.sage),
                items: [
                  const DropdownMenuItem(value: null, child: Text('لا يوجد')),
                  ..._crops.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                ],
                onChanged: (v) => setState(() => _prevCrop = v),
              ),
            ),
          ),
          _buildDivider(),
          _buildFormItem(
            icon: Icons.calendar_month_outlined,
            title: 'تاريخ الزراعة',
            child: InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedDate != null
                            ? DateFormat('dd MMMM yyyy', 'fr').format(_selectedDate!)
                            : 'اختر التاريخ',
                        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      ),
                    ),
                    const Icon(Icons.calendar_today_outlined, color: AppColors.sage, size: 18),
                  ],
                ),
              ),
            ),
          ),
          _buildDivider(),
          _buildFormItem(
            icon: Icons.crop_square_outlined,
            title: 'المساحة (هكتار)',
            child: TextField(
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
                hintText: 'مثال: 2.5',
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
              onChanged: (v) => _area = double.tryParse(v) ?? 0,
            ),
          ),
          _buildDivider(),
          _buildFormItem(
            icon: Icons.water_drop_outlined,
            title: 'توفر المياه',
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _waterLevel,
                isExpanded: true,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                dropdownColor: AppColors.surface,
                icon: const Icon(Icons.expand_more_rounded, color: AppColors.sage),
                items: const [
                  DropdownMenuItem(value: 'منخفضة جداً', child: Text('منخفضة جداً')),
                  DropdownMenuItem(value: 'منخفضة', child: Text('منخفضة')),
                  DropdownMenuItem(value: 'متوسطة', child: Text('متوسطة')),
                  DropdownMenuItem(value: 'عالية', child: Text('عالية')),
                ],
                onChanged: (v) => setState(() => _waterLevel = v!),
              ),
            ),
          ),
          _buildDivider(),
          _buildFormItem(
            icon: Icons.track_changes_outlined,
            title: 'الهدف',
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _goal,
                isExpanded: true,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                dropdownColor: AppColors.surface,
                icon: const Icon(Icons.expand_more_rounded, color: AppColors.sage),
                items: const [
                  DropdownMenuItem(value: 'اكتفاء', child: Text('اكتفاء ذاتي')),
                  DropdownMenuItem(value: 'تجاري', child: Text('تجاري')),
                  DropdownMenuItem(value: 'متوازن', child: Text('متوازن')),
                  DropdownMenuItem(value: 'تصدير', child: Text('تصدير')),
                ],
                onChanged: (v) => setState(() => _goal = v!),
              ),
            ),
          ),
          _buildDivider(),
          _buildFormItem(
            icon: Icons.school_outlined,
            title: 'الخبرة',
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _experience,
                isExpanded: true,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                dropdownColor: AppColors.surface,
                icon: const Icon(Icons.expand_more_rounded, color: AppColors.sage),
                items: const [
                  DropdownMenuItem(value: 'مبتدئ', child: Text('مبتدئ (أقل من 3 سنوات)')),
                  DropdownMenuItem(value: 'متوسط', child: Text('متوسط (3-10 سنوات)')),
                  DropdownMenuItem(value: 'خبير', child: Text('خبير (أكثر من 10 سنوات)')),
                ],
                onChanged: (v) => setState(() => _experience = v!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormItem({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.sage.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.sage),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: AppColors.textMuted, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() => const Divider(height: 0, thickness: 0.5, color: AppColors.border);

  Widget _buildCalculateButton() {
    return Container(
      height: 58,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.sage, AppColors.primaryDark],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.forest.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _generateRecommendations,
          borderRadius: BorderRadius.circular(18),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome_outlined, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Text('احصل على التوصيات',
                    style: TextStyle(color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.w700, letterSpacing: 0.2)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // RESULTS TAB
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildResultsTab() {
    final now = DateTime.now();
    final monthName = _selectedDate != null ? _months[_selectedDate!.month - 1] : '';
    final year = _selectedDate?.year ?? now.year;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryDark, AppColors.sage],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 5))],
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
                  child: const Text('أفضل التوصيات',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                ),
                const Spacer(),
                Text(DateFormat('dd MMM yyyy', 'fr').format(now),
                    style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ]),
              const SizedBox(height: 14),
              Text(_selectedWilaya ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 22,
                      fontWeight: FontWeight.w800, fontFamily: 'Georgia')),
              const SizedBox(height: 5),
              Row(children: [
                const Icon(Icons.calendar_month_outlined, color: Colors.white60, size: 14),
                const SizedBox(width: 3),
                Text('زراعة: $monthName $year',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(width: 12),
                const Icon(Icons.crop_square_outlined, color: Colors.white60, size: 14),
                const SizedBox(width: 3),
                Text('${_area.toStringAsFixed(1)} هكتار',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ]),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
            itemCount: _recommendations.length,
            itemBuilder: (context, index) => _buildResultCard(_recommendations[index], index),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('بحث جديد'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.sage),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(CropRecommendation crop, int rank) {
    final rankColors = [AppColors.gold, Colors.grey.shade600, Colors.brown.shade400];
    final rankColor = rank < 3 ? rankColors[rank] : AppColors.sage;
    final isOptimal = crop.timingType == 'optimal';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.forest.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: rankColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: rankColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text('${rank + 1}',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: rankColor)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(crop.name,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.sage.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(crop.category,
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                        color: AppColors.sage)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isOptimal ? AppColors.success : AppColors.warning).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(crop.timingIcon, style: const TextStyle(fontSize: 10)),
                                    const SizedBox(width: 3),
                                    Text(crop.timingMsg,
                                        style: TextStyle(fontSize: 10, color: isOptimal ? AppColors.success : AppColors.warning)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: rankColor, width: 3),
                      ),
                      child: Center(
                        child: Text('${crop.score}%',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: rankColor)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (crop.rotationMsg.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: crop.rotationValid ? AppColors.success.withOpacity(0.08) : AppColors.danger.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(crop.rotationValid ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                            size: 14, color: crop.rotationValid ? AppColors.success : AppColors.danger),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(crop.rotationMsg,
                              style: TextStyle(fontSize: 11, color: crop.rotationValid ? AppColors.success : AppColors.danger,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatChip(Icons.agriculture_outlined, '${crop.yieldTotal.toStringAsFixed(1)} طن', 'الإنتاج'),
                    const SizedBox(width: 8),
                    _buildStatChip(Icons.schedule_outlined, '${crop.cycleDays} يوم', 'الدورة'),
                    const SizedBox(width: 8),
                    _buildStatChip(Icons.water_drop_outlined, crop.waterNeed, 'مياه'),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildStatChip(Icons.attach_money_outlined, '${(crop.pricePerTon / 1000).toStringAsFixed(0)}K دج/طن', 'السعر'),
                    const SizedBox(width: 8),
                    _buildStatChip(
                      crop.exportable ? Icons.flight_outlined : Icons.shopping_cart_outlined,
                      crop.exportable ? 'قابل للتصدير' : 'سوق محلي', '',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('تفاصيل التوصية',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      _buildDetailRow('التربة', crop.waterNeed, crop.soilMatch),
                      const SizedBox(height: 4),
                      _buildDetailRow('الصعوبة', crop.difficulty, false),
                      const SizedBox(height: 4),
                      _buildDetailRow('الحصاد', crop.harvestMonth, false),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: crop.diseases.map((d) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(d, style: TextStyle(fontSize: 10, color: AppColors.danger)),
                  )).toList(),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _saveCropToFirestore(crop),
                    icon: const Icon(Icons.bookmark_add_rounded, size: 18),
                    label: const Text('حفظ المحصول في مزرعتي', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sage,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.backgroundSoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 14, color: AppColors.sage),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            if (label.isNotEmpty)
              Text(label,
                  style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isMatch) {
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(fontSize: 11, color: AppColors.textSecond)),
        Expanded(
          child: Text(value,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: isMatch ? AppColors.success : AppColors.textPrimary)),
        ),
        if (isMatch)
          const Icon(Icons.check_circle, size: 12, color: AppColors.success),
      ],
    );
  }
}