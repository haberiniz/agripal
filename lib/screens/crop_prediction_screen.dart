import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agripal/core/constants/app_colors.dart';

class CropPredictionScreen extends StatefulWidget {
  const CropPredictionScreen({super.key});

  @override
  State<CropPredictionScreen> createState() => _CropPredictionScreenState();
}

class _CropPredictionScreenState extends State<CropPredictionScreen>
    with TickerProviderStateMixin {
  late final WebViewController _webController;
  bool _isLoadingPage = true;
  double _progress = 0.0;
  bool _showError = false;

  // Tractor animation controllers
  late AnimationController _floatController;
  late AnimationController _wheelController;
  late AnimationController _smokeController;
  late AnimationController _progressController;

  late Animation<double> _floatAnimation;
  late Animation<double> _wheelAnimation;
  late Animation<double> _smokeAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initWebView();
  }

  void _initAnimations() {
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    _wheelController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _smokeController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();

    _progressController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _floatAnimation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _wheelAnimation = Tween<double>(begin: 0, end: 2 * 3.14159).animate(
      CurvedAnimation(parent: _wheelController, curve: Curves.linear),
    );

    _smokeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _smokeController, curve: Curves.easeOut),
    );

    _progressAnimation = Tween<double>(begin: 0, end: 0.95).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
  }

  void _initWebView() {
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFEEF5E4))
      ..addJavaScriptChannel(
        'CropSelected',
        onMessageReceived: (JavaScriptMessage message) {
          _handleCropSelection(message.message);
        },
      )
      ..addJavaScriptChannel(
        'PageLoaded',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint('Page loaded: ${message.message}');
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoadingPage = true;
              _progress = 0.0;
              _showError = false;
            });
          },
          onProgress: (progress) {
            setState(() {
              _progress = progress / 100;
            });
          },
          onPageFinished: (url) {
            setState(() {
              _isLoadingPage = false;
              _progress = 1.0;
            });
            _injectJavaScript();
          },
          onWebResourceError: (error) {
            debugPrint('WebView error: ${error.description}');
            setState(() {
              _isLoadingPage = false;
              _showError = true;
            });
          },
          onNavigationRequest: (request) {
            debugPrint('Navigating to: ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(
        Uri.parse("https://haberiniz.github.io/agri-recommend/"),
      );
  }

  void _injectJavaScript() async {
    try {
      await _webController.runJavaScript('''
        if (window.PageLoaded) {
          PageLoaded.postMessage('ready');
        }
        
        function setupCropSelection() {
          console.log('Setting up crop selection...');
          setTimeout(() => {
            const cropCards = document.querySelectorAll('.rec-card');
            cropCards.forEach((card) => {
              if (!card.dataset.flutterListener) {
                card.dataset.flutterListener = 'true';
                card.style.cursor = 'pointer';
                
                const head = card.querySelector('.rec-head');
                if (head && !head.querySelector('.save-btn-flutter')) {
                  const saveBtn = document.createElement('button');
                  saveBtn.className = 'save-btn-flutter';
                  saveBtn.innerHTML = '💾';
                  saveBtn.title = 'حفظ في التطبيق';
                  saveBtn.style.cssText = \`
                    position: absolute;
                    bottom: 8px;
                    left: 12px;
                    background: #55833D;
                    color: white;
                    border: none;
                    width: 28px;
                    height: 28px;
                    border-radius: 50%;
                    cursor: pointer;
                    font-size: 13px;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    z-index: 100;
                    box-shadow: 0 2px 6px rgba(85,131,61,0.25);
                    transition: all 0.15s ease;
                    padding: 0;
                  \`;
                  
                  saveBtn.onclick = (e) => {
                    e.preventDefault();
                    e.stopPropagation();
                    saveBtn.style.background = '#3d5c2e';
                    saveBtn.innerHTML = '✓';
                    
                    const cropName = card.querySelector('.rec-name')?.textContent?.trim() || 'غير محدد';
                    const category = card.querySelector('.cat-pill')?.textContent?.trim() || 'غير محدد';
                    const score = card.querySelector('.score-num')?.textContent?.trim() || '0%';
                    let yieldInfo = '';
                    const yieldEls = card.querySelectorAll('.sv, .yield');
                    if (yieldEls.length > 0) yieldInfo = yieldEls[0].textContent?.trim() || '';
                    
                    if (window.CropSelected) {
                      window.CropSelected.postMessage(JSON.stringify({
                        name: cropName,
                        category: category,
                        score: score,
                        yield: yieldInfo,
                        timestamp: new Date().toISOString()
                      }));
                    }
                    
                    setTimeout(() => {
                      saveBtn.innerHTML = '💾';
                      saveBtn.style.background = '#55833D';
                    }, 1000);
                  };
                  
                  head.style.position = 'relative';
                  head.appendChild(saveBtn);
                }
              }
            });
          }, 2000);
        }
        
        const observer = new MutationObserver((mutations) => {
          mutations.forEach((m) => {
            if (m.addedNodes.length > 0) setupCropSelection();
          });
        });
        observer.observe(document.body, {childList: true, subtree: true});
        setupCropSelection();
      ''');
    } catch (e) {
      debugPrint('Error injecting JavaScript: $e');
    }
  }

  Future<void> _handleCropSelection(String message) async {
    try {
      final cropData = json.decode(message) as Map<String, dynamic>;
      if (!mounted) return;

      final confirm = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.backgroundSoft.withValues(alpha: 0.3),
                  Colors.white,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.agriculture_rounded,
                      size: 48, color: AppColors.primary),
                ),
                const SizedBox(height: 20),
                Text('حفظ المحصول الموصى به',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2))),
                  child: Column(
                    children: [
                      _buildInfoRow('المحصول', cropData['name'] ?? 'غير محدد'),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                          'الفئة', cropData['category'] ?? 'غير محدد'),
                      const SizedBox(height: 8),
                      _buildInfoRow('التقييم', cropData['score'] ?? '0%'),
                      if (cropData['yield'] != null &&
                          cropData['yield'].isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow('الإنتاج', cropData['yield']),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('هل تريد حفظ هذا المحصول في مزرعتك؟',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade600),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                        child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                side:
                                    BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12))),
                            child: Text('إلغاء',
                                style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12))),
                            child: const Text('حفظ المحصول',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)))),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      if (confirm == true && mounted) {
        await _saveCropToFirestore(cropData);
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) _showSnackBar('حدث خطأ في معالجة البيانات', isError: true);
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label,
          style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500)),
      Text(value,
          style: TextStyle(
              fontSize: 13,
              color: AppColors.primaryDark,
              fontWeight: FontWeight.bold)),
    ]);
  }

  Future<void> _saveCropToFirestore(Map<String, dynamic> cropData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('يرجى تسجيل الدخول أولاً', isError: true);
      return;
    }

    try {
      if (mounted) _showSnackBar('⏳ جاري حفظ المحصول...');

      String cropType = cropData['name'] ?? 'محصول';
      final prefs = await SharedPreferences.getInstance();
      final farmLat = prefs.getDouble('farm_lat') ?? 36.9;
      final farmLng = prefs.getDouble('farm_lng') ?? 7.76;
      final locationName =
          prefs.getString('farm_location_name') ?? 'غير محدد';
      final cropDocId = DateTime.now().millisecondsSinceEpoch.toString();

      final cropDoc = {
        'crop_id':
            'ai_recommended_${cropType.replaceAll(' ', '_').toLowerCase()}',
        'crop_type': cropType,
        'category': cropData['category'] ?? 'غير محدد',
        'location_name': locationName,
        'farm_lat': farmLat,
        'farm_lng': farmLng,
        'farm_area': 1.0,
        'planting_date': DateTime.now().toIso8601String(),
        'soil_type': 'طينية',
        'irrigation_type': 'بالتنقيط',
        'cycle_days': 120,
        'score': cropData['score'] ?? '0%',
        'yield_info': cropData['yield'] ?? '',
        'setup_completed': false,
        'is_active': false,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'source': 'ai_recommendation',
      };

      await FirebaseFirestore.instance
          .collection('farmers')
          .doc(user.uid)
          .collection('crops')
          .doc(cropDocId)
          .set(cropDoc);

      if (mounted) {
        _showSnackBar('✅ تم حفظ "$cropType" بنجاح!');
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.primary, size: 28),
                const SizedBox(width: 8),
                const Text('تم الحفظ بنجاح'),
              ],
            ),
            content: Text('تم إضافة $cropType إلى مزرعتك.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('حسناً'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('الرئيسية'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving: $e');
      if (mounted) _showSnackBar('❌ خطأ في الحفظ: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red.shade600 : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3)));
  }

  void _reloadPage() {
    setState(() => _showError = false);
    _webController.reload();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _wheelController.dispose();
    _smokeController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════
  // TRACTOR LOADING WIDGET
  // ══════════════════════════════════════════════
  Widget _buildTractorLoader(bool isDark) {
    return Container(
      color: (isDark ? const Color(0xFF0F1A0F) : const Color(0xFFEDF0E8))
          .withValues(alpha: 0.98),
      child: Stack(
        children: [
          // Background circles
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x0F55833D),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x0D55833D),
              ),
            ),
          ),
          // Main content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Floating tractor
                AnimatedBuilder(
                  animation: _floatAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _floatAnimation.value),
                      child: child,
                    );
                  },
                  child: Column(
                    children: [
                      SizedBox(
                        width: 160,
                        height: 100,
                        child: AnimatedBuilder(
                          animation: _wheelAnimation,
                          builder: (context, _) {
                            return CustomPaint(
                              painter: TractorPainter(
                                wheelAngle: _wheelAnimation.value,
                                smokeProgress: _smokeAnimation.value,
                              ),
                            );
                          },
                        ),
                      ),
                      // Tractor shadow
                      AnimatedBuilder(
                        animation: _floatController,
                        builder: (context, _) {
                          final scale =
                              1.0 - (_floatController.value * 0.25);
                          final opacity =
                              0.5 - (_floatController.value * 0.25);
                          return Transform.scale(
                            scaleX: scale,
                            child: Container(
                              width: 120,
                              height: 10,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                color: Color.fromRGBO(
                                    85, 131, 61, opacity.clamp(0.1, 0.5)),
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Progress bar
                Container(
                  width: 200,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0x2655833D),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, _) {
                      return FractionallySizedBox(
                        alignment: Alignment.centerRight,
                        widthFactor: _progress < 1.0
                            ? _progress.clamp(0.05, 0.95)
                            : _progressAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF55833D),
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Loading text with dots
                _AnimatedDotsText(
                  text: 'جاري تحميل بياناتك',
                  color: const Color(0xFF55833D),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F1A0F)
          : const Color(0xFFEEF5E4),
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('التوصيات الذكية'),
          const SizedBox(width: 8),
          
        ]),
        centerTitle: true,
        backgroundColor: isDark
            ? const Color(0xFF1A2A18)
            : AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _reloadPage,
              tooltip: 'تحديث'),
          const SizedBox(width: 8)
        ],
        flexibleSpace: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
              isDark
                  ? const Color(0xFF1A2A18)
                  : AppColors.primary,
              isDark
                  ? const Color(0xFF2A3A2A)
                  : AppColors.primary
            ]))),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _webController),

          // ── TRACTOR LOADING (replaces circular progress) ──
          if (_isLoadingPage)
            Positioned.fill(child: _buildTractorLoader(isDark)),

          // ── ERROR STATE ──
          if (_showError)
            Container(
              color: (isDark
                      ? const Color(0xFF0F1A0F)
                      : const Color(0xFFEEF5E4))
                  .withValues(alpha: 0.98),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            shape: BoxShape.circle),
                        child: Icon(Icons.wifi_off_rounded,
                            size: 56, color: Colors.red.shade400)),
                    const SizedBox(height: 20),
                    Text('فشل الاتصال بالخادم',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white70
                                : AppColors.primaryDark)),
                    const SizedBox(height: 8),
                    Text('تحقق من اتصالك بالإنترنت',
                        style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.white38
                                : Colors.grey.shade600)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                        onPressed: _reloadPage,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('إعادة المحاولة'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// TRACTOR CUSTOM PAINTER
// ══════════════════════════════════════════════
class TractorPainter extends CustomPainter {
  final double wheelAngle;
  final double smokeProgress;

  TractorPainter({required this.wheelAngle, required this.smokeProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width;
    final double cy = size.height;

    // Scale factor to match the SVG viewBox 140x100 → actual size
    final scaleX = size.width / 140;
    final scaleY = size.height / 100;
    canvas.scale(scaleX, scaleY);

    _drawSmoke(canvas);
    _drawRearWheel(canvas);
    _drawFrontWheel(canvas);
    _drawBody(canvas);
  }

  void _drawSmoke(Canvas canvas) {
    final paint = Paint()..style = PaintingStyle.fill;
    // Smoke puff 1
    paint.color = Color.fromRGBO(184, 201, 168, (0.6 * (1 - smokeProgress)).clamp(0, 1));
    final offset1 = Offset(102 - smokeProgress * 12, 22 - smokeProgress * 18);
    final radius1 = 5 * (1 + smokeProgress * 0.8);
    canvas.drawCircle(offset1, radius1, paint);

    // Smoke puff 2 (delayed)
    final delay = (smokeProgress + 0.5) % 1.0;
    paint.color = Color.fromRGBO(197, 212, 176, (0.4 * (1 - delay)).clamp(0, 1));
    final offset2 = Offset(98 - delay * 12, 18 - delay * 18);
    final radius2 = 3.5 * (1 + delay * 0.8);
    canvas.drawCircle(offset2, radius2, paint);
  }

  void _drawRearWheel(Canvas canvas) {
    canvas.save();
    canvas.translate(35, 70);
    canvas.rotate(wheelAngle);
    canvas.translate(-35, -70);

    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFF3A3A3A);
    canvas.drawCircle(const Offset(35, 70), 25, paint);

    paint.color = const Color(0xFF2D2D2D);
    canvas.drawCircle(const Offset(35, 70), 20, paint);

    paint.color = const Color(0xFFE8E4DC);
    canvas.drawCircle(const Offset(35, 70), 10, paint);

    paint.color = const Color(0xFF55833D);
    canvas.drawCircle(const Offset(35, 70), 5, paint);

    final spokePaint = Paint()
      ..color = const Color(0xFF444444)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(const Offset(35, 45), const Offset(35, 95), spokePaint);
    canvas.drawLine(const Offset(10, 70), const Offset(60, 70), spokePaint);

    spokePaint.strokeWidth = 2;
    canvas.drawLine(const Offset(18, 52), const Offset(52, 88), spokePaint);
    canvas.drawLine(const Offset(52, 52), const Offset(18, 88), spokePaint);

    canvas.restore();
  }

  void _drawFrontWheel(Canvas canvas) {
    canvas.save();
    canvas.translate(105, 70);
    canvas.rotate(wheelAngle);
    canvas.translate(-105, -70);

    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFF3A3A3A);
    canvas.drawCircle(const Offset(105, 70), 16, paint);

    paint.color = const Color(0xFF2D2D2D);
    canvas.drawCircle(const Offset(105, 70), 12, paint);

    paint.color = const Color(0xFFE8E4DC);
    canvas.drawCircle(const Offset(105, 70), 6, paint);

    paint.color = const Color(0xFF55833D);
    canvas.drawCircle(const Offset(105, 70), 3, paint);

    final spokePaint = Paint()
      ..color = const Color(0xFF444444)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(const Offset(105, 54), const Offset(105, 86), spokePaint);
    canvas.drawLine(const Offset(89, 70), const Offset(121, 70), spokePaint);

    canvas.restore();
  }

  void _drawBody(Canvas canvas) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Main body
    paint.color = const Color(0xFF55833D);
    final bodyPath = Path()
      ..moveTo(55, 70)
      ..lineTo(55, 52)
      ..quadraticBezierTo(55, 44, 63, 44)
      ..lineTo(95, 44)
      ..quadraticBezierTo(112, 44, 112, 60)
      ..lineTo(112, 70)
      ..close();
    canvas.drawPath(bodyPath, paint);

    // Cabin
    paint.color = const Color(0xFF4A7535);
    final cabinPath = Path()
      ..moveTo(57, 44)
      ..lineTo(57, 24)
      ..quadraticBezierTo(57, 16, 67, 16)
      ..lineTo(88, 16)
      ..quadraticBezierTo(96, 16, 96, 24)
      ..lineTo(96, 44)
      ..close();
    canvas.drawPath(cabinPath, paint);

    // Window
    paint.color = const Color(0xD9C8DFF0);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(61, 20, 30, 20), const Radius.circular(3)),
        paint);

    paint.color = const Color(0xB3A8CBEA);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(63, 22, 12, 16), const Radius.circular(2)),
        paint);

    // Exhaust pipe
    paint.color = const Color(0xFF524133);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(97, 28, 4, 16), const Radius.circular(2)),
        paint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(97, 25, 6, 5), const Radius.circular(3)),
        paint);

    // Grill
    paint.color = const Color(0xFF3D6B2B);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(100, 50, 10, 18), const Radius.circular(2)),
        paint);

    final grillPaint = Paint()
      ..color = const Color(0xB3E3EED4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(101, 54), const Offset(109, 54), grillPaint);
    canvas.drawLine(const Offset(101, 58), const Offset(109, 58), grillPaint);
    canvas.drawLine(const Offset(101, 62), const Offset(109, 62), grillPaint);

    // Headlight
    paint.color = const Color(0xFFDDA811);
    canvas.drawCircle(const Offset(110, 47), 3.5, paint);
    paint.color = const Color(0x80FFFFFF);
    canvas.drawCircle(const Offset(110, 47), 1.5, paint);

    // Ground line
    final groundPaint = Paint()
      ..color = const Color(0x663D6B2B)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final groundPath = Path()
      ..moveTo(58, 68)
      ..quadraticBezierTo(46, 75, 22, 75);
    canvas.drawPath(groundPath, groundPaint);
  }

  @override
  bool shouldRepaint(TractorPainter oldDelegate) =>
      oldDelegate.wheelAngle != wheelAngle ||
      oldDelegate.smokeProgress != smokeProgress;
}

