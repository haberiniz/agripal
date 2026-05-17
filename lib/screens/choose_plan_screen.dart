import 'package:flutter/material.dart';
import 'package:agripal/core/constants/app_colors.dart';
import 'package:agripal/screens/home/home_screen.dart';
import 'package:agripal/services/auth_service.dart';

class ChoosePlanScreen extends StatefulWidget {
  const ChoosePlanScreen({super.key});

  @override
  State<ChoosePlanScreen> createState() => _ChoosePlanScreenState();
}

class _ChoosePlanScreenState extends State<ChoosePlanScreen>
    with TickerProviderStateMixin {
  int _selectedPlan = 1; // default: Pro
  bool _isLoading = false;

  late AnimationController _headerController;
  late AnimationController _cardsController;
  late AnimationController _pulseController;

  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late List<Animation<double>> _cardFades;
  late List<Animation<Offset>> _cardSlides;
  late Animation<double> _pulse;

  final AuthService _authService = AuthService();

  final List<_PlanData> _plans = [
    _PlanData(
      emoji: '🌱',
      title: 'Free',
      subtitle: 'Perfect to get started',
      price: 'FREE',
      priceLabel: '',
      features: [
        'Plant disease detection',
        'Basic chatbot',
        'Limited recommendations',
      ],
      gradientColors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
      accentColor: Color(0xFF66BB6A),
      badge: null,
    ),
    _PlanData(
      emoji: '🚜',
      title: 'Pro',
      subtitle: 'For serious farmers',
      price: '\$4.99',
      priceLabel: '/month',
      features: [
        'Smart AI recommendations',
        'Fertilizer analysis',
        'Weather insights',
        'Advanced crop support',
      ],
      gradientColors: [Color(0xFF55833D), Color(0xFF3A5F2A)],
      accentColor: Colors.white,
      badge: 'Most Popular',
    ),
    _PlanData(
      emoji: '🧠',
      title: 'Premium',
      subtitle: 'Full power unlocked',
      price: '\$9.99',
      priceLabel: '/month',
      features: [
        'Full AI analytics',
        'Advanced reports',
        'Unlimited usage',
        'Smart farm management',
      ],
      gradientColors: [Color(0xFF524133), Color(0xFF3A2E25)],
      accentColor: Color(0xFFE1D4C2),
      badge: null,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _cardsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _headerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerController, curve: Curves.easeOut));

    _pulse = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _cardFades = List.generate(3, (i) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _cardsController,
          curve: Interval(0.1 + i * 0.2, 0.5 + i * 0.2, curve: Curves.easeOut),
        ),
      );
    });
    _cardSlides = List.generate(3, (i) {
      return Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _cardsController,
          curve: Interval(0.1 + i * 0.2, 0.5 + i * 0.2, curve: Curves.easeOut),
        ),
      );
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _cardsController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    setState(() => _isLoading = true);
    try {
      final planName = _plans[_selectedPlan].title.toLowerCase();
      await (_authService as dynamic).setPlan(planName);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, a, __) => const HomeScreen(),
            transitionsBuilder: (_, a, __, child) =>
                FadeTransition(opacity: a, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.backgroundSoft, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              FadeTransition(
                opacity: _headerFade,
                child: SlideTransition(
                  position: _headerSlide,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Text('🌾', style: TextStyle(fontSize: 36)),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Choose Your Plan',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Unlock smart farming features',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Cards
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _plans.length,
                  itemBuilder: (context, i) {
                    return FadeTransition(
                      opacity: _cardFades[i],
                      child: SlideTransition(
                        position: _cardSlides[i],
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _buildPlanCard(i),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Continue button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                child: _buildContinueButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(int index) {
    final plan = _plans[index];
    final isSelected = _selectedPlan == index;
    final isPro = index == 1;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: plan.gradientColors,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (isPro ? Colors.white.withValues(alpha: 0.8) : AppColors.primary)
                : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: plan.gradientColors.last
                  .withValues(alpha: isSelected ? 0.45 : 0.15),
              blurRadius: isSelected ? 24 : 10,
              spreadRadius: isSelected ? 2 : 0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Selected checkmark
            if (isSelected)
              Positioned(
                top: 14,
                right: 14,
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, child) => Transform.scale(
                    scale: _pulse.value,
                    child: child,
                  ),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: isPro
                          ? Colors.white
                          : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      size: 16,
                      color: isPro ? AppColors.primary : Colors.white,
                    ),
                  ),
                ),
              ),

            // Badge
            if (plan.badge != null)
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    plan.badge!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (plan.badge != null) const SizedBox(height: 12),

                  // Emoji + Title row
                  Row(
                    children: [
                      Text(plan.emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: plan.accentColor,
                            ),
                          ),
                          Text(
                            plan.subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: plan.accentColor.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            plan.price,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: plan.accentColor,
                            ),
                          ),
                          if (plan.priceLabel.isNotEmpty)
                            Text(
                              plan.priceLabel,
                              style: TextStyle(
                                fontSize: 12,
                                color: plan.accentColor.withValues(alpha: 0.7),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Divider(
                      color: plan.accentColor.withValues(alpha: 0.2),
                      height: 1),

                  const SizedBox(height: 10),

                  // Features
                  ...plan.features.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 15,
                              color: plan.accentColor.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              f,
                              style: TextStyle(
                                fontSize: 13,
                                color: plan.accentColor.withValues(alpha: 0.9),
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
  }

  Widget _buildContinueButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleContinue,
      child: Container(
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7CB87A), AppColors.primary],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: _isLoading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                ),
              )
            : const Center(
                child: Text(
                  'Continue',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
      ),
    );
  }
}

class _PlanData {
  final String emoji;
  final String title;
  final String subtitle;
  final String price;
  final String priceLabel;
  final List<String> features;
  final List<Color> gradientColors;
  final Color accentColor;
  final String? badge;

  const _PlanData({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.priceLabel,
    required this.features,
    required this.gradientColors,
    required this.accentColor,
    this.badge,
  });
}