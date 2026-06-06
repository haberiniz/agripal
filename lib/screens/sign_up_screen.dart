import 'package:flutter/material.dart';
import 'package:agripal/core/constants/app_colors.dart';
import 'package:agripal/screens/choose_plan_screen.dart';
import 'package:agripal/services/auth_service.dart';
import 'package:agripal/widgets/auth_text_field.dart';


class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _floatController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _float;
  late Animation<double> _glow;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _float = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _glow = Tween<double>(begin: 0.3, end: 0.65).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _floatController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'الاسم الكامل مطلوب';
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'البريد الإلكتروني مطلوب';
    final r = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!r.hasMatch(v.trim())) return 'أدخل بريداً إلكترونياً صالحاً';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'كلمة المرور مطلوبة';
    if (v.length < 8) return 'الحد الأدنى 8 أحرف';
    if (!v.contains(RegExp(r'[A-Z]'))) return 'يجب أن تحتوي على حرف كبير';
    if (!v.contains(RegExp(r'[a-z]'))) return 'يجب أن تحتوي على حرف صغير';
    if (!v.contains(RegExp(r'[0-9]'))) return 'يجب أن تحتوي على رقم';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v != _passwordController.text) return 'كلمتا المرور غير متطابقتين';
    return null;
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final user = await (_authService as dynamic).signUpWithEmail(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (user != null && mounted) {
        Navigator.pushReplacement(context, _fadeRoute(const ChoosePlanScreen()));
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() => _isGoogleLoading = true);
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null && mounted) {
        Navigator.pushReplacement(context, _fadeRoute(const ChoosePlanScreen()));
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  PageRoute _fadeRoute(Widget page) => PageRouteBuilder(
        pageBuilder: (_, a, __) => page,
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF4F8EE), AppColors.backgroundSoft],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideUp,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // زر الرجوع
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 10,
                              )
                            ],
                          ),
                          child: const Icon(Icons.arrow_back_ios_new,
                              size: 16, color: AppColors.textDark),
                        ),
                        padding: EdgeInsets.zero,
                      ),

                      const SizedBox(height: 16),

                      // الشعار + العنوان
                      Center(
                        child: AnimatedBuilder(
                          animation: _float,
                          builder: (_, child) => Transform.translate(
                            offset: Offset(0, _float.value * 0.5),
                            child: child,
                          ),
                          child: Image.asset(
                            'assets/images/app_icon.png',
                            height: 64,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Center(
                        child: Text(
                          'إنشاء حساب',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          'سجّل للوصول إلى الميزات الحصرية',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // الحقول
                      AuthTextField(
                        controller: _nameController,
                        label: 'الاسم الكامل',
                        hint: 'اسمك',
                        prefixIcon: Icons.person_outline,
                        validator: _validateName,
                      ),
                      const SizedBox(height: 14),
                      AuthTextField(
                        controller: _emailController,
                        label: 'البريد الإلكتروني',
                        hint: 'you@example.com',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 14),
                      AuthTextField(
                        controller: _passwordController,
                        label: 'كلمة المرور',
                        hint: '••••••••',
                        obscureText: _obscurePassword,
                        prefixIcon: Icons.lock_outline,
                        validator: _validatePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.primary.withValues(alpha: 0.6),
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      const SizedBox(height: 14),
                      AuthTextField(
                        controller: _confirmController,
                        label: 'تأكيد كلمة المرور',
                        hint: '••••••••',
                        obscureText: _obscureConfirm,
                        prefixIcon: Icons.lock_outline,
                        validator: _validateConfirm,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.primary.withValues(alpha: 0.6),
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // زر إنشاء حساب
                      AnimatedBuilder(
                        animation: _glow,
                        builder: (_, __) => GestureDetector(
                          onTap: _isLoading ? null : _handleSignUp,
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
                                  color: AppColors.primary
                                      .withValues(alpha: _glow.value),
                                  blurRadius: 22,
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
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : const Center(
                                    child: Text(
                                      'إنشاء حساب',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // رابط تسجيل الدخول
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'هل لديك حساب بالفعل؟ ',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey.shade600),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Text(
                                'تسجيل الدخول',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // فاصل OR
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'أو',
                              style: TextStyle(
                                  color: Colors.grey.shade400, fontSize: 12),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // جوجل
                      Center(child: _buildGoogleButton()),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return GestureDetector(
      onTap: _isGoogleLoading ? null : _handleGoogleSignUp,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _isGoogleLoading
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              )
            : Center(
                child: Image.asset(
                  'assets/images/G-removebg-preview.png',
                  height: 28,
                ),
              ),
      ),
    );
  }
}