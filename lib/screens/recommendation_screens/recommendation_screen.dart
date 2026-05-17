// ══════════════════════════════════════════════════════════════════
// recommendation_screen.dart  — AgriPal (إصلاح كامل)
// ══════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agripal/core/constants/app_colors.dart';
import 'package:agripal/data/crop_information.dart';
import 'package:agripal/screens/home/widgets/farm_setup_sheet.dart';

const _kOwmKey = '3bd015115660091719e9545a0d7f5202';

// ─────────────────────────────────────────────────────────────────
// مساعد كاش الطقس — يخزن بيانات كل موقع على حدا ويتحدث يومياً
// ─────────────────────────────────────────────────────────────────
class _WeatherCache {
  /// مفتاح التخزين: weather_lat_lng_date
  static String _key(double lat, double lng) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final latS = lat.toStringAsFixed(4);
    final lngS = lng.toStringAsFixed(4);
    return 'weather_${latS}_${lngS}_$today';
  }

  static Future<Map<String, dynamic>?> load(double lat, double lng) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _key(lat, lng);
      final raw = prefs.getString(key);
      if (raw == null) return null;
      return json.decode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(
      double lat, double lng, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _key(lat, lng);
      // احذف مفاتيح أقدم من اليوم لنفس الموقع (تنظيف)
      final latS = lat.toStringAsFixed(4);
      final lngS = lng.toStringAsFixed(4);
      final prefix = 'weather_${latS}_${lngS}_';
      final allKeys = prefs.getKeys().where((k) => k.startsWith(prefix));
      for (final old in allKeys) {
        if (old != key) await prefs.remove(old);
      }
      await prefs.setString(key, json.encode(data));
    } catch (_) {}
  }
}

// ══════════════════════════════════════════════════════════════════
// الشاشة الرئيسية
// ══════════════════════════════════════════════════════════════════
class RecommendationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> rec;

  const RecommendationDetailScreen({super.key, required this.rec});

  @override
  State<RecommendationDetailScreen> createState() =>
      _RecommendationDetailScreenState();
}