// ══════════════════════════════════════════════
// ANIMATED DOTS TEXT WIDGET
// ══════════════════════════════════════════════
class _AnimatedDotsText extends StatefulWidget {
  final String text;
  final Color color;

  const _AnimatedDotsText({required this.text, required this.color});

  @override
  State<_AnimatedDotsText> createState() => _AnimatedDotsTextState();
}

class _AnimatedDotsTextState extends State<_AnimatedDotsText>
    with TickerProviderStateMixin {
  late List<AnimationController> _dotControllers;
  late List<Animation<double>> _dotAnimations;

  @override
  void initState() {
    super.initState();
    _dotControllers = List.generate(
      3,
      (i) => AnimationController(
        duration: const Duration(milliseconds: 1200),
        vsync: this,
      )..repeat(reverse: true),
    );

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) _dotControllers[i].repeat(reverse: true);
      });
    }

    _dotAnimations = _dotControllers
        .map((c) => Tween<double>(begin: 0.2, end: 1.0).animate(
              CurvedAnimation(parent: c, curve: Curves.easeInOut),
            ))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _dotControllers) {
      c.dispose();
    }
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
            fontSize: 13,
            color: widget.color,
            letterSpacing: 0.04,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 2),
        ...List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _dotAnimations[i],
            builder: (context, _) {
              return Opacity(
                opacity: _dotAnimations[i].value,
                child: Text(
                  '.',
                  style: TextStyle(
                    fontSize: 13,
                    color: widget.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }
}