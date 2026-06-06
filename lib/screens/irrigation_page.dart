// lib/screens/irrigation_page.dart
// 💧 نظام الري الذكي الجزائري
// ✅ Redesigned: clean icon-based cards, no emoji decorations, matches fertilization_screen style

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// ============================================================
// 🎨 DESIGN SYSTEM
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

  static Color urgenceColor(String urgence) {
    if (urgence.contains('FORTE') || urgence.contains('CRITIQUE')) return danger;
    if (urgence.contains('MODÉRÉE') || urgence.contains('NORMALE'))  return warning;
    if (urgence.contains('LÉGÈRE')) return earth;
    return success;
  }
}

// ============================================================
// 🌾 58 WILAYAS
// ============================================================
const List<String> kWilayas = [
  'Adrar','Chlef','Laghouat','Oum El Bouaghi','Batna',
  'Béjaïa','Biskra','Béchar','Blida','Bouira',
  'Tamanrasset','Tébessa','Tlemcen','Tiaret','Tizi Ouzou',
  'Alger','Djelfa','Jijel','Sétif','Saïda',
  'Skikda','Sidi Bel Abbès','Annaba','Guelma','Constantine',
  'Médéa','Mostaganem',"M'Sila",'Mascara','Ouargla',
  'Oran','El Bayadh','Illizi','Bordj Bou Arreridj','Boumerdès',
  'El Tarf','Tindouf','Tissemsilt','El Oued','Khenchela',
  'Souk Ahras','Tipaza','Mila','Aïn Defla','Naâma',
  'Aïn Témouchent','Ghardaïa','Relizane','Timimoun',
  'Bordj Badji Mokhtar','Ouled Djellal','Béni Abbès','In Salah',
  'In Guezzam','Touggourt','Djanet',"El M'Ghair",'El Menia',
];

const Map<String, List<String>> kCulturesByCategory = {
  'Céréales': ['Blé dur','Blé tendre','Orge','Maïs','Sorgho','Avoine'],
  'Maraîchage': [
    'Tomate','Pomme de terre','Oignon','Ail','Poivron',
    'Courgette','Aubergine','Carotte','Laitue','Pastèque',
    'Melon','Piment fort','Navet','Artichaut',
  ],
  'Légumineuses': ['Pois chiche','Lentille','Fève','Haricot vert','Petits pois'],
  'Arboriculture': [
    'Olivier','Palmier dattier','Figuier','Grenadier','Vigne',
    'Amandier','Abricotier','Pêcher','Prunier','Cerisier',
    'Agrumes (Oranger)','Citronnier',
  ],
  'Industrie': ['Tournesol','Betterave sucrière','Coton','Tabac'],
  'Fourrages': ['Luzerne','Vesce-avoine'],
  'Oasis': ['Henné','Tomate saharienne'],
  'Sous serre': ['Concombre sous serre','Tomate sous serre'],
  'Aromates': ['Coriandre','Aneth','Cumin','Géranium rosat','Safran'],
};

// ============================================================
// 📦 MODÈLE HISTORIQUE
// ============================================================
class IrrigationRecord {
  final String id;
  final String wilaya;
  final String culture;
  final DateTime datePlantation;
  final double superficie;
  final DateTime dateCalcul;
  final String urgence;
  final double quantiteParM2;
  final double quantiteTotale;
  final String stade;
  final int progression;
  final String raison;
  final String typeIrrigation;
  final Map<String, dynamic> rawData;

  IrrigationRecord({
    required this.id,
    required this.wilaya,
    required this.culture,
    required this.datePlantation,
    required this.superficie,
    required this.dateCalcul,
    required this.urgence,
    required this.quantiteParM2,
    required this.quantiteTotale,
    required this.stade,
    required this.progression,
    required this.raison,
    required this.typeIrrigation,
    required this.rawData,
  });

