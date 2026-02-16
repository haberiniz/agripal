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
            offset: const Offset(0, 6),
            child: Icon(icon, size: 24, color: AppColors.accent),
          ),
          Transform.translate(
            offset: const Offset(0, 28),
            child: Text(
              text,
              style: const TextStyle(color: AppColors.accent, fontSize: 12),
            ),
          ),
        ],
      ),
      activeIcon: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: const Offset(0, 6),
            child: Icon(activeIcon, size: 24, color: AppColors.backgroundSoft),
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
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.3),
              spreadRadius: 1,
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
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
                text: 'Home',
              ),
              navItem(
                icon: Icons.add_circle_outline,
                activeIcon: Icons.add_circle,
                text: 'Add',
              ),
              navItem(
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                text: 'Chatbot',
              ),
              navItem(
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                text: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AgriPal'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        
        // ✅ أيقونة البروفايل في أقصى اليمين مع صورة المستخدم (إذا كانت موجودة)
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                final User? user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(user: user),
                    ),
                  );
                }
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                // ✅ إذا كانت الصورة موجودة، نعرضها
                backgroundImage: (FirebaseAuth.instance.currentUser?.photoURL != null)
                    ? NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!)
                    : null,
                // ✅ إذا كانت الصورة غير موجودة، نعرض الأيقونة
                child: (FirebaseAuth.instance.currentUser?.photoURL == null)
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
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🌱', style: TextStyle(fontSize: 80)),
            SizedBox(height: 20),
            Text(
              'أهلاً بك في AgriPal',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}