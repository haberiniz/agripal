import 'package:flutter/material.dart';
import 'package:agripal/screens/signin_screen.dart';

class SplashScreens extends StatefulWidget {
  const SplashScreens({super.key});

  @override
  State<SplashScreens> createState() => _SplashScreensState();
}

class _SplashScreensState extends State<SplashScreens> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> pages = [
    {
      "title": "Smart Farming",
      "desc": "Predict your harvest with AI insights",
      "image": "assets/images/farm1.jpg",
    },
    {
      "title": "Water & Fertilizer",
      "desc": "Optimize resources with precision",
      "image": "assets/images/farm3.jpg",
    },
    {
      "title": "AI Assistant",
      "desc": "Ask anything about your crops",
      "image": "assets/images/farm2.jpg",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          // PAGE VIEW
          PageView.builder(
            controller: _pageController,
            itemCount: pages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, index) {
              return Stack(
                fit: StackFit.expand,
                children: [

                  // BACKGROUND IMAGE
                  Image.asset(
                    pages[index]["image"]!,
                    fit: BoxFit.cover,
                  ),

                  // GRADIENT OVERLAY
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF524133)
                              .withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                  ),

                  // TEXT
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 80),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pages[index]["title"]!,
                          style: const TextStyle(
                            color: Color(0xFFE3EED4),
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          pages[index]["desc"]!,
                          style: const TextStyle(
                            color: Color(0xFFE1D4C2),
                            fontSize: 16,
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

          // DOTS
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

          // BUTTON
          Positioned(
            bottom: 40,
            left: 30,
            right: 30,
            child: ElevatedButton(
              onPressed: () {
                if (_currentPage == pages.length - 1) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SignInScreen()),
                  );
                } else {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C9473),
                foregroundColor: const Color(0xFFE3EED4),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                _currentPage == pages.length - 1
                    ? "Get Started"
                    : "Continue",
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
