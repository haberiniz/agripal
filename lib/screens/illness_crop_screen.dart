// lib/screens/illness_crop_screen.dart
// 🌿 كاشف أمراض النباتات
// ✅ Redesigned: matches irrigation_page + fertilization_screen design system

import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  static const Color bark           = Color(0xFF6B4C2E);
  static const Color earth          = Color(0xFF8B6914);
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
    final rng = Random(77);
    for (int i = 0; i < 18; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        20.0 + rng.nextDouble() * 80,
        paint,
      );
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

// ============================================================
// 🚜 TRACTOR PAINTER  (same as irrigation_page)
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
    canvas.translate(35, 70); canvas.rotate(wheelAngle); canvas.translate(-35, -70);
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
      ..color = const Color(0xFF444444) ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(35, 45), const Offset(35, 95), spoke);
    canvas.drawLine(const Offset(10, 70), const Offset(60, 70), spoke);
    spoke.strokeWidth = 2;
    canvas.drawLine(const Offset(18, 52), const Offset(52, 88), spoke);
    canvas.drawLine(const Offset(52, 52), const Offset(18, 88), spoke);
    canvas.restore();
  }

  void _drawFrontWheel(Canvas canvas) {
    canvas.save();
    canvas.translate(105, 70); canvas.rotate(wheelAngle); canvas.translate(-105, -70);
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
      ..color = const Color(0xFF444444) ..strokeWidth = 2
      ..style = PaintingStyle.stroke ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(105, 54), const Offset(105, 86), spoke);
    canvas.drawLine(const Offset(89, 70), const Offset(121, 70), spoke);
    canvas.restore();
  }

  void _drawBody(Canvas canvas) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = const Color(0xFF55833D);
    final body = Path()
      ..moveTo(55, 70) ..lineTo(55, 52)
      ..quadraticBezierTo(55, 44, 63, 44)
      ..lineTo(95, 44) ..quadraticBezierTo(112, 44, 112, 60)
      ..lineTo(112, 70) ..close();
    canvas.drawPath(body, paint);
    paint.color = const Color(0xFF4A7535);
    final cabin = Path()
      ..moveTo(57, 44) ..lineTo(57, 24)
      ..quadraticBezierTo(57, 16, 67, 16)
      ..lineTo(88, 16) ..quadraticBezierTo(96, 16, 96, 24)
      ..lineTo(96, 44) ..close();
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
      ..color = const Color(0xB3E3EED4) ..strokeWidth = 1.5 ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(101, 54), const Offset(109, 54), grill);
    canvas.drawLine(const Offset(101, 58), const Offset(109, 58), grill);
    canvas.drawLine(const Offset(101, 62), const Offset(109, 62), grill);
    paint.color = const Color(0xFFDDA811);
    canvas.drawCircle(const Offset(110, 47), 3.5, paint);
    paint.color = const Color(0x80FFFFFF);
    canvas.drawCircle(const Offset(110, 47), 1.5, paint);
    final ground = Paint()
      ..color = const Color(0x663D6B2B) ..strokeWidth = 3
      ..style = PaintingStyle.stroke ..strokeCap = StrokeCap.round;
    canvas.drawPath(Path()..moveTo(58, 68)..quadraticBezierTo(46, 75, 22, 75), ground);
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
  late List<Animation<double>>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = List.generate(3, (i) => AnimationController(
        duration: const Duration(milliseconds: 1200), vsync: this));
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) _ctrl[i].repeat(reverse: true);
      });
    }
    _anim = _ctrl.map((c) => Tween<double>(begin: 0.2, end: 1.0)
        .animate(CurvedAnimation(parent: c, curve: Curves.easeInOut))).toList();
  }

  @override
  void dispose() { for (final c in _ctrl) c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.text, style: TextStyle(fontSize: 14, color: widget.color,
            fontWeight: FontWeight.w600, letterSpacing: 0.3)),
        const SizedBox(width: 2),
        ...List.generate(3, (i) => AnimatedBuilder(
          animation: _anim[i],
          builder: (_, __) => Opacity(
            opacity: _anim[i].value,
            child: Text('.', style: TextStyle(fontSize: 16, color: widget.color,
                fontWeight: FontWeight.w700)),
          ),
        )),
      ],
    );
  }
}

// ============================================================
// 🏗️ MAIN SCREEN
// ============================================================
class IllnessCropScreen extends StatefulWidget {
  const IllnessCropScreen({super.key});
  @override
  State<IllnessCropScreen> createState() => _IllnessCropScreenState();
}

