import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agripal/core/constants/app_colors.dart';
import 'package:agripal/screens/home/widgets/crop_data.dart';// ← ملف بيانات المحاصيل

// ══════════════════════════════════════════════════════════════════
//  RecommendationDetailScreen
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

  static const _owmApiKey = 'your api key';
 

  // ── بيانات المزرعة ────────────────────────────────────────────
  double _farmLat = 36.9, _farmLng = 7.76;
  String _soilType = 'طينية رملية', _irrigationType = 'بالتنقيط';
  double? _farmAreaHa;
  late CropInfo _cropInfo; // معلومات المحصول من crop_data.dart

  // ── الطقس ─────────────────────────────────────────────────────
  List<_DayForecast>? _weekForecast;
  bool _forecastLoading = true;
  String _cityName = '';

  // ── ردود الذكاء الاصطناعي ─────────────────────────────────────
  final Map<String, Map<String, dynamic>?> _aiData = {
    'today': null, 'irrigation': null,
    'fertilization': null, 'diseases': null, 'marketing': null,
  };
  final Map<String, bool> _aiLoading = {
    'today': true, 'irrigation': true,
    'fertilization': true, 'diseases': true, 'marketing': true,
  };

  @override
  void initState() {
    super.initState();
    // تحميل معلومات المحصول من الـ map المُمرَّر
    final cropName = widget.rec['crop_type'] as String? ?? 'البطاطا';
    _cropInfo = getCropInfo(cropName);

    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(_onTabChanged);
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    _farmLat = prefs.getDouble('farm_lat') ?? 36.9;
    _farmLng = prefs.getDouble('farm_lng') ?? 7.76;

    final farmDataStr = prefs.getString('farm_data');
    if (farmDataStr != null) {
      try {
        final fd = json.decode(farmDataStr) as Map<String, dynamic>;
        _soilType = fd['soil_type']?.toString() ?? 'طينية رملية';
        _irrigationType = fd['irrigation_type']?.toString() ?? 'بالتنقيط';
        final area = fd['area_ha'];
        if (area != null) _farmAreaHa = (area as num).toDouble();
      } catch (_) {}
    }

    await _fetchWeekForecast(_farmLat, _farmLng);
    _fetchAiTab('today');
    _fetchAiTab('irrigation');
  }

  void _onTabChanged() {
    const tabKeys = ['today', 'irrigation', 'fertilization', 'diseases', 'marketing'];
    final idx = _tabController.index;
    if (idx < tabKeys.length) {
      final key = tabKeys[idx];
      if (_aiLoading[key] == true && _aiData[key] == null) {
        _fetchAiTab(key);
      }
    }
  }

  // ── جلب الطقس الأسبوعي ────────────────────────────────────────
  Future<void> _fetchWeekForecast(double lat, double lng) async {
    try {
      final res = await http.get(Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast'
        '?lat=$lat&lon=$lng&appid=$_owmApiKey&units=metric&lang=ar&cnt=40',
      ));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        _cityName = data['city']?['name']?.toString() ?? '';

        final Map<String, List<dynamic>> byDay = {};
        for (final item in data['list'] as List<dynamic>) {
          final dt = DateTime.fromMillisecondsSinceEpoch((item['dt'] as int) * 1000);
          byDay.putIfAbsent(DateFormat('yyyy-MM-dd').format(dt), () => []).add(item);
        }

        final forecasts = <_DayForecast>[];
        for (final key in (byDay.keys.toList()..sort()).take(7)) {
          final items = byDay[key]!;
          double maxT = -99, minT = 99, rain = 0, humidity = 0, wind = 0;
          String desc = '', icon = '';
          for (final item in items) {
            final main = item['main'] as Map<String, dynamic>;
            final t = (main['temp'] as num).toDouble();
            if (t > maxT) maxT = t;
            if (t < minT) minT = t;
            humidity += (main['humidity'] as num).toDouble();
            wind    += (item['wind']?['speed'] as num? ?? 0).toDouble();
            rain    += (item['rain']?['3h'] as num? ?? 0).toDouble();
            if (desc.isEmpty) {
              desc = item['weather']?[0]?['description']?.toString() ?? '';
              icon = item['weather']?[0]?['icon']?.toString() ?? '';
            }
          }
          forecasts.add(_DayForecast(
            date: DateTime.parse(key),
            maxTemp: maxT, minTemp: minT, rain: rain,
            humidity: humidity / items.length,
            windSpeed: wind / items.length,
            description: desc, icon: icon,
          ));
        }
        if (mounted) setState(() { _weekForecast = forecasts; _forecastLoading = false; });
      } else {
        if (mounted) setState(() => _forecastLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _forecastLoading = false);
    }
  }

  // ── استدعاء الذكاء الاصطناعي ──────────────────────────────────
  Future<void> _fetchAiTab(String tabKey) async {
    if (_aiLoading[tabKey] == false && _aiData[tabKey] != null) return;

    final rec = widget.rec;
    final cropType   = _cropInfo.name;
    final day        = rec['day'] as int? ?? 1;
    final cycleDays  = _cropInfo.cycleDays;
    final growthStage = _cropInfo.stageForDay(day).name; // ← ديناميكي!

    String weatherSummary = 'بيانات الطقس غير متاحة';
    if (_weekForecast?.isNotEmpty == true) {
      weatherSummary = 'المنطقة: $_cityName\nتوقعات الأسبوع:\n'
          + _weekForecast!.take(7).map((f) =>
              '${f.dayName}: ${f.minTemp.toStringAsFixed(0)}-${f.maxTemp.toStringAsFixed(0)}°م، '
              'رطوبة ${f.humidity.toStringAsFixed(0)}%، مطر ${f.rain.toStringAsFixed(1)}مم').join('\n');
    }

    final farmContext = '''
المحصول: $cropType (${_cropInfo.emoji})
اليوم: $day من $cycleDays
المرحلة: $growthStage
التربة: $_soilType
نظام الري: $_irrigationType
المساحة: ${_farmAreaHa != null ? '$_farmAreaHa هكتار' : 'غير محددة'}
$weatherSummary''';

    final prompt = _buildPrompt(tabKey, farmContext, cropType, day, cycleDays, growthStage);
    if (prompt.isEmpty) return;

    try {
      final res = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _claudeApiKey,
          'anthropic-version': '2023-06-01',
        },
        body: json.encode({
          'model': 'claude-sonnet-4-20250514',
          'max_tokens': 2000,
          'messages': [{'role': 'user', 'content': prompt}],
        }),
      );

      if (res.statusCode == 200) {
        final body   = json.decode(res.body) as Map<String, dynamic>;
        final raw    = (body['content'] as List).first['text'] as String;
        final cleaned = raw.replaceAll('```json', '').replaceAll('```', '').trim();
        final parsed = json.decode(cleaned) as Map<String, dynamic>;
        if (mounted) setState(() { _aiData[tabKey] = parsed; _aiLoading[tabKey] = false; });
      } else {
        if (mounted) setState(() => _aiLoading[tabKey] = false);
      }
    } catch (_) {
      if (mounted) setState(() => _aiLoading[tabKey] = false);
    }
  }

  // ── بناء الـ prompts ──────────────────────────────────────────
  String _buildPrompt(String tabKey, String ctx, String crop, int day, int cycleDays, String stage) {
    switch (tabKey) {
      case 'today':
        return '''أنت خبير زراعي. بناءً على:
$ctx
أعطني توصيات اليوم JSON فقط بدون نص إضافي:
{
  "summary": "ملخص الحالة اليوم في جملتين",
  "priority_tasks": ["مهمة1","مهمة2","مهمة3"],
  "weather_advice": "نصيحة مبنية على الطقس",
  "growth_observation": "ما يجب ملاحظته في هذه المرحلة",
  "risk_level": "منخفض|متوسط|عالي",
  "risk_reason": "سبب مستوى الخطر"
}''';

      case 'irrigation':
        return '''أنت خبير ري زراعي دقيق. بناءً على:
$ctx
احسب خطة الري الأسبوعية. أعطني JSON فقط:
{
  "daily_plan": [
    {"day_name":"اليوم","date":"التاريخ","quantity_liters_per_m2":2.5,
     "start_time":"06:30","duration_hours":1.5,"sessions":1,
     "reason":"سبب الكمية","skip":false}
  ],
  "weekly_total_liters_per_m2": 15.0,
  "water_saved_vs_traditional_pct": 35,
  "tips": ["نصيحة1","نصيحة2"]
}
قواعد الحساب: مطر>3مم → skip=true، حرارة>35°م → +40% جلستان،
حرارة<20°م → -20%، رطوبة>75% → -10%، تربة رملية → +30%''';

      case 'fertilization':
        return '''أنت خبير تسميد. بناءً على:
$ctx
خطة التسميد JSON فقط:
{
  "today_needed": true,
  "today_fertilizer": {
    "name":"اسم السماد","npk":"N-P-K",
    "quantity_kg_per_1000m2":2.5,"method":"فيرتيجيشن|رش|تربة",
    "best_time":"07:00","duration_minutes":30,"notes":"ملاحظات"
  },
  "weekly_schedule": [
    {"day":"اسم اليوم","fertilizer":"الاسم أو لا يوجد","qty":"الكمية","timing":"الوقت"}
  ],
  "full_cycle_plan": [
    {"stage":"المرحلة","days":"1-30","fertilizer":"الاسم","qty":"الكمية","goal":"الهدف"}
  ],
  "deficiency_signs": ["علامة1","علامة2"],
  "soil_notes": "ملاحظات التربة"
}''';

      case 'diseases':
        final todayWeather = _weekForecast?.isNotEmpty == true
            ? 'حرارة ${_weekForecast!.first.maxTemp.toStringAsFixed(0)}°م، رطوبة ${_weekForecast!.first.humidity.toStringAsFixed(0)}%'
            : 'غير متاح';
        return '''أنت خبير أمراض النبات. المحصول: $crop، اليوم $day، المرحلة: $stage.
طقس اليوم: $todayWeather
أعطني JSON فقط:
{
  "current_risk_assessment": "تقييم عام للمخاطر",
  "diseases": [
    {"name":"اسم المرض","scientific_name":"العلمي","type":"فطر|بكتيريا|حشرة|فيروس",
     "risk_level":"منخفض|متوسط|عالي|حرج","risk_reason":"السبب",
     "symptoms":"الأعراض","prevention":"الوقاية","treatment":"العلاج",
     "image_search_term":"plant disease english term"}
  ],
  "weekly_action": "ما يجب فعله هذا الأسبوع"
}''';

      case 'marketing':
        return '''أنت خبير اقتصاد زراعي. المحصول: $crop، اليوم $day من $cycleDays.
المنطقة: $_cityName (الجزائر)، المساحة: ${_farmAreaHa != null ? '$_farmAreaHa هكتار' : '1 هكتار افتراضي'}
تحليل اقتصادي JSON فقط:
{
  "yield_estimate": {
    "min_tons_per_ha":20,"max_tons_per_ha":32,"realistic_tons_per_ha":26,
    "total_tons":26.0,"yield_factors":["عامل1","عامل2"]
  },
  "market_analysis": {
    "current_price_dzd_per_quintal":8000,"price_trend":"مستقر|صاعد|هابط",
    "best_sell_period":"متى يُباع","gross_revenue_dzd":2080000,
    "estimated_costs_dzd":800000,"net_profit_dzd":1280000,"profit_margin_pct":62
  },
  "harvest_readiness": {
    "days_remaining":45,"readiness_signs":["علامة1","علامة2"],"harvest_date":"التاريخ"
  },
  "sell_channels": [
    {"channel":"قناة البيع","pros":"الميزات","price_premium_pct":10}
  ],
  "storage_recommendation": "نصيحة التخزين",
  "upcoming_tasks": ["مهمة1","مهمة2"]
}''';

      default: return '';
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rec = widget.rec;
    final day         = rec['day'] as int? ?? 1;
    final progressPct = rec['progress_pct'] as int? ?? 0;
    final currentStage = _cropInfo.stageForDay(day).name;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1A0F) : const Color(0xFFF5F9F0),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          _buildAppBar(isDark, day, currentStage, progressPct),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _TodayTab(
              rec: rec, cropInfo: _cropInfo,
              weekForecast: _weekForecast, forecastLoading: _forecastLoading,
              aiData: _aiData['today'], aiLoading: _aiLoading['today']!,
              isDark: isDark,
            ),
            _IrrigationTab(
              rec: rec, weekForecast: _weekForecast,
              forecastLoading: _forecastLoading,
              aiData: _aiData['irrigation'], aiLoading: _aiLoading['irrigation']!,
              soilType: _soilType, irrigationType: _irrigationType, isDark: isDark,
            ),
            _FertilizationTab(
              rec: rec,
              aiData: _aiData['fertilization'], aiLoading: _aiLoading['fertilization']!,
              soilType: _soilType, isDark: isDark,
            ),
            _DiseasesTab(
              aiData: _aiData['diseases'],
              aiLoading: _aiLoading['diseases']!,
              isDark: isDark,
            ),
            _MarketingTab(
              rec: rec,
              aiData: _aiData['marketing'], aiLoading: _aiLoading['marketing']!,
              farmAreaHa: _farmAreaHa, isDark: isDark,
              onAreaChanged: (val) {
                setState(() { _farmAreaHa = val; _aiData['marketing'] = null; _aiLoading['marketing'] = true; });
                _fetchAiTab('marketing');
              },
            ),
            _LibraryTab(cropInfo: _cropInfo, isDark: isDark),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(bool isDark, int day, String stage, int progressPct) {
    return SliverAppBar(
      expandedHeight: 185,
      pinned: true,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, Color(0xFF5a8f3c)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 44, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(children: [
                    // أيقونة المحصول
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_cropInfo.emoji, style: const TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('خطة زراعة ${_cropInfo.name}',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 3),
                        Text('$stage  •  اليوم $day من ${_cropInfo.cycleDays}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    )),
                    if (_cityName.isNotEmpty)
                      _LocationBadge(cityName: _cityName),
                  ]),
                  const SizedBox(height: 12),
                  _ProgressRow(progressPct: progressPct),
                ],
              ),
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(46),
        child: Container(
          color: isDark ? const Color(0xFF1A2A18) : Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            indicatorWeight: 2.5,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelPadding: const EdgeInsets.symmetric(horizontal: 14),
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: '📋 اليوم'),
              Tab(text: '💧 الري'),
              Tab(text: '🌿 الأسمدة'),
              Tab(text: '🦠 الأمراض'),
              Tab(text: '📊 التسويق'),
              Tab(text: '📚 المكتبة'),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widgets مصغّرة للـ AppBar ─────────────────────────────────────
class _LocationBadge extends StatelessWidget {
  final String cityName;
  const _LocationBadge({required this.cityName});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
    child: Row(children: [
      const Icon(Icons.location_on_rounded, size: 10, color: Colors.white70),
      const SizedBox(width: 3),
      Text(cityName, style: const TextStyle(color: Colors.white70, fontSize: 10)),
    ]),
  );
}

class _ProgressRow extends StatelessWidget {
  final int progressPct;
  const _ProgressRow({required this.progressPct});
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('تقدم الدورة الزراعية', style: TextStyle(color: Colors.white70, fontSize: 10)),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: progressPct / 100, minHeight: 6,
          backgroundColor: Colors.white.withOpacity(0.3),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    ])),
    const SizedBox(width: 12),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
      child: Text('$progressPct%', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    ),
  ]);
}

