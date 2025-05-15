import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tapped
        print('Notification tapped: ${response.payload}');
      },
    );

    // Request permissions for iOS
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> scheduleDaily(TimeOfDay time, {String? title, String? body}) async {
    final now = DateTime.now();
    DateTime scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If time is earlier than current time, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0, // Notification ID
      title ?? 'Expense Reminder',
      body ?? 'Time to check your expenses!',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_notification_channel_id',
          'Daily Notifications',
          channelDescription: 'Daily expense reminder notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_notification',
    );

    // Save the notification time to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notification_time', '${time.hour}:${time.minute}');
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();

    // Clear the notification time from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notification_time');
  }

  Future<TimeOfDay?> getScheduledNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString('notification_time');

    if (timeString != null) {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);

        if (hour != null && minute != null) {
          return TimeOfDay(hour: hour, minute: minute);
        }
      }
    }

    return null;
  }
}

// Helper extension for TimeOfDay
extension TimeOfDayExtension on TimeOfDay {
  String format12Hour() {
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final period = hour < 12 ? 'AM' : 'PM';
    return '$hour12:${minute.toString().padLeft(2, '0')} $period';
  }
}