  factory IrrigationRecord.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return IrrigationRecord(
      id: doc.id,
      wilaya: d['wilaya'] ?? '',
      culture: d['culture'] ?? '',
      datePlantation: (d['date_plantation'] as Timestamp).toDate(),
      superficie: (d['superficie'] as num?)?.toDouble() ?? 0,
      dateCalcul: (d['date_calcul'] as Timestamp).toDate(),
      urgence: d['urgence'] ?? '',
      quantiteParM2: (d['quantite_par_m2'] as num?)?.toDouble() ?? 0,
      quantiteTotale: (d['quantite_totale'] as num?)?.toDouble() ?? 0,
      stade: d['stade'] ?? '',
      progression: (d['progression'] as num?)?.toInt() ?? 0,
      raison: d['raison'] ?? '',
      typeIrrigation: d['type_irrigation'] ?? '',
      rawData: Map<String, dynamic>.from(d['raw_data'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'wilaya': wilaya,
    'culture': culture,
    'date_plantation': Timestamp.fromDate(datePlantation),
    'superficie': superficie,
    'date_calcul': Timestamp.fromDate(dateCalcul),
    'urgence': urgence,
    'quantite_par_m2': quantiteParM2,
    'quantite_totale': quantiteTotale,
    'stade': stade,
    'progression': progression,
    'raison': raison,
    'type_irrigation': typeIrrigation,
    'raw_data': rawData,
    'source': 'irrigation_recommendation',
    'record_type': 'irrigation',
    'updated_at': FieldValue.serverTimestamp(),
    'created_at': FieldValue.serverTimestamp(),
  };
}

// ============================================================
// 🚜 TRACTOR PAINTER
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
    final alpha1 = (0.6 * (1 - smokeProgress)).clamp(0.0, 1.0);
    paint.color = Color.fromRGBO(184, 201, 168, alpha1);
    canvas.drawCircle(
      Offset(102 - smokeProgress * 12, 22 - smokeProgress * 18),
      5 * (1 + smokeProgress * 0.8), paint,
    );
    final delay = (smokeProgress + 0.5) % 1.0;
    final alpha2 = (0.4 * (1 - delay)).clamp(0.0, 1.0);
    paint.color = Color.fromRGBO(197, 212, 176, alpha2);
    canvas.drawCircle(
      Offset(98 - delay * 12, 18 - delay * 18),
      3.5 * (1 + delay * 0.8), paint,
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
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(61, 20, 30, 20), const Radius.circular(3)), paint);
    paint.color = const Color(0xB3A8CBEA);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(63, 22, 12, 16), const Radius.circular(2)), paint);
    paint.color = const Color(0xFF524133);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(97, 28, 4, 16), const Radius.circular(2)), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(97, 25, 6, 5), const Radius.circular(3)), paint);
    paint.color = const Color(0xFF3D6B2B);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(100, 50, 10, 18), const Radius.circular(2)), paint);
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
    _ctrl = List.generate(3,
      (i) => AnimationController(duration: const Duration(milliseconds: 1200), vsync: this));
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) _ctrl[i].repeat(reverse: true);
      });
    }
    _anim = _ctrl.map((c) => Tween<double>(begin: 0.2, end: 1.0)
        .animate(CurvedAnimation(parent: c, curve: Curves.easeInOut))).toList();
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
        Text(widget.text,
            style: TextStyle(fontSize: 14, color: widget.color,
                fontWeight: FontWeight.w600, letterSpacing: 0.3)),
        const SizedBox(width: 2),
        ...List.generate(3, (i) => AnimatedBuilder(
          animation: _anim[i],
          builder: (_, __) => Opacity(
            opacity: _anim[i].value,
            child: Text('.', style: TextStyle(fontSize: 16,
                color: widget.color, fontWeight: FontWeight.w700)),
          ),
        )),
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
    final rng = Random(42);
    for (int i = 0; i < 18; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        20.0 + rng.nextDouble() * 80, paint,
      );
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

// ============================================================
// 🏗️ IRRIGATION PAGE
// ============================================================
class IrrigationPage extends StatefulWidget {
  const IrrigationPage({Key? key}) : super(key: key);
  @override
  State<IrrigationPage> createState() => _IrrigationPageState();
}

