import 'package:flutter_test/flutter_test.dart';

import 'package:last_time_i/utils/date_formatter.dart';

void main() {
  // "Today" with time-of-day stripped, matching how the app treats dates.
  DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  group('daysAgo', () {
    test('today is 0 days ago', () {
      expect(daysAgo(today()), 0);
    });

    test('yesterday is 1 day ago', () {
      expect(daysAgo(today().subtract(const Duration(days: 1))), 1);
    });

    test('47 days ago is 47', () {
      expect(daysAgo(today().subtract(const Duration(days: 47))), 47);
    });

    test('crosses month boundaries correctly', () {
      // 45 days back always spans at least one month boundary.
      expect(daysAgo(today().subtract(const Duration(days: 45))), 45);
    });
  });

  group('daysAgo edge cases', () {
    test('366 days back spans a leap year', () {
      expect(daysAgo(today().subtract(const Duration(days: 366))), 366);
    });

    test('365 days back returns 365 (works across years)', () {
      expect(daysAgo(today().subtract(const Duration(days: 365))), 365);
    });

    test('a future date is clamped to 0 or less (defensive)', () {
      // The label layer clamps this to "Today"; daysAgo itself must not
      // throw or return a misleading positive number.
      expect(
        daysAgo(today().add(const Duration(days: 1))),
        lessThanOrEqualTo(0),
      );
    });
  });

  group('daysAgoLabel', () {
    test('today shows "Today"', () {
      expect(daysAgoLabel(today()), 'Today');
    });

    test('yesterday shows "1 day ago"', () {
      expect(
        daysAgoLabel(today().subtract(const Duration(days: 1))),
        '1 day ago',
      );
    });

    test('two days ago shows "2 days ago"', () {
      expect(
        daysAgoLabel(today().subtract(const Duration(days: 2))),
        '2 days ago',
      );
    });

    test('47 days ago shows "47 days ago"', () {
      expect(
        daysAgoLabel(today().subtract(const Duration(days: 47))),
        '47 days ago',
      );
    });

    test('a future date (defensive) shows "Today"', () {
      expect(
        daysAgoLabel(today().add(const Duration(days: 1))),
        'Today',
      );
    });
  });

  group('formatDate', () {
    test('pads month and day with zeros', () {
      expect(formatDate(DateTime(2026, 7, 4)), '2026-07-04');
    });

    test('keeps two-digit month and day as-is', () {
      expect(formatDate(DateTime(2026, 12, 31)), '2026-12-31');
    });

    test('formats leap day 29 February', () {
      expect(formatDate(DateTime(2028, 2, 29)), '2028-02-29');
    });
  });
}
