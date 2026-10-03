import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../data/models.dart';

/// Local reminder scheduling with explicit integration state.
///
/// - Mobile/desktop: real OS scheduling via flutter_local_notifications.
/// - Web: not supported — the UI reports this honestly instead of pretending.
class NotificationService {
  NotificationService._();
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static bool _permissionGranted = false;

  static bool get supported => !kIsWeb;
  static bool get permissionGranted => _permissionGranted;

  static Future<void> init() async {
    if (!supported || _initialized) return;
    tzdata.initializeTimeZones();
    try {
      final String local = DateTime.now().timeZoneName;
      tz.setLocalLocation(tz.getLocation(_guessTz(local)));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const mac = DarwinInitializationSettings();
    const linux = LinuxInitializationSettings(defaultActionName: 'Open');
    await _plugin.initialize(
      const InitializationSettings(
          android: android, iOS: ios, macOS: mac, linux: linux),
    );
    _initialized = true;
  }

  // Best-effort mapping; falls back to UTC.
  static String _guessTz(String name) {
    const known = [
      'Asia/Manila', 'Asia/Singapore', 'Asia/Tokyo', 'Asia/Jakarta',
      'Asia/Kolkata', 'Asia/Dubai', 'Europe/London', 'Europe/Paris',
      'Europe/Berlin', 'America/New_York', 'America/Chicago',
      'America/Denver', 'America/Los_Angeles', 'Australia/Sydney',
      'Pacific/Auckland', 'UTC',
    ];
    return known.contains(name) ? name : 'UTC';
  }

  static Future<bool> requestPermission() async {
    if (!supported) return false;
    await init();
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      _permissionGranted = await android?.requestNotificationsPermission() ?? false;
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      _permissionGranted = await ios?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    } else {
      _permissionGranted = true;
    }
    return _permissionGranted;
  }

  static Future<void> scheduleReminder(ReminderItem r,
      {required bool showPreview}) async {
    if (!supported) return;
    await init();
    final parts = r.time.split(':');
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    final id = r.id.hashCode & 0x7fffffff;
    final weekdays = r.weekdays.isEmpty
        ? [1, 2, 3, 4, 5, 6, 7]
        : r.weekdays;
    // Daily-style repeat: schedule the next occurrence; the app re-schedules
    // on each launch for the selected weekdays.
    var next = scheduled;
    var guard = 0;
    while (!weekdays.contains(next.weekday) && guard < 8) {
      next = next.add(const Duration(days: 1));
      guard++;
    }
    await _plugin.zonedSchedule(
      id,
      showPreview ? r.title : 'Bloom reminder',
      showPreview ? r.body : 'You have a reminder in Bloom.',
      next,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'bloom_reminders',
          'Bloom reminders',
          channelDescription: 'Habit and health reminders you set in Bloom',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
        linux: LinuxNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancel(String id) async {
    if (!supported) return;
    await _plugin.cancel(id.hashCode & 0x7fffffff);
  }

  static Future<void> cancelAll() async {
    if (!supported) return;
    await _plugin.cancelAll();
  }
}