class _IrrigationPageState extends State<IrrigationPage>
    with TickerProviderStateMixin {

  int _tabIndex = 0;

  // -- Form --
  String   _selectedWilaya  = 'Annaba';
  String   _selectedCulture = 'Tomate';
  DateTime _datePlantation  = DateTime.now().subtract(const Duration(days: 5));
  final    _superficieCtrl  = TextEditingController(text: '1.0');
  final    _superficieFocus = FocusNode();

  // -- API --
  final String _apiBase = 'https://agri-irrigation-api.onrender.com';
  Map<String, dynamic>? _data;
  bool   _loading = false;
  String _error   = '';

  // -- Firebase --
  final _firestore = FirebaseFirestore.instance;
  final _auth      = FirebaseAuth.instance;
  List<IrrigationRecord> _history = [];
  bool _loadingHistory = false;

  // -- Entrance animations --
  late AnimationController _entranceCtrl;
  late AnimationController _resultCtrl;
  late Animation<double>   _entranceFade;
  late Animation<Offset>   _entranceSlide;
  late Animation<double>   _resultFade;

  // -- Tractor animations --
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

    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _resultCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _entranceFade  = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _entranceSlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut));
    _resultFade = CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOut);
    _entranceCtrl.forward();

    _floatCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat(reverse: true);
    _wheelCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _smokeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
    _progressCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 22));

    _floatAnim    = Tween<double>(begin: 0, end: -8)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
    _wheelAnim    = Tween<double>(begin: 0, end: 2 * pi)
        .animate(CurvedAnimation(parent: _wheelCtrl, curve: Curves.linear));
    _smokeAnim    = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _smokeCtrl, curve: Curves.easeOut));
    _progressAnim = Tween<double>(begin: 0, end: 0.9)
        .animate(CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOut));

    _loadHistory();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _resultCtrl.dispose();
    _floatCtrl.dispose();
    _wheelCtrl.dispose();
    _smokeCtrl.dispose();
    _progressCtrl.dispose();
    _superficieCtrl.dispose();
    _superficieFocus.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    if (_farmerId == null) return;
    setState(() => _loadingHistory = true);
    try {
      final snap = await _firestore
          .collection('farmers').doc(_farmerId)
          .collection('irrigation_history')
          .orderBy('date_calcul', descending: true).limit(50).get();
      setState(() => _history = snap.docs.map(IrrigationRecord.fromFirestore).toList());
    } catch (e) { debugPrint('Firestore load error: $e'); }
    setState(() => _loadingHistory = false);
  }

  Future<void> _saveToFirestore(Map<String, dynamic> apiData) async {
    if (_farmerId == null) return;
    final superficie    = double.tryParse(_superficieCtrl.text) ?? 1.0;
    final quantiteParM2 = (apiData['quantite_eau'] as num?)?.toDouble() ?? 0;
    final record = IrrigationRecord(
      id: '', wilaya: _selectedWilaya, culture: _selectedCulture,
      datePlantation: _datePlantation, superficie: superficie,
      dateCalcul: DateTime.now(),
      urgence: apiData['niveau_urgence'] ?? '',
      quantiteParM2: quantiteParM2,
      quantiteTotale: quantiteParM2 * superficie * 10000,
      stade: apiData['stade'] ?? '',
      progression: (apiData['progression_pct'] as num?)?.toInt() ?? 0,
      raison: apiData['raison_ajustement'] ?? '',
      typeIrrigation: apiData['type_irrigation'] ?? '',
      rawData: apiData,
    );
    try {
      await _firestore.collection('farmers').doc(_farmerId)
          .collection('irrigation_history').add(record.toFirestore());
      await _firestore.collection('farmers').doc(_farmerId).set({
        'last_irrigation': {
          'culture':     _selectedCulture, 'wilaya': _selectedWilaya,
          'date':        Timestamp.now(),
          'urgence':     apiData['niveau_urgence'] ?? '',
          'quantite_m3': (quantiteParM2 * superficie * 10000 / 1000),
        },
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _loadHistory();
    } catch (e) { debugPrint('Firestore save error: $e'); }
  }

  Future<void> _fetchRecommendation() async {
    if (_loading) return;
    final superficie = double.tryParse(_superficieCtrl.text);
    if (superficie == null || superficie <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Veuillez entrer une superficie valide'),
        backgroundColor: AppColors.warning,
      ));
      return;
    }
    setState(() { _loading = true; _error = ''; _data = null; });
    _resultCtrl.reset();
    _progressCtrl.reset();
    _progressCtrl.forward();

    final dateStr =
        '${_datePlantation.year}-${_datePlantation.month.toString().padLeft(2, '0')}-${_datePlantation.day.toString().padLeft(2, '0')}';
    final uri = Uri.parse(
      '$_apiBase/irrigation'
      '?wilaya=${Uri.encodeComponent(_selectedWilaya)}'
      '&culture=${Uri.encodeComponent(_selectedCulture)}'
      '&date_plantation=$dateStr'
      '&superficie=$superficie',
    );
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 25));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        setState(() => _data = data);
        _resultCtrl.forward();
        await _saveToFirestore(data);
        setState(() => _tabIndex = 1);
      } else {
        setState(() => _error = 'Erreur serveur: ${res.statusCode}');
      }
    } catch (e) {
      setState(() => _error = 'Connexion échouée. Vérifiez votre réseau.');
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
            primary: AppColors.sage, onPrimary: Colors.white,
            surface: AppColors.cream, onSurface: AppColors.textPrimary,
          ),
          dialogBackgroundColor: AppColors.cream,
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _datePlantation = picked);
  }

  Future<void> _pickCulture() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CulturePickerSheet(
        selected: _selectedCulture,
        categories: kCulturesByCategory,
      ),
    );
    if (result != null) setState(() => _selectedCulture = result);
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
          Column(children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: _buildCurrentTab(),
              ),
            ),
          ]),
          if (_loading) _buildTractorOverlay(),
        ],
      ),
    );
  }

  // ============================================================
  // 🚜 TRACTOR LOADING OVERLAY
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
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x0F55833D)),
              ),
            ),
            Positioned(
              bottom: -60, left: -60,
              child: Container(
                width: 200, height: 200,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x0D55833D)),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _floatCtrl,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(0, _floatAnim.value), child: child),
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
                        _AnimatedDotsText(text: 'جاري الحساب', color: AppColors.sage),
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
        boxShadow: [BoxShadow(color: Color(0x30000000), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: SafeArea(
        bottom: false,
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
                  const Text('Irrigation',
                      style: TextStyle(fontFamily: 'Georgia', fontSize: 22,
                          fontWeight: FontWeight.w700, color: AppColors.textLight)),
                  Text('نظام الري الذكي الجزائري',
                      style: TextStyle(fontSize: 12, color: AppColors.mint.withOpacity(0.85))),
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
      (Icons.edit_note_rounded,   'الإدخال'),
      (Icons.water_drop_rounded,  'النتيجة'),
      (Icons.history_rounded,     'السجل'),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 251, 251, 251),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = _tabIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: active
                      ? [BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tabs[i].$1, size: 17,
                        color: active ? AppColors.textLight : AppColors.primary),
                    const SizedBox(width: 6),
                    Text(tabs[i].$2,
                        style: TextStyle(fontSize: 13,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                            color: active ? AppColors.textLight : AppColors.primary)),
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
                Text('أدخل معلومات قطعتك\nلنحسب لك احتياج الري بدقة',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, height: 1.5)),
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
        const Padding(
          padding: EdgeInsets.only(bottom: 12, right: 4),
          child: Text('معلومات القطعة',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ),
        _buildFormCard(
          label: 'الولاية',
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedWilaya, isExpanded: true,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              dropdownColor: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              icon: const Icon(Icons.expand_more_rounded, color: AppColors.sage),
              items: kWilayas.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
              onChanged: (v) => setState(() => _selectedWilaya = v!),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildFormCard(
          label: 'المحصول',
          child: InkWell(
            onTap: _pickCulture,
            child: Row(children: [
              Expanded(child: Text(_selectedCulture,
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary))),
              const Icon(Icons.expand_more_rounded, color: AppColors.sage),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        _buildFormCard(
          label: 'تاريخ الزراعة',
          child: InkWell(
            onTap: _pickDate,
            child: Row(children: [
              Expanded(child: Text(
                DateFormat('dd MMMM yyyy', 'fr').format(_datePlantation),
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              )),
              const Icon(Icons.calendar_month_outlined, color: AppColors.sage, size: 18),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        _buildFormCard(
          label: 'المساحة',
          trailing: _buildAreaBadge(),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _superficieCtrl,
                focusNode: _superficieFocus,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  border: InputBorder.none, isDense: true,
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
              child: const Text('هكتار',
                  style: TextStyle(fontSize: 11, color: AppColors.sage, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _buildAreaBadge() {
    final ha = double.tryParse(_superficieCtrl.text) ?? 0;
    return Text('${(ha * 10000).toStringAsFixed(0)} م²',
        style: const TextStyle(fontSize: 11, color: AppColors.sage, fontWeight: FontWeight.w600));
  }

  Widget _buildFormCard({required String label, required Widget child, Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.backgroundSoft),
        boxShadow: [BoxShadow(color: AppColors.forest.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                color: AppColors.textMuted, letterSpacing: 0.8)),
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
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.forest.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _loading ? null : _fetchRecommendation,
          borderRadius: BorderRadius.circular(18),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.water_drop_rounded, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Text('احسب توصية الري',
                    style: TextStyle(color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.w700, letterSpacing: 0.2)),
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
        Expanded(child: Text(_error,
            style: const TextStyle(fontSize: 12, color: AppColors.danger))),
      ]),
    );
  }

  // ============================================================
  // 💧 TAB 2 – Result
  // ============================================================
  Widget _buildResultTab() {
    if (_data == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                color: AppColors.mint.withOpacity(0.15), shape: BoxShape.circle),
              child: const Center(child: Icon(Icons.water_drop_rounded,
                  size: 40, color: AppColors.sage)),
            ),
            const SizedBox(height: 20),
            const Text('لا توجد نتائج بعد',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                    color: AppColors.textSecond)),
            const SizedBox(height: 8),
            const Text('أدخل معلوماتك واضغط احسب',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => setState(() => _tabIndex = 0),
              icon: const Icon(Icons.edit_note_rounded, color: AppColors.sage),
              label: const Text('اذهب للإدخال',
                  style: TextStyle(color: AppColors.sage, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    final d             = _data!;
    final superficie    = double.tryParse(_superficieCtrl.text) ?? 1.0;
    final quantiteParM2 = (d['quantite_eau'] as num?)?.toDouble() ?? 0;
    final quantiteTotale = quantiteParM2 * superficie * 10000;
    final urgence        = d['niveau_urgence'] as String? ?? '';
    final urgenceColor   = AppColors.urgenceColor(urgence);

    return FadeTransition(
      opacity: _resultFade,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        children: [
          _buildUrgenceBanner(d, urgence),
          const SizedBox(height: 14),
          _buildWaterVolumeCard(quantiteParM2, quantiteTotale, superficie, urgenceColor, d),
          const SizedBox(height: 12),
          _buildGrowthStageCard(d),
          const SizedBox(height: 12),
          _buildWeatherCard(d),
          const SizedBox(height: 12),
          _buildForecastCard(d),
          const SizedBox(height: 12),
          _buildSoilCard(d),
          const SizedBox(height: 12),
          _buildAdviceCard(d),
        ],
      ),
    );
  }

  Widget _buildUrgenceBanner(Map<String, dynamic> d, String urgence) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
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
              child: Text(urgence.isEmpty ? 'تحليل مكتمل' : urgence,
                  style: const TextStyle(color: Colors.white, fontSize: 11,
                      fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            ),
            const Spacer(),
            Text(DateFormat('dd MMM yyyy', 'fr').format(DateTime.now()),
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ]),
          const SizedBox(height: 14),
          Text(d['culture'] ?? _selectedCulture,
              style: const TextStyle(color: Colors.white, fontSize: 22,
                  fontWeight: FontWeight.w800, fontFamily: 'Georgia')),
          const SizedBox(height: 5),
          Row(children: [
            const Icon(Icons.location_on, color: Colors.white60, size: 14),
            const SizedBox(width: 3),
            Text(d['wilaya'] ?? _selectedWilaya,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ]),
        ],
      ),
    );
  }

  Widget _buildWaterVolumeCard(double perM2, double total, double superficie,
      Color urgenceColor, Map<String, dynamic> d) {
    return _ResultCard(
      title: 'حجم الماء الموصى به',
      icon: Icons.water_drop_outlined,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: urgenceColor.withOpacity(0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: urgenceColor.withOpacity(0.15)),
          ),
          child: Row(children: [
            Expanded(child: Column(children: [
              Text(perM2.toStringAsFixed(1),
                  style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800,
                      color: urgenceColor, fontFamily: 'Georgia', height: 1)),
              Text('لتر/م²', style: TextStyle(fontSize: 12, color: urgenceColor.withOpacity(0.7))),
            ])),
            Container(width: 1, height: 55, color: urgenceColor.withOpacity(0.2)),
            Expanded(child: Column(children: [
              Text(
                total >= 1000
                    ? '${(total / 1000).toStringAsFixed(1)} م³'
                    : '${total.toStringAsFixed(0)} لتر',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                    color: urgenceColor, fontFamily: 'Georgia', height: 1),
              ),
              Text('المجموع (${superficie.toStringAsFixed(1)} هك)',
                  style: TextStyle(fontSize: 11, color: urgenceColor.withOpacity(0.7))),
            ])),
          ]),
        ),
        const SizedBox(height: 12),
        if (d['frequence_recommandee'] != null)
          _InfoRow(label: 'التكرار', value: d['frequence_recommandee'].toString(),
              icon: Icons.repeat_rounded),
        _InfoRow(label: 'نوع الري', value: d['type_irrigation'] ?? '—', icon: Icons.water_rounded),
      ]),
    );
  }

  Widget _buildGrowthStageCard(Map<String, dynamic> d) {
    final prog = (d['progression_pct'] as num?)?.toDouble() ?? 0;
    return _ResultCard(
      title: 'مرحلة النمو',
      icon: Icons.grass_outlined,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(d['stade'] ?? '—',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary))),
          Text('${prog.toInt()}%',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                  color: AppColors.sage)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: prog / 100, minHeight: 9,
            backgroundColor: AppColors.backgroundSoft,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.sage),
          ),
        ),
        const SizedBox(height: 12),
        _InfoRow(label: 'أيام بلا مطر',
            value: '${d['jours_sans_pluie'] ?? 0} يوم', icon: Icons.wb_sunny_outlined),
        _InfoRow(
          label: 'إجهاد مائي',
          value: d['stress_hydrique'] != null
              ? '+${(((d['stress_hydrique'] as num).toDouble() - 1) * 100).toStringAsFixed(0)}%'
              : '—',
          icon: Icons.thermostat_outlined,
        ),
      ]),
    );
  }

  Widget _buildWeatherCard(Map<String, dynamic> d) {
    final forecast = d['forecast_7j'] as List? ?? [];
    final today    = forecast.isNotEmpty ? forecast[0] : null;
    final pluie7j  = d['analyse_pluie']?['total_7j'] ?? 0;

    return _ResultCard(
      title: 'الطقس الحالي',
      icon: Icons.cloud_outlined,
      child: Row(children: [
        Expanded(child: _WeatherTile(
          icon: Icons.device_thermostat_outlined,
          label: 'أقصى حرارة',
          value: today != null ? '${today['temp_max']}°' : '—',
          color: AppColors.danger,
        )),
        const SizedBox(width: 8),
        Expanded(child: _WeatherTile(
          icon: Icons.grain_rounded,
          label: 'مطر 7 أيام',
          value: '$pluie7j مم',
          color: AppColors.info,
        )),
        const SizedBox(width: 8),
        Expanded(child: _WeatherTile(
          icon: Icons.wb_sunny_outlined,
          label: 'أيام جافة',
          value: '${d['jours_sans_pluie'] ?? 0}ي',
          color: AppColors.warning,
        )),
      ]),
    );
  }

  Widget _buildForecastCard(Map<String, dynamic> d) {
    final forecast = d['forecast_7j'] as List? ?? [];
    return _ResultCard(
      title: 'توقعات 7 أيام',
      icon: Icons.calendar_today_outlined,
      child: SizedBox(
        height: 116,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: forecast.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final p        = forecast[i];
            final hasPluie = p['a_pluie'] == true;
            final parts    = (p['date'] as String? ?? '').split('-');
            final label    = parts.length == 3 ? '${parts[2]}/${parts[1]}' : 'ي${i + 1}';
            return Container(
              width: 74,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: hasPluie
                    ? AppColors.info.withOpacity(0.08)
                    : AppColors.sand.withOpacity(0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasPluie
                      ? AppColors.info.withOpacity(0.25)
                      : AppColors.border,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: const TextStyle(fontSize: 10,
                      fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                  const SizedBox(height: 5),
                  Icon(
                    hasPluie ? Icons.grain_rounded : Icons.wb_sunny_outlined,
                    size: 20,
                    color: hasPluie ? AppColors.info : AppColors.warning,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${(p['temp_max'] as num?)?.round()}°/${(p['temp_min'] as num?)?.round()}°',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                  Text(
                    hasPluie
                        ? '${p['precipitation']}مم'
                        : '${(p['vent_kmh'] as num?)?.round()}ك/س',
                    style: TextStyle(fontSize: 10,
                        color: hasPluie ? AppColors.info : AppColors.textMuted),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSoilCard(Map<String, dynamic> d) {
    return _ResultCard(
      title: 'معلومات التربة',
      icon: Icons.layers_outlined,
      child: Column(children: [
        _InfoRow(label: 'نوع التربة', value: d['soil_type'] ?? '—', icon: Icons.layers_outlined),
        _InfoRow(label: 'الاحتفاظ بالماء', value: d['soil_retention'] ?? '—', icon: Icons.opacity_outlined),
      ]),
    );
  }

  Widget _buildAdviceCard(Map<String, dynamic> d) {
    final conseils = d['conseils_detailles'] as List? ?? [];
    return _ResultCard(
      title: 'نصائح زراعية',
      icon: Icons.lightbulb_outline_rounded,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (d['raison_ajustement'] != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.sage.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.sage.withOpacity(0.2)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.info_outline, color: AppColors.sage, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(d['raison_ajustement'].toString(),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecond,
                      fontStyle: FontStyle.italic, height: 1.5))),
            ]),
          ),
          const SizedBox(height: 12),
        ],
        ...conseils.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              margin: const EdgeInsets.only(top: 5), width: 7, height: 7,
              decoration: const BoxDecoration(color: AppColors.mint, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(c.toString(),
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.5))),
          ]),
        )),
      ]),
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
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
          ? const Center(child: CircularProgressIndicator(color: AppColors.sage))
          : _history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 88, height: 88,
                        decoration: const BoxDecoration(color: AppColors.sand, shape: BoxShape.circle),
                        child: const Center(child: Icon(Icons.history_rounded,
                            size: 40, color: AppColors.textMuted)),
                      ),
                      const SizedBox(height: 18),
                      const Text('لا يوجد سجل بعد',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                              color: AppColors.textSecond)),
                      const SizedBox(height: 8),
                      const Text('سيتم الحفظ تلقائيًا بعد كل حساب',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
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

  void _showHistoryDetail(IrrigationRecord record) {
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
      await _firestore.collection('farmers').doc(_farmerId)
          .collection('irrigation_history').doc(recordId).delete();
      if (!mounted) return;
      setState(() => _history.removeWhere((r) => r.id == recordId));
    } catch (e) { debugPrint('Firestore delete error: $e'); }
  }
}

