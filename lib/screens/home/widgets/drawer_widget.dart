import 'package:agripal/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agripal/main.dart';
import 'package:agripal/screens/profile_screen.dart';
import 'package:agripal/screens/settings_screen.dart';

class HomeDrawer extends StatelessWidget {
  final User? user;
  final bool isDark;
  final int selectedIndex;
  final void Function(int) onItemSelected;
  final VoidCallback onProfileTap;
  final VoidCallback onSettingsTap;

  const HomeDrawer({
    super.key,
    required this.user,
    required this.isDark,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onProfileTap,
    required this.onSettingsTap,
  });

  static const _items = [
    {'icon': Icons.home_outlined,         'activeIcon': Icons.home_rounded,         'title': 'الرئيسية'},
    {'icon': Icons.person_outline,        'activeIcon': Icons.person_rounded,       'title': 'البروفايل'},
    {'icon': Icons.settings_outlined,     'activeIcon': Icons.settings_rounded,     'title': 'الإعدادات'},
    {'icon': Icons.contact_mail_outlined, 'activeIcon': Icons.contact_mail_rounded, 'title': 'تواصل معنا'},
    {'icon': Icons.info_outline,          'activeIcon': Icons.info_rounded,         'title': 'حول التطبيق'},
    {'icon': Icons.share_outlined,        'activeIcon': Icons.share_rounded,        'title': 'مشاركة التطبيق'},
  ];

  @override
  Widget build(BuildContext context) {
    final firebaseUser = FirebaseAuth.instance.currentUser ?? user;

    return Drawer(
      shape: const RoundedRectangleBorder(),
      backgroundColor: isDark ? const Color(0xFF0F1A0F) : Colors.white,
      child: Column(
        children: [
          _buildHeader(firebaseUser),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _items.length,
              itemBuilder: (context, index) {
                return _AnimatedDrawerItem(
                  icon:       _items[index]['icon']       as IconData,
                  activeIcon: _items[index]['activeIcon'] as IconData,
                  title:      _items[index]['title']      as String,
                  isSelected: selectedIndex == index,
                  activeColor: AppColors.primary,
                  delay: index * 60,
                  onTap: () => _handleTap(context, index),
                );
              },
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  // ── Router ────────────────────────────────────────────────────────────────
  void _handleTap(BuildContext context, int index) {
    onItemSelected(index);

    // ── نقرأ themeProvider قبل Navigator.pop لأن Context يتكسر بعدها ──
    final themeProvider = AppThemeProvider.of(context);

    Navigator.pop(context);

    switch (index) {
      case 0: // الرئيسية
        break;

      case 1: // البروفايل
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
        break;

      case 2: // الإعدادات
        if (themeProvider != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SettingsScreen(
                onThemeChanged: themeProvider.onThemeChanged,
                currentTheme:   themeProvider.currentTheme,
              ),
            ),
          );
        }
        break;

      case 3: // تواصل معنا
        _showContactDialog(context);
        break;

      case 4: // حول التطبيق
        _showAboutDialog(context);
        break;

      case 5: // مشاركة التطبيق
        _shareApp(context);
        break;
    }
  }

  // ── تواصل معنا ────────────────────────────────────────────────────────────
  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A2B1A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.contact_mail_rounded, color: AppColors.primary),
          const SizedBox(width: 8),
          const Text('تواصل معنا'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'يمكنك التواصل معنا عبر البريد الإلكتروني:',
              style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                Clipboard.setData(
                    const ClipboardData(text: 'support@agripal.app'));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('تم نسخ البريد الإلكتروني'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  Icon(Icons.email_outlined,
                      color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Text('support@agripal.app',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Icon(Icons.copy_rounded,
                      color: AppColors.primary, size: 14),
                ]),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إغلاق',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  // ── حول التطبيق ───────────────────────────────────────────────────────────
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A2B1A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.eco_rounded, color: AppColors.primary),
          const SizedBox(width: 8),
          const Text('حول AgriPal'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AgriPal هو تطبيق ذكي للمزارعين يوفر توصيات زراعية مخصصة، '
              'تنبؤات الطقس، وإدارة المزارع بكفاءة عالية.',
              style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                  height: 1.6),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                Icon(Icons.info_outline_rounded,
                    color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Text('الإصدار 1.0.0',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold)),
              ]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('حسناً',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  // ── مشاركة التطبيق ────────────────────────────────────────────────────────
  void _shareApp(BuildContext context) async {
    const appLink =
        'حمّل تطبيق AgriPal للزراعة الذكية 🌱\nhttps://play.google.com/store/apps/details?id=com.agripal';
    await Clipboard.setData(const ClipboardData(text: appLink));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('تم نسخ رابط التطبيق — شاركه مع أصدقائك'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(User? firebaseUser) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.accent.withValues(alpha: 0.85),
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.6), width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  backgroundImage: (firebaseUser?.photoURL != null)
                      ? NetworkImage(firebaseUser!.photoURL!)
                      : null,
                  child: (firebaseUser?.photoURL == null)
                      ? const Icon(Icons.person_rounded,
                          color: Colors.white, size: 34)
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF69F0AE),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            firebaseUser?.displayName ?? 'مستخدم AgriPal',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17,
                letterSpacing: 0.3),
          ),
          const SizedBox(height: 3),
          if ((firebaseUser?.email ?? '').isNotEmpty)
            Row(children: [
              Icon(Icons.mail_outline_rounded,
                  color: Colors.white.withValues(alpha: 0.7), size: 12),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  firebaseUser!.email!,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
        ],
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Icon(Icons.eco_rounded, color: AppColors.primary, size: 16),
        const SizedBox(width: 8),
        Text('AgriPal v1.0.0',
            style: TextStyle(
                fontSize: 12,
                color: AppColors.primary.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AnimatedDrawerItem
// ─────────────────────────────────────────────────────────────────────────────
class _AnimatedDrawerItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final int delay;
  final Color activeColor;

  const _AnimatedDrawerItem({
    required this.icon,
    required this.activeIcon,
    required this.title,
    required this.isSelected,
    required this.onTap,
    required this.delay,
    required this.activeColor,
  });

  @override
  State<_AnimatedDrawerItem> createState() => _AnimatedDrawerItemState();
}

class _AnimatedDrawerItemState extends State<_AnimatedDrawerItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnimation =
        Tween<Offset>(begin: const Offset(-0.3, 0), end: Offset.zero).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? widget.activeColor.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: widget.isSelected
                  ? Border.all(
                      color: widget.activeColor.withValues(alpha: 0.25))
                  : null,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? widget.activeColor.withValues(alpha: 0.18)
                        : Colors.grey.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.isSelected ? widget.activeIcon : widget.icon,
                    size: 18,
                    color: widget.isSelected
                        ? widget.activeColor
                        : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: widget.isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: widget.isSelected
                        ? widget.activeColor
                        : Colors.grey.shade600,
                  ),
                ),
                if (widget.isSelected) ...[
                  const Spacer(),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                        color: widget.activeColor, shape: BoxShape.circle),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}