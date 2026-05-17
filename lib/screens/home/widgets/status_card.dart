import 'package:agripal/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StatusCard extends StatelessWidget {
  final Map<String, dynamic> farmData;
  final bool isDark;

  const StatusCard({
    super.key,
    required this.farmData,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2E1A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'لوحة التحكم',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Icon(Icons.eco_rounded, color: AppColors.primary),
            ],
          ),
          Divider(
              height: 25,
              color: isDark ? Colors.white10 : Colors.grey.shade200),
          _statusItem(Icons.grass_rounded, 'المحصول',
              farmData['cropType'] ?? 'غير محدد'),
          _statusItem(Icons.location_on_rounded, 'الموقع',
              farmData['locationName'] ?? 'غير محدد'),
          _statusItem(
            Icons.calendar_today_rounded,
            'تاريخ الزرع',
            farmData['plantingDate'] != null
                ? DateFormat('yyyy-MM-dd')
                    .format(DateTime.parse(farmData['plantingDate']))
                : 'غير محدد',
          ),
          if (farmData['soilTypeLabel'] != null)
            _statusItem(Icons.layers_rounded, 'نوع التربة',
                farmData['soilTypeLabel']),
          if (farmData['irrigationTypeLabel'] != null)
            _statusItem(Icons.water_drop_rounded, 'طريقة الري',
                farmData['irrigationTypeLabel']),
        ],
      ),
    );
  }

  Widget _statusItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon,
              size: 20, color: AppColors.primary.withOpacity(0.7)),
          const SizedBox(width: 12),
          Text('$label: ',
              style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.grey,
                  fontSize: 14)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── بطاقة ابدأ الرحلة ──────────────────────────────────────────────
class StartJourneyCard extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const StartJourneyCard({
    super.key,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2E1A) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_chart_rounded,
                  color: AppColors.primary, size: 30),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ابدأ رحلتك الزراعية',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black),
                  ),
                  Text(
                    'اضغط لإعداد بيانات محصولك الأول',
                    style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.grey,
                        fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }
}
 