// ============================================================
// 🔷 SHARED WIDGETS
// ============================================================
class _ResultCard extends StatelessWidget {
  final String   title;
  final IconData icon;
  final Widget   child;
  const _ResultCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.backgroundSoft),
        boxShadow: [BoxShadow(color: AppColors.forest.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: AppColors.sage.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.sage),
          ),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 14,
              fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ]),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;
  const _InfoRow({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 14, color: AppColors.sage),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecond)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 13,
            fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ]),
    );
  }
}

class _WeatherTile extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;
  const _WeatherTile({required this.icon, required this.label,
      required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 17, color: color),
        ),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

// ============================================================
// 📜 HISTORY CARD
// ============================================================
class _HistoryCard extends StatelessWidget {
  final IrrigationRecord record;
  final VoidCallback     onTap;
  final VoidCallback     onDelete;
  const _HistoryCard({required this.record, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy – HH:mm', 'fr').format(record.dateCalcul);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.backgroundSoft),
          boxShadow: [BoxShadow(color: AppColors.forest.withOpacity(0.04),
              blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 4, height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(record.culture,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    record.quantiteTotale >= 1000
                        ? '${(record.quantiteTotale / 1000).toStringAsFixed(1)} م³'
                        : '${record.quantiteTotale.toStringAsFixed(0)} ل',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                        color: AppColors.primary),
                  ),
                ),
              ]),
              const SizedBox(height: 5),
              Row(children: [
                const Icon(Icons.location_on_outlined, size: 11, color: AppColors.textMuted),
                const SizedBox(width: 2),
                Text(record.wilaya,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                const SizedBox(width: 10),
                const Icon(Icons.crop_square_outlined, size: 11, color: AppColors.textMuted),
                const SizedBox(width: 2),
                Text('${record.superficie.toStringAsFixed(1)} هك',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ]),
              const SizedBox(height: 4),
              Text(dateStr,
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ]),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
            onPressed: onDelete,
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
        ]),
      ),
    );
  }
}

