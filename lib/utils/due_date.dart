import '../models/task_item.dart';

/// The hour of day (local time) at which due-date notifications fire.
const int kReminderHour = 9;

/// The date a task falls due: its last completion date plus its interval.
///
/// Returns a date-only DateTime (midnight) so callers can compare it to
/// other dates regardless of time of day. Dart's DateTime normalises
/// overflow automatically: adding 7 days to 28 September gives
/// 5 October, not "35 September".
///
/// Returns null for tasks without an interval — they have no due date.
DateTime? dueDate(TaskItem task) {
  final interval = task.intervalDays;
  if (interval == null) {
    return null;
  }
  final last = task.lastCompletedAt;
  return DateTime(last.year, last.month, last.day + interval);
}

/// True when the task needs a scheduled notification: it has an interval
/// and its due date is strictly in the future.
///
/// Due today or already past is NOT scheduled — the in-app banner covers
/// those cases, and a past-due notification would fire immediately.
///
/// [now] is injectable so tests can pin the reference date.
bool shouldSchedule(TaskItem task, {DateTime? now}) {
  final due = dueDate(task);
  if (due == null) {
    return false;
  }
  final reference = now ?? DateTime.now();
  final today = DateTime(reference.year, reference.month, reference.day);
  return due.isAfter(today);
}