class _RecommendationDetailScreenState
    extends State<RecommendationDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── بيانات المحصول ──
  late String _cropType;
  late String _soilType;
  late String _irrigationType;
  late DateTime _plantingDate;
  late double _farmArea;
  late double _farmLat;
  late double _farmLng;
  late int _cycleDays;
  late String _locationName;
  CropInfo? _cropInfo;

  // ── بيانات الطقس ──
  List<Map<String, dynamic>> _weekForecast = [];
  Map<String, dynamic>? _currentWeather;
  bool _weatherLoading = true;
  bool _weatherError = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _parseCropData();
    _loadWeather(); // يحمل من الكاش أولاً ثم يحدّث إن احتاج
  }

  void _parseCropData() {
    final r = widget.rec;
    _cropType = r['crop_type'] as String? ?? 'بطاطس';
    _soilType = r['soil_type'] as String? ?? 'طميية (لومي)';
    _irrigationType = r['irrigation_type'] as String? ?? 'بالتنقيط';
    _farmArea = (r['farm_area'] as num?)?.toDouble() ?? 1.0;
    // !! الإحداثيات الحقيقية من بيانات المحصول — لا تستخدم إحداثيات ثابتة
    _farmLat = (r['farm_lat'] as num?)?.toDouble() ?? 36.9;
    _farmLng = (r['farm_lng'] as num?)?.toDouble() ?? 7.76;
    _cycleDays = (r['cycle_days'] as int?) ?? 120;
    _locationName = r['location_name'] as String? ?? 'غير محدد';
    final dateStr = r['planting_date'] as String?;
    _plantingDate =
        (dateStr != null ? DateTime.tryParse(dateStr) : null) ?? DateTime.now();
    _cropInfo = CropDatabase.getCrop(_cropType);
  }

  // ── تحميل الطقس: كاش أولاً → شبكة إن لزم ──
  Future<void> _loadWeather({bool forceRefresh = false}) async {
    setState(() {
      _weatherLoading = true;
      _weatherError = false;
    });

    // جرّب الكاش أولاً (إلا إذا طُلب تحديث قسري)
    if (!forceRefresh) {
      final cached = await _WeatherCache.load(_farmLat, _farmLng);
      if (cached != null) {
        _applyWeatherData(cached);
        setState(() => _weatherLoading = false);
        return;
      }
    }

    // جلب من الشبكة
    await _fetchFromNetwork();
  }

  Future<void> _fetchFromNetwork() async {
    try {
      // ── الطقس الحالي ──
      final currentRes = await http
          .get(Uri.parse(
            'https://api.openweathermap.org/data/2.5/weather'
            '?lat=$_farmLat&lon=$_farmLng&appid=$_kOwmKey&units=metric&lang=ar',
          ))
          .timeout(const Duration(seconds: 10));

      // ── توقعات 5 أيام ──
      final forecastRes = await http
          .get(Uri.parse(
            'https://api.openweathermap.org/data/2.5/forecast'
            '?lat=$_farmLat&lon=$_farmLng&appid=$_kOwmKey&units=metric&lang=ar',
          ))
          .timeout(const Duration(seconds: 10));

      Map<String, dynamic>? current;
      List<Map<String, dynamic>> forecast = [];

      if (currentRes.statusCode == 200) {
        current = json.decode(currentRes.body) as Map<String, dynamic>;
      }

      if (forecastRes.statusCode == 200) {
        final data = json.decode(forecastRes.body) as Map<String, dynamic>;
        final list = data['list'] as List;

        final Map<String, Map<String, dynamic>> dailyMap = {};
        for (final item in list) {
          final dt = DateTime.fromMillisecondsSinceEpoch(
              (item['dt'] as int) * 1000);
          final dayKey = DateFormat('yyyy-MM-dd').format(dt);
          if (!dailyMap.containsKey(dayKey) || dt.hour == 12) {
            dailyMap[dayKey] = item as Map<String, dynamic>;
          }
        }

        forecast = dailyMap.values.take(7).map((item) {
          final dt = DateTime.fromMillisecondsSinceEpoch(
              (item['dt'] as int) * 1000);
          return {
            'date': dt.toIso8601String(),
            'temp': (item['main']['temp'] as num).toDouble(),
            'temp_min': (item['main']['temp_min'] as num).toDouble(),
            'temp_max': (item['main']['temp_max'] as num).toDouble(),
            'humidity': item['main']['humidity'] as int,
            'wind_speed': (item['wind']['speed'] as num).toDouble(),
            'rain': ((item['rain']?['3h'] as num?) ?? 0.0).toDouble(),
            'description': item['weather'][0]['description'] as String,
            'icon': item['weather'][0]['icon'] as String,
            'weather_id': item['weather'][0]['id'] as int,
          };
        }).toList();
      }

      final payload = {
        'current': current,
        'forecast': forecast,
        'fetched_at': DateTime.now().toIso8601String(),
      };

      // حفظ في الكاش
      await _WeatherCache.save(_farmLat, _farmLng, payload);
      _applyWeatherData(payload);
    } catch (e) {
      debugPrint('خطأ في جلب الطقس للموقع ($_farmLat, $_farmLng): $e');
      if (mounted) setState(() => _weatherError = true);
    } finally {
      if (mounted) setState(() => _weatherLoading = false);
    }
  }

  void _applyWeatherData(Map<String, dynamic> payload) {
    _currentWeather = payload['current'] as Map<String, dynamic>?;

    final rawForecast = payload['forecast'] as List? ?? [];
    _weekForecast = rawForecast.map((item) {
      final m = Map<String, dynamic>.from(item as Map);
      // date مخزّنة كـ String → نحوّلها DateTime
      if (m['date'] is String) {
        m['date'] = DateTime.parse(m['date'] as String);
      }
      return m;
    }).toList();
  }

  // ── حسابات ──
  int get _daysSincePlanting =>
      DateTime.now().difference(_plantingDate).inDays + 1;
  int get _daysToHarvest =>
      (_cycleDays - _daysSincePlanting).clamp(0, _cycleDays);
  int get _progressPct =>
      ((_daysSincePlanting / _cycleDays) * 100).clamp(0, 100).toInt();

  String get _currentGrowthStage {
    if (_cropInfo != null) {
      for (final stage in _cropInfo!.growthStages) {
        if (_daysSincePlanting >= stage.fromDay &&
            _daysSincePlanting <= stage.toDay) {
          return stage.name;
        }
      }
    }
    final p = _progressPct;
    if (p < 20) return 'مرحلة الإنبات';
    if (p < 50) return 'نمو خضري';
    if (p < 80) return 'تكوين الثمار';
    return 'نضج وحصاد';
  }

  String get _cropEmoji => _cropInfo?.emoji ?? '🌱';
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F1A0F) : const Color(0xFFF5F9F0),
      body: NestedScrollView(
        headerSliverBuilder: (ctx, inner) => [_buildSliverHeader()],
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _CropTab(
                    cropInfo: _cropInfo,
                    cropType: _cropType,
                    soilType: _soilType,
                    irrigationType: _irrigationType,
                    plantingDate: _plantingDate,
                    farmArea: _farmArea,
                    locationName: _locationName,
                    cycleDays: _cycleDays,
                    daysSincePlanting: _daysSincePlanting,
                    daysToHarvest: _daysToHarvest,
                    progressPct: _progressPct,
                    currentGrowthStage: _currentGrowthStage,
                    weekForecast: _weekForecast,
                    weatherLoading: _weatherLoading,
                    weatherError: _weatherError,
                    onRetryWeather: () => _loadWeather(forceRefresh: true),
                    isDark: isDark,
                  ),
                  _IrrigationTab(
                    cropInfo: _cropInfo,
                    soilType: _soilType,
                    irrigationType: _irrigationType,
                    weekForecast: _weekForecast,
                    weatherLoading: _weatherLoading,
                    farmArea: _farmArea,
                    currentGrowthStage: _currentGrowthStage,
                    isDark: isDark,
                  ),
                  _FertilizationTab(
                    cropInfo: _cropInfo,
                    plantingDate: _plantingDate,
                    daysSincePlanting: _daysSincePlanting,
                    farmArea: _farmArea,
                    isDark: isDark,
                  ),
                  _DiseasesTab(cropInfo: _cropInfo, isDark: isDark),
                  _LibraryTab(
                      cropInfo: _cropInfo,
                      cropType: _cropType,
                      isDark: isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // SLIVER HEADER — مصلوح (لا overflow، زر + صغير في AppBar)
  // ══════════════════════════════════════════════════════════════════
  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 190,
      pinned: true,
      backgroundColor: AppColors.primary,
      // ── زر الرجوع ──
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
         
          child: const Icon(Icons.arrow_back_sharp,
              color: Colors.white, size: 18),
        ),
      ),
      // ── زر + (صغير، في AppBar الثابتة) ──
      actions: [
        Padding(
          padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
          child: Material(
            color: Colors.white.withOpacity(0.22),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                FarmSetupSheet.show(context);
              },
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(Icons.add_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3d7a28), Color(0xFF55833D)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 52, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── صف الهيدر الرئيسي ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // أيقونة المحصول
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(_cropEmoji,
                              style: const TextStyle(fontSize: 28)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // النصوص — Expanded لمنع الـ overflow
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'خطة زراعة $_cropType',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$_currentGrowthStage  •  اليوم $_daysSincePlanting من $_cycleDays',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // موقع (مضغوط)
                      Container(
                        constraints: const BoxConstraints(maxWidth: 100),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_rounded,
                                color: Colors.white, size: 11),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                _locationName,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ── شريط التقدم ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'تقدم الدورة الزراعية',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        '$_progressPct%  •  متبقي $_daysToHarvest يوم',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _progressPct / 100,
                      minHeight: 7,
                      backgroundColor: Colors.white.withOpacity(0.25),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // TAB BAR
  // ══════════════════════════════════════════════════════════════════
  Widget _buildTabBar() {
    final tabs = [
      ('المحصول', Icons.dashboard_rounded),
      ('الري', Icons.water_drop_rounded),
      ('الأسمدة', Icons.science_rounded),
      ('الأمراض', Icons.bug_report_rounded),
      ('المكتبة', Icons.menu_book_rounded),
    ];

    return Container(
      color: isDark ? const Color(0xFF1A2A18) : Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        padding: EdgeInsets.zero,
        tabAlignment: TabAlignment.start,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.primary, width: 3),
          insets: const EdgeInsets.symmetric(horizontal: 8),
        ),
        labelColor: AppColors.primary,
        unselectedLabelColor:
            isDark ? Colors.white38 : Colors.grey.shade400,
        labelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        tabs: tabs
            .map((t) => Tab(
                  child: Row(
                    children: [
                      Icon(t.$2, size: 15),
                      const SizedBox(width: 5),
                      Text(t.$1),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 1: المحصول
// ══════════════════════════════════════════════════════════════════
class _CropTab extends StatelessWidget {
  final CropInfo? cropInfo;
  final String cropType,
      soilType,
      irrigationType,
      locationName,
      currentGrowthStage;
  final DateTime plantingDate;
  final double farmArea;
  final int cycleDays, daysSincePlanting, daysToHarvest, progressPct;
  final List<Map<String, dynamic>> weekForecast;
  final bool weatherLoading, weatherError, isDark;
  final VoidCallback onRetryWeather;

  const _CropTab({
    required this.cropInfo,
    required this.cropType,
    required this.soilType,
    required this.irrigationType,
    required this.plantingDate,
    required this.farmArea,
    required this.locationName,
    required this.cycleDays,
    required this.daysSincePlanting,
    required this.daysToHarvest,
    required this.progressPct,
    required this.currentGrowthStage,
    required this.weekForecast,
    required this.weatherLoading,
    required this.weatherError,
    required this.onRetryWeather,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // ── معلومات المحصول ──
        _SectionCard(
          title: 'معلومات المحصول',
          icon: Icons.info_rounded,
          isDark: isDark,
          child: Column(
            children: [
              _InfoRow('نوع المحصول', cropType, Icons.grass_rounded, isDark),
              _InfoRow('الموقع', locationName, Icons.location_on_rounded, isDark),
              _InfoRow(
                'تاريخ الزراعة',
                DateFormat('dd / MM / yyyy').format(plantingDate),
                Icons.calendar_today_rounded,
                isDark,
              ),
              _InfoRow('نوع التربة', soilType, Icons.layers_rounded, isDark),
              _InfoRow(
                  'طريقة الري', irrigationType, Icons.water_drop_rounded, isDark),
              _InfoRow(
                'مساحة الأرض',
                farmArea >= 1
                    ? '${farmArea.toStringAsFixed(2)} هكتار'
                    : '${(farmArea * 10000).toStringAsFixed(0)} م²',
                Icons.crop_square_rounded,
                isDark,
              ),
              _InfoRow(
                'موعد الحصاد',
                DateFormat('dd / MM / yyyy')
                    .format(plantingDate.add(Duration(days: cycleDays))),
                Icons.agriculture_rounded,
                isDark,
              ),
              _InfoRow(
                'المتبقي للحصاد',
                '$daysToHarvest يوم',
                Icons.timer_rounded,
                isDark,
                highlight: daysToHarvest < 14,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── جدول الدورة الزراعية ──
        if (cropInfo != null) ...[
          _SectionCard(
            title: 'جدول الدورة الزراعية',
            icon: Icons.timeline_rounded,
            isDark: isDark,
            child: Column(
              children: cropInfo!.growthStages.map((stage) {
                final isCurrent = daysSincePlanting >= stage.fromDay &&
                    daysSincePlanting <= stage.toDay;
                final isDone = daysSincePlanting > stage.toDay;
                return _GrowthStageRow(
                  stage: stage,
                  isCurrent: isCurrent,
                  isDone: isDone,
                  isDark: isDark,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── الطقس الأسبوعي ──
        _SectionCard(
          title: 'الطقس الأسبوعي',
          icon: Icons.wb_sunny_rounded,
          isDark: isDark,
          child: weatherLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              : weatherError
                  ? _WeatherErrorWidget(onRetry: onRetryWeather, isDark: isDark)
                  : weekForecast.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'تعذّر جلب بيانات الطقس',
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.grey.shade500),
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: weekForecast
                                .map((d) => _WeatherDayCard(
                                      data: d,
                                      isDark: isDark,
                                    ))
                                .toList(),
                          ),
                        ),
        ),

        const SizedBox(height: 16),

        // ── نصائح عامة ──
        if (cropInfo != null)
          _SectionCard(
            title: 'نصائح عامة',
            icon: Icons.lightbulb_rounded,
            isDark: isDark,
            accentColor: Colors.amber,
            child: Column(
              children: cropInfo!.generalTipsForCrop
                  .map((tip) => _TipRow(tip: tip, isDark: isDark))
                  .toList(),
            ),
          ),
      ],
    );
  }
}

// ── ويدجت خطأ الطقس مع زر إعادة المحاولة ──
class _WeatherErrorWidget extends StatelessWidget {
  final VoidCallback onRetry;
  final bool isDark;

  const _WeatherErrorWidget({required this.onRetry, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded,
              color: isDark ? Colors.white38 : Colors.grey.shade400),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'تعذّر جلب الطقس — تحقق من اتصالك',
              style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.grey.shade500),
            ),
          ),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('إعادة', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 2: الري
// ══════════════════════════════════════════════════════════════════
class _IrrigationTab extends StatelessWidget {
  final CropInfo? cropInfo;
  final String soilType, irrigationType, currentGrowthStage;
  final List<Map<String, dynamic>> weekForecast;
  final bool weatherLoading, isDark;
  final double farmArea;

  const _IrrigationTab({
    required this.cropInfo,
    required this.soilType,
    required this.irrigationType,
    required this.weekForecast,
    required this.weatherLoading,
    required this.farmArea,
    required this.currentGrowthStage,
    required this.isDark,
  });

  double _adjustedWaterAmount(double baseAmount, String soil) {
    const m = {
      'طينية': 0.7,
      'رملية': 1.25,
      'طميية (لومي)': 1.0,
      'طينية رملية': 1.15,
      'حصوية': 1.4,
      'عضوية (خصبة)': 0.95,
    };
    return baseAmount * (m[soil] ?? 1.0);
  }

  double _weatherMultiplier(Map<String, dynamic> day) {
    final temp = day['temp'] as double;
    final rain = day['rain'] as double;
    if (rain > 5) return 0.3;
    if (rain > 2) return 0.6;
    if (temp > 35) return 1.4;
    if (temp > 28) return 1.2;
    if (temp < 15) return 0.7;
    return 1.0;
  }

  String _irrigationTime(Map<String, dynamic> day) {
    final temp = day['temp'] as double;
    if (temp > 30) return '6:00 ص - 7:30 ص  أو  6:00 م - 7:00 م';
    return '7:00 ص - 8:30 ص';
  }

  String _irrigationAdvice(Map<String, dynamic> day) {
    final rain = day['rain'] as double;
    final temp = day['temp'] as double;
    if (rain > 5) return '🌧️ مطر كافٍ - لا حاجة للري اليوم';
    if (rain > 2) return '🌦️ مطر خفيف - قلل كمية الري بنسبة 40%';
    if (temp > 35) return '🌡️ حرارة شديدة - زد الكمية وتجنب وقت الذروة';
    return '✅ ري طبيعي';
  }

  @override
  Widget build(BuildContext context) {
    final irr = cropInfo?.irrigation;
    final baseWeekly = irr?.waterNeedMmPerWeek ?? 35.0;
    final stageMultiplier = irr?.stageWaterMultiplier[currentGrowthStage] ?? 1.0;
    final soilAdjusted = _adjustedWaterAmount(baseWeekly, soilType);
    final dailyBase = (soilAdjusted * stageMultiplier) / 7;
    final areaM2 = farmArea * 10000;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _SectionCard(
          title: 'احتياج الري الأسبوعي',
          icon: Icons.water_drop_rounded,
          isDark: isDark,
          accentColor: Colors.blue,
          child: Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: 'حجم الري الأسبوعي',
                  value:
                      '${(soilAdjusted * stageMultiplier).toStringAsFixed(0)} مم',
                  icon: Icons.water_rounded,
                  color: Colors.blue,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBox(
                  label: 'لترات/هكتار/أسبوع',
                  value:
                      '${(soilAdjusted * stageMultiplier * 10).toStringAsFixed(0)} ألف',
                  icon: Icons.opacity_rounded,
                  color: Colors.cyan,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'الخطة الأسبوعية للري',
          icon: Icons.calendar_view_week_rounded,
          isDark: isDark,
          accentColor: Colors.blue,
          child: weatherLoading
              ? const Center(child: CircularProgressIndicator())
              : weekForecast.isEmpty
                  ? _buildStaticIrrigationPlan(dailyBase, areaM2)
                  : Column(
                      children: weekForecast.asMap().entries.map((entry) {
                        final day = entry.value;
                        final wMult = _weatherMultiplier(day);
                        final dayAmount = dailyBase * wMult;
                        final liters = dayAmount * areaM2 / 1000;
                        final skip = wMult < 0.5;
                        return _IrrigationDayCard(
                          dayIndex: entry.key,
                          date: day['date'] as DateTime,
                          amount: dayAmount,
                          liters: liters,
                          time: _irrigationTime(day),
                          advice: _irrigationAdvice(day),
                          skip: skip,
                          rain: day['rain'] as double,
                          temp: day['temp'] as double,
                          isDark: isDark,
                        );
                      }).toList(),
                    ),
        ),
        const SizedBox(height: 16),
        if (irr != null) ...[
          _SectionCard(
            title: 'نصيحة لنوع ريّك ($irrigationType)',
            icon: Icons.tips_and_updates_rounded,
            isDark: isDark,
            accentColor: Colors.teal,
            child: _AdviceBlock(
              text: irr.irrigationTypeAdvice[irrigationType] ??
                  'اتبع الجدول العام للري',
              isDark: isDark,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'نصيحة لتربتك ($soilType)',
            icon: Icons.layers_rounded,
            isDark: isDark,
            accentColor: Colors.brown,
            child: _AdviceBlock(
              text: irr.soilTypeAdvice[soilType] ?? 'اتبع الجدول العام',
              isDark: isDark,
              color: Colors.brown,
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'نصائح عامة للري',
            icon: Icons.lightbulb_rounded,
            isDark: isDark,
            accentColor: Colors.amber,
            child: Column(
              children: irr.generalTips
                  .map((tip) => _TipRow(tip: tip, isDark: isDark))
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStaticIrrigationPlan(double dailyBase, double areaM2) {
    final days = [
      'السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'
    ];
    return Column(
      children: days.asMap().entries.map((e) {
        final skip = e.key % 3 == 2;
        return _IrrigationDayCard(
          dayIndex: e.key,
          date: DateTime.now().add(Duration(days: e.key)),
          amount: skip ? 0 : dailyBase,
          liters: skip ? 0 : dailyBase * areaM2 / 1000,
          time: '7:00 ص - 8:30 ص',
          advice: skip ? '✅ يوم راحة' : '✅ ري طبيعي',
          skip: skip,
          rain: 0,
          temp: 25,
          isDark: isDark,
        );
      }).toList(),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 3: الأسمدة
// ══════════════════════════════════════════════════════════════════
class _FertilizationTab extends StatelessWidget {
  final CropInfo? cropInfo;
  final DateTime plantingDate;
  final int daysSincePlanting;
  final double farmArea;
  final bool isDark;

  const _FertilizationTab({
    required this.cropInfo,
    required this.plantingDate,
    required this.daysSincePlanting,
    required this.farmArea,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final stages = cropInfo?.fertilization ?? [];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (stages.isEmpty)
          Center(
            child: Text('لا توجد بيانات للأسمدة',
                style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.grey)),
          )
        else ...[
          _currentStageCard(stages),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'خطة التسميد الكاملة',
            icon: Icons.science_rounded,
            isDark: isDark,
            accentColor: Colors.green,
            child: Column(
              children: stages
                  .map((stage) => _FertilizationCard(
                        stage: stage,
                        plantingDate: plantingDate,
                        daysSincePlanting: daysSincePlanting,
                        farmArea: farmArea,
                        isDark: isDark,
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'نصائح مهمة للتسميد',
            icon: Icons.warning_amber_rounded,
            isDark: isDark,
            accentColor: Colors.orange,
            child: Column(
              children: const [
                _StaticTip('لا تضع السماد مباشرة على الساق أو الجذور لتجنب الحرق'),
                _StaticTip('تجنب التسميد في أوقات الحرارة الشديدة'),
                _StaticTip('تأكد من ري التربة قبل وبعد إضافة الأسمدة الكيميائية'),
                _StaticTip('لا تفرط في النيتروجين - يزيد الأوراق ويقلل الثمار'),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _currentStageCard(List<FertilizationStage> stages) {
    FertilizationStage? current;
    for (final s in stages) {
      if (daysSincePlanting >= s.fromDay && daysSincePlanting <= s.toDay) {
        current = s;
        break;
      }
    }
    if (current == null) {
      return _SectionCard(
        title: 'مرحلة التسميد الحالية',
        icon: Icons.access_time_rounded,
        isDark: isDark,
        accentColor: Colors.green,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            daysSincePlanting < 0 ? 'لم تبدأ الزراعة بعد' : 'انتهت جميع مراحل التسميد',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          ),
        ),
      );
    }
    final qty = current.quantityPer100Sqm * farmArea * 100;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.primary.withOpacity(0.15),
          Colors.green.withOpacity(0.05),
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.circle, color: Colors.green, size: 10),
            const SizedBox(width: 8),
            Text('السماد الحالي: ${current.stageName}',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
          ]),
          const SizedBox(height: 10),
          _InfoRow('نوع السماد', current.fertilizerType,
              Icons.science_rounded, isDark),
          _InfoRow('اسم السماد', current.fertilizerName,
              Icons.inventory_2_rounded, isDark),
          _InfoRow(
              'الكمية الإجمالية',
              '${qty.toStringAsFixed(1)} كغ لـ ${farmArea.toStringAsFixed(2)} هكتار',
              Icons.scale_rounded,
              isDark),
          _InfoRow('طريقة الاستخدام', current.applicationMethod,
              Icons.handyman_rounded, isDark),
          _InfoRow('وقت التطبيق', current.applicationTime,
              Icons.schedule_rounded, isDark),
          if (current.notes.isNotEmpty)
            _InfoRow('ملاحظات', current.notes, Icons.note_rounded, isDark),
        ],
      ),
    );
  }
}

class _StaticTip extends StatelessWidget {
  final String text;
  const _StaticTip(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _TipRow(tip: text, isDark: isDark);
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 4: الأمراض
// ══════════════════════════════════════════════════════════════════
class _DiseasesTab extends StatelessWidget {
  final CropInfo? cropInfo;
  final bool isDark;

  const _DiseasesTab({required this.cropInfo, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final diseases = cropInfo?.diseases ?? [];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (diseases.isEmpty)
          const Center(child: Text('لا توجد بيانات للأمراض'))
        else ...[
          ...diseases.map((d) => _DiseaseCard(disease: d, isDark: isDark)),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'نصائح للوقاية العامة',
            icon: Icons.shield_rounded,
            isDark: isDark,
            accentColor: Colors.red,
            child: Column(children: [
              _TipRow(
                  tip: 'تجنب الري الزائد - البيئة الرطبة تشجع الأمراض الفطرية',
                  isDark: isDark,
                  isWarning: true),
              _TipRow(tip: 'تناوب المحاصيل كل موسم لتقليل الأمراض', isDark: isDark),
              _TipRow(
                  tip: 'افحص النباتات أسبوعياً للكشف المبكر عن الأعراض',
                  isDark: isDark),
              _TipRow(
                  tip: 'أزل وأحرق النباتات المصابة فوراً لمنع الانتشار',
                  isDark: isDark,
                  isWarning: true),
              _TipRow(
                  tip: 'استخدم بذاراً صحياً معتمداً من مصادر موثوقة',
                  isDark: isDark),
              _TipRow(
                  tip: 'تجنب الزراعة في التربة الباردة والمبللة', isDark: isDark),
            ]),
          ),
        ],
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 5: المكتبة
// ══════════════════════════════════════════════════════════════════
class _LibraryTab extends StatelessWidget {
  final CropInfo? cropInfo;
  final String cropType;
  final bool isDark;

  const _LibraryTab(
      {required this.cropInfo, required this.cropType, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final info = cropInfo;
    if (info == null) {
      return Center(child: Text('لا توجد معلومات لـ $cropType'));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _SectionCard(
          title: 'عن ${info.cropName}',
          icon: Icons.info_outline_rounded,
          isDark: isDark,
          child: Text(info.description,
              style: TextStyle(
                  fontSize: 14,
                  height: 1.7,
                  color: isDark ? Colors.white70 : Colors.black54)),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'ظروف النمو المناسبة',
          icon: Icons.thermostat_rounded,
          isDark: isDark,
          child: Column(children: [
            _ClimateRow('درجة الحرارة المثلى', '${info.climate.optimalTempC}°C', isDark),
            _ClimateRow('المدى الحراري',
                '${info.climate.minTempC}°C - ${info.climate.maxTempC}°C', isDark),
            _ClimateRow('الرطوبة النسبية',
                '${info.climate.minHumidityPct}% - ${info.climate.maxHumidityPct}%', isDark),
            _ClimateRow('التعرض للشمس', info.climate.sunExposure, isDark),
            _ClimateRow('تحمل الرياح', info.climate.windTolerance, isDark),
            _ClimateRow('الأمطار السنوية', '${info.climate.annualRainfallMm} مم', isDark),
          ]),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'دورة النمو (${info.cycleDays} يوم)',
          icon: Icons.rotate_right_rounded,
          isDark: isDark,
          child: Column(
            children: info.growthStages
                .map((s) => _GrowthStageRow(
                    stage: s, isCurrent: false, isDone: false, isDark: isDark, showDays: true))
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'معايير التربة الملائمة',
          icon: Icons.layers_rounded,
          isDark: isDark,
          child: Column(children: [
            _ClimateRow('التربة المناسبة', info.soil.suitableSoils.join('، '), isDark),
            _ClimateRow('درجة الحموضة (pH)',
                '${info.soil.minPH} - ${info.soil.maxPH}  (مثالي: ${info.soil.optimalPH})', isDark),
            _ClimateRow('التصريف', info.soil.drainage, isDark),
            _ClimateRow('المادة العضوية', info.soil.organicMatter, isDark),
            _ClimateRow('القوام', info.soil.texture, isDark),
          ]),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'احتياج الري',
          icon: Icons.water_drop_rounded,
          isDark: isDark,
          accentColor: Colors.blue,
          child: Column(children: [
            _ClimateRow('الاحتياج الأسبوعي',
                '${info.irrigation.waterNeedMmPerWeek} مم/أسبوع', isDark),
            _ClimateRow('أفضل وقت للري', info.irrigation.bestTime, isDark),
            _ClimateRow('التردد', info.irrigation.frequency, isDark),
          ]),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'المحاصيل المرافقة',
          icon: Icons.people_alt_rounded,
          isDark: isDark,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _TagRow(label: '✅ جيدة', tags: info.companionGood, color: Colors.green, isDark: isDark),
            const SizedBox(height: 8),
            _TagRow(label: '❌ سيئة', tags: info.companionBad, color: Colors.red, isDark: isDark),
          ]),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'كيفية الزراعة',
          icon: Icons.agriculture_rounded,
          isDark: isDark,
          child: Text(info.plantingMethod.replaceAll('**', ''),
              style: TextStyle(
                  fontSize: 13,
                  height: 1.8,
                  color: isDark ? Colors.white70 : Colors.black54)),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: _SectionCard(
              title: '✅ افعل',
              icon: Icons.check_circle_rounded,
              isDark: isDark,
              accentColor: Colors.green,
              child: Column(
                  children: info.doList
                      .map((t) => _TipRow(tip: t, isDark: isDark))
                      .toList()),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SectionCard(
              title: '❌ تجنب',
              icon: Icons.cancel_rounded,
              isDark: isDark,
              accentColor: Colors.red,
              child: Column(
                  children: info.dontList
                      .map((t) => _TipRow(tip: t, isDark: isDark, isWarning: true))
                      .toList()),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'طريقة الحصاد',
          icon: Icons.cut_rounded,
          isDark: isDark,
          accentColor: Colors.amber,
          child: Text(info.harvestMethod,
              style: TextStyle(
                  fontSize: 13,
                  height: 1.7,
                  color: isDark ? Colors.white70 : Colors.black54)),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ══════════════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final bool isDark;
  final Color? accentColor;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    required this.isDark,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2A18) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 10),
                Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1A2A1A))),
              ],
            ),
          ),
          Divider(
              height: 1,
              color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100),
          Padding(padding: const EdgeInsets.all(14), child: child),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final bool isDark, highlight;

  const _InfoRow(this.label, this.value, this.icon, this.isDark,
      {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 8),
        SizedBox(
          width: 110,
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.grey.shade500)),
        ),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
                  color: highlight
                      ? Colors.orange
                      : (isDark ? Colors.white : Colors.black87))),
        ),
      ]),
    );
  }
}

class _GrowthStageRow extends StatelessWidget {
  final GrowthStage stage;
  final bool isCurrent, isDone, isDark, showDays;

  const _GrowthStageRow({
    required this.stage,
    required this.isCurrent,
    required this.isDone,
    required this.isDark,
    this.showDays = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCurrent
        ? AppColors.primary
        : isDone
            ? Colors.grey
            : (isDark ? Colors.white24 : Colors.grey.shade300);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: isCurrent
                ? AppColors.primary.withOpacity(0.15)
                : isDone ? Colors.grey.withOpacity(0.1) : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: isCurrent ? 2 : 1),
          ),
          child: Center(child: Text(stage.emoji, style: const TextStyle(fontSize: 16))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(stage.name,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      color: isCurrent
                          ? AppColors.primary
                          : isDark ? Colors.white70 : Colors.black87)),
              const Spacer(),
              if (showDays || isCurrent)
                Text('يوم ${stage.fromDay} - ${stage.toDay}',
                    style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.grey.shade400)),
              if (isCurrent)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8)),
                  child: const Text('الآن',
                      style: TextStyle(color: Colors.white, fontSize: 10)),
                ),
            ]),
            const SizedBox(height: 3),
            Text(stage.description,
                style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.grey.shade500)),
          ]),
        ),
      ]),
    );
  }
}

class _WeatherDayCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDark;

  const _WeatherDayCard({required this.data, required this.isDark});

  String _weatherEmoji(int id) {
    if (id >= 200 && id < 300) return '⛈️';
    if (id >= 300 && id < 400) return '🌦️';
    if (id >= 500 && id < 600) return '🌧️';
    if (id >= 600 && id < 700) return '❄️';
    if (id >= 700 && id < 800) return '🌫️';
    if (id == 800) return '☀️';
    if (id > 800) return '⛅';
    return '🌤️';
  }

  @override
  Widget build(BuildContext context) {
    final date = data['date'] as DateTime;
    final temp = data['temp'] as double;
    final humidity = data['humidity'] as int;
    final wind = data['wind_speed'] as double;
    final rain = data['rain'] as double;
    final id = data['weather_id'] as int;

    return Container(
      width: 80,
      margin: const EdgeInsets.only(left: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? Colors.white12 : Colors.blue.shade100),
      ),
      child: Column(children: [
        Text(DateFormat('EEE', 'ar').format(date),
            style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : Colors.grey.shade500)),
        const SizedBox(height: 4),
        Text(_weatherEmoji(id), style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text('${temp.toStringAsFixed(0)}°',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.water_drop_rounded, size: 10, color: Colors.blue),
          Text('$humidity%',
              style: const TextStyle(fontSize: 9, color: Colors.blue)),
        ]),
        if (rain > 0) ...[
          const SizedBox(height: 2),
          Text('${rain.toStringAsFixed(1)}مم',
              style: const TextStyle(fontSize: 9, color: Colors.lightBlue)),
        ],
        const SizedBox(height: 2),
        Text('${wind.toStringAsFixed(1)}م/ث',
            style: TextStyle(
                fontSize: 9,
                color: isDark ? Colors.white38 : Colors.grey)),
      ]),
    );
  }
}

