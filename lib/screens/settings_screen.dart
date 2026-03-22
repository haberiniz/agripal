import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agripal/core/constants/app_colors.dart';
import 'package:agripal/main.dart';

class SettingsScreen extends StatefulWidget {
  final Function(AppTheme) onThemeChanged;
  final AppTheme currentTheme;

  const SettingsScreen({
    super.key,
    required this.onThemeChanged,
    required this.currentTheme,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeIn;

  bool _notificationsEnabled = true;
  String _selectedLanguage = 'ar';
  String _selectedUnit = 'metric';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
      _selectedLanguage = prefs.getString('language') ?? 'ar';
      _selectedUnit = prefs.getString('unit') ?? 'metric';
    });
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) prefs.setBool(key, value);
    if (value is String) prefs.setString(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F1A0F) : const Color(0xFFF5F9F0);
    final cardBg = isDark ? const Color(0xFF1A2A1A) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F1A0F) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'الإعدادات',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: AppColors.primary.withValues(alpha: 0.1),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          children: [
            // ── المظهر ────────────────────────────────────────────
            _sectionLabel('المظهر', isDark),
            const SizedBox(height: 8),
            _card(
              isDark: isDark,
              cardBg: cardBg,
              child: Column(
                children: [
                  _themeRow(AppTheme.light, 'فاتح', Icons.light_mode_outlined,
                      isDark, cardBg),
                  _divider(isDark),
                  _themeRow(AppTheme.dark, 'داكن', Icons.dark_mode_outlined,
                      isDark, cardBg),
                  _divider(isDark),
                  _themeRow(AppTheme.system, 'حسب النظام',
                      Icons.phone_android_outlined, isDark, cardBg),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // ── الإشعارات ─────────────────────────────────────────
            _sectionLabel('الإشعارات', isDark),
            const SizedBox(height: 8),
            _card(
              isDark: isDark,
              cardBg: cardBg,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      _notificationsEnabled
                          ? Icons.notifications_outlined
                          : Icons.notifications_off_outlined,
                      color: _notificationsEnabled
                          ? AppColors.primary
                          : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تفعيل الإشعارات',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : const Color(0xFF2A3A2A),
                            ),
                          ),
                          Text(
                            'تنبيهات المحاصيل والطقس',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _notificationsEnabled,
                      onChanged: (val) {
                        setState(() => _notificationsEnabled = val);
                        _savePreference('notifications', val);
                      },
                      activeColor: AppColors.primary,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            // ── اللغة ─────────────────────────────────────────────
            _sectionLabel('اللغة', isDark),
            const SizedBox(height: 8),
            _card(
              isDark: isDark,
              cardBg: cardBg,
              child: Column(
                children: [
                  _selectRow(
                    label: 'العربية',
                    sub: '🇩🇿',
                    selected: _selectedLanguage == 'ar',
                    isDark: isDark,
                    onTap: () {
                      setState(() => _selectedLanguage = 'ar');
                      _savePreference('language', 'ar');
                    },
                  ),
                  _divider(isDark),
                  _selectRow(
                    label: 'English',
                    sub: '🇬🇧',
                    selected: _selectedLanguage == 'en',
                    isDark: isDark,
                    onTap: () {
                      setState(() => _selectedLanguage = 'en');
                      _savePreference('language', 'en');
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // ── الوحدات ───────────────────────────────────────────
            _sectionLabel('الوحدات', isDark),
            const SizedBox(height: 8),
            _card(
              isDark: isDark,
              cardBg: cardBg,
              child: Column(
                children: [
                  _selectRow(
                    label: 'متري',
                    sub: 'كغ، هكتار',
                    selected: _selectedUnit == 'metric',
                    isDark: isDark,
                    onTap: () {
                      setState(() => _selectedUnit = 'metric');
                      _savePreference('unit', 'metric');
                    },
                  ),
                  _divider(isDark),
                  _selectRow(
                    label: 'إمبراطوري',
                    sub: 'رطل، فدان',
                    selected: _selectedUnit == 'imperial',
                    isDark: isDark,
                    onTap: () {
                      setState(() => _selectedUnit = 'imperial');
                      _savePreference('unit', 'imperial');
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // ── معلومات ───────────────────────────────────────────
            _sectionLabel('معلومات', isDark),
            const SizedBox(height: 8),
            _card(
              isDark: isDark,
              cardBg: cardBg,
              child: Column(
                children: [
                  _linkRow(
                    icon: Icons.info_outline_rounded,
                    label: 'حول التطبيق',
                    sub: 'الإصدار 1.0.0',
                    isDark: isDark,
                    onTap: () {},
                  ),
                  _divider(isDark),
                  _linkRow(
                    icon: Icons.star_outline_rounded,
                    label: 'قيم التطبيق',
                    sub: 'شاركنا رأيك',
                    isDark: isDark,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────

  Widget _sectionLabel(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(right: 4, bottom: 0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark
              ? Colors.white38
              : Colors.grey.shade500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _card({
    required bool isDark,
    required Color cardBg,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: isDark ? Colors.white10 : Colors.grey.shade100,
    );
  }

  Widget _themeRow(AppTheme theme, String label, IconData icon, bool isDark,
      Color cardBg) {
    final isSelected = widget.currentTheme == theme;
    return GestureDetector(
      onTap: () => widget.onThemeChanged(theme),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: isSelected ? AppColors.primary : Colors.grey.shade400),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? AppColors.primary
                    : isDark
                        ? Colors.white70
                        : const Color(0xFF2A3A2A),
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_rounded, size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _selectRow({
    required String label,
    required String sub,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(sub, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected
                    ? AppColors.primary
                    : isDark
                        ? Colors.white70
                        : const Color(0xFF2A3A2A),
              ),
            ),
            const Spacer(),
            if (selected)
              Icon(Icons.check_rounded, size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _linkRow({
    required IconData icon,
    required String label,
    required String sub,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade400),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : const Color(0xFF2A3A2A),
                  ),
                ),
                Text(
                  sub,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}