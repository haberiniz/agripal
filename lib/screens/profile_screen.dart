import 'package:flutter/material.dart';
import 'package:agripal/core/constants/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart'; // ✅ مهم لتسجيل الخروج

class ProfileScreen extends StatelessWidget {
  final User user;

  const ProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ✅ صورة المستخدم
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary,
              backgroundImage: user.photoURL != null 
                ? NetworkImage(user.photoURL!) 
                : null,
              child: user.photoURL == null
                ? const Icon(Icons.person, size: 50, color: Colors.white)
                : null,
            ),
            const SizedBox(height: 20),
            
            // ✅ اسم المستخدم
            Text(
              user.displayName ?? 'اسم المستخدم',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            
            // ✅ إيميل المستخدم
            Text(
              user.email ?? 'user@example.com',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 40),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildMenuItem(
                    Icons.settings, 
                    'الإعدادات', 
                    context, // ✅ تمرير context
                  ),
                  const Divider(),
                  _buildMenuItem(
                    Icons.logout, 
                    'تسجيل الخروج', 
                    context,
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ دالة مساعدة لبناء عناصر القائمة مع تمرير context
  Widget _buildMenuItem(IconData icon, String title, BuildContext context, {Color color = AppColors.textDark}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      onTap: () async {
        if (title == 'تسجيل الخروج') {
          // ✅ تسجيل الخروج من Firebase و Google
          await FirebaseAuth.instance.signOut();
          await GoogleSignIn().signOut();
          
          if (context.mounted) {
            // ✅ الرجوع لصفحة البداية
            Navigator.pushReplacementNamed(context, '/');
          }
        } else {
          // ✅ إجراءات أخرى (مثل الإعدادات)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title قريباً')),
          );
        }
      },
    );
  }
}