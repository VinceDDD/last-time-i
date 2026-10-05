import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/task_item.dart';
import '../utils/due_date.dart';

/// Abstraction over notification scheduling, so screens and tests can
/// swap the real OS-backed implementation for a fake that records calls.
abstract class ReminderScheduler {
  /// Initialises the plugin and requests notification permission.
  Future<void> init();

  /// Replaces every scheduled notification with one per task that falls
  /// due in the future. Idempotent: cancels everything first.
  Future<void> rescheduleAll(List<TaskItem> tasks);

  /// Removes any scheduled notification for [taskId].
  Future<void> cancelTask(int taskId);
}

/// Real implementation backed by the OS notification service (Android).
class NotificationService implements ReminderScheduler {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// The notification channel id, shown under the app's notification
  /// settings on the phone.
  static const _channelId = 'due_date_reminders';

  bool _initialized = false;

  @override
  Future<void> init() async {
    if (_initialized) {
      return;
    }
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    // Note: since flutter_local_notifications 20.x the main plugin methods
    // take named parameters (settings:, id:, ...).
    await _plugin.initialize(settings: settings);
    await _initTimeZone();
    // Android 13+ needs runtime permission before any notification shows.
    // In current versions the permission call lives on the Android-specific
    // implementation, not on the main plugin object.
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    _initialized = true;
  }

  /// Loads the IANA timezone database and sets the local location from
  /// the device, so "9am" means 9am on the phone, wherever it is.
  Future<void> _initTimeZone() async {
    tzdata.initializeTimeZones();
    final info = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(info.identifier));
  }

  @override
  Future<void> rescheduleAll(List<TaskItem> tasks) async {
    await init();
    // Start from a clean slate so stale reminders never linger.
    await _plugin.cancelAll();

    for (final task in tasks) {
      if (!shouldSchedule(task)) {
        continue;
      }
      final id = task.id;
      if (id == null) {
        continue; // unsaved task; there is nothing to schedule
      }
      final due = dueDate(task)!;
      // Fire at 9:00 AM local time on the due date.
      final scheduledAt = tz.TZDateTime(
        tz.local,
        due.year,
        due.month,
        due.day,
        kReminderHour,
      );
      await _plugin.zonedSchedule(
        id: id,
        title: task.name,
        body: 'Due today',
        scheduledDate: scheduledAt,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'Due date reminders',
            channelDescription: 'Reminds you when a tracked task falls due.',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
        // Inexact is good enough for a 9am reminder and avoids needing
        // the Android "exact alarm" permission.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  @override
  Future<void> cancelTask(int taskId) async {
    await _plugin.cancel(id: taskId);
  }
}
