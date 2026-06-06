import 'package:flutter/material.dart';
import 'package:agripal/screens/sign_in_screen.dart';
import 'package:agripal/core/constants/app_colors.dart';

class SplashScreens extends StatefulWidget {
  const SplashScreens({super.key});

  @override
  State<SplashScreens> createState() => _SplashScreensState();
}

class _SplashScreensState extends State<SplashScreens>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _textController;
  late AnimationController _buttonController;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _buttonScale;
  late Animation<double> _buttonGlow;

  final List<Map<String, String>> pages = [
    {
      'title': 'الزراعة الذكية',
      'desc': 'تنبؤ بمحصولك باستخدام رؤى الذكاء الاصطناعي',
      'image': 'assets/images/farm1.jpg',
    },
    {
      'title': 'المياه والأسمدة',
      'desc': 'تحسين الموارد بدقة متناهية',
      'image': 'assets/images/farm2.jpg',
    },
    {
      'title': 'المساعد الذكي',
      'desc': 'اسأل أي شيء عن محاصيلك',
      'image': 'assets/images/farm3.jpg',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initTextAnimation();
    _initButtonAnimation();
  }

  void _initTextAnimation() {
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _textFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
  }

  void _initButtonAnimation() {
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _buttonScale = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    _buttonGlow = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _textController.reset();
    _textController.forward();
  }

  @override
  void dispose() {
    _textController.dispose();
    _buttonController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── PageView ──
          PageView.builder(
            controller: _pageController,
            itemCount: pages.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (_, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  // ── Background Image ──
                  Image.asset(
                    pages[index]['image']!,
                    fit: BoxFit.cover,
                  ),

                  // ── Gradient Overlay ──
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                          const Color(0xFF2A3A1F).withOpacity(0.92),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),

                  // ── Text Content ──
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 80),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Title ──
                        FadeTransition(
                          opacity: _textFade,
                          child: SlideTransition(
                            position: _textSlide,
                            child: Text(
                              pages[index]['title']!,
                              style: const TextStyle(
                                color: Color(0xFFE3EED4),
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        // ── Description ──
                        FadeTransition(
                          opacity: _textFade,
                          child: SlideTransition(
                            position: _textSlide,
                            child: Text(
                              pages[index]['desc']!,
                              style: const TextStyle(
                                color: Color(0xFFE1D4C2),
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 140),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          // ── Dots ──
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? const Color(0xFF7C9473)
                        : const Color(0xFFE1D4C2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),

          // ── Button ──
          Positioned(
            bottom: 40,
            left: 30,
            right: 30,
            child: _currentPage == pages.length - 1
                ? _buildGetStartedButton()
                : _buildContinueButton(),
          ),
        ],
      ),
    );
  }

  // ── Continue Button ──
  Widget _buildContinueButton() {
    return AnimatedBuilder(
      animation: _buttonController,
      builder: (context, child) {
        return Transform.scale(
          scale: _buttonScale.value,
          child: GestureDetector(
            onTap: () {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              height: 55,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: const Color(0xFF7C9473).withOpacity(0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C9473)
                        .withOpacity(_buttonGlow.value * 0.5),
                    blurRadius: 20,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SizedBox(width: 10),
                  Text(
                    'متابعة ←',
                    style: TextStyle(
                      color: Color(0xFFE3EED4),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Get Started Button ──
  Widget _buildGetStartedButton() {
    return AnimatedBuilder(
      animation: _buttonController,
      builder: (context, child) {
        return Transform.scale(
          scale: _buttonScale.value,
          child: GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const SignInScreen(),
                  transitionsBuilder: (_, animation, __, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 500),
                ),
              );
            },
            child: Container(
              height: 55,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF7C9473),
                    Color(0xFF55833D),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary
                        .withOpacity(_buttonGlow.value),
                    blurRadius: 24,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SizedBox(width: 10),
                  Text(
                    'ابدأ الآن',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}