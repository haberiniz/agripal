import 'package:flutter/material.dart';
import 'package:agripal/core/constants/app_colors.dart';
import 'package:agripal/screens/add_screen.dart';
import 'package:agripal/screens/chatbot_screen.dart';
import 'package:agripal/screens/settings_screen.dart';
import 'package:agripal/screens/profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = <Widget>[
    _HomeContent(),
    AddScreen(),
    ChatbotScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  BottomNavigationBarItem navItem({
    required IconData icon,
    required IconData activeIcon,
    required String text,
  }) {
    return BottomNavigationBarItem(
      label: '',
      icon: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: const Offset(0, 14),
            child: Icon(icon, size: 26, color: AppColors.backgroundSoft),
          ),
          Transform.translate(
            offset: const Offset(0, 28),
            child: Text(
              text,
              style: const TextStyle(color: AppColors.backgroundSoft, fontSize: 12),
            ),
          ),
        ],
      ),
      activeIcon: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: const Offset(0, 14),
            child: Icon(activeIcon, size: 26, color: AppColors.backgroundSoft),
          ),
          Transform.translate(
            offset: const Offset(0, 28),
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.backgroundSoft,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3EED4),
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.primary,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            elevation: 0,
            items: [
              navItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                text: '',
              ),
              navItem(
                icon: Icons.add_circle_outline,
                activeIcon: Icons.add_circle,
                text: '',
              ),
              navItem(
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                text: '',
              ),
              navItem(
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                text: '',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent({super.key});

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFE3EED4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE3EED4),
        elevation: 0,
        title: ScaleTransition(
          scale: _scaleAnimation,
          child: RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Agri',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    color: Color(0xFF7C9473),
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(2, 2),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
                TextSpan(
                  text: 'Pal',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    color: Color(0xFF8B5E3C),
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(2, 2),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(user: user),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  backgroundImage: user.photoURL != null
                      ? NetworkImage(user.photoURL!)
                      : null,
                  child: user.photoURL == null
                      ? const Icon(
                          Icons.person,
                          size: 20,
                          color: AppColors.primary,
                        )
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
