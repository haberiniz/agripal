import 'dart:convert';
import 'package:agripal/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agripal/main.dart';
import 'package:agripal/screens/home/widgets/weather_card.dart';
import 'package:agripal/screens/home/widgets/status_card.dart';
import 'package:agripal/screens/home/widgets/farm_setup_sheet.dart';
import 'package:agripal/screens/home/widgets/drawer_widget.dart';
import 'package:agripal/screens/settings_screen.dart';
import 'package:agripal/screens/crop_prediction_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:agripal/screens/home/widgets/farm-recommandation.dart' as farm_rec;
import 'package:agripal/screens/recommendation_screens/recommendation_screen.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  static const _apiKey = '3bd015115660091719e9545a0d7f5202';

  int _selectedDrawerIndex = 0;
  double? _farmLat;
  double? _farmLng;
  String _locationDisplayName = 'جاري التحديد...';
  Map<String, dynamic>? _weatherData;
  bool _weatherLoading = true;

  bool _hasAnyCrop = false;

  @override
  void initState() {
    super.initState();
    _loadFarmAndWeather();
  }

  Future<void> _loadLocalFarmData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _hasAnyCrop = false;
      });
      return;
    }

    try {
      final cropsSnapshot = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(user.uid)
          .collection('crops')
          .limit(1)
          .get();

      if (cropsSnapshot.docs.isNotEmpty) {
        setState(() {
          _hasAnyCrop = true;
        });
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('farm_info')
          .doc('data')
          .get();

      if (doc.exists && doc.data() != null) {
        final oldData = doc.data()!;
        await _migrateOldData(user.uid, oldData);
        setState(() {
          _hasAnyCrop = true;
        });
      } else {
        setState(() {
          _hasAnyCrop = false;
        });
      }
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final farmDataStr = prefs.getString('farm_data');
      if (farmDataStr != null) {
        setState(() {
          _hasAnyCrop = true;
        });
      } else {
        setState(() {
          _hasAnyCrop = false;
        });
      }
    }
  }

  Future<void> _migrateOldData(String uid, Map<String, dynamic> oldData) async {
    try {
      final cropData = {
        'crop_id': 'potato_algeria_pro',
        'crop_type': oldData['cropType'] ?? 'بطاطس',
        'location_name': oldData['locationName'] ?? '',
        'farm_lat': oldData['farmLat'],
        'farm_lng': oldData['farmLng'],
        'farm_area': oldData['farmArea']?.toDouble() ?? 0,
        'planting_date': oldData['plantingDate'] ?? DateTime.now().toIso8601String(),
        'soil_type': oldData['soilTypeLabel'] ?? 'طينية',
        'irrigation_type': oldData['irrigationTypeLabel'] ?? 'بالتنقيط',
        'cycle_days': 120,
        'setup_completed': true,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'is_active': true,
      };
      
      await FirebaseFirestore.instance
          .collection('farmers')
          .doc(uid)
          .collection('crops')
          .doc('migrated_crop')
          .set(cropData);
    } catch (e) {
      debugPrint('خطأ في ترحيل البيانات: $e');
    }
  }

  Future<void> _loadFarmAndWeather() async {
    final prefs = SharedPreferences.getInstance();
    final lat = (await prefs).getDouble('farm_lat');
    final lng = (await prefs).getDouble('farm_lng');
    final savedName = (await prefs).getString('farm_location_name');

    if (lat != null && lng != null) {
      setState(() {
        _farmLat = lat;
        _farmLng = lng;
        _locationDisplayName = savedName ?? 'جاري التحديد...';
      });
      if (savedName == null || savedName.isEmpty) {
        _fetchRealLocationName(lat, lng);
      }
      await _fetchWeather(lat, lng);
    } else {
      setState(() {
        _farmLat = 36.9;
        _farmLng = 7.76;
        _locationDisplayName = 'عنابة، الجزائر';
      });
      await _fetchWeather(36.9, 7.76);
    }
    await _loadLocalFarmData();
  }

  Future<void> _fetchRealLocationName(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=$lat&lon=$lng&format=json&accept-language=ar',
      );
      final res =
          await http.get(uri, headers: {'User-Agent': 'AgriPalApp/1.0'});
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final addr = data['address'] as Map<String, dynamic>? ?? {};
        final name = (addr['village'] as String?) ??
            (addr['town'] as String?) ??
            (addr['city'] as String?) ??
            (addr['municipality'] as String?) ??
            (addr['county'] as String?) ??
            (addr['state'] as String?) ??
            'موقعي';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('farm_location_name', name);
        if (mounted) setState(() => _locationDisplayName = name);
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

  void _openSetupSheet() {
    FarmSetupSheet.show(
      context,
      onSaved: () async {
        await _loadFarmAndWeather();
        await _loadLocalFarmData();
        if (mounted) setState(() {});
      },
    );
  }

  void _openCropPrediction() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CropPredictionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = AppThemeProvider.of(context);
    if (themeProvider == null) throw Exception('AppThemeProvider not found');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F1A0F) : const Color(0xFFF5F9F0),
      appBar: _buildAppBar(context, isDark),
      drawer: HomeDrawer(
        user: FirebaseAuth.instance.currentUser,
        isDark: isDark,
        selectedIndex: _selectedDrawerIndex,
        onItemSelected: (index) =>
            setState(() => _selectedDrawerIndex = index),
        onProfileTap: () {},
        onSettingsTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SettingsScreen(
                onThemeChanged: themeProvider.onThemeChanged,
                currentTheme: themeProvider.currentTheme,
              ),
            ),
          );
        },
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadFarmAndWeather,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            children: [
              if (_weatherLoading)
                const WeatherCardSkeleton()
              else if (_weatherData == null)
                const WeatherCardUnavailable()
              else
                WeatherCard(
                  weatherData: _weatherData!,
                  locationDisplayName: _locationDisplayName,
                  farmLat: _farmLat,
                  farmLng: _farmLng,
                ),
              const SizedBox(height: 16),

              if (_hasAnyCrop)
                _buildCropsList(isDark)
              else
                StartJourneyCard(isDark: isDark, onTap: _openSetupSheet),

              const SizedBox(height: 16),

              
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCropsList(bool isDark) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('farmers')
          .doc(userId)
          .collection('crops')
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text('خطأ: ${snapshot.error}');
        }

        final crops = snapshot.data?.docs ?? [];
        
        if (crops.isEmpty) {
          return StartJourneyCard(isDark: isDark, onTap: _openSetupSheet);
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: crops.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final cropDoc = crops[index];
            final crop = cropDoc.data() as Map<String, dynamic>;
            crop['docId'] = cropDoc.id;
            return _CropCard(
              crop: crop,
              isDark: isDark,
              isActive: crop['is_active'] == true,
            );
          },
        );
      },
    );
  }

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
        builder: (ctx) => GestureDetector(
          onTap: () => Scaffold.of(ctx).openDrawer(),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.menu_rounded, color: AppColors.primary, size: 20),
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
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('قريباً: صفحة الإشعارات'),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ));
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
            height: 1, color: AppColors.primary.withValues(alpha: 0.08)),
      ),
    );
  }
}

