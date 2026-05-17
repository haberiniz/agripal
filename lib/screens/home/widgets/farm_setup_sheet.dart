import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agripal/screens/farm_location_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agripal/core/constants/app_colors.dart';
import 'package:agripal/services/smart_recommendation_service.dart';

const String _kOpenWeatherKey = '3bd015115660091719e9545a0d7f5202';

enum SoilType {
  clay('طينية', Icons.layers_rounded, 'ثقيلة، تحتفظ بالماء جيداً'),
  sandy('رملية', Icons.grain_rounded, 'خفيفة، تصرف الماء بسرعة'),
  loamy('طميية (لومي)', Icons.grass_rounded, 'مثالية لمعظم المحاصيل'),
  sandyClay('طينية رملية', Icons.texture_rounded, 'متوازنة بين الطين والرمل'),
  gravel('حصوية', Icons.circle_rounded, 'تصريف عالي، فقيرة بالمغذيات'),
  organic('عضوية (خصبة)', Icons.eco_rounded, 'غنية بالمواد العضوية');

  final String label;
  final IconData icon;
  final String description;
  const SoilType(this.label, this.icon, this.description);
}

enum IrrigationType {
  drip('بالتنقيط', Icons.water_drop_rounded, 'موفر للماء، مثالي للخضروات'),
  sprinkler('بالرش', Icons.shower_rounded, 'مناسب للمساحات الواسعة'),
  flood('بالغمر (فيضي)', Icons.waves_rounded, 'تقليدي، يحتاج كمية ماء كبيرة'),
  pivot('رش محوري', Icons.rotate_right_rounded, 'للمساحات الكبيرة جداً'),
  manual('يدوي', Icons.pan_tool_rounded, 'ري يدوي بالخرطوم أو الدلو');

  final String label;
  final IconData icon;
  final String description;
  const IrrigationType(this.label, this.icon, this.description);
}

class FarmSetupSheet extends StatefulWidget {
  final String? existingCropId;
  final VoidCallback? onSaved;

