import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _morningNotificationId = 1;
  static const int _eveningNotificationId = 2;

  Future<void> initialize() async {
    // تهيئة المناطق الزمنية
    tz.initializeTimeZones();
    final String timezoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneName));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // طلب صلاحية الإشعارات على Android 13+
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }

    // جدولة الإشعارات
    await scheduleDailyNotifications();
  }

  void _onNotificationTap(NotificationResponse response) {
    // يمكن إضافة navigation لاحقاً
    debugPrint('Notification tapped: ${response.id}');
  }

  Future<void> scheduleDailyNotifications() async {
    await _scheduleMorningNotification();
    await _scheduleEveningNotification();
  }

  Future<void> _scheduleMorningNotification() async {
    await _plugin.zonedSchedule(
      _morningNotificationId,
      '📋 تسجيل الحضور',
      'لا تنسى تسجيل حضورك اليوم!',
      _nextInstanceOfTime(8, 0),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'attendance_channel',
          'تسجيل الحضور',
          channelDescription: 'إشعار يومي لتسجيل الحضور',
          importance: Importance.max,
          priority: Priority.high,
          ongoing: false,
          autoCancel: true,
          enableVibration: true,
          playSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleEveningNotification() async {
    await _plugin.zonedSchedule(
      _eveningNotificationId,
      '⏰ تسجيل الإضافي',
      'هل عملت ساعات إضافية اليوم؟ سجلها الآن!',
      _nextInstanceOfTime(21, 0),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'overtime_channel',
          'تسجيل الإضافي',
          channelDescription: 'إشعار يومي لتسجيل ساعات العمل الإضافي',
          importance: Importance.max,
          priority: Priority.high,
          ongoing: false,
          autoCancel: true,
          enableVibration: true,
          playSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
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
    return scheduledDate;
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}