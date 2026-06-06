import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:convert';
import 'dart:math';


class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _notificationsBox = 'notifications_box';
  static const int _maxNotifications = 100;

  // ─── IDs ثابتة للإشعارات المجدولة ────────────────────────────────────────
  static const int _dailyTipId       = 1001;
  static const int _morningCheckId   = 1002;
  static const int _eveningCheckId   = 1003;
  static const int _weeklyReportId   = 1004;

  // ─── init ─────────────────────────────────────────────────────────────────
  Future<void> init() async {
    // تهيئة timezone
    tz.initializeTimeZones();
    // يمكن تغيير المنطقة الزمنية حسب الجهاز: tz.setLocalLocation(...)

    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _setupNotificationChannels();
    await _saveFCMToken();

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpen);

    final RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpen(initialMessage);
    }

    // ─── جدولة الإشعارات التلقائية ─────────────────────────────────────────
    await _scheduleAllAutoNotifications();
  }

  // ─── قنوات الإشعارات ──────────────────────────────────────────────────────
  Future<void> _setupNotificationChannels() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'agripal_channel',
      'AgriPal Notifications',
      description: 'Notifications about your crops, weather, and tips',
      importance: Importance.high,
      showBadge: true,
      enableVibration: true,
      enableLights: true,
    );

    const AndroidNotificationChannel emergencyChannel =
        AndroidNotificationChannel(
      'agripal_emergency',
      'Emergency Alerts',
      description: 'Urgent alerts about your crops',
      importance: Importance.max,
      showBadge: true,
      enableVibration: true,
      enableLights: true,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(channel);
    await androidPlugin?.createNotificationChannel(emergencyChannel);
  }

  // ─── جدولة كل الإشعارات التلقائية ────────────────────────────────────────
  Future<void> _scheduleAllAutoNotifications() async {
    // نصيحة يومية الساعة 8:00 صباحاً
    await _scheduleDailyNotification(
      id: _dailyTipId,
      hour: 8,
      minute: 0,
      titleBuilder: () => '💡 نصيحة زراعية اليوم',
      bodyBuilder: () {
        final tips = [
          'الري الصباحي يقلل التبخر ويحمي من الفطريات 🚿',
          'أوراق النباتات الصفراء قد تشير إلى نقص النيتروجين 🌿',
          'الدعسوقة صديقة المزارع، تأكل المن والحشرات الضارة 🐞',
          'التغطية العضوية تحافظ على رطوبة التربة وتقلل الحشائش 💚',
          'التباعد المناسب بين النباتات يزيد التهوية ويقلل الأمراض 📏',
          'فحص النباتات يومياً يساعد على الكشف المبكر عن الأمراض 🔍',
          'التسميد المتوازن يعطي محصولاً أفضل وأكثر صحة 🌱',
        ];
        return tips[DateTime.now().weekday % tips.length];
      },
      type: 'tip',
    );

    // فحص صباحي الساعة 7:00
    await _scheduleDailyNotification(
      id: _morningCheckId,
      hour: 7,
      minute: 0,
      titleBuilder: () => '🌅 الفحص الصباحي',
      bodyBuilder: () => 'وقت فحص محاصيلك! تحقق من حالة الري والنباتات',
      type: 'reminder',
    );

    // تذكير مسائي الساعة 18:00
    await _scheduleDailyNotification(
      id: _eveningCheckId,
      hour: 18,
      minute: 0,
      titleBuilder: () => '🌙 مراجعة المساء',
      bodyBuilder: () => 'لا تنسَ تسجيل ملاحظات اليوم على محاصيلك',
      type: 'reminder',
    );

    // تقرير أسبوعي كل يوم الأحد الساعة 10:00
    await _scheduleWeeklyNotification(
      id: _weeklyReportId,
      dayOfWeek: DateTime.sunday,
      hour: 10,
      minute: 0,
      title: '📊 تقريرك الأسبوعي',
      body: 'راجع أداء محاصيلك هذا الأسبوع وخطط للأسبوع القادم',
      type: 'update',
    );
  }

  // ─── جدولة يومية ──────────────────────────────────────────────────────────
  Future<void> _scheduleDailyNotification({
    required int id,
    required int hour,
    required int minute,
    required String Function() titleBuilder,
    required String Function() bodyBuilder,
    required String type,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final channelId =
        type == 'emergency' ? 'agripal_emergency' : 'agripal_channel';

    await _localNotifications.zonedSchedule(
      id,
      titleBuilder(),
      bodyBuilder(),
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId == 'agripal_emergency'
              ? 'Emergency Alerts'
              : 'AgriPal Notifications',
          importance: Importance.high,
          priority: Priority.high,
          colorized: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // يكرر كل يوم
    );
  }

  // ─── جدولة أسبوعية ────────────────────────────────────────────────────────
  Future<void> _scheduleWeeklyNotification({
    required int id,
    required int dayOfWeek,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String type,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // التقدم للوصول ليوم الأسبوع المحدد
    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'agripal_channel',
          'AgriPal Notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime, // أسبوعي
    );
  }

  // ─── FCM token ────────────────────────────────────────────────────────────
  Future<void> _saveFCMToken() async {
    String? token = await _fcm.getToken();
    if (token != null) {
      print('✅ FCM Token: $token');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
    }
  }

  // ─── معالجة الرسائل ───────────────────────────────────────────────────────
  void _handleForegroundMessage(RemoteMessage message) {
    RemoteNotification? notification = message.notification;

    if (notification != null) {
      String channelId = 'agripal_channel';
      if (message.data['type'] == 'emergency') {
        channelId = 'agripal_emergency';
      }

      _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelId == 'agripal_emergency'
                ? 'Emergency Alerts'
                : 'AgriPal Notifications',
            importance: channelId == 'agripal_emergency'
                ? Importance.max
                : Importance.high,
            priority: channelId == 'agripal_emergency'
                ? Priority.max
                : Priority.high,
            colorized: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    }

    _saveNotification({
      'title': notification?.title ?? message.data['title'] ?? 'تنبيه',
      'body': notification?.body ?? message.data['body'] ?? '',
      'type': message.data['type'] ?? 'general',
      'data': message.data,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void _handleMessageOpen(RemoteMessage message) {
    print('🔔 Notification tapped: ${message.data}');
  }

  void _onNotificationTap(NotificationResponse response) {
    print('📱 Notification tapped: ${response.payload}');
  }

  // ─── حفظ الإشعارات ────────────────────────────────────────────────────────
  Future<void> _saveNotification(Map<String, dynamic> notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String>? saved = prefs.getStringList(_notificationsBox);
      List<Map<String, dynamic>> notifications = [];

      if (saved != null) {
        notifications = saved
            .map((e) => json.decode(e) as Map<String, dynamic>)
            .toList();
      }

      notifications.insert(0, notification);

      if (notifications.length > _maxNotifications) {
        notifications = notifications.sublist(0, _maxNotifications);
      }

      List<String> toSave =
          notifications.map((e) => json.encode(e)).toList();
      await prefs.setStringList(_notificationsBox, toSave);
    } catch (e) {
      print('Error saving notification: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSavedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String>? saved = prefs.getStringList(_notificationsBox);
      if (saved == null) return [];
      return saved
          .map((e) => json.decode(e) as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error loading notifications: $e');
      return [];
    }
  }

  Future<void> clearAllNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notificationsBox);
    await _localNotifications.cancelAll();
    // أعد جدولة التلقائية بعد المسح
    await _scheduleAllAutoNotifications();
  }

  Future<void> deleteNotification(int index) async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? saved = prefs.getStringList(_notificationsBox);
    if (saved != null && index < saved.length) {
      saved.removeAt(index);
      await prefs.setStringList(_notificationsBox, saved);
    }
  }

  // ─── إشعارات لحظية (triggered) ────────────────────────────────────────────
  Future<void> scheduleWateringReminder(
      String cropName, int daysRemaining) async {
    if (daysRemaining <= 0) {
      await _showAutoNotification(
        title: '💧 تنبيه الري',
        body: 'يحتاج محصول $cropName إلى الري اليوم',
        type: 'watering',
      );
    } else if (daysRemaining == 1) {
      await _showAutoNotification(
        title: '💧 تذكير بالري',
        body: 'غداً موعد ري محصول $cropName',
        type: 'reminder',
      );
    }
  }

  Future<void> sendWeatherAlert(String condition, String message) async {
    await _showAutoNotification(
      title: '🌤️ حالة الطقس',
      body: message,
      type: 'weather',
    );
  }

  Future<void> sendPestAlert(String pestName, String cropName) async {
    await _showAutoNotification(
      title: '⚠️ تنبيه آفات',
      body: 'تم رصد $pestName على محصول $cropName، يرجى المراجعة',
      type: 'emergency',
    );
  }

  Future<void> sendDiseaseAlert(String disease, String cropName) async {
    await _showAutoNotification(
      title: '⚠️ تنبيه أمراض',
      body: 'احتمالية إصابة محصول $cropName بمرض $disease',
      type: 'emergency',
    );
  }

  Future<void> sendHarvestReminder(String cropName, int daysLeft) async {
    if (daysLeft <= 7) {
      await _showAutoNotification(
        title: '🌾 تذكير بالحصاد',
        body: 'باقي $daysLeft أيام على حصاد $cropName',
        type: 'harvest',
      );
    }
  }

  Future<void> sendFertilizerTip(String cropName, String stage) async {
    final tips = {
      'seedling': 'مرحلة البادرات - احرص على التسميد بالنيتروجين',
      'vegetative': 'مرحلة النمو الخضري - احتياج عالي للبوتاسيوم',
      'flowering': 'مرحلة التزهير - يفضل الفوسفور لتكوين الأزهار',
      'fruiting': 'مرحلة الثمر - زود البوتاسيوم لجودة المحصول',
    };

    await _showAutoNotification(
      title: '🌱 نصيحة تسميد',
      body: '$cropName: ${tips[stage] ?? tips['vegetative']}',
      type: 'tip',
    );
  }

  Future<void> sendDailyTip() async {
    final tips = [
      '🚿 الري الصباحي يقلل من تبخر الماء ويحمي من الفطريات',
      '🌿 أوراق النباتات الصفراء قد تشير إلى نقص النيتروجين',
      '🐞 الدعسوقة صديقة المزارع، تأكل المن والحشرات الضارة',
      '💚 التغطية العضوية تحافظ على رطوبة التربة وتقلل الحشائش',
      '📏 تباعد مناسب بين النباتات يزيد التهوية ويقلل الأمراض',
    ];

    final randomTip = tips[DateTime.now().day % tips.length];
    await _showAutoNotification(
      title: '💡 نصيحة زراعية يومية',
      body: randomTip,
      type: 'tip',
    );
  }

  Future<void> sendIrrigationAdvice(
      double soilMoisture, double threshold) async {
    if (soilMoisture < threshold) {
      await _showAutoNotification(
        title: '💧 تنبيه الري العاجل',
        body:
            'رطوبة التربة منخفضة (${soilMoisture.toStringAsFixed(1)}%)، يرجى الري فوراً',
        type: 'emergency',
      );
    } else if (soilMoisture > 80) {
      await _showAutoNotification(
        title: '💧 تنبيه',
        body: 'رطوبة التربة مرتفعة، توقف عن الري لتجنب تعفن الجذور',
        type: 'warning',
      );
    }
  }

  Future<void> sendCropStageUpdate(
      String cropName, String newStage) async {
    final stageMessages = {
      'planted': 'تمت زراعة $cropName بنجاح',
      'germinated': 'بدأت بذور $cropName في الإنبات 🌱',
      'growing': '$cropName في مرحلة النمو النشط',
      'flowering': '$cropName بدأ في التزهير 🌸',
      'fruiting': 'بدأ تكوين الثمار على $cropName 🍎',
      'ready': '$cropName جاهز للحصاد 🎉',
    };

    await _showAutoNotification(
      title: '📢 تحديث حالة المحصول',
      body: stageMessages[newStage] ?? '$cropName: $newStage',
      type: 'update',
    );
  }

  Future<void> _showAutoNotification({
    required String title,
    required String body,
    required String type,
  }) async {
    final channelId =
        type == 'emergency' ? 'agripal_emergency' : 'agripal_channel';

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId == 'agripal_emergency'
              ? 'Emergency Alerts'
              : 'AgriPal Notifications',
          importance:
              type == 'emergency' ? Importance.max : Importance.high,
          priority:
              type == 'emergency' ? Priority.max : Priority.high,
          colorized: true,
          autoCancel: type != 'emergency',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );

    await _saveNotification({
      'title': title,
      'body': body,
      'type': type,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> refreshFCMToken() async {
    await _fcm.deleteToken();
    await _saveFCMToken();
  }

  /// إلغاء إشعار مجدول بالـ id
  Future<void> cancelScheduledNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// إلغاء جميع المجدولة
  Future<void> cancelAllScheduled() async {
    for (final id in [
      _dailyTipId,
      _morningCheckId,
      _eveningCheckId,
      _weeklyReportId,
    ]) {
      await _localNotifications.cancel(id);
    }
  }
}