  const FarmSetupSheet({
    super.key,
    this.existingCropId,
    this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    String? existingCropId,
    VoidCallback? onSaved,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FarmSetupSheet(
        existingCropId: existingCropId,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<FarmSetupSheet> createState() => _FarmSetupSheetState();
}

class _FarmSetupSheetState extends State<FarmSetupSheet> {
  String _selectedCrop = 'بطاطس';
  DateTime _selectedDate = DateTime.now();
  SoilType? _selectedSoil;
  IrrigationType? _selectedIrrigation;
  bool _detectingSoil = false;
  int _currentStep = 0;
  bool _isSaving = false;

  String _locationDisplayName = 'جاري التحديد...';
  double? _farmLat;
  double? _farmLng;
  double _farmArea = 0;

  final _crops = [
    'بطاطس', 'طماطم', 'فلفل', 'بصل', 'ثوم',
    'ذرة', 'قمح', 'شعير', 'دوار الشمس', 'بطيخ', 'خيار',
  ];

  final Map<String, String> _cropToId = {
    'بطاطس': 'potato_algeria_pro',
    'طماطم': 'tomato_algeria',
    'فلفل': 'pepper_algeria',
    'بصل': 'onion_algeria',
    'ثوم': 'garlic_algeria',
    'ذرة': 'corn_algeria',
    'قمح': 'wheat_algeria',
    'شعير': 'barley_algeria',
    'دوار الشمس': 'sunflower_algeria',
    'بطيخ': 'watermelon_algeria',
    'خيار': 'cucumber_algeria',
  };

  int get _cycleDays {
    switch (_selectedCrop) {
      case 'بطاطس': return 120;
      case 'طماطم': return 100;
      case 'فلفل': return 90;
      case 'بصل': return 110;
      case 'ثوم': return 120;
      case 'ذرة': return 100;
      case 'قمح': return 150;
      case 'شعير': return 130;
      case 'دوار الشمس': return 110;
      case 'بطيخ': return 90;
      case 'خيار': return 70;
      default: return 90;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    if (widget.existingCropId != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('farmers')
              .doc(user.uid)
              .collection('crops')
              .doc(widget.existingCropId)
              .get();
          
          if (doc.exists) {
            final data = doc.data()!;
            setState(() {
              _selectedCrop = data['crop_type'] ?? _selectedCrop;
              _locationDisplayName = data['location_name'] ?? _locationDisplayName;
              _farmLat = data['farm_lat'];
              _farmLng = data['farm_lng'];
              _farmArea = data['farm_area']?.toDouble() ?? 0;
              _selectedDate = DateTime.tryParse(data['planting_date'] ?? '') ?? _selectedDate;
              
              final soilName = data['soil_type'];
              _selectedSoil = SoilType.values.firstWhere(
                (s) => s.label == soilName,
                orElse: () => SoilType.loamy,
              );
              
              final irrigationName = data['irrigation_type'];
              _selectedIrrigation = IrrigationType.values.firstWhere(
                (i) => i.label == irrigationName,
                orElse: () => IrrigationType.drip,
              );
            });
          }
        } catch (e) {
          debugPrint('خطأ في تحميل البيانات: $e');
        }
      }
    }
  }

  Future<void> _openLocationScreen() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const FarmLocationScreen()),
    );
    if (result != null && mounted) {
      setState(() {
        _locationDisplayName = result['locationName'] as String? ?? _locationDisplayName;
        _farmLat = result['lat'] as double?;
        _farmLng = result['lng'] as double?;
        _farmArea = result['area'] as double? ?? 0;
      });
    }
  }

  Future<void> _autoDetectSoil() async {
    if (_farmLat == null || _farmLng == null) {
      _showSnack('يرجى تحديد موقع المزرعة أولاً');
      return;
    }
    setState(() => _detectingSoil = true);
    try {
      final uri = Uri.parse(
        'https://rest.isric.org/soilgrids/v2.0/properties/query'
        '?lon=$_farmLng&lat=$_farmLat'
        '&property=clay&property=sand&depth=0-5cm&value=mean',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final layers = data['properties']?['layers'] as List? ?? [];
        double clay = 0, sand = 0;
        for (final layer in layers) {
          final name = layer['name'] as String? ?? '';
          final val = (layer['depths']?[0]?['values']?['mean'] as num?)?.toDouble() ?? 0;
          if (name == 'clay') {
            clay = val / 10;
          }
          if (name == 'sand') {
            sand = val / 10;
          }
        }
        final SoilType detected;
        if (clay > 40) {
          detected = SoilType.clay;
        } else if (sand > 70) {
          detected = SoilType.sandy;
        } else if (clay > 20 && sand > 40) {
          detected = SoilType.sandyClay;
        } else {
          detected = SoilType.loamy;
        }

        if (mounted) {
          setState(() => _selectedSoil = detected);
          _showSnack('✅ تم تحديد التربة: ${detected.label}  •  طين ${clay.toStringAsFixed(0)}%  رمل ${sand.toStringAsFixed(0)}%');
        }
      } else {
        _showSnack('تعذّر جلب بيانات التربة، اختر يدوياً');
      }
    } catch (_) {
      if (mounted) _showSnack('تعذّر الاتصال — اختر نوع التربة يدوياً');
    } finally {
      if (mounted) setState(() => _detectingSoil = false);
    }
  }

  // ✅ دالة _save() المصححة بالكامل
  Future<void> _save() async {
    // التحقق من صحة المدخلات
    if (_selectedSoil == null) {
      _showSnack('يرجى اختيار نوع التربة');
      return;
    }
    if (_selectedIrrigation == null) {
      _showSnack('يرجى اختيار طريقة الري');
      return;
    }
    if (_farmLat == null || _farmLng == null) {
      _showSnack('يرجى تحديد موقع المزرعة أولاً');
      return;
    }
    if (_farmArea <= 0) {
      _showSnack('يرجى تحديد مساحة الأرض');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnack('يرجى تسجيل الدخول أولاً');
        return;
      }

      final cycleDays = _cycleDays;
      final cropId = _cropToId[_selectedCrop] ?? 'potato_algeria_pro';
      final cropDocId = widget.existingCropId ?? DateTime.now().millisecondsSinceEpoch.toString();

      // ✅ بيانات المحصول الكاملة
      final cropData = {
        'crop_type': _selectedCrop,
        'soil_type': _selectedSoil!.label,
        'irrigation_type': _selectedIrrigation!.label,
        'farm_area': _farmArea,
        'planting_date': _selectedDate.toIso8601String(),
        'cycle_days': cycleDays,
        'farm_lat': _farmLat,
        'farm_lng': _farmLng,
        'location_name': _locationDisplayName,
        'is_active': true,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      // 1️⃣ حفظ في Firebase - مجموعة crops
      await FirebaseFirestore.instance
          .collection('farmers')
          .doc(user.uid)
          .collection('crops')
          .doc(cropDocId)
          .set(cropData);

      // 2️⃣ إلغاء تفعيل المحاصيل الأخرى
      final otherCrops = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(user.uid)
          .collection('crops')
          .where('is_active', isEqualTo: true)
          .get();

      for (final doc in otherCrops.docs) {
        if (doc.id != cropDocId) {
          await doc.reference.update({'is_active': false});
        }
      }

      // 3️⃣ حفظ في مسار التوصيات
      final recommendationData = {
        'crop_id': cropId,
        'crop_type': _selectedCrop,
        'growth_stage': 'مرحلة الإنبات',
        'day': 0,
        'cycle_days': cycleDays,
        'progress_pct': 0,
        'harvest_in_days': cycleDays,
        'soil_type': _selectedSoil!.label,
        'irrigation_type': _selectedIrrigation!.label,
        'planting_date': _selectedDate.toIso8601String(),
        'last_updated': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('farmers')
          .doc(user.uid)
          .collection('recommendations')
          .doc('latest')
          .set(recommendationData);

      // 4️⃣ حفظ المحصول النشط محلياً في SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final activeCrop = {
        'cropDocId': cropDocId,
        'crop_id': cropId,
        'crop_type': _selectedCrop,
        'location_name': _locationDisplayName,
        'farm_lat': _farmLat,
        'farm_lng': _farmLng,
        'farm_area': _farmArea,
        'planting_date': _selectedDate.toIso8601String(),
        'soil_type': _selectedSoil!.label,
        'irrigation_type': _selectedIrrigation!.label,
        'cycle_days': cycleDays,
      };
      await prefs.setString('active_crop', json.encode(activeCrop));

      _showSnack('⏳ جارٍ جلب التوصية الذكية...');

      // 5️⃣ تحديث التوصية الذكية عبر الخدمة
      await SmartRecommendationService.loadPotatoData();
      await SmartRecommendationService.updateRecommendation(
        user.uid,
        _selectedDate,
        _selectedIrrigation!.label,
        _farmArea,
        _selectedSoil!.label,
      );

      // بدء التحديث التلقائي
      SmartRecommendationService.startAutoUpdate(
        user.uid,
        _selectedDate,
        _selectedIrrigation!.label,
        _farmArea,
        _selectedSoil!.label,
      );

      _showSnack('تم حفظ بيانات المحصول بنجاح');
      
      if (mounted) Navigator.pop(context);
      widget.onSaved?.call();

    } catch (e) {
      _showSnack('حدث خطأ أثناء الحفظ: $e');
      debugPrint('[AgriPal] ❌ خطأ في الحفظ: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2A18) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.agriculture_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                widget.existingCropId != null ? 'تعديل بيانات المحصول' : 'إضافة محصول جديد',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
              ),
            ]),
          ),
          _buildStepBar(isDark),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(anim), child: child),
                ),
                child: _currentStep == 0 ? _buildStep0(isDark) : _currentStep == 1 ? _buildStep1(isDark) : _buildStep2(isDark),
              ),
            ),
          ),
          _buildButtons(isDark),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }

  Widget _buildStepBar(bool isDark) {
    const labels = ['المحصول', 'التربة', 'الري'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: List.generate(3, (i) {
          final active = i == _currentStep;
          final done = i < _currentStep;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < 2 ? 6 : 0),
              child: Column(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 4,
                  decoration: BoxDecoration(
                    color: done || active ? AppColors.primary : (isDark ? Colors.white12 : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 5),
                Text(labels[i], style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w600 : FontWeight.normal, color: active ? AppColors.primary : (isDark ? Colors.white38 : Colors.grey.shade400))),
              ]),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep0(bool isDark) {
    final locationConfirmed = _farmLat != null && _farmLng != null && _locationDisplayName != 'جاري التحديد...' && _locationDisplayName.isNotEmpty;

    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('🌱  نوع المحصول', isDark),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _crops.map((crop) {
            final sel = _selectedCrop == crop;
            return GestureDetector(
              onTap: () => setState(() => _selectedCrop = crop),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(crop, style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.normal, color: sel ? Colors.white : (isDark ? Colors.white70 : Colors.black87))),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        _label('📍  موقع المزرعة', isDark),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _openLocationScreen,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: locationConfirmed ? AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.07) : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: locationConfirmed ? AppColors.primary : (isDark ? Colors.white12 : Colors.grey.shade200), width: locationConfirmed ? 1.5 : 1),
            ),
            child: Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 40, height: 40,
                decoration: BoxDecoration(color: locationConfirmed ? AppColors.primary.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(locationConfirmed ? Icons.location_on_rounded : Icons.map_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(locationConfirmed ? 'موقع الأرض' : 'تحديد الموقع على الخريطة', style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey.shade400)),
                  const SizedBox(height: 3),
                  Text(locationConfirmed ? _locationDisplayName : 'اضغط لفتح الخريطة', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: locationConfirmed ? AppColors.primary : (isDark ? Colors.white : Colors.black87))),
                  if (locationConfirmed && _farmArea > 0) ...[
                    const SizedBox(height: 2),
                    Text(_farmArea >= 10000 ? '${(_farmArea / 10000).toStringAsFixed(2)} هكتار' : '${_farmArea.toStringAsFixed(0)} م²', style: TextStyle(fontSize: 12, color: AppColors.primary.withValues(alpha: 0.7))),
                  ],
                ]),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: locationConfirmed ? 1 : 0,
                child: Container(width: 22, height: 22, decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle), child: const Icon(Icons.check_rounded, color: Colors.white, size: 14)),
              ),
              if (!locationConfirmed) Icon(Icons.arrow_back_ios_rounded, size: 14, color: isDark ? Colors.white24 : Colors.grey.shade300),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        _label('📅  تاريخ الزراعة', isDark),
        const SizedBox(height: 10),
        _tapCard(
          icon: Icons.calendar_today_rounded,
          title: 'اختر تاريخ الزراعة',
          subtitle: DateFormat('dd / MM / yyyy').format(_selectedDate),
          isDark: isDark,
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.light(primary: AppColors.primary)), child: child!),
            );
            if (date != null) setState(() => _selectedDate = date);
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStep1(bool isDark) {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _detectingSoil ? null : _autoDetectSoil,
            icon: _detectingSoil ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)) : Icon(Icons.gps_fixed_rounded, size: 17, color: AppColors.primary),
            label: Text(_detectingSoil ? 'جارٍ تحليل التربة...' : 'تحديد نوع التربة تلقائياً من GPS', style: TextStyle(color: AppColors.primary, fontSize: 13)),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13), side: BorderSide(color: AppColors.primary.withValues(alpha: 0.45)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          ),
        ),
        const SizedBox(height: 16),
        _label('أو اختر يدوياً', isDark, muted: true),
        const SizedBox(height: 10),
        ...SoilType.values.map((s) => _selCard(selected: _selectedSoil == s, icon: s.icon, label: s.label, desc: s.description, isDark: isDark, onTap: () => setState(() => _selectedSoil = s))),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildStep2(bool isDark) {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('اختر طريقة الري المستخدمة', isDark, muted: true),
        const SizedBox(height: 10),
        ...IrrigationType.values.map((irr) => _selCard(selected: _selectedIrrigation == irr, icon: irr.icon, label: irr.label, desc: irr.description, isDark: isDark, onTap: () => setState(() => _selectedIrrigation = irr))),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildButtons(bool isDark) {
    final isLast = _currentStep == 2;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(children: [
        if (_currentStep > 0) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: _isSaving ? null : () => setState(() => _currentStep--),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: Text('رجوع', style: TextStyle(color: AppColors.primary, fontSize: 14)),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isSaving ? null : (isLast ? _save : () => setState(() => _currentStep++)),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(isLast ? (widget.existingCropId != null ? 'تحديث' : 'حفظ') : 'التالي', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    Icon(isLast ? Icons.check_rounded : Icons.arrow_back_ios_rounded, color: Colors.white, size: 15),
                  ]),
          ),
        ),
      ]),
    );
  }

  Widget _label(String text, bool isDark, {bool muted = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(text, style: TextStyle(fontSize: muted ? 12 : 13, fontWeight: FontWeight.w600, color: muted ? (isDark ? Colors.white38 : Colors.grey.shade400) : (isDark ? Colors.white70 : Colors.black54))),
      );

  Widget _selCard({required bool selected, required IconData icon, required String label, required String desc, required bool isDark, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.08) : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.primary : (isDark ? Colors.white12 : Colors.grey.shade200), width: selected ? 1.5 : 1),
        ),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 42, height: 42,
            decoration: BoxDecoration(color: selected ? AppColors.primary.withValues(alpha: 0.15) : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 21, color: selected ? AppColors.primary : (isDark ? Colors.white38 : Colors.grey.shade400)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: selected ? AppColors.primary : (isDark ? Colors.white : Colors.black87))),
              const SizedBox(height: 3),
              Text(desc, style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey.shade500)),
            ]),
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: selected ? 1 : 0,
            child: Container(width: 22, height: 22, decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle), child: const Icon(Icons.check_rounded, color: Colors.white, size: 14)),
          ),
        ]),
      ),
    );
  }

  Widget _tapCard({required IconData icon, required String title, required String subtitle, required bool isDark, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
        ),
        child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: AppColors.primary, size: 20)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey.shade400)),
              const SizedBox(height: 3),
              Text(subtitle, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
            ]),
          ),
          Icon(Icons.arrow_back_ios_rounded, size: 14, color: isDark ? Colors.white24 : Colors.grey.shade300),
        ]),
      ),
    );
  }
}