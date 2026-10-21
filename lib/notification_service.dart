import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  // تهيئة الإشعارات
  static Future<void> initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(
      android: androidSettings,
    );

    await notifications.initialize(settings: settings);

    await notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
        await notifications
    .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
    ?.requestExactAlarmsPermission();
  }

  // إرسال إشعار فوري
  static Future<void> showNotification(
    int id,
    String title,
    String body,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      'health_reminders',
      'Rivo تذكيرات',
      channelDescription: 'تذكيرات الماء والوجبات والرياضة',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(
      android: androidDetails,
    );

    await notifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  // تذكير شرب الماء
  static Future<void> waterReminder() async {
    await showNotification(
      1,
      '💧 تذكير شرب الماء',
      'حان وقت شرب كوب من الماء!',
    );
  }

  // تذكير الوجبات
  static Future<void> mealReminder() async {
    await showNotification(
      2,
      '🍎 تذكير الوجبات',
  'Rivoلاتنسى تسجل وجبتك في تطبيق ',
    );
  }

  // تذكير الرياضة
  static Future<void> exerciseReminder() async {
    await showNotification(
      3,
      '🏃‍♀️ تذكير الرياضة',
      'حان وقت ممارسة بعض التمارين الرياضية!',
    );
  }
  // جدولة إشعار يومي
static Future<void> scheduleDailyNotification(
  int id,
  String title,
  String body,
  int hour,
  int minute,
) async {
  const androidDetails = AndroidNotificationDetails(
    'health_reminders',
    'Rivo تذكيرات',
    channelDescription: 'تذكيرات الماء والوجبات والرياضة',
    importance: Importance.max,
    priority: Priority.high,
  );

  const details = NotificationDetails(
    android: androidDetails,
  );

  final now = tz.TZDateTime.now(tz.local);

  var scheduledDate = tz.TZDateTime(
    tz.local,
    now.year,
    now.month,
    now.day,
    hour,
    minute,
  );

  if (!scheduledDate.isAfter(now)) {
    scheduledDate = scheduledDate.add(
      const Duration(days: 1),
    );
  }

  await notifications.zonedSchedule(
    id: id,
    title: title,
    body: body,
    scheduledDate: scheduledDate,
    notificationDetails: details,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.time,
  );
}
// إلغاء تذكير محدد
  static Future<void> cancelReminder(int id) async {
    await notifications.cancel(id: id);
  }
}