class _IrrigationDayCard extends StatelessWidget {
  final int dayIndex;
  final DateTime date;
  final double amount, liters;
  final String time, advice;
  final bool skip, isDark;
  final double rain, temp;

  const _IrrigationDayCard({
    required this.dayIndex,
    required this.date,
    required this.amount,
    required this.liters,
    required this.time,
    required this.advice,
    required this.skip,
    required this.isDark,
    required this.rain,
    required this.temp,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());
    final color = skip ? Colors.grey : Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isToday
            ? Colors.blue.withOpacity(isDark ? 0.15 : 0.07)
            : (isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday
              ? Colors.blue.withOpacity(0.4)
              : (isDark ? Colors.white12 : Colors.grey.shade200),
          width: isToday ? 1.5 : 1,
        ),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(DateFormat('EEE', 'ar').format(date),
                style: TextStyle(fontSize: 10, color: color)),
            Text(DateFormat('dd').format(date),
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              skip ? '🚫 بدون ري' : '💧 ${amount.toStringAsFixed(1)} مم',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: skip ? Colors.grey : (isDark ? Colors.white : Colors.black87)),
            ),
            if (!skip)
              Text('${(liters / 1000).toStringAsFixed(1)} م³  •  ⏰ $time',
                  style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.grey.shade500)),
            Text(advice,
                style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.grey.shade400)),
          ]),
        ),
        if (isToday)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.blue, borderRadius: BorderRadius.circular(8)),
            child: const Text('اليوم',
                style: TextStyle(color: Colors.white, fontSize: 10)),
          ),
      ]),
    );
  }
}