// ══════════════════════════════════════════════════════════════════
//  Model: _DayForecast
// ══════════════════════════════════════════════════════════════════
class _DayForecast {
  final DateTime date;
  final double maxTemp, minTemp, rain, humidity, windSpeed;
  final String description, icon;

  const _DayForecast({
    required this.date, required this.maxTemp, required this.minTemp,
    required this.rain, required this.humidity, required this.windSpeed,
    required this.description, required this.icon,
  });

  bool get isHot   => maxTemp >= 30;
  bool get isRainy => rain > 2;
  bool get isWindy => windSpeed > 5;

  String get dayName {
    const days = ['الإثنين','الثلاثاء','الأربعاء','الخميس','الجمعة','السبت','الأحد'];
    return days[date.weekday - 1];
  }
}

// ══════════════════════════════════════════════════════════════════
//  TAB 1: اليوم
// ══════════════════════════════════════════════════════════════════
class _TodayTab extends StatelessWidget {
  final Map<String, dynamic> rec;
  final CropInfo cropInfo;
  final List<_DayForecast>? weekForecast;
  final bool forecastLoading, isDark, aiLoading;
  final Map<String, dynamic>? aiData;

  const _TodayTab({
    required this.rec, required this.cropInfo,
    required this.weekForecast, required this.forecastLoading,
    required this.aiData, required this.aiLoading, required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final day        = rec['day'] as int? ?? 1;
    final harvestIn  = rec['harvest_in_days'] as int? ?? (cropInfo.cycleDays - day);
    final plantingDateStr = rec['plantingDate'] as String?;
    final today      = weekForecast?.isNotEmpty == true ? weekForecast!.first : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── الجدول الزمني (ديناميكي حسب المحصول) ────────────
        _SectionCard(
          isDark: isDark,
          title: 'الجدول الزمني — ${cropInfo.name}',
          iconWidget: Text(cropInfo.emoji, style: const TextStyle(fontSize: 16)),
          accentColor: AppColors.primary,
          child: Column(children: [
            _StageTimeline(currentDay: day, stages: cropInfo.stages, isDark: isDark),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _MiniStat('اليوم الحالي', '$day', AppColors.primary, isDark),
              _MiniStat('المتبقي للحصاد', '$harvestIn يوم', const Color(0xFF4A90C8), isDark),
              if (plantingDateStr != null)
                _MiniStat('تاريخ الزراعة',
                    DateFormat('dd/MM').format(DateTime.parse(plantingDateStr)),
                    Colors.orange, isDark),
            ]),
          ]),
        ),

