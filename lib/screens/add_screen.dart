import 'package:flutter/material.dart';
import 'package:agripal/core/constants/app_colors.dart';
import 'package:agripal/screens/irrigation_page.dart' hide AppColors;
import 'package:agripal/screens/fertilization_screen.dart' hide AppColors;
import 'package:agripal/screens/crop_prediction_screen.dart';
import 'package:agripal/screens/illness_crop_screen.dart';



class AddScreen extends StatefulWidget {
  const AddScreen({super.key});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> with TickerProviderStateMixin {
  late AnimationController _headerController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _headerFade = CurvedAnimation(
      parent: _headerController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final categories = [
      {
        'icon': Icons.water_drop_rounded,
        'title': 'الري',
        'desc': 'توصيات وتسجيل عمليات الري',
        'color': const Color(0xFF4A90C8),
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const IrrigationPage()),
            ),
      },
      {
        'icon': Icons.spa_rounded,
        'title': 'الأسمدة',
        'desc': 'توصيات وتسجيل عمليات التسميد',
        'color': const Color(0xFF55833D),
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FertilizationScreen()),
            ),
      },
      {
        'icon': Icons.grass_rounded,
        'title': 'المحاصيل',
        'desc': 'أصناف وتواريخ الزراعة',
        'color': const Color(0xFFE07B30),
         'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CropPredictionScreen()),
            ),
      },
      {
        'icon': Icons.biotech_rounded,
        'title': 'أمراض النباتات',
        'desc': 'تتبع وتشخيص الأمراض',
        'color': const Color(0xFF7B68EE),
         'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const IllnessCropScreen()),
            ),
      },
    ];

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F1A0F) : const Color(0xFFF5F9F0),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: SlideTransition(
                position: _headerSlide,
                child: FadeTransition(
                  opacity: _headerFade,
                  child: _buildHeader(isDark),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _headerFade,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(children: [
                    Container(
                      width: 3, height: 16,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, const Color(0xFF7C9473)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('اختر فئة',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF2A3A2A),
                        )),
                  ]),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = categories[index];
                    return _buildCard(
                      icon: item['icon'] as IconData,
                      label: item['title'] as String,
                      desc: item['desc'] as String,
                      color: item['color'] as Color,
                      isDark: isDark,
                      index: index,
                      onTap: item['onTap'] as VoidCallback,
                    );
                  },
                  childCount: categories.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.05,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: _buildTipCard(isDark),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  void _comingSoon(String label, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('سيتم فتح صفحة $label قريباً'),
      behavior: SnackBarBehavior.floating,
      backgroundColor: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: const Duration(seconds: 1),
    ));
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, const Color(0xFF7C9473)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(children: [
        Positioned(
          right: -20, top: -20,
          child: Container(
            width: 130, height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
        ),
        Positioned(
          left: -15, bottom: -25,
          child: Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
            ),
            const Spacer(),
            const Text('إضافة جديدة',
                style: TextStyle(
                  color: Colors.white, fontSize: 26,
                  fontWeight: FontWeight.bold, letterSpacing: 0.3, height: 1.1,
                )),
            Text('اختر نوع السجل الذي تريد إضافته',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78), fontSize: 13)),
            const SizedBox(height: 16),
          ]),
        ),
      ]),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String label,
    required String desc,
    required Color color,
    required bool isDark,
    required int index,
    required VoidCallback onTap,
  }) {
    final cardBg = isDark ? const Color(0xFF1A2A1A) : Colors.white;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + index * 80),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Transform.scale(
        scale: value.clamp(0.0, 1.05),
        child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isDark ? 0.08 : 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1A2E1A),
                  fontWeight: FontWeight.bold, fontSize: 14,
                )),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(desc,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? Colors.white38 : Colors.grey.shade500,
                    height: 1.3,
                  )),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildTipCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2A1A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10, offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.lightbulb_outline_rounded,
              color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('نصيحة اليوم',
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                )),
            const SizedBox(height: 3),
            Text('سجّل بيانات حقلك بانتظام للحصول على توصيات أدق',
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? Colors.white54 : Colors.grey.shade500,
                  height: 1.4,
                )),
          ]),
        ),
      ]),
    );
  }
}