class _FertilizationCard extends StatelessWidget {
  final FertilizationStage stage;
  final DateTime plantingDate;
  final int daysSincePlanting;
  final double farmArea;
  final bool isDark;

  const _FertilizationCard({
    required this.stage,
    required this.plantingDate,
    required this.daysSincePlanting,
    required this.farmArea,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrent = daysSincePlanting >= stage.fromDay &&
        daysSincePlanting <= stage.toDay;
    final isDone = daysSincePlanting > stage.toDay;
    final fromDate = plantingDate.add(Duration(days: stage.fromDay));
    final toDate = plantingDate.add(Duration(days: stage.toDay));
    final qty = stage.quantityPer100Sqm * farmArea * 100;
    final color = isCurrent
        ? AppColors.primary
        : isDone ? Colors.grey : (isDark ? Colors.white24 : Colors.grey.shade400);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppColors.primary.withOpacity(isDark ? 0.12 : 0.06)
            : (isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent
              ? AppColors.primary.withOpacity(0.35)
              : (isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200),
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(
            isDone ? Icons.check_circle_rounded
                : isCurrent ? Icons.circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(stage.stageName,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isCurrent ? AppColors.primary
                        : isDark ? Colors.white70 : Colors.black87)),
          ),
          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8)),
              child: const Text('الآن',
                  style: TextStyle(color: Colors.white, fontSize: 10)),
            ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey),
          const SizedBox(width: 4),
          Text('${DateFormat('dd/MM').format(fromDate)} - ${DateFormat('dd/MM').format(toDate)}',
              style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white38 : Colors.grey.shade500)),
          const SizedBox(width: 12),
          const Icon(Icons.science_rounded, size: 12, color: Colors.grey),
          const SizedBox(width: 4),
          Flexible(
            child: Text(stage.fertilizerType,
                style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.grey.shade500)),
          ),
        ]),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _MiniInfo('السماد:', stage.fertilizerName, isDark),
            if (stage.quantityPer100Sqm > 0)
              _MiniInfo('الكمية:',
                  qty > 0 ? '${qty.toStringAsFixed(1)} كغ / ${farmArea.toStringAsFixed(2)} هكتار' : '—',
                  isDark),
            _MiniInfo('الطريقة:', stage.applicationMethod, isDark),
            _MiniInfo('التوقيت:', stage.applicationTime, isDark),
            if (stage.notes.isNotEmpty)
              _MiniInfo('ملاحظة:', stage.notes, isDark),
          ]),
        ),
      ]),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final String label, value;
  final bool isDark;
  const _MiniInfo(this.label, this.value, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
              fontSize: 12, color: isDark ? Colors.white54 : Colors.black54),
          children: [
            TextSpan(text: '$label ', style: const TextStyle(fontWeight: FontWeight.w600)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _DiseaseCard extends StatefulWidget {
  final CropDisease disease;
  final bool isDark;
  const _DiseaseCard({required this.disease, required this.isDark});

  @override
  State<_DiseaseCard> createState() => _DiseaseCardState();
}

class _DiseaseCardState extends State<_DiseaseCard> {
  bool _expanded = false;

  Color _typeColor(String type) {
    switch (type) {
      case 'فطري': return Colors.orange;
      case 'بكتيري': return Colors.red;
      case 'فيروسي': return Colors.purple;
      case 'حشري': return Colors.teal;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.disease;
    final isDark = widget.isDark;
    final color = _typeColor(d.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2A18) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(d.type,
                    style: TextStyle(
                        fontSize: 11, color: color, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(d.name,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87)),
              ),
              Icon(
                _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                color: isDark ? Colors.white38 : Colors.grey.shade400),
            ]),
          ),
        ),
        if (_expanded) ...[
          Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade100),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _DiseaseSection('السبب', d.cause, Icons.help_outline_rounded, Colors.blue, isDark),
              const SizedBox(height: 8),
              _DiseaseSectionList('الأعراض', d.symptoms, Icons.warning_amber_rounded, Colors.orange, isDark),
              const SizedBox(height: 8),
              _DiseaseSectionList('الوقاية', d.prevention, Icons.shield_rounded, Colors.green, isDark),
              const SizedBox(height: 8),
              _DiseaseSectionList('العلاج', d.treatment, Icons.medical_services_rounded, Colors.red, isDark),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _DiseaseSection extends StatelessWidget {
  final String title, content;
  final IconData icon;
  final Color color;
  final bool isDark;
  const _DiseaseSection(this.title, this.content, this.icon, this.color, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ]),
      const SizedBox(height: 4),
      Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Text(content,
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
      ),
    ]);
  }
}