        const SizedBox(height: 12),

        // ── طقس اليوم ────────────────────────────────────────
        _SectionCard(
          isDark: isDark,
          title: 'طقس اليوم — بيانات حقيقية',
          iconWidget: const Text('🌤', style: TextStyle(fontSize: 16)),
          accentColor: const Color(0xFF4A90C8),
          child: forecastLoading
              ? const _LoadingWidget(message: 'جاري جلب الطقس...')
              : today == null
                  ? _NoData(isDark: isDark)
                  : _WeatherToday(forecast: today, isDark: isDark),
        ),

        const SizedBox(height: 12),

        // ── توصيات الذكاء الاصطناعي ──────────────────────────
        _SectionCard(
          isDark: isDark,
          title: 'توصيات الذكاء الاصطناعي',
          iconWidget: const Text('🤖', style: TextStyle(fontSize: 16)),
          accentColor: AppColors.primary,
          child: aiLoading
              ? const _LoadingWidget(message: 'يحلل المعطيات الزراعية...')
              : aiData == null
                  ? _NoData(isDark: isDark)
                  : _AiTodayContent(data: aiData!, isDark: isDark),
        ),
      ]),
    );
  }
}

class _WeatherToday extends StatelessWidget {
  final _DayForecast forecast;
  final bool isDark;
  const _WeatherToday({required this.forecast, required this.isDark});

  @override
  Widget build(BuildContext context) => Column(children: [
    Row(children: [
      Image.network(
        'https://openweathermap.org/img/wn/${forecast.icon}@2x.png',
        width: 52, height: 52,
        errorBuilder: (_, __, ___) => const Icon(Icons.wb_sunny_rounded, size: 40, color: Colors.amber),
      ),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(forecast.description, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF2A3A2A))),
        Text('${forecast.minTemp.toStringAsFixed(0)}° - ${forecast.maxTemp.toStringAsFixed(0)}°م',
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade600)),
      ])),
    ]),
    const SizedBox(height: 12),
    Row(children: [
      _WeatherChip('💧 رطوبة', '${forecast.humidity.toStringAsFixed(0)}%', isDark),
      const SizedBox(width: 8),
      _WeatherChip('💨 ريح', '${forecast.windSpeed.toStringAsFixed(1)} م/ث', isDark),
      const SizedBox(width: 8),
      _WeatherChip('🌧 مطر', '${forecast.rain.toStringAsFixed(1)} مم', isDark),
    ]),
  ]);
}

class _AiTodayContent extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDark;
  const _AiTodayContent({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final summary      = data['summary'] as String? ?? '';
    final tasks        = (data['priority_tasks'] as List<dynamic>?) ?? [];
    final weatherAdvice = data['weather_advice'] as String? ?? '';
    final growth       = data['growth_observation'] as String? ?? '';
    final riskLevel    = data['risk_level'] as String? ?? 'منخفض';
    final riskReason   = data['risk_reason'] as String? ?? '';
    final riskColor    = riskLevel == 'عالي' ? Colors.red
        : riskLevel == 'متوسط' ? Colors.orange : const Color(0xFF55AA66);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (summary.isNotEmpty) ...[
        _NoteTile(text: summary, color: AppColors.primary, isDark: isDark),
        const SizedBox(height: 10),
      ],
      // مستوى الخطر
      _RiskBadge(level: riskLevel, reason: riskReason, color: riskColor),
      const SizedBox(height: 10),
      // المهام
      if (tasks.isNotEmpty) ...[
        Text('المهام ذات الأولوية:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : const Color(0xFF2A3A2A))),
        const SizedBox(height: 6),
        ...tasks.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 20, height: 20,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
              child: Center(child: Text('${e.key + 1}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(e.value.toString(), style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey.shade700))),
          ]),
        )),
        const SizedBox(height: 8),
      ],
      if (weatherAdvice.isNotEmpty)
        _AlertTip(text: weatherAdvice, color: const Color(0xFF4A90C8), isDark: isDark),
      if (growth.isNotEmpty) ...[
        const SizedBox(height: 8),
        _NoteTile(text: '🔍 $growth', color: const Color(0xFF55AA66), isDark: isDark),
      ],
    ]);
  }
}

