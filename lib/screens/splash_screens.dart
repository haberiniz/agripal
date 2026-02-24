import 'package:flutter/material.dart';
import 'package:agripal/screens/signin_screen.dart';

class SplashScreens extends StatefulWidget {
  const SplashScreens({super.key});

  @override
  State<SplashScreens> createState() => _SplashScreensState();
}

class _SplashScreensState extends State<SplashScreens>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;

  // Color palette
  final Color primaryGreen = const Color(0xFF7C9473);
  final Color lightGreen = const Color(0xFFCFDACB);
  final Color warmBrown = const Color(0xFFBC9F8B);
  final Color mintGreen = const Color(0xFFB5CFB7);
  final Color softGreen = const Color(0xFFCADABF);

  // Page data with icons and colors
  final List<Map<String, dynamic>> _pages = [
    {
      "title": "Monitor Your Land",
      "description": "Track your plants' health with satellites",
      "icon": Icons.agriculture,
    },
    {
      "title": "Ask the AI Assistant",
      "description": "Instant answers in Darija to all your questions",
      "icon": Icons.smart_toy,
    },
    {
      "title": "Predict Your Harvest",
      "description": "Plan a better future with accurate forecasts",
      "icon": Icons.analytics,
    },
  ];

  late List<AnimationController> _iconControllers;
  late List<Animation<double>> _iconAnimations;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);

    // Setup animations for each page icon
    _iconControllers = List.generate(_pages.length, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      )..forward();
    });

    _iconAnimations = _iconControllers.map((controller) {
      return Tween<double>(
        begin: 0.8,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.elasticOut));
    }).toList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _iconControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [lightGreen, softGreen],
              ),
            ),
          ),
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
              _iconControllers[page].forward(from: 0.0);
            },
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.3)).clamp(0.7, 1.0);
                  }
                  return Transform.scale(scale: value, child: child);
                },
                child: _buildPage(index),
              );
            },
          ),
          // Page indicator dots (brown active)
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: _currentPage == index ? 30 : 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? warmBrown
                        : warmBrown.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: _currentPage == index
                        ? [
                            BoxShadow(
                              color: warmBrown.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ),
          ),
          // Buttons
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: _currentPage == _pages.length - 1
                ? _buildGetStartedButton()
                : _buildNextButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(int index) {
    return Container(
      padding: EdgeInsets.zero, // إزالة الحواشي الداخلية
      child: Center(
        // توسيط المحتوى عمودياً وأفقياً
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Animated icon
            AnimatedBuilder(
              animation: _iconAnimations[index],
              builder: (context, child) {
                return Transform.scale(
                  scale: _iconAnimations[index].value,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: mintGreen.withOpacity(0.4),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: warmBrown.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      _pages[index]["icon"],
                      size: 70,
                      color: primaryGreen,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            // Title
            Text(
              _pages[index]["title"],
              textAlign: TextAlign.center, // توسيط أفقي للنص
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
                letterSpacing: 1.2,
                shadows: [
                  Shadow(
                    color: primaryGreen.withOpacity(0.2),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                _pages[index]["description"],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: warmBrown,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return ElevatedButton(
      onPressed: () {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        shadowColor: primaryGreen.withOpacity(0.5),
      ),
      child: const Text(
        'Next',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildGetStartedButton() {
    return ElevatedButton(
      onPressed: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SignInScreen()),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: warmBrown,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        shadowColor: warmBrown.withOpacity(0.5),
      ),
      child: const Text(
        'Get Started',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }
}
