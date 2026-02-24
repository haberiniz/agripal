import 'package:flutter/material.dart';
import 'package:agripal/screens/add_screen.dart';
import 'package:agripal/screens/chatbot_screen.dart';
import 'package:agripal/screens/settings_screen.dart';
import 'package:agripal/screens/profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agripal/main.dart'; // لاستيراد AppThemeProvider

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
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
          backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.withOpacity(0.3),
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          elevation: 0,
          items: [
            _buildNavItem(Icons.home_outlined, Icons.home, 'Home'),
            _buildNavItem(Icons.add_circle_outline, Icons.add_circle, 'Add'),
            _buildNavItem(Icons.chat_bubble_outline, Icons.chat_bubble, 'Chatbot'),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, IconData activeIcon, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark ? Colors.grey.shade400 : const Color(0xFF7C9473).withOpacity(0.6);
    final activeColor = isDark ? Colors.amber.shade200 : const Color(0xFF7C9473);
    return BottomNavigationBarItem(
      icon: Icon(icon, color: inactiveColor),
      activeIcon: Icon(activeIcon, color: activeColor),
      label: label,
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final themeProvider = AppThemeProvider.of(context);
    if (themeProvider == null) throw Exception('AppThemeProvider not found');

    return Scaffold(
      appBar: AppBar(
        title: const Text('AgriPal'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : null,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('قريباً: صفحة الإشعارات')),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user?.displayName ?? 'مستخدم AgriPal'),
              accountEmail: Text(user?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: (user?.photoURL != null)
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: (user?.photoURL == null)
                    ? Icon(Icons.person, color: Theme.of(context).colorScheme.primary)
                    : null,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            ListTile(
              leading: Icon(Icons.person_outline, color: Theme.of(context).iconTheme.color),
              title: const Text('البروفايل'),
              onTap: () {
                Navigator.pop(context);
                if (user != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(user: user),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('الرجاء تسجيل الدخول أولاً')),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.settings_outlined, color: Theme.of(context).iconTheme.color),
              title: const Text('الإعدادات'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(
                      // نحصل على الدوال من الـ provider
                      onThemeChanged: themeProvider.onThemeChanged,
                      currentTheme: themeProvider.currentTheme,
                    ),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.info_outline, color: Theme.of(context).iconTheme.color),
              title: const Text('حول التطبيق'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('قريباً: صفحة حول التطبيق')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.share_outlined, color: Theme.of(context).iconTheme.color),
              title: const Text('مشاركة التطبيق'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('قريباً: مشاركة التطبيق')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'تسجيل الخروج',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تسجيل الخروج')),
                );
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🌱', style: TextStyle(fontSize: 80, color: Theme.of(context).textTheme.bodyLarge?.color)),
            const SizedBox(height: 20),
            Text(
              'أهلاً بك في AgriPal',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}