// ── كارد المحصول (نفس تصميم RecommendationCard) ───────────────────
class _CropCard extends StatelessWidget {
  final Map<String, dynamic> crop;
  final bool isDark;
  final bool isActive;

  const _CropCard({
    required this.crop,
    required this.isDark,
    required this.isActive,
  });

  String _cropEmoji(String cropType) {
    final emojis = {
      'البطاطا': '🥔',
      'طماطم': '🍅',
      'قمح': '🌾',
      'ذرة': '🌽',
      'فول': '🫘',
      'بصل': '🧅',
      'جزر': '🥕',
      'خيار': '🥒',
      'بطاطس': '🥔',
    };
    return emojis[cropType] ?? '🌱';
  }

  Future<void> _deleteCrop(BuildContext context, String userId, String cropDocId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف المحصول'),
        content: const Text('هل أنت متأكد من حذف هذا المحصول؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    try {
      await FirebaseFirestore.instance
          .collection('farmers')
          .doc(userId)
          .collection('crops')
          .doc(cropDocId)
          .delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف المحصول بنجاح')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الحذف: $e')),
        );
      }
    }
  }

// داخل _CropCard - استبدل الـ onTap بهذا:

@override
Widget build(BuildContext context) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  
  // ✅ استخراج cropDocId من crop (تم إضافته في StreamBuilder)
  final cropDocId = crop['docId'] as String;
  
  final cropType = crop['crop_type'] as String? ?? 'البطاطا';
  final soilType = crop['soil_type'] as String? ?? 'طينية';
  final farmArea = crop['farm_area'] as double? ?? 1.0;
  final location = crop['location_name'] as String? ?? '—';
  final plantingDateStr = crop['planting_date'] as String?;
  
  DateTime plantingDate;
  if (plantingDateStr != null) {
    plantingDate = DateTime.tryParse(plantingDateStr) ?? DateTime.now();
  } else {
    plantingDate = DateTime.now();
  }
  
  final cycleDays = crop['cycle_days'] as int? ?? 120;
  final daysSincePlanting = DateTime.now().difference(plantingDate).inDays + 1;
  final daysSincePlantingPositive = daysSincePlanting < 0 ? 0 : daysSincePlanting;
  final progressPct = ((daysSincePlantingPositive / cycleDays) * 100).clamp(0, 100).toInt();
  
  final cropEmoji = _cropEmoji(cropType);
  final isNearHarvest = progressPct >= 80;
  final accentColor = isNearHarvest ? Colors.orange : AppColors.primary;

  String growthStage = 'مرحلة الإنبات';
  if (progressPct < 20) {
    growthStage = 'مرحلة الإنبات';
  } else if (progressPct < 50) {
    growthStage = 'نمو خضري';
  } else if (progressPct < 80) {
    growthStage = 'تكوين الثمار';
  } else {
    growthStage = 'نضج وحصاد';
  }

  // ✅ الكلمة المفتاحية return قبل GestureDetector
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecommendationDetailScreen(
            rec: {
              ...crop,  // جميع بيانات المحصول
              'docId': cropDocId,
            },
          ),
        ),
      );
    },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2A18) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: accentColor.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor.withValues(alpha: isDark ? 0.2 : 0.08),
                    accentColor.withValues(alpha: isDark ? 0.08 : 0.02),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(cropEmoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              cropType,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1A2A1A),
                              ),
                            ),
                            if (isActive) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'نشط',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded, size: 11, color: accentColor),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                location,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white54 : Colors.grey.shade500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.calendar_today_rounded, size: 11, color: accentColor),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                DateFormat('dd/MM/yyyy').format(plantingDate),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white54 : Colors.grey.shade500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (userId != null)
                    GestureDetector(
                      onTap: () => _deleteCrop(context, userId, crop['docId']),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: Colors.red,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Body ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildMiniChip('اليوم $daysSincePlantingPositive', Icons.today_rounded, accentColor),
                      const SizedBox(width: 8),
                      _buildMiniChip(growthStage, Icons.eco_rounded, const Color(0xFF55AA66)),
                      const SizedBox(width: 8),
                      _buildMiniChip('${farmArea.toStringAsFixed(1)} هكتار', Icons.crop_square_rounded, Colors.blueGrey),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'تقدم الدورة الزراعية',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark ? Colors.white38 : Colors.grey.shade500,
                                  ),
                                ),
                                Text(
                                  '$progressPct%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: accentColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progressPct / 100,
                                minHeight: 7,
                                backgroundColor: accentColor.withValues(alpha: isDark ? 0.2 : 0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (isNearHarvest) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'قرب موعد الحصاد — ابدأ التحضيرات',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _buildQuickNavBtn(context, '💧 ري', 1),
                      const SizedBox(width: 8),
                      _buildQuickNavBtn(context, '🌿 أسمدة', 2),
                      const SizedBox(width: 8),
                      _buildQuickNavBtn(context, '🦠 أمراض', 3),
                      const SizedBox(width: 8),
                      _buildQuickNavBtn(context, '📚 مكتبة', 4),
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

  Widget _buildMiniChip(String text, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.07),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickNavBtn(BuildContext context, String label, int tabIndex) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RecommendationDetailScreen (
                rec: crop,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFF0F7EC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFD4E8CA),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white60 : const Color(0xFF3A6A2A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}