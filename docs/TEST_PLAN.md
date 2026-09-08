# Last Time I — Test Plan (V1)

Testing strategy: automated tests run with `flutter test`, plus a manual QA
checklist on a real phone. Every meaningful code change must keep
`flutter analyze` and `flutter test` green.

## 1. Unit tests

### date_formatter_test.dart — the date logic

The most important calculation in the app. Test:

| Case                | Expected result       |
|---------------------|-----------------------|
| last done today     | "Today"               |
| last done yesterday | "1 day ago"           |
| last done 2 days ago| "2 days ago"          |
| last done 47 days ago | "47 days ago"       |
| 31 December boundary| correct across year   |
| Leap-year dates (29 Feb) | correct          |
| Future date         | handled / rejected    |

### task_service_test.dart — validation and business rules

- Blank name is rejected.
- Future date is rejected.
- `markDoneToday` sets `lastCompletedAt` to today.
- Create / read / update / delete round-trip through the repository.
- Data survives a simulated app restart (repository reopens the same database).

## 2. Widget tests

- Home screen shows the empty state when there are no tasks.
- Home screen lists tasks and shows the correct "X days ago" text.
- Tapping "Mark Done Today" updates the display to "Today".
- Add screen shows validation errors for blank name / future date.
- Edit screen loads existing values and saves changes.
- Delete shows a confirmation dialog; cancel does nothing, confirm deletes.

## 3. Manual QA checklist (on a real Android phone)

- App launches with no console errors.
- Add task → appears in list → shows correct days ago.
- Mark done today → shows "Today".
- Edit name and date → changes are saved.
- Delete → confirmation appears → task is gone.
- **Close and reopen the app → data is still there** (persistence).
- Rotate the device → layout survives, no crash.
- Android back button behaves correctly on every screen.
- Empty state shows the friendly message and Add button.
- Long task names wrap or truncate gracefully (no overflow errors).

## 4. Unusual input tests

- Single-character name
- Very long name (100+ characters)
- Chinese characters
- Emoji
- 31 December
- 29 February (leap year)
- Future date
- Today's date
- Date one day after last save (check "1 day ago")

## 5. Scope guard

Verify that **nothing outside the V1 spec** has been added: no login, no cloud
sync, no Firebase, no ads, no subscriptions, no AI, no backend.
