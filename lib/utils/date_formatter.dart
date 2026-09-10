/// Date helpers shared across the app.
///
/// All dates are stored and displayed with day precision ("yyyy-MM-dd"),
/// so they compare and sort reliably regardless of time of day.
library;

/// Formats [date] as "yyyy-MM-dd" (day precision only).
String formatDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Whole days between [date] and today (0 = today, 1 = yesterday, ...).
///
/// The calculation is deliberately date-only: time of day is ignored,
/// so "last night at 11pm" and "this morning at 6am" both count as today.
int daysAgo(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final thatDay = DateTime(date.year, date.month, date.day);
  return today.difference(thatDay).inDays;
}

/// Human-friendly label: "Today", "1 day ago", "47 days ago".
///
/// Future dates (which the app forbids, but we stay defensive) read as
/// "Today" instead of showing a negative number.
String daysAgoLabel(DateTime date) {
  final days = daysAgo(date);
  if (days <= 0) {
    return 'Today';
  }
  if (days == 1) {
    return '1 day ago';
  }
  return '$days days ago';
}
