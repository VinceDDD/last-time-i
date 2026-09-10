/// Date helpers shared across the app.
///
/// All dates are stored and displayed with day precision ("yyyy-MM-dd"),
/// so they compare and sort reliably regardless of time of day.
String formatDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
