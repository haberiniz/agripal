import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: iOS);
    await _notifications.initialize(settings);
    
    // طلب إذن على أندرويد 13+
    await _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  static Future<void> scheduleDailyReminder() async {
    const androidDetails = AndroidNotificationDetails(
      'daily_reminder_channel',
      'تذكيرات يومية',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iOSDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iOSDetails);

    // قائمة الرسائل التحفيزية (يمكنك تعديلها أو إضافة المزيد)
    final messages = [
      '🌱 تفقد نباتاتك اليوم بالكاميرا واكتشف الأمراض مبكرًا.',
      '📸 صورة واحدة تكفي لتحليل نباتك بالذكاء الاصطناعي.',
      '⚠️ تذكير: الفحص الدوري يحمي محصولك.',
      '💡 هل تعلم؟ معظم الأمراض تظهر على الأوراق أولاً. افحص نباتك الآن.',
      '👋 AgriPal في خدمتك. جرب كاشف الأمراض المجاني.',
    ];
    final randomMessage = messages[DateTime.now().day % messages.length];
    
    await _notifications.periodicallyShow(
      0,
      'تذكير يومي من AgriPal',
      randomMessage,
      RepeatInterval.daily,
      const Time(09, 0), // الساعة 9 صباحاً
      details,
    );
  }
}