class _RiskBadge extends StatelessWidget {
  final String level, reason;
  final Color color;
  const _RiskBadge({required this.level, required this.reason, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(children: [
      Icon(Icons.shield_rounded, size: 16, color: color),
      const SizedBox(width: 8),
      Text('مستوى الخطر: $level', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      if (reason.isNotEmpty) ...[
        const SizedBox(width: 6),
        Expanded(child: Text('— $reason', style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)))),
      ],
    ]),
  );
}

// ══════════════════════════════════════════════════════════════════
//  TAB 2: الري
// ══════════════════════════════════════════════════════════════════
class _IrrigationTab extends StatelessWidget {
  final Map<String, dynamic> rec;
  final List<_DayForecast>? weekForecast;
  final bool forecastLoading, isDark, aiLoading;
  final Map<String, dynamic>? aiData;
  final String soilType, irrigationType;

  const _IrrigationTab({
    required this.rec, required this.weekForecast,
    required this.forecastLoading, required this.aiData,
    required this.aiLoading, required this.soilType,
    required this.irrigationType, required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        _SectionCard(
          isDark: isDark,
          title: 'خطة الري الأسبوعية',
          iconWidget: const Text('💧', style: TextStyle(fontSize: 16)),
          accentColor: const Color(0xFF4A90C8),
          child: aiLoading
              ? const _LoadingWidget(message: 'يحسب كميات الري حسب الطقس...')
              : aiData == null ? _NoData(isDark: isDark)
              : _AiIrrigationPlan(data: aiData!, isDark: isDark),
        ),

        const SizedBox(height: 12),

        _SectionCard(
          isDark: isDark,
          title: 'توقعات الطقس الأسبوعية',
          iconWidget: const Text('🌦', style: TextStyle(fontSize: 16)),
          accentColor: const Color(0xFF4A90C8),
          child: forecastLoading
              ? const _LoadingWidget(message: 'جاري جلب التوقعات...')
              : weekForecast == null || weekForecast!.isEmpty
                  ? _NoData(isDark: isDark)
                  : Column(children: weekForecast!.map((f) => _WeatherDayRow(forecast: f, isDark: isDark)).toList()),
        ),

        const SizedBox(height: 12),

        _SectionCard(
          isDark: isDark,
          title: 'معلومات وتحذيرات الري',
          iconWidget: const Text('⚠️', style: TextStyle(fontSize: 16)),
          accentColor: Colors.orange,
          child: Column(children: [
            _InfoRow(label: 'نوع التربة', value: soilType, isDark: isDark),
            _InfoRow(label: 'نظام الري', value: irrigationType, isDark: isDark),
            const SizedBox(height: 8),
            if (aiData != null)
              ...((aiData!['tips'] as List<dynamic>?) ?? []).map((t) =>
                Padding(padding: const EdgeInsets.only(bottom: 5), child: _BulletTip('✅ ${t.toString()}', isDark)))
            else ...[
              _BulletTip('✅ سقِ في الصباح الباكر (6-8 ص) أو المساء لتقليل التبخر', isDark),
              _BulletTip('❌ تجنب الري وقت الظهيرة في الأيام الحارة', isDark),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _AiIrrigationPlan extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDark;
  const _AiIrrigationPlan({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final plan        = (data['daily_plan'] as List<dynamic>?) ?? [];
    final weeklyTotal = data['weekly_total_liters_per_m2'];
    final saved       = data['water_saved_vs_traditional_pct'];

    return Column(children: [
      if (saved != null)
        _SavedWaterBadge(saved: saved, weeklyTotal: weeklyTotal, isDark: isDark),
      _IrrHeader(isDark: isDark),
      const SizedBox(height: 6),
      ...plan.asMap().entries.map((e) {
        final d     = e.value as Map<String, dynamic>;
        final skip  = d['skip'] as bool? ?? false;
        return _IrrDayRow(
          dayName:   e.key == 0 ? 'اليوم' : (d['day_name'] as String? ?? ''),
          qty:       skip ? 'إيقاف' : '${d['quantity_liters_per_m2'] ?? 0} ل/م²',
          startTime: skip ? '—' : (d['start_time'] as String? ?? '07:00'),
          duration:  skip ? '—' : '${(d['duration_hours'] as num?)?.toStringAsFixed(1) ?? 0} ساعة',
          sessions:  skip ? '—' : '${d['sessions'] ?? 1} جلسة',
          reason:    d['reason'] as String? ?? '',
          isToday:   e.key == 0,
          isSkip:    skip,
          isDark:    isDark,
        );
      }),
    ]);
  }
}

class _SavedWaterBadge extends StatelessWidget {
  final dynamic saved, weeklyTotal;
  final bool isDark;
  const _SavedWaterBadge({required this.saved, required this.weeklyTotal, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFF55AA66).withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFF55AA66).withOpacity(0.3)),
    ),
    child: Row(children: [
      const Text('💚', style: TextStyle(fontSize: 14)),
      const SizedBox(width: 8),
      Expanded(child: Text(
        'توفير الماء مقارنة بالري التقليدي: $saved%  •  الإجمالي: ${weeklyTotal ?? '—'} ل/م²',
        style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF88CC88) : const Color(0xFF2A6A2A)),
      )),
    ]),
  );
}

class _IrrHeader extends StatelessWidget {
  final bool isDark;
  const _IrrHeader({required this.isDark});
  @override
  Widget build(BuildContext context) => Row(children: [
    _IrrCell('اليوم', isDark, flex: 2, isHeader: true),
    _IrrCell('الكمية', isDark, isHeader: true),
    _IrrCell('وقت البدء', isDark, isHeader: true),
    _IrrCell('المدة', isDark, isHeader: true),
    _IrrCell('الجلسات', isDark, isHeader: true),
  ]);
}

class _IrrDayRow extends StatefulWidget {
  final String dayName, qty, startTime, duration, sessions, reason;
  final bool isToday, isSkip, isDark;
  const _IrrDayRow({
    required this.dayName, required this.qty, required this.startTime,
    required this.duration, required this.sessions, required this.reason,
    required this.isToday, required this.isSkip, required this.isDark,
  });

  @override
  State<_IrrDayRow> createState() => _IrrDayRowState();
}

class _IrrDayRowState extends State<_IrrDayRow> {
  bool _showReason = false;

  @override
  Widget build(BuildContext context) {
    final qtyColor = widget.isSkip ? const Color(0xFF4A90C8)
        : widget.isToday ? AppColors.primary : null;

    return GestureDetector(
      onTap: () => setState(() => _showReason = !_showReason),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: widget.isToday ? AppColors.primary.withOpacity(0.1)
              : widget.isSkip  ? const Color(0xFF4A90C8).withOpacity(0.06)
              : widget.isDark  ? Colors.white.withOpacity(0.03) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: widget.isToday ? Border.all(color: AppColors.primary.withOpacity(0.4)) : null,
        ),
        child: Column(children: [
          Row(children: [
            _IrrCell(widget.dayName, widget.isDark, flex: 2, isBold: widget.isToday),
            _IrrCell(widget.qty,      widget.isDark, color: qtyColor),
            _IrrCell(widget.startTime,widget.isDark),
            _IrrCell(widget.duration, widget.isDark),
            _IrrCell(widget.sessions, widget.isDark),
          ]),
          if (_showReason && widget.reason.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(widget.reason, style: TextStyle(fontSize: 10,
                  color: widget.isDark ? Colors.white38 : Colors.grey.shade500)),
            ),
        ]),
      ),
    );
  }
}

