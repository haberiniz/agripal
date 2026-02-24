import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agripal/main.dart'; // لاستيراد AppTheme

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
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _notificationsEnabled = true;
  String _selectedLanguage = 'ar';
  String _selectedUnit = 'metric';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
    final iconColor = isDark ? Colors.amber.shade200 : const Color(0xFF7C9473);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: isDark ? Colors.white : null,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle('المظهر', iconColor),
              _buildThemeOptions(),
              const Divider(height: 32),
              _buildSectionTitle('اللغة', iconColor),
              _buildLanguageOptions(),
              const Divider(height: 32),
              _buildSectionTitle('الإشعارات', iconColor),
              _buildNotificationTile(),
              const Divider(height: 32),
              _buildSectionTitle('الوحدات', iconColor),
              _buildUnitOptions(),
              const Divider(height: 32),
              ListTile(
                leading: Icon(Icons.info_outline, color: iconColor),
                title: const Text('حول التطبيق'),
                subtitle: const Text('الإصدار 1.0.0'),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(Icons.star_outline, color: iconColor),
                title: const Text('قيم التطبيق'),
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.settings, size: 20, color: iconColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOptions() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).cardColor,
      ),
      child: Column(
        children: [
          _buildRadioTile<AppTheme>(
            value: AppTheme.light,
            groupValue: widget.currentTheme,
            title: 'فاتح',
            icon: Icons.light_mode,
            onChanged: (val) => widget.onThemeChanged(val!),
          ),
          _buildRadioTile<AppTheme>(
            value: AppTheme.dark,
            groupValue: widget.currentTheme,
            title: 'داكن',
            icon: Icons.dark_mode,
            onChanged: (val) => widget.onThemeChanged(val!),
          ),
          _buildRadioTile<AppTheme>(
            value: AppTheme.system,
            groupValue: widget.currentTheme,
            title: 'حسب النظام',
            icon: Icons.settings_suggest,
            onChanged: (val) => widget.onThemeChanged(val!),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOptions() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).cardColor,
      ),
      child: Column(
        children: [
          _buildRadioTile<String>(
            value: 'ar',
            groupValue: _selectedLanguage,
            title: 'العربية',
            icon: Icons.language,
            onChanged: (val) {
              setState(() => _selectedLanguage = val!);
              _savePreference('language', val);
            },
          ),
          _buildRadioTile<String>(
            value: 'en',
            groupValue: _selectedLanguage,
            title: 'English',
            icon: Icons.language,
            onChanged: (val) {
              setState(() => _selectedLanguage = val!);
              _savePreference('language', val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUnitOptions() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).cardColor,
      ),
      child: Column(
        children: [
          _buildRadioTile<String>(
            value: 'metric',
            groupValue: _selectedUnit,
            title: 'متري (كغ، هكتار)',
            icon: Icons.scale,
            onChanged: (val) {
              setState(() => _selectedUnit = val!);
              _savePreference('unit', val);
            },
          ),
          _buildRadioTile<String>(
            value: 'imperial',
            groupValue: _selectedUnit,
            title: 'إمبراطوري (رطل، فدان)',
            icon: Icons.monitor_weight,
            onChanged: (val) {
              setState(() => _selectedUnit = val!);
              _savePreference('unit', val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRadioTile<T>({
    required T value,
    required T groupValue,
    required String title,
    required IconData icon,
    required Function(T?) onChanged,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: RadioListTile<T>(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        title: Text(title),
        secondary: Icon(icon),
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildNotificationTile() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).cardColor,
      ),
      child: SwitchListTile(
        title: const Text('تفعيل الإشعارات'),
        subtitle: const Text('استلام تنبيهات حول المحاصيل والطقس'),
        secondary: Icon(
          _notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
          color: _notificationsEnabled ? Colors.green : Colors.grey,
        ),
        value: _notificationsEnabled,
        onChanged: (val) {
          setState(() => _notificationsEnabled = val);
          _savePreference('notifications', val);
        },
      ),
    );
  }
}