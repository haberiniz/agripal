import 'dart:convert';
import 'package:agripal/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:agripal/screens/add_screen.dart';
import 'package:agripal/screens/chatbot_screen.dart';
import 'package:agripal/screens/settings_screen.dart';
import 'package:agripal/screens/profile_screen.dart';
import 'package:agripal/screens/weather_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agripal/main.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _navAnimController;

  static const List<Widget> _screens = <Widget>[
    _HomeContent(),
    AddScreen(),
    ChatbotScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _navAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _navAnimController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 8, 24, 12),
        height: 64,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2E1A) : Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.15),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: isDark
                ? AppColors.primary.withValues(alpha: 0.2)
                : AppColors.primary.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.home_rounded, Icons.home_rounded, 0, 'الرئيسية'),
            _buildNavItem(Icons.add_rounded, Icons.add_rounded, 1, 'إضافة'),
            _buildNavItem(Icons.chat_bubble_outline_rounded,
                Icons.chat_bubble_rounded, 2, 'المستشار'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon, IconData activeIcon, int index, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 18 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.primary : const Color(0xFF55833D),
              size: 22,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: isSelected
                  ? Row(children: [
                      const SizedBox(width: 6),
                      Text(label,
                          style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ])
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Animated Drawer Item ──────────────────────────────────────────
class _AnimatedDrawerItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final int delay;
  final Color activeColor;

  const _AnimatedDrawerItem({
    required this.icon,
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
    _slideAnimation = Tween<Offset>(
            begin: const Offset(-0.3, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? widget.activeColor.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: widget.isSelected
                  ? Border.all(color: widget.activeColor.withValues(alpha: 0.25))
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
                  child: Icon(widget.icon,
                      size: 18,
                      color: widget.isSelected
                          ? widget.activeColor
                          : Colors.grey.shade500),
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

// ─── Home Content ──────────────────────────────────────────────────
class _HomeContent extends StatefulWidget {
  const _HomeContent();
  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  static const _apiKey = '3bd015115660091719e9545a0d7f5202';
  int _selectedDrawerIndex = 0;
  double? _farmLat;
  double? _farmLng;

  // ← هنا التغيير: نستخدم اسم الموقع الحقيقي
  String _locationDisplayName = 'جاري التحديد...';

  Map<String, dynamic>? _weatherData;
  bool _weatherLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFarmAndWeather();
  }

  Future<void> _loadFarmAndWeather() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('farm_lat');
    final lng = prefs.getDouble('farm_lng');

    // ← أولوية: farm_location_name (اسم الموقع الحقيقي) ثم نجيبه بـ reverse geocoding
    final savedLocationName = prefs.getString('farm_location_name');

    if (lat != null && lng != null) {
      setState(() {
        _farmLat = lat;
        _farmLng = lng;
        _locationDisplayName = savedLocationName ?? 'جاري التحديد...';
      });

      // إذا ما عندنا اسم موقع حقيقي محفوظ، نجيبه بـ reverse geocoding
      if (savedLocationName == null || savedLocationName.isEmpty) {
        _fetchRealLocationName(lat, lng);
      }

      await _fetchWeather(lat, lng);
    } else {
      // موقع افتراضي: عنابة
      setState(() {
        _farmLat = 36.9;
        _farmLng = 7.76;
        _locationDisplayName = 'عنابة، الجزائر';
      });
      await _fetchWeather(36.9, 7.76);
    }
  }

  // ← دالة جديدة: reverse geocoding لجلب اسم الموقع الحقيقي
  Future<void> _fetchRealLocationName(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=$lat&lon=$lng&format=json&accept-language=ar',
      );
      final res = await http.get(uri, headers: {'User-Agent': 'AgriPalApp/1.0'});
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final addr = data['address'] as Map<String, dynamic>? ?? {};
        final name =
            (addr['village'] as String?) ??
            (addr['town'] as String?) ??
            (addr['city'] as String?) ??
            (addr['municipality'] as String?) ??
            (addr['county'] as String?) ??
            (addr['state'] as String?) ??
            'موقعي';

        // احفظه للمرة القادمة
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('farm_location_name', name);

        if (mounted) {
          setState(() => _locationDisplayName = name);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _locationDisplayName = 'موقعي');
    }
  }

  Future<void> _fetchWeather(double lat, double lng) async {
    try {
      final res = await http.get(Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather'
        '?lat=$lat&lon=$lng&appid=$_apiKey&units=metric&lang=ar',
      ));
      if (res.statusCode == 200) {
        setState(() {
          _weatherData = json.decode(res.body);
          _weatherLoading = false;
        });
      } else {
        setState(() => _weatherLoading = false);
      }
    } catch (_) {
      setState(() => _weatherLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final themeProvider = AppThemeProvider.of(context);
    if (themeProvider == null) throw Exception('AppThemeProvider not found');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = AppColors.primary;

    final drawerItems = [
      {'icon': Icons.home_outlined, 'title': 'الرئيسية'},
      {'icon': Icons.person_outline, 'title': 'البروفايل'},
      {'icon': Icons.settings_outlined, 'title': 'الإعدادات'},
      {'icon': Icons.contact_mail_outlined, 'title': 'تواصل معنا'},
      {'icon': Icons.info_outline, 'title': 'حول التطبيق'},
      {'icon': Icons.share_outlined, 'title': 'مشاركة التطبيق'},
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1A0F) : const Color(0xFFF5F9F0),
      appBar: _buildAppBar(context, isDark),
      drawer: _buildDrawer(context, user, isDark, activeColor, drawerItems, themeProvider),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadFarmAndWeather,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            _buildWeatherCard(context, isDark),
          ],
        ),
      ),
    );
  }

  // ── Weather Card ────────────────────────────────────────────────
  Widget _buildWeatherCard(BuildContext context, bool isDark) {
    if (_weatherLoading) return _weatherSkeleton(isDark);
    if (_weatherData == null) return _weatherUnavailable(context, isDark);

    final temp = (_weatherData!['main']['temp'] as num).round();
    final feelsLike = (_weatherData!['main']['feels_like'] as num).round();
    final humidity = (_weatherData!['main']['humidity'] as num).toInt();
    final windSpeed = (_weatherData!['wind']['speed'] as num).toDouble();
    final desc = _weatherData!['weather'][0]['description'] as String;
    final icon = _weatherData!['weather'][0]['icon'] as String;
    final bool goodForIrrigation =
        temp < 35 && humidity < 80 && windSpeed < 8 && !desc.contains('مطر');

    return GestureDetector(
      onTap: _farmLat != null
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WeatherScreen(
                    lat: _farmLat!,
                    lng: _farmLng!,
                    // ← نمرر اسم الموقع الحقيقي لصفحة الطقس أيضاً
                    locationName: _locationDisplayName,
                  ),
                ),
              )
          : null,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              const Color(0xFF7C9473),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // دوائر زخرفية
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              bottom: -25,
              left: -10,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ← اسم الموقع الحقيقي هنا
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _locationDisplayName,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Text('تفاصيل',
                          style:
                              TextStyle(color: Colors.white60, fontSize: 12)),
                      const SizedBox(width: 3),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.white60, size: 11),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // درجة الحرارة + أيقونة
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$temp°C',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 52,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(desc,
                              style: TextStyle(
                                  color:
                                      Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13)),
                          const SizedBox(height: 2),
                          Text('الإحساس بـ $feelsLike°',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                      const Spacer(),
                      Image.network(
                        'https://openweathermap.org/img/wn/$icon@2x.png',
                        width: 72,
                        height: 72,
                        errorBuilder: (_, e, __) => const Icon(
                            Icons.cloud_rounded,
                            color: Colors.white54,
                            size: 56),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Divider(
                      color: Colors.white.withValues(alpha: 0.2), height: 1),

                  const SizedBox(height: 14),

                  // stats + badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _weatherStat(Icons.water_drop_rounded, '$humidity%',
                          'الرطوبة'),
                      _weatherStat(Icons.air_rounded,
                          '${windSpeed.toStringAsFixed(1)} م/ث', 'الرياح'),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: goodForIrrigation
                              ? Colors.white.withValues(alpha: 0.18)
                              : Colors.red.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: goodForIrrigation
                                ? Colors.white.withValues(alpha: 0.4)
                                : Colors.red.shade300.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              goodForIrrigation
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              color: goodForIrrigation
                                  ? Colors.white
                                  : Colors.red.shade200,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              goodForIrrigation ? 'مناسب للري' : 'تجنب الري',
                              style: TextStyle(
                                color: goodForIrrigation
                                    ? Colors.white
                                    : Colors.red.shade200,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _weatherStat(IconData icon, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white60, size: 13),
            const SizedBox(width: 4),
            Text(label,
                style:
                    const TextStyle(color: Colors.white60, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _weatherSkeleton(bool isDark) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.3),
            const Color(0xFF7C9473).withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: CircularProgressIndicator(
            color: AppColors.primary, strokeWidth: 2),
      ),
    );
  }

  Widget _weatherUnavailable(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, const Color(0xFF7C9473)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded,
              color: Colors.white70, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('بيانات الطقس غير متاحة',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 14)),
                const SizedBox(height: 4),
                Text('تأكد من إضافة موقع مزرعتك',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.refresh_rounded,
              color: Colors.white70, size: 20),
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor:
          isDark ? const Color(0xFF0F1A0F) : const Color(0xFFF5F9F0),
      foregroundColor: AppColors.primary,
      titleTextStyle: TextStyle(
        color: AppColors.primary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
      leading: Builder(
        builder: (context) => GestureDetector(
          onTap: () => Scaffold.of(context).openDrawer(),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                Icon(Icons.menu_rounded, color: AppColors.primary, size: 20),
          ),
        ),
      ),
      title: const Text('AgriPal'),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('قريباً: صفحة الإشعارات'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.notifications_outlined,
                  color: AppColors.primary, size: 20),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
            height: 1,
            color: AppColors.primary.withValues(alpha: 0.08)),
      ),
    );
  }

  // ── Drawer ────────────────────────────────────────────────────────
  Widget _buildDrawer(
    BuildContext context,
    User? user,
    bool isDark,
    Color activeColor,
    List<Map<String, Object>> drawerItems,
    AppThemeProvider themeProvider,
  ) {
    return Drawer(
      shape: const RoundedRectangleBorder(),
      backgroundColor:
          isDark ? const Color(0xFF0F1A0F) : Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.accent.withValues(alpha: 0.85)
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
                            color: Colors.white.withValues(alpha: 0.6),
                            width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4)),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 34,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.2),
                        backgroundImage: (user?.photoURL != null)
                            ? NetworkImage(user!.photoURL!)
                            : null,
                        child: (user?.photoURL == null)
                            ? Icon(Icons.person_rounded,
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
                          border:
                              Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(user?.displayName ?? 'مستخدم AgriPal',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        letterSpacing: 0.3)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.mail_outline_rounded,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 12),
                    const SizedBox(width: 4),
                    Text(user?.email ?? '',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: drawerItems.length,
              itemBuilder: (context, index) {
                return _AnimatedDrawerItem(
                  icon: drawerItems[index]['icon'] as IconData,
                  title: drawerItems[index]['title'] as String,
                  isSelected: _selectedDrawerIndex == index,
                  activeColor: activeColor,
                  delay: index * 60,
                  onTap: () {
                    setState(() => _selectedDrawerIndex = index);
                    Navigator.pop(context);
                    switch (index) {
                      case 1:
                        if (user != null) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      ProfileScreen(user: user)));
                        }
                        break;
                      case 2:
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => SettingsScreen(
                                      onThemeChanged:
                                          themeProvider.onThemeChanged,
                                      currentTheme:
                                          themeProvider.currentTheme,
                                    )));
                        break;
                      default:
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(
                          content: Text(
                              'قريباً: ${drawerItems[index]['title']}'),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ));
                    }
                  },
                );
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 20),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.eco_rounded,
                    color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Text('AgriPal v1.0.0',
                    style: TextStyle(
                        fontSize: 12,
                        color:
                            AppColors.primary.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}