class _IllnessCropScreenState extends State<IllnessCropScreen>
    with TickerProviderStateMixin {

  final ImagePicker _picker = ImagePicker();
  File? _image;
  bool  _isLoading = false;
  Map<String, dynamic>? _result;

  // -- Entrance animations --
  late AnimationController _entranceCtrl;
  late Animation<double>   _entranceFade;
  late Animation<Offset>   _entranceSlide;

  // -- Tractor animations --
  late AnimationController _floatCtrl;
  late AnimationController _wheelCtrl;
  late AnimationController _smokeCtrl;
  late AnimationController _progressCtrl;
  late Animation<double>   _floatAnim;
  late Animation<double>   _wheelAnim;
  late Animation<double>   _smokeAnim;
  late Animation<double>   _progressAnim;

  // -- Result reveal --
  late AnimationController _resultCtrl;
  late Animation<double>   _resultFade;

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

    _floatCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat(reverse: true);
    _wheelCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _smokeCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
    _progressCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 18));

    _floatAnim    = Tween<double>(begin: 0, end: -8)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
    _wheelAnim    = Tween<double>(begin: 0, end: 2 * pi)
        .animate(CurvedAnimation(parent: _wheelCtrl, curve: Curves.linear));
    _smokeAnim    = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _smokeCtrl, curve: Curves.easeOut));
    _progressAnim = Tween<double>(begin: 0, end: 0.9)
        .animate(CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _entranceCtrl.dispose(); _resultCtrl.dispose();
    _floatCtrl.dispose(); _wheelCtrl.dispose();
    _smokeCtrl.dispose(); _progressCtrl.dispose();
    super.dispose();
  }

  // ---- Pick image ----
  Future<void> _pickImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(source: source);
    if (picked != null) {
      setState(() { _image = File(picked.path); _result = null; });
      _resultCtrl.reset();
      _uploadImage();
    }
  }

  // ---- Upload & analyze ----
  Future<void> _uploadImage() async {
    setState(() => _isLoading = true);
    _progressCtrl.reset();
    _progressCtrl.forward();

    final request = http.MultipartRequest(
      'POST', Uri.parse('https://plant-disease-api-2-5ykk.onrender.com/predict'));
    request.files.add(await http.MultipartFile.fromPath('file', _image!.path));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final raw  = await response.stream.bytesToString();
        final data = json.decode(raw) as Map<String, dynamic>;
        setState(() => _result = data);
        _resultCtrl.forward();
      } else {
        setState(() => _result = {'error': 'فشل التحليل، حاول مرة أخرى'});
      }
    } catch (_) {
      setState(() => _result = {'error': 'خطأ في الاتصال بالخادم'});
    }

    _progressCtrl.animateTo(1.0,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    setState(() => _isLoading = false);
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
            Expanded(
              child: SlideTransition(
                position: _entranceSlide,
                child: FadeTransition(
                  opacity: _entranceFade,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                    children: [
                      _buildWelcomeCard(),
                      const SizedBox(height: 20),
                      _buildImageZone(),
                      if (_result != null && !_isLoading) ...[
                        const SizedBox(height: 20),
                        _buildResultCard(),
                      ],
                      const SizedBox(height: 24),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ]),
          if (_isLoading) _buildTractorOverlay(),
        ],
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
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppColors.sage, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
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
                  const Text('تشخيص النباتات',
                      style: TextStyle(fontFamily: 'Georgia', fontSize: 22,
                          fontWeight: FontWeight.w700, color: AppColors.textLight)),
                  Text('كاشف أمراض المحاصيل',
                      style: TextStyle(fontSize: 12,
                          color: AppColors.mint.withOpacity(0.85))),
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
  // 🌿 WELCOME CARD
  // ============================================================
  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.sage, AppColors.primaryDark],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.sage.withOpacity(0.25),
            blurRadius: 16, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('مرحباً بك، فلاح',
                    style: TextStyle(color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 5),
                Text('التقط صورة لنباتك أو اختر من المعرض\nلنشخص الأمراض بدقة',
                    style: TextStyle(color: Colors.white.withOpacity(0.8),
                        fontSize: 12, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🖼️ IMAGE ZONE
  // ============================================================
  Widget _buildImageZone() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _image != null
              ? AppColors.sage.withOpacity(0.4)
              : AppColors.backgroundSoft,
          width: _image != null ? 2 : 1,
        ),
        boxShadow: [BoxShadow(color: AppColors.forest.withOpacity(0.05),
            blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: _image != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(19),
              child: Image.file(_image!, fit: BoxFit.cover,
                  width: double.infinity, height: double.infinity),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.sage.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_photo_alternate_outlined,
                      size: 30, color: AppColors.sage),
                ),
                const SizedBox(height: 14),
                const Text('لم يتم اختيار صورة بعد',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                        color: AppColors.textSecond)),
                const SizedBox(height: 6),
                Text('اضغط أحد الزرين أدناه للبدء',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
    );
  }

  // ============================================================
  // 📋 RESULT CARD
  // ============================================================
  Widget _buildResultCard() {
    final bool hasError   = _result!.containsKey('error');
    final bool isRejected = _result!['status'] == 'rejected';
    final bool isHealthy  = _result!['healthy'] == true;

    return FadeTransition(
      opacity: _resultFade,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasError || isRejected
                ? AppColors.warning.withOpacity(0.3)
                : isHealthy
                    ? AppColors.success.withOpacity(0.3)
                    : AppColors.danger.withOpacity(0.3),
          ),
          boxShadow: [BoxShadow(color: AppColors.forest.withOpacity(0.05),
              blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: hasError
            ? _buildErrorResult()
            : isRejected
                ? _buildRejectedResult()
                : _buildDiagnosisResult(isHealthy),
      ),
    );
  }

  Widget _buildErrorResult() {
    return Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.warning_amber_rounded,
            color: AppColors.warning, size: 20),
      ),
      const SizedBox(width: 14),
      Expanded(child: Text(_result!['error'],
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary))),
    ]);
  }

  Widget _buildRejectedResult() {
    return Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.block_rounded, color: AppColors.warning, size: 20),
      ),
      const SizedBox(width: 14),
      Expanded(child: Text(_result!['message'] ?? 'الصورة غير صالحة',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
              color: AppColors.textPrimary))),
    ]);
  }

  Widget _buildDiagnosisResult(bool isHealthy) {
    final statusColor = isHealthy ? AppColors.success : AppColors.danger;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Status banner
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [statusColor, statusColor.withOpacity(0.75)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: statusColor.withOpacity(0.25),
              blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isHealthy ? Icons.verified_outlined : Icons.healing_outlined,
              color: Colors.white, size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isHealthy ? 'النبات سليم' : 'تم اكتشاف مرض',
            style: const TextStyle(color: Colors.white, fontSize: 16,
                fontWeight: FontWeight.w800, fontFamily: 'Georgia'),
          ),
        ]),
      ),
      const SizedBox(height: 16),

      // Diagnosis
      _ResultRow(
        icon: Icons.biotech_outlined,
        label: 'التشخيص',
        value: _result!['disease']?.toString() ?? '—',
        color: AppColors.sage,
      ),
      const SizedBox(height: 10),
      const Divider(color: AppColors.backgroundSoft),
      const SizedBox(height: 10),

      // Treatment
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.sage.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.sage.withOpacity(0.2)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.local_pharmacy_outlined,
              color: AppColors.sage, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('العلاج الموصى به',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: AppColors.textMuted, letterSpacing: 0.6)),
              const SizedBox(height: 5),
              Text(_result!['treatment']?.toString() ?? '—',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecond,
                      fontStyle: FontStyle.italic, height: 1.5)),
            ]),
          ),
        ]),
      ),
    ]);
  }

  // ============================================================
  // 🎛️ ACTION BUTTONS
  // ============================================================
  Widget _buildActionButtons() {
    return Row(children: [
      Expanded(child: _ActionButton(
        icon: Icons.camera_alt_outlined,
        label: 'التقاط صورة',
        onTap: () => _pickImage(ImageSource.camera),
        gradient: const LinearGradient(
          colors: [AppColors.sage, AppColors.primaryDark],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      )),
      const SizedBox(width: 12),
      Expanded(child: _ActionButton(
        icon: Icons.photo_library_outlined,
        label: 'من المعرض',
        onTap: () => _pickImage(ImageSource.gallery),
        gradient: LinearGradient(
          colors: [AppColors.bark, AppColors.bark.withOpacity(0.8)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      )),
    ]);
  }

  // ============================================================
  // 🚜 TRACTOR LOADING OVERLAY
  // ============================================================
  Widget _buildTractorOverlay() {
    return Positioned.fill(
      child: Container(
        color: const Color(0xFF0F1A0F).withOpacity(0.88),
        child: Stack(children: [
          Positioned(
            top: -80, right: -80,
            child: Container(width: 300, height: 300,
                decoration: const BoxDecoration(shape: BoxShape.circle,
                    color: Color(0x0F55833D))),
          ),
          Positioned(
            bottom: -60, left: -60,
            child: Container(width: 200, height: 200,
                decoration: const BoxDecoration(shape: BoxShape.circle,
                    color: Color(0x0D55833D))),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _floatCtrl,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(0, _floatAnim.value), child: child),
                  child: Column(children: [
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
                  ]),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 220,
                  child: Column(children: [
                    _AnimatedDotsText(text: 'جاري التشخيص', color: AppColors.sage),
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
                  ]),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ============================================================
// 🔷 SHARED WIDGETS
// ============================================================
class _ResultRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;
  const _ResultRow({required this.icon, required this.label,
      required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
              color: AppColors.textMuted, letterSpacing: 0.8)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
        ]),
      ),
    ]);
  }
}

class _ActionButton extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final VoidCallback onTap;
  final Gradient     gradient;
  const _ActionButton({required this.icon, required this.label,
      required this.onTap, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.forest.withOpacity(0.25),
            blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white,
                  fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}