// ============================================================
// 📋 HISTORY DETAIL SHEET
// ============================================================
class _HistoryDetailSheet extends StatelessWidget {
  final IrrigationRecord record;
  const _HistoryDetailSheet({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.86,
      decoration: const BoxDecoration(
        color: AppColors.backgroundSoft,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          width: 38, height: 4,
          decoration: BoxDecoration(
            color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.withOpacity(0.75)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.28),
                      blurRadius: 14, offset: const Offset(0, 5))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(record.culture,
                      style: const TextStyle(color: Colors.white, fontSize: 20,
                          fontWeight: FontWeight.w800, fontFamily: 'Georgia')),
                  const SizedBox(height: 5),
                  Text(record.urgence.isEmpty ? '—' : record.urgence,
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(DateFormat('dd MMMM yyyy – HH:mm', 'fr').format(record.dateCalcul),
                      style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ]),
              ),
              const SizedBox(height: 14),
              _DetailSection(title: 'حجم الماء', rows: [
                ('بالمتر المربع', '${record.quantiteParM2.toStringAsFixed(1)} لتر/م²'),
                ('المجموع (${record.superficie.toStringAsFixed(1)} هك)',
                  record.quantiteTotale >= 1000
                      ? '${(record.quantiteTotale / 1000).toStringAsFixed(2)} م³'
                      : '${record.quantiteTotale.toStringAsFixed(0)} لتر'),
                ('نوع الري', record.typeIrrigation),
              ]),
              const SizedBox(height: 10),
              _DetailSection(title: 'معلومات القطعة', rows: [
                ('الولاية', record.wilaya),
                ('المساحة', '${record.superficie.toStringAsFixed(2)} هكتار'),
                ('تاريخ الزراعة', DateFormat('dd/MM/yyyy').format(record.datePlantation)),
              ]),
              const SizedBox(height: 10),
              _DetailSection(title: 'مرحلة النمو', rows: [
                ('المرحلة', record.stade),
                ('التقدم', '${record.progression}%'),
              ]),
              const SizedBox(height: 10),
              if (record.raison.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.backgroundSoft),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('التفسير',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Text(record.raison,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecond,
                            fontStyle: FontStyle.italic, height: 1.5)),
                  ]),
                ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String                 title;
  final List<(String, String)> rows;
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
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
            color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        ...rows.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Row(children: [
            Expanded(child: Text(r.$1,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecond))),
            Text(r.$2, style: const TextStyle(fontSize: 13,
                fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
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
  const _CulturePickerSheet({required this.selected, required this.categories});
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
          width: 38, height: 4,
          decoration: BoxDecoration(
            color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
        ),
        const Text('اختر المحصول',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
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
                prefixIcon: Icon(Icons.search, color: AppColors.sage, size: 20),
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
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(e.key,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                          color: AppColors.sage, letterSpacing: 0.5)),
                ),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: e.value.map((c) {
                    final isSelected = c == widget.selected;
                    return GestureDetector(
                      onTap: () => Navigator.pop(context, c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [AppColors.sage, AppColors.primaryDark],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isSelected ? null : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.sage : AppColors.backgroundSoft),
                          boxShadow: isSelected
                              ? [BoxShadow(color: AppColors.sage.withOpacity(0.3),
                                  blurRadius: 6, offset: const Offset(0, 2))]
                              : null,
                        ),
                        child: Text(c,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
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