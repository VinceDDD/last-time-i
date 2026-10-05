import 'package:flutter_test/flutter_test.dart';

import 'package:last_time_i/utils/date_formatter.dart';

void main() {
  // ONE clock read per test, pinned as the reference date for every call.
  //
  // Reading DateTime.now() separately inside daysAgo would produce a
  // different "today" if the suite happens to run across midnight, and a
  // duration-based "today minus 24 hours" lands on the wrong calendar day
  // around a daylight-saving transition (Sydney springs forward in
  // early October). Date arithmetic on (year, month, day) avoids both.
  late DateTime today;

  setUp(() {
    final now = DateTime.now();
    today = DateTime(now.year, now.month, now.day);
  });

  /// [days] calendar days before the pinned reference date.
  DateTime daysBack(int days) =>
      DateTime(today.year, today.month, today.day - days);

  group('daysAgo', () {
    test('today is 0 days ago', () {
      expect(daysAgo(today, now: today), 0);
    });

    test('yesterday is 1 day ago', () {
      expect(daysAgo(daysBack(1), now: today), 1);
    });

    test('47 days ago is 47', () {
      expect(daysAgo(daysBack(47), now: today), 47);
    });

    test('crosses month boundaries correctly', () {
      // 45 days back always spans at least one month boundary.
      expect(daysAgo(daysBack(45), now: today), 45);
    });
  });

  group('daysAgo edge cases', () {
    test('366 days back spans a leap year', () {
      expect(daysAgo(daysBack(366), now: today), 366);
    });

    test('365 days back returns 365 (works across years)', () {
      expect(daysAgo(daysBack(365), now: today), 365);
    });

    test('a future date is clamped to 0 or less (defensive)', () {
      // The label layer clamps this to "Today"; daysAgo itself must not
      // throw or return a misleading positive number.
      expect(daysAgo(daysBack(-1), now: today), lessThanOrEqualTo(0));
    });

    test('day after a DST transition still counts as 1 day', () {
      // 2026-10-04 is the Sydney spring-forward date: that local day has
      // only 23 hours. Comparing local midnights would report 0; UTC
      // normalisation reports the correct 1.
      expect(daysAgo(DateTime(2026, 10, 4), now: DateTime(2026, 10, 5)), 1);
    });
  });

  group('daysAgoLabel', () {
    test('today shows "Today"', () {
      expect(daysAgoLabel(today, now: today), 'Today');
    });

    test('yesterday shows "1 day ago"', () {
      expect(daysAgoLabel(daysBack(1), now: today), '1 day ago');
    });

    test('two days ago shows "2 days ago"', () {
      expect(daysAgoLabel(daysBack(2), now: today), '2 days ago');
    });

    test('47 days ago shows "47 days ago"', () {
      expect(daysAgoLabel(daysBack(47), now: today), '47 days ago');
    });

    test('a future date (defensive) shows "Today"', () {
      expect(daysAgoLabel(daysBack(-1), now: today), 'Today');
    });
  });

  group('statusLabel and isOverdue', () {
    test('no interval keeps the days-ago label and is never overdue', () {
      final d = daysBack(47);
      expect(isOverdue(d, now: today), isFalse);
      expect(statusLabel(d, now: today), '47 days ago');
    });

    test('before the interval keeps the days-ago label', () {
      final d = daysBack(89);
      expect(isOverdue(d, intervalDays: 90, now: today), isFalse);
      expect(statusLabel(d, intervalDays: 90, now: today), '89 days ago');
    });

    test('exactly on the interval is "Due today"', () {
      final d = daysBack(90);
      expect(isOverdue(d, intervalDays: 90, now: today), isFalse);
      expect(statusLabel(d, intervalDays: 90, now: today), 'Due today');
    });

    test('one day past the interval is "1 day overdue"', () {
      final d = daysBack(91);
      expect(isOverdue(d, intervalDays: 90, now: today), isTrue);
      expect(statusLabel(d, intervalDays: 90, now: today), '1 day overdue');
    });

    test('ten days past the interval is "10 days overdue"', () {
      final d = daysBack(100);
      expect(isOverdue(d, intervalDays: 90, now: today), isTrue);
      expect(statusLabel(d, intervalDays: 90, now: today), '10 days overdue');
    });
  });

  group('isDueToday', () {
    test('with no interval it is never due today', () {
      expect(isDueToday(today, now: today), isFalse);
    });

    test('exactly on the interval is due today', () {
      final d = daysBack(90);
      expect(isDueToday(d, intervalDays: 90, now: today), isTrue);
    });

    test('one day before the interval is not due yet', () {
      final d = daysBack(89);
      expect(isDueToday(d, intervalDays: 90, now: today), isFalse);
    });

    test('one day past the interval is overdue, not due today', () {
      final d = daysBack(91);
      expect(isDueToday(d, intervalDays: 90, now: today), isFalse);
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
