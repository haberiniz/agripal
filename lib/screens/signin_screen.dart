import 'package:flutter/material.dart';
import 'package:agripal/screens/home_screen.dart';
import 'package:agripal/services/auth_service.dart';
import 'package:agripal/core/constants/app_colors.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    try {
      final authService = AuthService();
      final user = await authService.signInWithGoogle();
      
      if (user != null) {
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تسجيل الدخول: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgr,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                 
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    height: 150,
                    width: 150,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Welcome To AgriPal',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Sign in with Google to unlock your smart farm and take full control effortlessly',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 30),
                _buildGoogleButton(context),
                const SizedBox(height: 30),
                Text(
                  'By signing in, you agree to the terms and conditions',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _handleGoogleSignIn(context),
      icon: Image.asset(
        'assets/images/image.png',
        height: 30,
        width: 24,
        errorBuilder: (context, error, stackTrace) => 
          const Icon(Icons.g_mobiledata_sharp, size: 30, color: Colors.red),
      ),
      label: const Text(
       'Continue with Google',
        style: TextStyle(fontSize: 16),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.backgroundSoft,
        foregroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, 55),
        side: BorderSide(
          color: Color.fromARGB(
            (0.3 * 255).round(),
             AppColors.accent.r.round(),
            AppColors.accent.g.round(),
            AppColors.accent.b.round(),
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    );
  }
} 