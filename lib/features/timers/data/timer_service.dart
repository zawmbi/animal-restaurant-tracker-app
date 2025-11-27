import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class TimerService {
  TimerService._();
  static final TimerService instance = TimerService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(
      android: androidInit,
      // you can add iOS/macOS init later if you want
    );

    await _plugin.initialize(initSettings);

    // Timezone setup for zonedSchedule
    tz.initializeTimeZones();

    // Simple: just use the device local timezone
    // (tz.local will default correctly on most setups once initialized)
  }

  Future<void> scheduleTimer({
    required String id,
    required String title,
    required String body,
    required Duration duration,
  }) async {
    final notifId = id.hashCode & 0x7fffffff;
    final when = tz.TZDateTime.now(tz.local).add(duration);

    const androidDetails = AndroidNotificationDetails(
      'timers_channel',
      'Timers',
      channelDescription: 'Buffet, tip jar, takeout, performers timers',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      notifId,
      title,
      body,
      when,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelTimer(String id) async {
    final notifId = id.hashCode & 0x7fffffff;
    await _plugin.cancel(notifId);
  }

  Future<void> cancelAll() => _plugin.cancelAll();


}
