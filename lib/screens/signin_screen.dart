import 'package:flutter/material.dart';
import 'package:agripal/screens/home_screen.dart';
import 'package:agripal/services/auth_service.dart';
import 'package:agripal/core/constants/app_colors.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with SingleTickerProviderStateMixin {

  bool _pressed = false;

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    try {
      final authService = AuthService();
      final user = await authService.signInWithGoogle();

      if (user != null && context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
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
              AppColors.backgroundSoft,
              const Color(0xFFE1D4C2),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                /// LOGO FADE ANIMATION
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 800),
                  builder: (_, value, child) =>
                      Opacity(opacity: value, child: child),
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    height: 150,
                  ),
                ),

                const SizedBox(height: 15),

                /// TITLE SLIDE
                TweenAnimationBuilder(
                  tween: Tween<Offset>(
                      begin: const Offset(0, 0.3), end: Offset.zero),
                  duration: const Duration(milliseconds: 700),
                  builder: (_, value, child) =>
                      Transform.translate(
                          offset: Offset(0, value.dy * 40),
                          child: child),
                  child: Text(
                    'Welcome To AgriPal',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'Sign in with Google to unlock your smart farm and take full control effortlessly',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textDark,
                  ),
                ),

                const SizedBox(height: 40),

                _buildGoogleButton(context),

                const SizedBox(height: 30),

                Text(
                  'By signing in, you agree to the terms and conditions',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// GOOGLE BUTTON WITH ANIMATION
  Widget _buildGoogleButton(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () => _handleGoogleSignIn(context),

      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 55,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.backgroundSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/image.png',
                height: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Continue with Google',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
