import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:agripal/core/constants/app_colors.dart';

class WeatherScreen extends StatefulWidget {
  final double lat;
  final double lng;
  final String locationName;

  const WeatherScreen({
    super.key,
    required this.lat,
    required this.lng,
    required this.locationName,
  });

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen>
    with SingleTickerProviderStateMixin {
  static const _apiKey = '3bd015115660091719e9545a0d7f5202';

  Map<String, dynamic>? _current;
  List<Map<String, dynamic>> _forecast = [];
  bool _loading = true;
  String? _error;

  late AnimationController _entryAnim;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _entryAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fade = CurvedAnimation(parent: _entryAnim, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryAnim, curve: Curves.easeOut));
    _fetchWeather();
  }

  @override
  void dispose() {
    _entryAnim.dispose();
    super.dispose();
  }

  Future<void> _fetchWeather() async {
    try {
      final currentRes = await http.get(Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather'
        '?lat=${widget.lat}&lon=${widget.lng}'
        '&appid=$_apiKey&units=metric&lang=ar',
      ));
      final forecastRes = await http.get(Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast'
        '?lat=${widget.lat}&lon=${widget.lng}'
        '&appid=$_apiKey&units=metric&lang=ar&cnt=16',
      ));

      if (currentRes.statusCode == 200 && forecastRes.statusCode == 200) {
        final curData = json.decode(currentRes.body);
        final foreData = json.decode(forecastRes.body);
        final List rawList = foreData['list'];
        final Map<String, Map<String, dynamic>> dayMap = {};
        for (final item in rawList) {
          final dt =
              DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
          final key =
              '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
          if (!dayMap.containsKey(key)) {
            dayMap[key] = Map<String, dynamic>.from(item);
          }
        }
        setState(() {
          _current = curData;
          _forecast = dayMap.values.take(5).toList();
          _loading = false;
        });
      } else {
        setState(() { _error = 'فشل تحميل بيانات الطقس'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'تحقق من اتصال الإنترنت'; _loading = false; });
    }
  }

  String _iconUrl(String code) =>
      'https://openweathermap.org/img/wn/$code@2x.png';

  String _arabicDay(DateTime dt) {
    const days = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    return days[dt.weekday - 1];
  }

  String _agriAdvice() {
    if (_current == null) return '';
    final desc = _current!['weather'][0]['description'] as String;
    final temp = (_current!['main']['temp'] as num).toDouble();
    final humidity = (_current!['main']['humidity'] as num).toDouble();
    final wind = (_current!['wind']['speed'] as num).toDouble();
    if (desc.contains('مطر') || desc.contains('rain'))
      return '🌧️ يوم ممطر - تجنب الري واحذر من التشبع المائي';
    if (temp > 38)
      return '🌡️ حرارة شديدة - اري نباتاتك في الصباح الباكر أو المساء';
    if (wind > 10) return '💨 رياح قوية - تأخر في رش المبيدات اليوم';
    if (humidity < 30) return '💧 جفاف في الهواء - زد كمية الري اليوم';
    return '✅ طقس مناسب للعمل الزراعي اليوم';
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F1A0F) : const Color(0xFFF5F9F0),
      body: _loading
          ? _buildLoading()
          : _error != null
              ? _buildError()
              : _buildContent(isDark),
    );
  }

  // ── Loading ───────────────────────────────────────────────────────
  Widget _buildLoading() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, const Color(0xFF7C9473)],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            SizedBox(height: 16),
            Text('جارٍ تحميل بيانات الطقس...',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // ── Error ─────────────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded,
              size: 60, color: AppColors.primary.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(_error!,
              style: const TextStyle(fontSize: 15, color: Colors.grey)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              setState(() { _loading = true; _error = null; });
              _fetchWeather();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [AppColors.primary, const Color(0xFF7C9473)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('إعادة المحاولة',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Content ───────────────────────────────────────────────────────
  Widget _buildContent(bool isDark) {
    final temp = (_current!['main']['temp'] as num).round();
    final feelsLike = (_current!['main']['feels_like'] as num).round();
    final humidity = (_current!['main']['humidity'] as num).toInt();
    final windSpeed = (_current!['wind']['speed'] as num).toDouble();
    final desc = _current!['weather'][0]['description'] as String;
    final icon = _current!['weather'][0]['icon'] as String;
    final sunrise = DateTime.fromMillisecondsSinceEpoch(
        (_current!['sys']['sunrise'] as num).toInt() * 1000);
    final sunset = DateTime.fromMillisecondsSinceEpoch(
        (_current!['sys']['sunset'] as num).toInt() * 1000);

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ──────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              elevation: 0,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    // Gradient bg — نفس add_screen header
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primary, const Color(0xFF7C9473)],
                        ),
                      ),
                    ),
                    // Decorative circles
                    Positioned(
                      top: -30,
                      right: -30,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    // Content
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Location
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.location_on_rounded,
                                    color: Colors.white70, size: 14),
                                const SizedBox(width: 4),
                                Text(widget.locationName,
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Temp
                            Text(
                              '$temp°C',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 68,
                                fontWeight: FontWeight.bold,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Icon + desc
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.network(_iconUrl(icon),
                                    width: 40,
                                    height: 40,
                                    errorBuilder: (_, e, __) =>
                                        const SizedBox()),
                                const SizedBox(width: 4),
                                Text(desc,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 15)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('الإحساس بـ $feelsLike°',
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── نصيحة زراعية ────────────────────────────────
                    _buildAdviceCard(isDark),
                    const SizedBox(height: 22),

                    // ── تفاصيل الطقس ─────────────────────────────────
                    _sectionTitle('تفاصيل الطقس', isDark),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.7,
                      children: [
                        _statCard(Icons.water_drop_rounded, 'الرطوبة',
                            '$humidity%', AppColors.primary, isDark),
                        _statCard(Icons.air_rounded, 'الرياح',
                            '${windSpeed.toStringAsFixed(1)} م/ث',
                            const Color(0xFF2E7D9A), isDark),
                        _statCard(Icons.wb_sunny_rounded, 'الشروق',
                            _fmt(sunrise), const Color(0xFFE07B30), isDark),
                        _statCard(Icons.nights_stay_rounded, 'الغروب',
                            _fmt(sunset), const Color(0xFF7B68EE), isDark),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // ── توقعات 5 أيام ────────────────────────────────
                    if (_forecast.isNotEmpty) ...[
                      _sectionTitle('توقعات 5 أيام', isDark),
                      const SizedBox(height: 12),
                      ..._forecast.map((day) => _buildForecastRow(day, isDark)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────

  Widget _buildAdviceCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2A1A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.eco_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('نصيحة زراعية',
                    style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.grey.shade400,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(
                  _agriAdvice(),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, bool isDark) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
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
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : const Color(0xFF2A3A2A),
          ),
        ),
      ],
    );
  }

  Widget _statCard(IconData icon, String label, String value, Color color,
      bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.06 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color:
                          isDark ? Colors.white38 : Colors.grey.shade500)),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastRow(Map<String, dynamic> day, bool isDark) {
    final dt = DateTime.fromMillisecondsSinceEpoch(
        (day['dt'] as num).toInt() * 1000);
    final dayName = _arabicDay(dt);
    final tempMax = (day['main']['temp_max'] as num).round();
    final tempMin = (day['main']['temp_min'] as num).round();
    final icon = day['weather'][0]['icon'] as String;
    final desc = day['weather'][0]['description'] as String;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (_, v, child) =>
          Opacity(opacity: v.clamp(0.0, 1.0), child: child),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2A1A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: Text(dayName,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isDark
                          ? Colors.white70
                          : const Color(0xFF2A3A2A))),
            ),
            Image.network(_iconUrl(icon),
                width: 34,
                height: 34,
                errorBuilder: (_, e, __) =>
                    Icon(Icons.cloud_rounded,
                        color: Colors.grey.shade400, size: 24)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(desc,
                  style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? Colors.white38
                          : Colors.grey.shade500)),
            ),
            Text('$tempMax°',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.primary)),
            const SizedBox(width: 6),
            Text('$tempMin°',
                style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? Colors.white38
                        : Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }
}