class _IrrCell extends StatelessWidget {
  final String text;
  final bool isDark, isHeader, isBold;
  final int flex;
  final Color? color;
  const _IrrCell(this.text, this.isDark,
      {this.flex = 1, this.isHeader = false, this.isBold = false, this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Text(text, style: TextStyle(
      fontSize: isHeader ? 9 : 11,
      fontWeight: isHeader || isBold ? FontWeight.bold : FontWeight.normal,
      color: color ?? (isHeader ? AppColors.primary : isDark ? Colors.white70 : Colors.grey.shade700),
    )),
  );
}

class _WeatherDayRow extends StatelessWidget {
  final _DayForecast forecast;
  final bool isDark;
  const _WeatherDayRow({required this.forecast, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isToday = forecast.date.day == DateTime.now().day && forecast.date.month == DateTime.now().month;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: isToday ? AppColors.primary.withOpacity(0.08)
            : isDark ? Colors.white.withOpacity(0.03) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        SizedBox(width: 60, child: Text(isToday ? 'اليوم' : forecast.dayName,
            style: TextStyle(fontSize: 11, fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday ? AppColors.primary : isDark ? Colors.white60 : Colors.grey.shade600))),
        Image.network('https://openweathermap.org/img/wn/${forecast.icon}.png',
            width: 24, height: 24,
            errorBuilder: (_, __, ___) => const Icon(Icons.wb_cloudy_rounded, size: 18)),
        const SizedBox(width: 6),
        Text('${forecast.minTemp.toStringAsFixed(0)}°-${forecast.maxTemp.toStringAsFixed(0)}°',
            style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.grey.shade700)),
        const Spacer(),
        if (forecast.isRainy)
          _WeatherTag('🌧 ${forecast.rain.toStringAsFixed(1)}مم', const Color(0xFF4A90C8)),
        if (forecast.isHot && !forecast.isRainy)
          _WeatherTag('🔥 ${forecast.maxTemp.toStringAsFixed(0)}°', Colors.red),
        const SizedBox(width: 8),
        Text('💧${forecast.humidity.toStringAsFixed(0)}%',
            style: TextStyle(fontSize: 9, color: isDark ? Colors.white38 : Colors.grey.shade500)),
      ]),
    );
  }
}

class _WeatherTag extends StatelessWidget {
  final String text;
  final Color color;
  const _WeatherTag(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
    child: Text(text, style: TextStyle(fontSize: 9, color: color)),
  );
}

// ══════════════════════════════════════════════════════════════════
//  TAB 3: الأسمدة
// ══════════════════════════════════════════════════════════════════
class _FertilizationTab extends StatelessWidget {
  final Map<String, dynamic> rec;
  final Map<String, dynamic>? aiData;
  final bool aiLoading, isDark;
  final String soilType;

  const _FertilizationTab({
    required this.rec, required this.aiData,
    required this.aiLoading, required this.soilType, required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: _SectionCard(
        isDark: isDark,
        title: 'توصية التسميد — الذكاء الاصطناعي',
        iconWidget: const Text('🌿', style: TextStyle(fontSize: 16)),
        accentColor: AppColors.primary,
        child: aiLoading
            ? const _LoadingWidget(message: 'يحلل احتياجات التسميد...')
            : aiData == null ? _NoData(isDark: isDark)
            : _AiFertContent(data: aiData!, soilType: soilType, isDark: isDark),
      ),
    );
  }
}

class _AiFertContent extends StatelessWidget {
  final Map<String, dynamic> data;
  final String soilType;
  final bool isDark;
  const _AiFertContent({required this.data, required this.soilType, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final todayNeeded  = data['today_needed'] as bool? ?? false;
    final todayFert    = data['today_fertilizer'] as Map<String, dynamic>?;
    final weekSchedule = (data['weekly_schedule'] as List<dynamic>?) ?? [];
    final cyclePlan    = (data['full_cycle_plan'] as List<dynamic>?) ?? [];
    final defSigns     = (data['deficiency_signs'] as List<dynamic>?) ?? [];
    final soilNotes    = data['soil_notes'] as String? ?? '';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // تسميد اليوم
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: todayNeeded ? AppColors.primary.withOpacity(0.08) : Colors.grey.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: todayNeeded ? AppColors.primary.withOpacity(0.3) : Colors.grey.withOpacity(0.2)),
        ),
        child: todayNeeded && todayFert != null
            ? _TodayFertCard(fert: todayFert, isDark: isDark)
            : Row(children: [
                const Icon(Icons.check_circle_outline_rounded, color: Colors.grey),
                const SizedBox(width: 8),
                Text('لا يوجد تسميد مبرمج لهذا اليوم',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey.shade500)),
              ]),
      ),

      const SizedBox(height: 14),

      // خطة الأسبوع
      Text('خطة الأسبوع:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
          color: isDark ? Colors.white70 : const Color(0xFF2A3A2A))),
      const SizedBox(height: 6),
      Row(children: [
        _IrrCell('اليوم', isDark, flex: 2, isHeader: true),
        _IrrCell('السماد', isDark, flex: 3, isHeader: true),
        _IrrCell('الكمية', isDark, flex: 2, isHeader: true),
        _IrrCell('الوقت', isDark, flex: 2, isHeader: true),
      ]),
      const SizedBox(height: 4),
      ...weekSchedule.asMap().entries.map((e) {
        final row     = e.value as Map<String, dynamic>;
        final hasFert = (row['fertilizer'] as String? ?? '') != 'لا يوجد';
        final isToday = e.key == 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
          decoration: BoxDecoration(
            color: isToday ? AppColors.primary.withOpacity(0.1)
                : hasFert ? AppColors.primary.withOpacity(0.04)
                : isDark ? Colors.white.withOpacity(0.02) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isToday ? Border.all(color: AppColors.primary.withOpacity(0.3)) : null,
          ),
          child: Row(children: [
            _IrrCell(isToday ? 'اليوم' : (row['day'] as String? ?? ''), isDark, flex: 2, isBold: isToday),
            _IrrCell(row['fertilizer'] as String? ?? '—', isDark, flex: 3, color: hasFert ? AppColors.primary : null),
            _IrrCell(row['qty'] as String? ?? '—', isDark, flex: 2),
            _IrrCell(row['timing'] as String? ?? '—', isDark, flex: 2),
          ]),
        );
      }),

      const SizedBox(height: 14),

      // خطة الدورة الكاملة
      Text('خطة التسميد للدورة الكاملة:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
          color: isDark ? Colors.white70 : const Color(0xFF2A3A2A))),
      const SizedBox(height: 8),
      ...cyclePlan.asMap().entries.map((e) {
        final stage = e.value as Map<String, dynamic>;
        const colors = [AppColors.primary, Color(0xFF55AA66), Colors.orange, Colors.purple, Color(0xFF4A90C8)];
        final color = colors[e.key % colors.length];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(isDark ? 0.1 : 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(stage['stage'] as String? ?? '', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
              const Spacer(),
              Text(stage['days'] as String? ?? '', style: TextStyle(fontSize: 10, color: color.withOpacity(0.7))),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(child: _InfoRow(label: 'السماد', value: stage['fertilizer'] as String? ?? '—', isDark: isDark, compact: true)),
              Expanded(child: _InfoRow(label: 'الكمية', value: stage['qty'] as String? ?? '—', isDark: isDark, compact: true)),
            ]),
            if ((stage['goal'] as String? ?? '').isNotEmpty)
              Text('🎯 ${stage['goal']}', style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.grey.shade500)),
          ]),
        );
      }),

      if (defSigns.isNotEmpty) ...[
        const SizedBox(height: 10),
        _AlertTip(text: '⚠️ علامات نقص: ${defSigns.join(' • ')}', color: Colors.orange, isDark: isDark),
      ],
      if (soilNotes.isNotEmpty) ...[
        const SizedBox(height: 8),
        _NoteTile(text: '🌱 $soilNotes', color: AppColors.primary, isDark: isDark),
      ],
    ]);
  }
}

