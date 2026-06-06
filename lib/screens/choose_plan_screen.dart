import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agripal/core/constants/app_colors.dart';
import 'package:agripal/screens/home/home_screen.dart';
import 'package:agripal/services/auth_service.dart';

// ─────────────────────────────────────────────
//  AppColors reference (from your constants):
//
//  primaryDark   = Color(0xFF524133)
//  primary       = Color(0xFF55833D)
//  backgroundSoft= Color(0xFFE3EED4)
//  accent        = Color(0xFFE1D4C2)
//  textDark      = Color(0xFF3E2F24)
//  textLight     = Color(0xFFF5F0E8)
//  background    = Color(0xFFFFFFFF)
// ─────────────────────────────────────────────

class ChoosePlanScreen extends StatefulWidget {
  const ChoosePlanScreen({super.key});

  @override
  State<ChoosePlanScreen> createState() => _ChoosePlanScreenState();
}

class _ChoosePlanScreenState extends State<ChoosePlanScreen>
    with TickerProviderStateMixin {
  int _selectedPlan = 1;
  bool _isLoading = false;
  bool _isAnnual = false;

  late AnimationController _headerController;
  late AnimationController _cardsController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;

  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late List<Animation<double>> _cardFades;
  late List<Animation<Offset>> _cardSlides;
  late Animation<double> _pulse;
  late Animation<double> _shimmer;

  final AuthService _authService = AuthService();

  // Payment form controllers
  final _cardNumberController = TextEditingController();
  final _cardNameController   = TextEditingController();
  final _expiryController     = TextEditingController();
  final _cvvController        = TextEditingController();

  // Extra design constants
  static const Color _greenDeep  = Color(0xFF2D5A1B);
  static const Color _greenMid   = Color(0xFF3E7228);
  static const Color _greenLight = Color(0xFF7AB356);
  static const Color _greenUltra = Color(0xFFEEF5E2);
  static const Color _orange     = Color(0xFFFF9E2C);

  final List<_PlanData> _plans = [
    _PlanData(
      emoji: '🌱',
      title: 'مجاني',
      subtitle: 'للبداية',
      monthlyPrice: 0,
      annualPrice: 0,
      priceUnit: 'DA',
      priceLabel: 'مجاني',
      features: [
        'اكتشاف الأمراض',
        'شات بوت أساسي',
        'توصيات محدودة',
      ],
      type: _PlanType.free,
      badge: null,
    ),
    _PlanData(
      emoji: '🚜',
      title: 'احترافي',
      subtitle: 'للمزارعين الجادين',
      monthlyPrice: 799,
      annualPrice: 639,
      priceUnit: 'DA',
      priceLabel: '/ شهر',
      features: [
        'توصيات ذكاء اصطناعي متقدمة',
        'تحليل الأسمدة',
        'توقعات طقس مدمجة',
        'دعم متقدم للمحاصيل',
      ],
      type: _PlanType.pro,
      badge: '⭐ موصى به',
    ),
    _PlanData(
      emoji: '🧠',
      title: 'مميز',
      subtitle: 'فتح جميع الميزات',
      monthlyPrice: 1499,
      annualPrice: 1199,
      priceUnit: 'DA',
      priceLabel: '/ شهر',
      features: [
        'تحليلات ذكاء اصطناعي شاملة',
        'تقارير متقدمة غير محدودة',
        'استخدام غير محدود',
        'إدارة ذكية',
      ],
      type: _PlanType.premium,
      badge: null,
    ),
  ];

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _headerController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700),
    )..forward();

    _cardsController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100),
    )..forward();

    _pulseController = AnimationController(
      vsync: this, duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800),
    )..repeat();

    _headerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.25), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerController, curve: Curves.easeOut));

    _pulse = Tween<double>(begin: 0.97, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shimmer = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _cardFades = List.generate(3, (i) => Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _cardsController,
        curve: Interval(0.1 + i * 0.2, 0.55 + i * 0.2, curve: Curves.easeOut),
      ),
    ));

    _cardSlides = List.generate(3, (i) => Tween<Offset>(
      begin: const Offset(0, 0.35), end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _cardsController,
        curve: Interval(0.1 + i * 0.2, 0.55 + i * 0.2, curve: Curves.easeOut),
      ),
    ));
  }

  @override
  void dispose() {
    _headerController.dispose();
    _cardsController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _cardNumberController.dispose();
    _cardNameController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  // ─── Navigation ───────────────────────────────────────────────────────────

  void _skipToHome() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _handleContinue() {
    final plan = _plans[_selectedPlan];
    if (plan.type == _PlanType.free) {
      _navigateHome();
      return;
    }
    _showPaymentSheet();
  }

  void _navigateHome() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  Future<void> _processPayment() async {
    if (_cardNumberController.text.replaceAll(' ', '').length < 16 ||
        _cardNameController.text.trim().isEmpty ||
        _expiryController.text.length < 5 ||
        _cvvController.text.length < 3) {
      _showSnack('يرجى ملء جميع الحقول بشكل صحيح');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final planName = _plans[_selectedPlan].title.toLowerCase();
      await (_authService as dynamic).setPlan(planName);
      if (mounted) {
        Navigator.pop(context); // close sheet
        _navigateHome();
      }
    } catch (e) {
      if (mounted) _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit()),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  void _showPaymentSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: _greenDeep.withValues(alpha: 0.75),
      builder: (_) => _buildPaymentSheet(),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSoft,
      body: SafeArea(
        child: Stack(
          children: [
            // Background blobs
            _buildBlob(
              top: -60, right: -80,
              width: 280, height: 280,
              color: AppColors.primary.withValues(alpha: 0.10),
            ),
            _buildBlob(
              bottom: 100, left: -50,
              width: 200, height: 200,
              color: _greenLight.withValues(alpha: 0.07),
            ),

            Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 14),
                _buildBillingToggle(),
                const SizedBox(height: 4),
                Flexible(child: _buildCards()),
                _buildBottomAction(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Background blob helper ───────────────────────────────────────────────

  Widget _buildBlob({
    double? top, double? bottom, double? left, double? right,
    required double width, required double height, required Color color,
  }) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Container(
        width: width, height: height,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: FadeTransition(
        opacity: _headerFade,
        child: SlideTransition(
          position: _headerSlide,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                   
                  ),
                  // Close button
                  GestureDetector(
                    onTap: _skipToHome,
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.textDark.withValues(alpha: 0.07),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.textDark.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'خطتك',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.2,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'اختر\nخطتك',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 30,
                  color: AppColors.textDark,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'افتح الميزات الذكية',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppColors.textDark.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Billing toggle ───────────────────────────────────────────────────────

  Widget _buildBillingToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.textDark.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _toggleBtn('شهري', !_isAnnual, () => setState(() => _isAnnual = false)),
            _toggleBtn('سنوي', _isAnnual, () => setState(() => _isAnnual = true),
                badge: '-20%'),
          ],
        ),
      ),
    );
  }

  Widget _toggleBtn(String label, bool active, VoidCallback onTap, {String? badge}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppColors.textDark.withValues(alpha: 0.45),
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _orange,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Plan cards ───────────────────────────────────────────────────────────

  Widget _buildCards() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: _plans.length,
      itemBuilder: (_, i) => FadeTransition(
        opacity: _cardFades[i],
        child: SlideTransition(
          position: _cardSlides[i],
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildPlanCard(i),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(int index) {
    final plan = _plans[index];
    final isSelected = _selectedPlan == index;
    final isPro = plan.type == _PlanType.pro;

    Widget card = GestureDetector(
      onTap: () => setState(() => _selectedPlan = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()
          ..scale(isPro ? 1.025 : 1.0),
        transformAlignment: Alignment.center,
        decoration: _cardDecoration(plan, isSelected),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Inner radial glow for Pro
            if (isPro) ...[
              Positioned(
                top: -40, right: -40,
                child: Container(
                  width: 140, height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [_greenLight.withValues(alpha: 0.28), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -20, left: -20,
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [AppColors.backgroundSoft.withValues(alpha: 0.12), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ],

            // Recommended badge
            if (plan.badge != null)
              Positioned(
                top: -11, left: 18,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _orange,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _orange.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    plan.badge!,
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),

            Padding(
              padding: EdgeInsets.fromLTRB(16, plan.badge != null ? 22 : 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card header row
                  Row(
                    children: [
                      // Icon container
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: _iconBg(plan),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(plan.emoji, style: const TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.title,
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: _titleColor(plan),
                              ),
                            ),
                            Text(
                              plan.subtitle,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: _subtitleColor(plan),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _displayPrice(plan),
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 28,
                              color: _titleColor(plan),
                              height: 1,
                            ),
                          ),
                          Text(
                            plan.monthlyPrice == 0
                                ? plan.priceLabel
                                : '${plan.priceUnit} ${plan.priceLabel}',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: _subtitleColor(plan),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  Divider(color: _dividerColor(plan), height: 1),
                  const SizedBox(height: 12),

                  // Features
                  ...plan.features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(
                      children: [
                        Container(
                          width: 17, height: 17,
                          decoration: BoxDecoration(
                            color: _checkBg(plan),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '✓',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: _checkIcon(plan),
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            f,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: _featureColor(plan),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Wrap Pro card with pulse
    if (isPro) {
      return AnimatedBuilder(
        animation: _pulse,
        builder: (_, child) => Transform.scale(
          scale: _pulse.value,
          alignment: Alignment.center,
          child: child,
        ),
        child: card,
      );
    }
    return card;
  }

  // ─── Bottom CTA ───────────────────────────────────────────────────────────

  Widget _buildBottomAction() {
    final plan = _plans[_selectedPlan];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCTAButton(plan),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _skipToHome,
            child: Text(
              'تخطي الآن',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppColors.textDark.withValues(alpha: 0.4),
                decoration: TextDecoration.underline,
                decorationColor: AppColors.textDark.withValues(alpha: 0.2),
                decorationThickness: 1,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, size: 11,
                  color: AppColors.textDark.withValues(alpha: 0.3)),
              const SizedBox(width: 4),
              Text(
                'دفع آمن · يمكن الإلغاء',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: AppColors.textDark.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCTAButton(_PlanData plan) {
    final label = plan.type == _PlanType.free
        ? 'المتابعة مجاناً'
        : 'المتابعة مع ${plan.title}';

    return GestureDetector(
      onTap: _isLoading ? null : _handleContinue,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_greenMid, Color(0xFF55833D)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(27),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(27),
          child: Stack(
            children: [
              // Shimmer sweep
              AnimatedBuilder(
                animation: _shimmer,
                builder: (_, __) => Positioned(
                  left: _shimmer.value * 380,
                  top: 0, bottom: 0,
                  child: Container(
                    width: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: _isLoading
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            label,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 13, color: Colors.white,
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

  // ─── Payment sheet ────────────────────────────────────────────────────────

  Widget _buildPaymentSheet() {
    final plan = _plans[_selectedPlan];
    final price = _isAnnual ? plan.annualPrice : plan.monthlyPrice;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 36),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textDark.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Sheet title
              Text(
                'الدفع الآمن',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 24, color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'خطة ${plan.title} — $price ${plan.priceUnit}/شهر',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppColors.textDark.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 24),

              _buildPaymentField(
                controller: _cardNumberController,
                label: 'رقم البطاقة',
                hint: '1234 5678 9012 3456',
                icon: Icons.credit_card_outlined,
                maxLength: 19,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),

              _buildPaymentField(
                controller: _cardNameController,
                label: 'اسم حامل البطاقة',
                hint: 'أحمد بوضياف',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _buildPaymentField(
                      controller: _expiryController,
                      label: 'تاريخ الانتهاء',
                      hint: 'شهر/سنة',
                      icon: Icons.calendar_today_outlined,
                      maxLength: 5,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildPaymentField(
                      controller: _cvvController,
                      label: 'CVV',
                      hint: '•••',
                      icon: Icons.lock_outline_rounded,
                      maxLength: 4,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Pay button
              GestureDetector(
                onTap: _isLoading ? null : _processPayment,
                child: Container(
                  height: 52,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_greenDeep, _greenMid],
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white,
                          ),
                        )
                      : Text(
                          'ادفع $price ${plan.priceUnit} ←',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              Center(
                child: Text(
                  '🔒  تشفير SSL 256-bit · بيانات محمية',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppColors.textDark.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int? maxLength,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: AppColors.textDark.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 7),
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.textDark.withValues(alpha: 0.08),
            ),
          ),
          child: TextField(
            controller: controller,
            maxLength: maxLength,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: GoogleFonts.outfit(
              fontSize: 14, color: AppColors.textDark,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.outfit(
                fontSize: 14,
                color: AppColors.textDark.withValues(alpha: 0.25),
              ),
              prefixIcon: Icon(icon, size: 18,
                  color: AppColors.textDark.withValues(alpha: 0.35)),
              border: InputBorder.none,
              counterText: '',
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Style helpers ────────────────────────────────────────────────────────

  BoxDecoration _cardDecoration(_PlanData plan, bool isSelected) {
    switch (plan.type) {
      case _PlanType.free:
        return BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.5)
                : AppColors.textDark.withValues(alpha: 0.09),
            width: isSelected ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        );
      case _PlanType.pro:
        return BoxDecoration(
          gradient: const LinearGradient(
            colors: [_greenDeep, _greenMid, Color(0xFF55833D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: _greenDeep.withValues(alpha: 0.35),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        );
      case _PlanType.premium:
        return BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        );
    }
  }

  Color _titleColor(_PlanData p) =>
      p.type == _PlanType.free ? AppColors.textDark : Colors.white;

  Color _subtitleColor(_PlanData p) => p.type == _PlanType.free
      ? AppColors.textDark.withValues(alpha: 0.45)
      : Colors.white.withValues(alpha: 0.55);

  Color _dividerColor(_PlanData p) => p.type == _PlanType.free
      ? AppColors.textDark.withValues(alpha: 0.08)
      : Colors.white.withValues(alpha: 0.15);

  Color _featureColor(_PlanData p) => p.type == _PlanType.free
      ? AppColors.textDark.withValues(alpha: 0.72)
      : Colors.white.withValues(alpha: 0.85);

  Color _iconBg(_PlanData p) {
    switch (p.type) {
      case _PlanType.free:    return _greenUltra;
      case _PlanType.pro:     return Colors.white.withValues(alpha: 0.15);
      case _PlanType.premium: return Colors.white.withValues(alpha: 0.1);
    }
  }

  Color _checkBg(_PlanData p) {
    switch (p.type) {
      case _PlanType.free:    return _greenUltra;
      case _PlanType.pro:     return Colors.white.withValues(alpha: 0.2);
      case _PlanType.premium: return Colors.white.withValues(alpha: 0.15);
    }
  }

  Color _checkIcon(_PlanData p) =>
      p.type == _PlanType.free ? AppColors.primary : Colors.white;

  String _displayPrice(_PlanData plan) {
    if (plan.monthlyPrice == 0) return '0';
    final price = _isAnnual ? plan.annualPrice : plan.monthlyPrice;
    return price.toString();
  }
}

// ─── Data models ──────────────────────────────────────────────────────────────

enum _PlanType { free, pro, premium }

class _PlanData {
  final String emoji;
  final String title;
  final String subtitle;
  final int monthlyPrice;
  final int annualPrice;
  final String priceUnit;
  final String priceLabel;
  final List<String> features;
  final _PlanType type;
  final String? badge;

  const _PlanData({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.monthlyPrice,
    required this.annualPrice,
    required this.priceUnit,
    required this.priceLabel,
    required this.features,
    required this.type,
    this.badge,
  });
}