class _DiseaseSectionList extends StatelessWidget {
  final String title;
  final List<String> items;
  final IconData icon;
  final Color color;
  final bool isDark;
  const _DiseaseSectionList(this.title, this.items, this.icon, this.color, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ]),
      const SizedBox(height: 4),
      ...items.map((item) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 0, 0),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('•  ', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey)),
              Expanded(
                child: Text(item,
                    style: TextStyle(
                        fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
              ),
            ]),
          )),
    ]);
  }
}

class _TipRow extends StatelessWidget {
  final String tip;
  final bool isDark, isWarning;
  const _TipRow({required this.tip, required this.isDark, this.isWarning = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(
          isWarning ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
          size: 14,
          color: isWarning ? Colors.orange : Colors.green),
        const SizedBox(width: 8),
        Expanded(
          child: Text(tip,
              style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                  height: 1.5)),
        ),
      ]),
    );
  }
}

class _ClimateRow extends StatelessWidget {
  final String label, value;
  final bool isDark;
  const _ClimateRow(this.label, this.value, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 130,
          child: Text(label,
              style: TextStyle(
                  fontSize: 12, color: isDark ? Colors.white38 : Colors.grey.shade500)),
        ),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87)),
        ),
      ]),
    );
  }
}

class _TagRow extends StatelessWidget {
  final String label;
  final List<String> tags;
  final Color color;
  final bool isDark;
  const _TagRow({required this.label, required this.tags, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      const SizedBox(height: 6),
      Wrap(
        spacing: 6, runSpacing: 6,
        children: tags
            .map((t) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text(t, style: TextStyle(fontSize: 12, color: color)),
                ))
            .toList(),
      ),
    ]);
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final bool isDark;
  const _StatBox({required this.label, required this.value, required this.icon, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: isDark ? Colors.white38 : Colors.grey.shade500)),
      ]),
    );
  }
}

class _AdviceBlock extends StatelessWidget {
  final String text;
  final bool isDark;
  final Color color;
  const _AdviceBlock({required this.text, required this.isDark, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 13, height: 1.7, color: isDark ? Colors.white70 : Colors.black54)),
    );
  }
}

extension CropInfoExtension on CropInfo {
  List<String> get generalTipsForCrop {
    final tips = <String>[];
    tips.add('راقب المحصول أسبوعياً للكشف المبكر عن الأمراض والآفات');
    tips.add('سجّل تواريخ الري والتسميد للمتابعة الدقيقة');
    tips.addAll(doList.take(3));
    return tips;
  }
}