class _TodayFertCard extends StatelessWidget {
  final Map<String, dynamic> fert;
  final bool isDark;
  const _TodayFertCard({required this.fert, required this.isDark});

  @override
  Widget build(BuildContext context) => Column(children: [
    Row(children: [
      const Text('🌱', style: TextStyle(fontSize: 18)),
      const SizedBox(width: 8),
      Expanded(child: Text(fert['name'] as String? ?? '—',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary))),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
        child: Text(fert['npk'] as String? ?? '', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
      ),
    ]),
    const SizedBox(height: 10),
    Row(children: [
      Expanded(child: _InfoRow(label: 'الكمية', value: '${fert['quantity_kg_per_1000m2'] ?? '—'} كغ/1000م²', isDark: isDark)),
      Expanded(child: _InfoRow(label: 'الطريقة', value: fert['method'] as String? ?? '—', isDark: isDark)),
    ]),
    Row(children: [
      Expanded(child: _InfoRow(label: 'أفضل وقت', value: fert['best_time'] as String? ?? '—', isDark: isDark)),
      Expanded(child: _InfoRow(label: 'المدة', value: '${fert['duration_minutes'] ?? '—'} دقيقة', isDark: isDark)),
    ]),
    if ((fert['notes'] as String? ?? '').isNotEmpty)
      _NoteTile(text: fert['notes'] as String, color: AppColors.primary, isDark: isDark),
  ]);
}

// ══════════════════════════════════════════════════════════════════
//  TAB 4: الأمراض
// ══════════════════════════════════════════════════════════════════
class _DiseasesTab extends StatelessWidget {
  final Map<String, dynamic>? aiData;
  final bool aiLoading, isDark;
  const _DiseasesTab({required this.aiData, required this.aiLoading, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (aiLoading)
          const _LoadingWidget(message: 'يحلل مخاطر الأمراض حسب الطقس...')
        else if (aiData == null)
          _NoData(isDark: isDark)
        else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Text('⚠️', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(child: Text(aiData!['current_risk_assessment'] as String? ?? '',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: isDark ? Colors.orange.shade200 : Colors.orange.shade800))),
            ]),
          ),
          const SizedBox(height: 12),
          ...((aiData!['diseases'] as List<dynamic>?) ?? [])
              .map((d) => _AiDiseaseCard(disease: d as Map<String, dynamic>, isDark: isDark)),
          if ((aiData!['weekly_action'] as String? ?? '').isNotEmpty)
            _NoteTile(text: '📋 ${aiData!['weekly_action']}', color: AppColors.primary, isDark: isDark),
        ],
      ]),
    );
  }
}

class _AiDiseaseCard extends StatefulWidget {
  final Map<String, dynamic> disease;
  final bool isDark;
  const _AiDiseaseCard({required this.disease, required this.isDark});

  @override
  State<_AiDiseaseCard> createState() => _AiDiseaseCardState();
}

class _AiDiseaseCardState extends State<_AiDiseaseCard> {
  bool _expanded = false;
  String? _imageUrl;

  @override
  Widget build(BuildContext context) {
    final d         = widget.disease;
    final isDark    = widget.isDark;
    final riskLevel = d['risk_level'] as String? ?? 'منخفض';
    final color     = riskLevel == 'حرج'  ? Colors.red.shade800
        : riskLevel == 'عالي'   ? Colors.red
        : riskLevel == 'متوسط'  ? Colors.orange
        : const Color(0xFF55AA66);

    const typeIcons = {'فطر': '🍄', 'حشرة': '🐛', 'بكتيريا': '🦠'};
    final typeEmoji = typeIcons[d['type']] ?? '🔬';

    return GestureDetector(
      onTap: () {
        setState(() { _expanded = !_expanded; });
        if (_expanded && _imageUrl == null) {
          final term = d['image_search_term'] as String? ?? d['name'] as String? ?? 'plant disease';
          _imageUrl = 'https://source.unsplash.com/400x200/?${Uri.encodeComponent(term)}';
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2A18) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Text(typeEmoji, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d['name'] as String? ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 2),
                Text(d['scientific_name'] as String? ?? '',
                    style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic,
                        color: isDark ? Colors.white38 : Colors.grey.shade500)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: Text('خطر: $riskLevel', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
              ),
            ]),
          ),
          _DiseaseInfoRow(icon: Icons.info_outline_rounded, color: color, isDark: isDark, text: d['risk_reason'] as String? ?? ''),
          _DiseaseInfoRow(icon: Icons.visibility_rounded, color: color, isDark: isDark, text: d['symptoms'] as String? ?? '', bigger: true),

          if (_expanded) ...[
            Divider(height: 1, color: color.withOpacity(0.15)),
            if (_imageUrl != null)
              ClipRRect(
                child: Image.network(_imageUrl!, width: double.infinity, height: 150, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox()),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                _DiseaseDetailRow('الوقاية', d['prevention'] as String? ?? '', Icons.shield_rounded, const Color(0xFF55AA66), isDark),
                const SizedBox(height: 8),
                _DiseaseDetailRow('العلاج', d['treatment'] as String? ?? '', Icons.medical_services_rounded, Colors.orange, isDark),
              ]),
            ),
          ],

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
            ),
            child: Center(child: Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: color, size: 18)),
          ),
        ]),
      ),
    );
  }
}

class _DiseaseInfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isDark, bigger;
  final String text;
  const _DiseaseInfoRow({required this.icon, required this.color, required this.isDark, required this.text, this.bigger = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: bigger ? 13 : 12, color: color),
      const SizedBox(width: 6),
      Expanded(child: Text(text, style: TextStyle(fontSize: bigger ? 11 : 10,
          color: isDark ? (bigger ? Colors.white60 : Colors.white38) : (bigger ? Colors.grey.shade700 : Colors.grey.shade500)))),
    ]),
  );
}

