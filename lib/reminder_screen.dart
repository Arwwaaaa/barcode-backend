import 'package:flutter/material.dart';
import 'notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  // قائمة أوقات التذكيرات
  List<TimeOfDay> waterTimes = [
    const TimeOfDay(hour: 9, minute: 0),
  ];

  List<TimeOfDay> mealTimes = [
    const TimeOfDay(hour: 13, minute: 0),
  ];

  List<TimeOfDay> exerciseTimes = [
    const TimeOfDay(hour: 17, minute: 0),
  ];

  bool waterEnabled = true;
  bool mealEnabled = true;
  bool exerciseEnabled = true;

  bool isSaving = false;
  @override
void initState() {
  super.initState();
  loadRemindersFromFirebase();
}
  // حفظ أوقات التذكيرات في Firebase
Future<void> saveRemindersToFirebase() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    throw Exception('يجب تسجيل الدخول أولاً');
  }

  List<String> convertTimes(List<TimeOfDay> times) {
    return times.map((time) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }).toList();
  }

  await FirebaseFirestore.instance
      .collection('reminders')
      .doc(user.uid)
      .set({
    'waterTimes': convertTimes(waterTimes),
    'mealTimes': convertTimes(mealTimes),
    'exerciseTimes': convertTimes(exerciseTimes),
    'waterEnabled': waterEnabled,
    'mealEnabled': mealEnabled,
    'exerciseEnabled': exerciseEnabled,
    'updatedAt': FieldValue.serverTimestamp(),
  });
}
// تحميل التذكيرات المحفوظة من Firebase
Future<void> loadRemindersFromFirebase() async {
  try {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('reminders')
        .doc(user.uid)
        .get();

    if (!doc.exists || !mounted) return;

    final data = doc.data()!;

    List<TimeOfDay> convertTimes(dynamic savedTimes) {
      if (savedTimes is! List) return [];

      final times = <TimeOfDay>[];

      for (final value in savedTimes) {
        if (value is! String) continue;

        final parts = value.split(':');
        if (parts.length != 2) continue;

        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);

        if (hour == null ||
            minute == null ||
            hour < 0 ||
            hour > 23 ||
            minute < 0 ||
            minute > 59) {
          continue;
        }

        times.add(TimeOfDay(hour: hour, minute: minute));
      }

      return times;
    }

    setState(() {
      waterTimes = convertTimes(data['waterTimes']);
      mealTimes = convertTimes(data['mealTimes']);
      exerciseTimes = convertTimes(data['exerciseTimes']);

      waterEnabled = data['waterEnabled'] ?? true;
      mealEnabled = data['mealEnabled'] ?? true;
      exerciseEnabled = data['exerciseEnabled'] ?? true;
    });
  } catch (e) {
    debugPrint('خطأ أثناء تحميل التذكيرات: $e');
  }
}
  // اختيار وقت تذكير جديد
  Future<void> addReminder(List<TimeOfDay> times) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selectedTime != null && mounted) {
      setState(() {
        times.add(selectedTime);
      });
    }
  }

  // تعديل وقت تذكير موجود
  Future<void> editReminder(
    List<TimeOfDay> times,
    int index,
  ) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: times[index],
    );

    if (selectedTime != null && mounted) {
      setState(() {
        times[index] = selectedTime;
      });
    }
  }

  // حذف تذكير
  void removeReminder(
    List<TimeOfDay> times,
    int index,
  ) {
    setState(() {
      times.removeAt(index);
    });
  }

  // تصميم قسم التذكيرات
  Widget reminderSection({
    required String title,
    required List<TimeOfDay> times,
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          SwitchListTile(
            title: Text(title),
            value: enabled,
            onChanged: onChanged,
            activeThumbColor: Colors.green,
          ),

          if (enabled)
            ...List.generate(times.length, (index) {
              return ListTile(
                leading: const Icon(
                  Icons.access_time,
                  color: Colors.green,
                ),
                title: Text(
                  'التذكير ${index + 1}',
                ),
                subtitle: Text(
                  times[index].format(context),
                ),
                onTap: () => editReminder(times, index),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  onPressed: () => removeReminder(times, index),
                ),
              );
            }),

          if (enabled)
            TextButton.icon(
              onPressed: () => addReminder(times),
              icon: const Icon(Icons.add),
              label: const Text('إضافة تذكير جديد'),
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // جدولة مجموعة من التذكيرات
  Future<void> scheduleReminders({
    required List<TimeOfDay> times,
    required bool enabled,
    required int startId,
    required String title,
    required String body,
  }) async {
    if (!enabled) return;

    for (int i = 0; i < times.length; i++) {
      await NotificationService.scheduleDailyNotification(
        startId + i,
        title,
        body,
        times[i].hour,
        times[i].minute,
      );
    }
  }

  // حفظ وجدولة جميع التذكيرات
  Future<void> saveReminders() async {
    if (isSaving) return;

    setState(() {
      isSaving = true;
    });

    try {
      // إلغاء التذكيرات القديمة التي أنشأتها صفحة الإعدادات.
      // لا نلغي جميع إشعارات التطبيق حتى لا نحذف إشعارات أخرى.
      final pending = await NotificationService.notifications
          .pendingNotificationRequests();

      for (final notification in pending) {
        final id = notification.id;

        if (id == 1 ||
            id == 2 ||
            id == 3 ||
            (id >= 1000 && id < 4000)) {
          await NotificationService.cancelReminder(id);
        }
      }

      // تذكيرات الماء: تبدأ من 1000
      await scheduleReminders(
        times: waterTimes,
        enabled: waterEnabled,
        startId: 1000,
        title: '💧 تذكير شرب الماء',
        body: 'حان وقت شرب كوب من الماء!',
      );

      // تذكيرات الوجبات: تبدأ من 2000
      await scheduleReminders(
        times: mealTimes,
        enabled: mealEnabled,
        startId: 2000,
        title: '🍎 تذكير الوجبات',
        body: 'لا تنسى تسجيل وجبتك في تطبيق Rivo',
      );

      // تذكيرات الرياضة: تبدأ من 3000
      await scheduleReminders(
        times: exerciseTimes,
        enabled: exerciseEnabled,
        startId: 3000,
        title: '🏃‍♀️ تذكير الرياضة',
        body: 'حان وقت ممارسة بعض التمارين الرياضية!',
      );
      //firebaseحفظ جميع الأوقات في 
      await saveRemindersToFirebase();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تمت جدولة التذكيرات بنجاح ✅'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء حفظ التذكيرات: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات التذكيرات'),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          reminderSection(
            title: '💧 تذكير شرب الماء',
            times: waterTimes,
            enabled: waterEnabled,
            onChanged: (value) {
              setState(() {
                waterEnabled = value;
              });
            },
          ),

          reminderSection(
            title: '🍎 تذكير الوجبات',
            times: mealTimes,
            enabled: mealEnabled,
            onChanged: (value) {
              setState(() {
                mealEnabled = value;
              });
            },
          ),

          reminderSection(
            title: '🏃‍♀️ تذكير الرياضة',
            times: exerciseTimes,
            enabled: exerciseEnabled,
            onChanged: (value) {
              setState(() {
                exerciseEnabled = value;
              });
            },
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: isSaving ? null : saveReminders,
            icon: const Icon(Icons.save),
            label: Text(
              isSaving ? 'جارٍ الحفظ...' : 'حفظ التذكيرات',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }
}