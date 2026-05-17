import 'package:agripal/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:agripal/screens/weather_screen.dart';

class WeatherCard extends StatelessWidget {
  final Map<String, dynamic> weatherData;
  final String locationDisplayName;
  final double? farmLat;
  final double? farmLng;

  const WeatherCard({
    super.key,
    required this.weatherData,
    required this.locationDisplayName,
    this.farmLat,
    this.farmLng,
  });

  @override
  Widget build(BuildContext context) {
    final temp = (weatherData['main']['temp'] as num).round();
    final feelsLike = (weatherData['main']['feels_like'] as num).round();
    final humidity = (weatherData['main']['humidity'] as num).toInt();
    final windSpeed = (weatherData['wind']['speed'] as num).toDouble();
    final desc = weatherData['weather'][0]['description'] as String;
    final icon = weatherData['weather'][0]['icon'] as String;
    final bool goodForIrrigation =
        temp < 35 && humidity < 80 && windSpeed < 8 && !desc.contains('مطر');

    return GestureDetector(
      onTap: farmLat != null
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WeatherScreen(
                    lat: farmLat!,
                    lng: farmLng!,
                    locationName: locationDisplayName,
                  ),
                ),
              )
          : null,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, const Color(0xFF7C9473)],
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
            Positioned(
              top: -20, right: -20,
              child: Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              bottom: -25, left: -10,
              child: Container(
                width: 90, height: 90,
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
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(locationDisplayName,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                            overflow: TextOverflow.ellipsis),
                      ),
                      const Text('تفاصيل',
                          style: TextStyle(color: Colors.white60, fontSize: 12)),
                      const SizedBox(width: 3),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.white60, size: 11),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$temp°C',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 52,
                                  fontWeight: FontWeight.bold,
                                  height: 1)),
                          const SizedBox(height: 4),
                          Text(desc,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
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
                        width: 72, height: 72,
                        errorBuilder: (_, e, __) => const Icon(
                            Icons.cloud_rounded,
                            color: Colors.white54,
                            size: 56),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _weatherStat(Icons.water_drop_rounded, '$humidity%', 'الرطوبة'),
                      _weatherStat(Icons.air_rounded,
                          '${windSpeed.toStringAsFixed(1)} م/ث', 'الرياح'),
                      _irrigationBadge(goodForIrrigation),
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
        Row(children: [
          Icon(icon, color: Colors.white60, size: 13),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ]),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _irrigationBadge(bool good) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: good
            ? Colors.white.withValues(alpha: 0.18)
            : Colors.red.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: good
              ? Colors.white.withValues(alpha: 0.4)
              : Colors.red.shade300.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            good ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: good ? Colors.white : Colors.red.shade200,
            size: 13,
          ),
          const SizedBox(width: 4),
          Text(
            good ? 'مناسب للري' : 'تجنب الري',
            style: TextStyle(
              color: good ? Colors.white : Colors.red.shade200,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── حالات التحميل والخطأ ──────────────────────────────────────────
class WeatherCardSkeleton extends StatelessWidget {
  const WeatherCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.primary.withValues(alpha: 0.3),
          const Color(0xFF7C9473).withValues(alpha: 0.3),
        ]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: CircularProgressIndicator(
            color: AppColors.primary, strokeWidth: 2),
      ),
    );
  }
}

class WeatherCardUnavailable extends StatelessWidget {
  const WeatherCardUnavailable({super.key});

  @override
  Widget build(BuildContext context) {
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
          const Icon(Icons.cloud_off_rounded, color: Colors.white70, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('بيانات الطقس غير متاحة',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white, fontSize: 14)),
                const SizedBox(height: 4),
                Text('تأكد من إضافة موقع مزرعتك',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.refresh_rounded, color: Colors.white70, size: 20),
        ],
      ),
    );
  }
}