class _DiseaseDetailRow extends StatelessWidget {
  final String label, text;
  final IconData icon;
  final Color color;
  final bool isDark;
  const _DiseaseDetailRow(this.label, this.text, this.icon, this.color, this.isDark);

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, size: 14, color: color),
    const SizedBox(width: 8),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(height: 2),
      Text(text, style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade700)),
    ])),
  ]);
}

// ══════════════════════════════════════════════════════════════════
//  TAB 5: التسويق
// ══════════════════════════════════════════════════════════════════
class _MarketingTab extends StatefulWidget {
  final Map<String, dynamic> rec;
  final Map<String, dynamic>? aiData;
  final bool aiLoading, isDark;
  final double? farmAreaHa;
  final ValueChanged<double?> onAreaChanged;

  const _MarketingTab({
    required this.rec, required this.aiData, required this.aiLoading,
    required this.farmAreaHa, required this.isDark, required this.onAreaChanged,
  });

  @override
  State<_MarketingTab> createState() => _MarketingTabState();
}

class _MarketingTabState extends State<_MarketingTab> {
  late final TextEditingController _areaCtrl;

  @override
  void initState() {
    super.initState();
    _areaCtrl = TextEditingController(text: widget.farmAreaHa?.toString() ?? '');
  }

  @override
  void dispose() { _areaCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(children: [

        _SectionCard(
          isDark: widget.isDark,
          title: 'مساحة الأرض',
          iconWidget: const Text('📐', style: TextStyle(fontSize: 16)),
          accentColor: const Color(0xFF55AA66),
          child: Column(children: [
            Row(children: [
              Expanded(child: TextField(
                controller: _areaCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: widget.isDark ? Colors.white : const Color(0xFF2A3A2A), fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'المساحة بالهكتار',
                  labelStyle: TextStyle(color: widget.isDark ? Colors.white38 : Colors.grey.shade500, fontSize: 12),
                  suffixText: 'هكتار',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  filled: true,
                  fillColor: widget.isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                ),
              )),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => widget.onAreaChanged(double.tryParse(_areaCtrl.text)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('احسب', style: TextStyle(fontSize: 13)),
              ),
            ]),
          ]),
        ),

        const SizedBox(height: 12),

        _SectionCard(
          isDark: widget.isDark,
          title: 'التحليل الاقتصادي',
          iconWidget: const Text('📊', style: TextStyle(fontSize: 16)),
          accentColor: const Color(0xFF55AA66),
          child: widget.aiLoading
              ? const _LoadingWidget(message: 'يحلل توقعات المنتوج والسوق...')
              : widget.aiData == null ? _NoData(isDark: widget.isDark)
              : _AiMarketingContent(data: widget.aiData!, isDark: widget.isDark),
        ),
      ]),
    );
  }
}

class _AiMarketingContent extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDark;
  const _AiMarketingContent({required this.data, required this.isDark});

  String _fmt(dynamic val) {
    if (val == null) return '—';
    final n = (val as num).toInt();
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)} م';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)} ألف';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final yield_   = data['yield_estimate'] as Map<String, dynamic>? ?? {};
    final market   = data['market_analysis'] as Map<String, dynamic>? ?? {};
    final harvest  = data['harvest_readiness'] as Map<String, dynamic>? ?? {};
    final channels = (data['sell_channels'] as List<dynamic>?) ?? [];
    final tasks    = (data['upcoming_tasks'] as List<dynamic>?) ?? [];
    final storage  = data['storage_recommendation'] as String? ?? '';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _StatTile(icon: Icons.agriculture_rounded, iconColor: const Color(0xFF55AA66),
            label: 'المنتوج الواقعي', value: '${yield_['realistic_tons_per_ha'] ?? '—'} طن/هكتار', isDark: isDark),
        const SizedBox(width: 10),
        _StatTile(icon: Icons.scale_rounded, iconColor: Colors.orange,
            label: 'المنتوج الكلي', value: '${yield_['total_tons'] ?? '—'} طن', isDark: isDark),
        const SizedBox(width: 10),
        _StatTile(icon: Icons.trending_up_rounded, iconColor: const Color(0xFF4A90C8),
            label: 'هامش الربح', value: '${market['profit_margin_pct'] ?? '—'}%', isDark: isDark),
      ]),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF55AA66).withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF55AA66).withOpacity(0.2)),
        ),
        child: Column(children: [
          _InfoRow(label: 'الإيرادات الإجمالية', value: '${_fmt(market['gross_revenue_dzd'])} دج', isDark: isDark),
          _InfoRow(label: 'التكاليف التقديرية', value: '${_fmt(market['estimated_costs_dzd'])} دج', isDark: isDark),
          Divider(color: const Color(0xFF55AA66).withOpacity(0.2), height: 12),
          _InfoRow(label: 'صافي الربح المتوقع', value: '${_fmt(market['net_profit_dzd'])} دج', isDark: isDark),
          _InfoRow(label: 'سعر السوق', value: '${market['current_price_dzd_per_quintal'] ?? '—'} دج/قنطار', isDark: isDark),
          _InfoRow(label: 'اتجاه الأسعار', value: market['price_trend'] as String? ?? '—', isDark: isDark),
          _InfoRow(label: 'أفضل وقت للبيع', value: market['best_sell_period'] as String? ?? '—', isDark: isDark),
        ]),
      ),

      if (harvest.isNotEmpty) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.2)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('🌾', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text('موعد الحصاد: ${harvest['harvest_date'] ?? '—'}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
              const Spacer(),
              if (harvest['days_remaining'] != null)
                Text('${harvest['days_remaining']} يوم', style: TextStyle(fontSize: 11, color: Colors.orange.shade600)),
            ]),
            const SizedBox(height: 8),
            ...((harvest['readiness_signs'] as List<dynamic>?) ?? []).map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.check_circle_rounded, size: 12, color: Colors.orange),
                const SizedBox(width: 6),
                Expanded(child: Text(s.toString(), style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade700))),
              ]),
            )),
          ]),
        ),
      ],

      if (channels.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text('قنوات البيع:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : const Color(0xFF2A3A2A))),
        const SizedBox(height: 6),
        ...channels.map((ch) {
          final c = ch as Map<String, dynamic>;
          final premium = c['price_premium_pct'] as int? ?? 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
            ),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c['channel'] as String? ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF2A3A2A))),
                Text(c['pros'] as String? ?? '', style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.grey.shade500)),
              ])),
              if (premium > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFF55AA66).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text('+$premium%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF55AA66))),
                ),
            ]),
          );
        }),
      ],

      if (storage.isNotEmpty) ...[
        const SizedBox(height: 8),
        _NoteTile(text: '🏪 $storage', color: Colors.blueGrey, isDark: isDark),
      ],
      if (tasks.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text('مهام الأيام القادمة:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : const Color(0xFF2A3A2A))),
        const SizedBox(height: 6),
        ...tasks.map((t) => Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: _BulletTip('📌 ${t.toString()}', isDark),
        )),
      ],
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════
//  TAB 6: المكتبة — ديناميكية حسب المحصول
// ══════════════════════════════════════════════════════════════════
class _LibraryTab extends StatelessWidget {
  final CropInfo cropInfo;
  final bool isDark;
  const _LibraryTab({required this.cropInfo, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // بطاقة المحصول
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.15), const Color(0xFF4A90C8).withOpacity(0.1)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(children: [
            Text(cropInfo.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('مكتبة ${cropInfo.name}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF2A3A2A))),
              Text('دورة زراعية: ${cropInfo.cycleDays} يوم  •  ${cropInfo.stages.length} مراحل',
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey.shade500)),
            ])),
          ]),
        ),

        const SizedBox(height: 12),

        // مراحل المحصول (ديناميكية من crop_data.dart)
        _SectionCard(
          isDark: isDark,
          title: 'مراحل نمو ${cropInfo.name}',
          iconWidget: Text(cropInfo.emoji, style: const TextStyle(fontSize: 16)),
          accentColor: AppColors.primary,
          child: Column(
            children: cropInfo.stages.map((stage) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 10, height: 10,
                  margin: const EdgeInsets.only(top: 3),
                  decoration: BoxDecoration(color: stage.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(stage.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: stage.color)),
                    const Spacer(),
                    Text('يوم ${stage.startDay} - ${stage.endDay}', style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.grey.shade500)),
                  ]),
                ])),
              ]),
            )).toList(),
          ),
        ),

        const SizedBox(height: 12),

        // نصائح عامة ثابتة
        _LibrarySection(isDark: isDark, title: 'مبادئ الزراعة الذكية', emoji: '🧠', color: AppColors.primary, steps: const [
          'التسميد والري المبنيان على البيانات يوفران 30-40% من التكاليف',
          'المراقبة المبكرة للأمراض تقلل خسائر المحصول بنسبة 60-80%',
          'توقيت الحصاد الصحيح يزيد من قيمة المنتوج بنسبة 15-25%',
          'تحليل التربة قبل كل دورة يعطي نتائج أفضل وتكاليف أقل',
        ]),

        const SizedBox(height: 12),

        _LibrarySection(isDark: isDark, title: 'نصائح الري الذكي', emoji: '💧', color: const Color(0xFF4A90C8), steps: const [
          'الري الصباحي (6-8 ص): يقلل التبخر ويمنع الأمراض الفطرية',
          'قياس رطوبة التربة على عمق 20-30 سم قبل كل ري',
          'الري بالتنقيط أكثر كفاءة من الرش بنسبة 30-40%',
          'تعديل الكميات حسب درجة الحرارة والرطوبة أسبوعياً',
        ]),
      ]),
    );
  }
}

class _LibrarySection extends StatelessWidget {
  final bool isDark;
  final String title, emoji;
  final Color color;
  final List<String> steps;
  const _LibrarySection({required this.isDark, required this.title, required this.emoji, required this.color, required this.steps});

  @override
  Widget build(BuildContext context) => _SectionCard(
    isDark: isDark, title: title,
    iconWidget: Text(emoji, style: const TextStyle(fontSize: 16)),
    accentColor: color,
    child: Column(children: steps.map((s) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.circle, size: 6, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(s, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey.shade700))),
      ]),
    )).toList()),
  );
}

// ══════════════════════════════════════════════════════════════════
//  Shared Widgets
// ══════════════════════════════════════════════════════════════════
class _LoadingWidget extends StatelessWidget {
  final String message;
  const _LoadingWidget({required this.message});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Column(children: [
      const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5)),
      const SizedBox(height: 10),
      Text(message, style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
    ]),
  );
}

class _SectionCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final Widget iconWidget;
  final Color accentColor;
  final Widget child;
  const _SectionCard({required this.isDark, required this.title, required this.iconWidget, required this.accentColor, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1A2A18) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: accentColor.withOpacity(0.15)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.04), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 3, height: 18, decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        iconWidget,
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: accentColor))),
      ]),
      const SizedBox(height: 14),
      child,
    ]),
  );
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label, value;
  final bool isDark;
  const _StatTile({required this.icon, required this.iconColor, required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
    decoration: BoxDecoration(
      color: iconColor.withOpacity(isDark ? 0.12 : 0.07),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(children: [
      Icon(icon, color: iconColor, size: 18),
      const SizedBox(height: 6),
      Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.grey.shade500)),
      const SizedBox(height: 3),
      Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF2A3A2A)), textAlign: TextAlign.center),
    ]),
  ));
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final bool isDark, compact;
  const _InfoRow({required this.label, required this.value, required this.isDark, this.compact = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: compact ? 4 : 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: compact ? 10 : 11, color: isDark ? Colors.white38 : Colors.grey.shade500)),
      const SizedBox(width: 8),
      Expanded(child: Text(value, style: TextStyle(fontSize: compact ? 11 : 12, fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : const Color(0xFF2A3A2A)), textAlign: TextAlign.end)),
    ]),
  );
}

class _NoteTile extends StatelessWidget {
  final String text;
  final Color color;
  final bool isDark;
  const _NoteTile({required this.text, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.info_outline_rounded, size: 14, color: color),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade700))),
    ]),
  );
}

class _AlertTip extends StatelessWidget {
  final String text;
  final Color color;
  final bool isDark;
  const _AlertTip({required this.text, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Row(children: [
      Icon(Icons.warning_amber_rounded, size: 14, color: color),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: TextStyle(fontSize: 11, color: color))),
    ]),
  );
}

class _BulletTip extends StatelessWidget {
  final String text;
  final bool isDark;
  const _BulletTip(this.text, this.isDark);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(width: 2),
      Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey.shade700))),
    ]),
  );
}

class _WeatherChip extends StatelessWidget {
  final String label, value;
  final bool isDark;
  const _WeatherChip(this.label, this.value, this.isDark);

  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
    decoration: BoxDecoration(
      color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
    ),
    child: Column(children: [
      Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.grey.shade500)),
      const SizedBox(height: 3),
      Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF2A3A2A))),
    ]),
  ));
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool isDark;
  const _MiniStat(this.label, this.value, this.color, this.isDark);

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
    Text(label, style: TextStyle(fontSize: 9, color: isDark ? Colors.white38 : Colors.grey.shade500)),
  ]);
}

class _NoData extends StatelessWidget {
  final bool isDark;
  const _NoData({required this.isDark});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text('لم يتم جلب البيانات — تحقق من الاتصال',
          style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey.shade500)),
    ),
  );
}

// ── Timeline ديناميكي ─────────────────────────────────────────────
class _StageTimeline extends StatelessWidget {
  final int currentDay;
  final List<GrowthStage> stages; // ← يأتي من CropInfo
  final bool isDark;
  const _StageTimeline({required this.currentDay, required this.stages, required this.isDark});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: Row(children: stages.map((s) {
      final isCurrent = currentDay >= s.startDay && currentDay <= s.endDay;
      return Expanded(child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isCurrent ? s.color.withOpacity(0.2)
              : isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isCurrent ? s.color : s.color.withOpacity(0.2), width: isCurrent ? 1.5 : 0.5),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(s.name, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: s.color)),
          Text('${s.startDay}-${s.endDay}', style: TextStyle(fontSize: 8, color: isDark ? Colors.white38 : Colors.grey.shade500)),
        ]),
      ));
    }).toList()),
  );
}
