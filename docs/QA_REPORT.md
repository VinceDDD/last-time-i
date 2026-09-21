# Last Time I — QA Report (v0.1.0)

**Report date:** 2026-09-22
**Tested revision:** `4423c28` — *Merge pull request #8 from VinceDDD/feature/release-v0.1.0* (`main`)
**QA workspace:** `D:\WorkBuddy\workspace\projects\last-time-i-qa` (fresh clone)
**Role:** QA engineer. **No source file was modified by this pass.** The only file added is this report.

---

## Test Summary

### Environment

| Item | Value |
|---|---|
| Flutter | 3.47.2 • stable • revision `d3b14c8769` |
| Dart | 3.13.2 (stable) |
| Pub packages | resolved OK (`flutter pub get` exit 0; 16 packages have newer, constraint-compatible versions) |
| JDK | Temurin 21.0.12.1+1 LTS |
| Android SDK | `D:\WorkBuddy\workspace\tools\android-sdk` — platform `android-36`, build-tools 36.0.0 / 36.1.0, NDK 28.2.13676358 |
| Gradle / AGP / Kotlin | Gradle 9.3.1 / AGP 9.1.0 / Kotlin 2.4.0 |
| Host timezone | `AUS Eastern Standard Time` (Sydney — **observes DST**) |

### Results

| # | Check | Command | Result |
|---|---|---|---|
| 1 | Flutter/Dart environment | `flutter --version` | **PASS** — 3.47.2 / Dart 3.13.2, satisfies `sdk: ^3.13.2` |
| 2 | Restore dependencies | `flutter pub get` | **PASS** — exit 0 |
| 3 | Formatting gate | `dart format --set-exit-if-changed .` | **FAIL** — exit 1, **13 of 18 files** would be reformatted (see Issue 2) |
| 4 | Static analysis | `flutter analyze` | **PASS** — “No issues found! (ran in 11.9s)” |
| 5 | Automated tests | `flutter test` | **PASS — 43/43** (matches the expected 43). Required a proxy workaround — see Issue 3 |
| 6 | Android build | `flutter build apk` | **PASS** — `build\app\outputs\flutter-apk\app-release.apk`, 47.2 MB, 124.6 s, exit 0 |
| 7 | Install + launch on device/emulator | — | **NOT RUN — environment limitation** (see below) |
| 8–10 | Manual user flows, runtime errors, persistence | — | **NOT RUN on device.** Exercised headlessly instead via temporary probe tests (see “Probe methodology”) |
| 11–13 | Invalid/unusual input, date maths, long text | — | **PASS (headless)** — see Verified working |
| 14 | V1 scope guard | source / manifest / pubspec inspection | **PASS** — no out-of-scope functionality found |

**Builds:** Android release APK builds clean. `package=com.lasttimei.last_time_i`, `versionName=0.1.0`, `versionCode=1`, `minSdk=24`, `targetSdk=36`, `compileSdk=36`, ABIs: `arm64-v8a`, `armeabi-v7a`, `x86_64`.

**Runtime:** **No Android runtime was available.** `adb devices` returned an empty list, the `emulator` package is not installed in the SDK, and there are no AVDs. `flutter devices` could not enumerate either — the Flutter tool calls `reg.exe`, which is blocked by the host sandbox security policy. Consequently checks 7–10 **could not be performed on a real device** and are reported as unverified in that dimension. No runtime exception or broken navigation was observable in the app under test.

**Probe methodology (temporary, removed):** to cover checks 8–13 without a device, two throwaway widget/unit test files were added, run, and then deleted; `git status` is clean. They drove the **real** screens against a **real** SQLite database (`sqflite_common_ffi`), and are the source of the empirical evidence quoted in Issues 1, 4, 5, 6, 7 and in “Verified working”.

### Verified working

- All 43 committed tests pass, including loading/error states, long-name rendering, delete cancel-vs-confirm, and persistence across a simulated app restart (`AppDatabase.close()` then reopen).
- **Date picker correctly rejects future dates** (probe): opening the picker and tapping tomorrow's cell left the selected date unchanged; a past date was selectable. `lastDate: DateTime.now()` in `add_task_screen.dart:41` / `edit_task_screen.dart:49` is effective.
- **No layout overflow at 360 dp width** with a ~240-character task name alongside the `MARK DONE TODAY` button (probe, `tester.view.physicalSize = 1080×1920 @3x`).
- Date arithmetic is correct for ordinary spans: leap-day boundary `2028-02-29 → 2028-03-01` = 1 day, year boundary `2025-12-31 → 2026-12-31` = 365 days.
- Unusual names round-trip correctly through SQLite: single character, Chinese (`换空气滤芯`), emoji (`Clean 🧽`), 150 characters.
- Persistence: rows survive close/reopen; no `INTERNET` permission in the release manifest; no Firebase, auth, ads, subscriptions, analytics, networking, or AI dependencies (`cupertino_icons`, `path`, `sqflite`, `sqflite_common_ffi` only).

---

## Issues Found

Issues are ordered by severity. No **Critical** issue was found — no crash, data loss, or broken primary flow was reproducible through the shipped UI.

---

### 1. `daysAgo` is one day short on the day after a daylight-saving transition — High

**Severity:** High (correctness of the app's single most important calculation)
**Component:** `lib/utils/date_formatter.dart:19-24` (`daysAgo`), used by `daysAgoLabel` (`:30-39`) and every label in `TaskCard`

**Reproduction**
```dart
// Host is Australia/Sydney. DST starts inside 2026-10-04.
DateTime(2026,10,5).difference(DateTime(2026,10,3)); // 47:00:00 -> .inDays == 1
DateTime(2026,10,5).difference(DateTime(2026,9,1));  // 815:00:00 -> .inDays == 33
DateTime(2026,10,5).difference(DateTime(2026,7,14)); // 1991:00:00 -> .inDays == 82
```
`daysAgo` is exactly `today.difference(thatDay).inDays`, so those are the values the app would show. Deterministic: `flutter test test/<probe>_test.dart` with the above assertions, or `dart run` on a snippet.

**Expected** — 2 / 34 / 83 days respectively. The spec defines “X days ago” as *whole days between `lastCompletedAt` and today, ignoring time of day* (`docs/PRODUCT_SPEC.md` → Definitions).

**Actual** — 1 / 33 / 82. On **2026-10-05 (Sydney)** the spring-forward 23-hour day makes every raw difference one hour short of a whole day, and `Duration.inDays` truncates instead of rounding. **Every task in the list reads one day less than it should** (e.g. the README example would show “82 days ago” instead of “83 days ago”). The error lasts the whole day and disappears on 2026-10-06. It affects any DST-observing timezone, roughly one day per year; southern-hemisphere and northern-hemisphere zones are hit on different dates.

**Error message** — none; a silent wrong value.

**Recommended fix** — normalise both dates to UTC before subtracting, so no DST rule can enter the arithmetic:
```dart
int daysAgo(DateTime date) {
  final now = DateTime.now();
  final today = DateTime.utc(now.year, now.month, now.day);
  final thatDay = DateTime.utc(date.year, date.month, date.day);
  return today.difference(thatDay).inDays;
}
```
(Alternatively `(.difference(...).inHours / 24).round()`, but UTC normalisation is cleaner.) Add a regression test that injects a fixed “now” — e.g. give `daysAgo` an optional `DateTime? now` parameter — and asserts the three cases above.

---

### 2. The repository's own formatting gate fails on a clean checkout — High

**Severity:** High (blocks the documented pre-merge check for every contributor)
**Component:** repository-wide; formatter version, not a specific file

**Reproduction**
```
git clone https://github.com/VinceDDD/last-time-i.git
cd last-time-i
dart format --set-exit-if-changed .     # exit code 1
```

**Expected** — exit 0 on a clean checkout (README: “Checks before every change”, `AGENTS.md`: “Format the code”).

**Actual** — exit 1. `Formatted 18 files (13 changed) in 0.06 seconds.` Files flagged:

`lib/database/app_database.dart`, `lib/repositories/task_repository.dart`, `lib/screens/add_task_screen.dart`, `lib/screens/edit_task_screen.dart`, `lib/screens/home_screen.dart`, `lib/services/task_service.dart`, `test/add_task_screen_test.dart`, `test/date_formatter_test.dart`, `test/edit_task_screen_test.dart`, `test/home_screen_test.dart`, `test/task_repository_test.dart`, `test/task_service_test.dart`, `test/unusual_inputs_test.dart`

**Root cause** — the committed code is formatted in the **pre-3.13 “short” style**; Dart 3.13.2 ships the new “tall” formatter as the default. Example diffs:
```diff
-  TaskService({TaskRepository? repository})
-      : _repository = repository ?? TaskRepository();
+  TaskService({TaskRepository? repository})
+    : _repository = repository ?? TaskRepository();
```
```diff
-  late final TaskRepository _repository =
-      widget.repository ?? TaskRepository();
+  late final TaskRepository _repository = widget.repository ?? TaskRepository();
```
The Dart SDK constraint `sdk: ^3.13.2` in `pubspec.yaml` permits 3.13+, so every developer on the declared minimum already sees this failure. Note: this check was run as `dart format --output=none --set-exit-if-changed .` so that no file was rewritten during QA; the plain command in the task produces the same exit code and additionally rewrites the 13 files.

**Recommended fix** — run `dart format .` once on `main` and commit the result as a standalone “reformat” commit (no logic changes), so later feature diffs stay readable. Consider documenting the formatter expectation in `AGENTS.md`, and optionally adding a CI job so the gate is enforced automatically rather than remembered.

---

### 3. `flutter test` cannot run at all when `HTTP_PROXY`/`HTTPS_PROXY` are set — Medium

**Severity:** Medium (environment/workflow; not a defect in the app code, but it silently breaks the whole test gate)
**Component:** test runner environment, not repository code

**Reproduction**
```
HTTP_PROXY=http://127.0.0.1:3133 HTTPS_PROXY=http://127.0.0.1:3133 \
  flutter test
```

**Expected** — 43 tests run and pass.

**Actual** — **all 43 tests fail to load**, exit code 1:
```
Failed to load ".../test/add_task_screen_test.dart": Unable to connect to
flutter_tester process: WebSocketException: Invalid WebSocket upgrade request
00:00 +0 -8: Some tests failed.
```
The Dart VM honours `HTTP(S)_PROXY` for the loopback websocket that `flutter test` opens to the `flutter_tester` process, so the proxy intercepts and rejects the upgrade. This presents as “every test in the project is broken” with no hint of the real cause.

**Recommended fix** — bypass the proxy for loopback when running tests:
```
NO_PROXY=127.0.0.1,localhost    # or: unset HTTP_PROXY HTTPS_PROXY
```
Worth adding a one-line note to `README.md` next to the test instructions, since `AGENTS.md` and `TEST_PLAN.md` both instruct the agent to run `flutter test` and a proxied shell will otherwise look like a total regression. Best long-term: a CI workflow that runs `flutter analyze` + `dart format --set-exit-if-changed .` + `flutter test` in a controlled environment.

---

### 4. Business rules live only in the UI; the service layer validates nothing — Medium

**Severity:** Medium (architecture / correctness-of-spec; no user-visible failure today)
**Components:** `lib/services/task_service.dart:8-36`, `lib/screens/add_task_screen.dart:50-61`, `lib/repositories/task_repository.dart:20-24`

**Reproduction** — a whitespace-only name and an unambiguously future date both persist without objection:
```dart
final repo = TaskRepository(database: testDb);
await repo.insertTask(TaskItem(name: '   ', lastCompletedAt: DateTime(2026, 9, 1)));
await repo.insertTask(TaskItem(name: 'Time traveller',
                               lastCompletedAt: DateTime(2030, 1, 1)));
// probe output: "P7 inserted blank name id=3 and future-dated id=4"
```

**Expected** — `docs/PRODUCT_SPEC.md` states as app rules: “**Future dates are not allowed.** The last-completed date must be today or earlier.” and “**Name cannot be blank.**” `docs/ARCHITECTURE.md` states “**Services** contain business rules (validation, date calculation)” and its data-flow diagram annotates `TaskService.markDoneToday` with “validates + sets `lastCompletedAt` = today”.

**Actual** — `TaskService` exposes only `markDoneToday`, `updateTask`, `deleteTask`; none validates anything, and there is no create/insert method. All validation is the `TextFormField` validator plus the date picker's `lastDate` bound, i.e. it exists only inside widget code. `AddTaskScreen._save()` also calls `_repository.insertTask(...)` **directly** (`add_task_screen.dart:58`), bypassing `TaskService` entirely — so the edit path goes through the service and the create path does not.

Secondary effect: `docs/TEST_PLAN.md` §1 promises service-level tests for “Blank name is rejected” and “Future date is rejected”. Those tests do not exist — `test/task_service_test.dart` covers only mark-done, update and delete. The plan and the code disagree.

**Recommended fix** — add `TaskService.createTask({required String name, required DateTime lastCompletedAt})` and `TaskService.validate(...)` enforcing non-blank (trimmed) name, no future date, and a sane minimum date; route both `AddTaskScreen._save` and `EditTaskScreen._save` through it; keep the widget validators as the fast user-facing feedback layer. Add the two missing `task_service_test.dart` cases. (Not applied — reported per instructions.)

---

### 5. `createdAt` and `updatedAt` are declared but never written — Medium

**Severity:** Medium (documented data model is not implemented; two dead columns)
**Components:** `lib/models/task_item.dart:53-61` (`toMap`), `lib/services/task_service.dart:18-30`, `lib/database/app_database.dart:50-60` (schema)

**Reproduction** — insert any task and read it back; probe output:
```
P5 insert returned createdAt=null updatedAt=null
P5 row read back createdAt=null updatedAt=null
```

**Expected** — `docs/PRODUCT_SPEC.md` data model lists `createdAt` (“When the item was created”) and `updatedAt` (“When the item was last modified”) as fields of the object, and the example row shows both populated (`createdAt: 2026-08-20`, `updatedAt: 2026-08-29`).

**Actual** — `AddTaskScreen._save` builds `TaskItem(name: ..., lastCompletedAt: ...)` and never sets `createdAt`/`updatedAt`; `TaskService.markDoneToday`/`updateTask` do not stamp `updatedAt`. `TaskItem.toMap` faithfully writes `null` for both. The columns therefore exist in SQLite but are `NULL` for every row in the app's lifetime, and they will be populated with `NULL` again on every edit.

**Recommended fix** — either stamp them (`createdAt: DateTime.now()` on insert; `updatedAt: DateTime.now()` in `markDoneToday` and `updateTask`) — note this makes `last_completed_at` the only date the user sees and `updated/created_at` internal — or remove both fields from the model, schema and spec so the documented data model matches reality. No migration is needed to start writing them; existing `NULL` rows simply stay `NULL`.

---

### 6. `HomeScreen` does not pass its repository to `AddTaskScreen` — Low

**Severity:** Low (no user-visible impact in the shipped app; breaks dependency injection and makes the add flow untestable)
**Components:** `lib/screens/home_screen.dart:43-48` (`_openAddScreen`) vs `:51-58` (`_openEditScreen`)

**Reproduction** — pump `HomeScreen(repository: TaskRepository(database: testDb))`, tap the FAB, enter “Water the plants”, tap SAVE, then read the injected database.

**Expected** — the new row appears in the injected database and in the list, exactly as the edit flow behaves (`_openEditScreen` does pass `_repository`).

**Actual** — `_openAddScreen` pushes `const AddTaskScreen()` with no repository, so `AddTaskScreen` falls back to `widget.repository ?? TaskRepository()` → `AppDatabase.instance`. Probe output:
```
P2b on Add screen: 1
P2b still on Add screen? false        <- save succeeded, screen popped
P2b rows in the INJECTED db = 0       <- but nothing landed in the given database
```
The write silently goes to the production singleton instead. In the real Android app both paths resolve to the same instance, so users are unaffected — but the add flow can never be verified against a controlled database, which is precisely why `test/home_screen_test.dart` contains no add test.

**Recommended fix** — `MaterialPageRoute(builder: (_) => AddTaskScreen(repository: _repository))`, matching the edit path, then add the missing home-screen add test.

---

### 7. Deleting a task with no `id` crashes on a null-check operator — Low

**Severity:** Low (confirmed crash; not reachable through the shipped UI)
**Component:** `lib/screens/edit_task_screen.dart:93` — `await _service.deleteTask(widget.task.id!);`

**Reproduction** — open `EditTaskScreen` with an unsaved task (`TaskItem(name: 'Unsaved', lastCompletedAt: ...)`, i.e. `id == null`), tap `DELETE`, then confirm `DELETE` in the dialog.

**Expected** — the action is rejected gracefully (or the button is not offered), with no unhandled exception.

**Actual** —
```
The following _TypeError was thrown running a test:
Null check operator used on a null value
#0  _EditTaskScreenState._delete (package:last_time_i/screens/edit_task_screen.dart:93:45)
```

**Reachability** — `HomeScreen` only ever passes rows read from the database, so tasks reaching this screen always have an `id`. The defect is latent, but it is a bare `!` on data the screen does not own.

**Recommended fix** —
```dart
final id = widget.task.id;
if (id == null) return;              // or disable/hide the DELETE button
await _service.deleteTask(id);
```

---

### 8. “X days ago” labels go stale while the app is left open — Low

**Severity:** Low (product promise vs. behaviour)
**Components:** `lib/screens/home_screen.dart:66-101`, `lib/widgets/task_card.dart:30`

**Reproduction** — launch the app with a task last completed today (label “Today”), leave it running overnight, and return to it the next day without triggering a rebuild (no navigation, no tap).

**Expected** — `docs/PRODUCT_SPEC.md`: “Tomorrow it shows '48 days ago' — it updates automatically, because the number is calculated from today's date, not stored.”

**Actual** — the label is recomputed in `TaskCard.build` only when the widget rebuilds. `_HomeScreenState` registers no `WidgetsBindingObserver`, no timer, and no `AppLifecycleState.resumed` handling, so after an overnight sleep the list still reads “Today” until the user performs some action. The value is indeed *computed* rather than stored (which satisfies the letter of the spec), but it is not *refreshed* with the passage of time.

**Recommended fix** — make `_HomeScreenState` a `WidgetsBindingObserver` and call `_reload()` from `didChangeAppLifecycleState` when the state becomes `resumed`; optionally also schedule a timer for the next local midnight. Invalidate via a counter/utils-method, not by rewriting stored data.

---

### 9. Test coverage gaps — the suite passes without exercising the paths it claims — Low

**Severity:** Low (test quality; hides Issues 4, 6 and 8)
**Components:** `test/` as a whole, notably `test/widget_test.dart:6-12`

- **`test/widget_test.dart` is vacuous.** It pumps the real `LastTimeIApp()` (which uses the production `AppDatabase.instance`) and asserts only that `'Last Time I...'` is found in the app bar. The `FutureBuilder` merely shows a spinner, so the test passes even if the database layer is completely unusable — it does not verify that the app launches into a working state.
- **No add-flow test from the home screen** (blocked by Issue 6). The FAB → add → list → SAVE round trip is never covered end to end.
- **No date-picker bounds test.** "Future dates are rejected" is asserted nowhere; the picker's `lastDate` is only enforced implicitly. (The QA probe confirmed the behaviour is currently correct.)
- **No service-level validation tests** even though `docs/TEST_PLAN.md` §1 lists them (see Issue 4).
- **No DST / fixed-clock test** for `daysAgo` (see Issue 1), and the existing date tests are all relative to `DateTime.now()`, so they can only prove self-consistency, never that the calendar arithmetic is right.
- **`docs/TEST_PLAN.md` §3 “Manual QA checklist”** — the device checklist (rotation, Android back button, launch with no console errors) has no record of ever being executed; it cannot be automated away entirely and needs a real device pass.

**Recommended fix** — make `daysAgo` accept an injectable “now” and add the DST cases; add a home-screen add test once Issue 6 is fixed; add the picker-bounds and service-validation tests promised by the test plan; and give `widget_test.dart` a repository-injected variant that asserts the empty state renders (i.e. that the app starts up against a real, working database).

---

### 10. `TaskItem` is `@immutable` but has no `==` / `hashCode` — Low

**Severity:** Low (code quality / future-bug risk)
**Component:** `lib/models/task_item.dart:9-77`

**Expected** — for an `@immutable` value object, two instances with equal fields compare equal.

**Actual** — only identity equality. `TaskItem` has `copyWith` and is annotated `@immutable` but defines neither `==` nor `hashCode`. Today nothing compares items, so there is no visible failure; the moment list diffing, `ListView` keys, `expect(task, equals(...))` or a state-management layer arrives, this becomes a subtle bug. Related: `copyWith` cannot clear `createdAt`/`updatedAt`, because `null` arguments mean “keep the current value” — the standard limitation of this idiom, worth a comment.

**Recommended fix** — add `operator ==`, `hashCode`, and (optionally) `toString`. Reuse the existing field set; no behaviour change.

---

### 11. Informational observations — Low

1. **Launcher label is the raw package name.** `android/app/src/main/AndroidManifest.xml` sets `android:label="last_time_i"`, confirmed by `aapt dump badging`: `application-label:'last_time_i'`. Users see `last_time_i` (with underscores) under the icon. Change it to `android:label="Last Time I"`, or move it to a `strings.xml` resource.
2. **No schema-migration path.** `lib/database/app_database.dart:21` sets `_dbVersion = 1` and `_open()` passes only `onCreate`. The first schema change will need an `onUpgrade`, or existing installs will break. Not a current defect — flagging it before v0.1.0 ships to real users.
3. **Debug-only stray file.** `tearDown` in `test/home_screen_test.dart` should be `tearDownAll` (the shared `testDb` is closed after every single test while `setUpAll` created it once). It works because `AppDatabase.database` lazily reopens, but the intent is ambiguous.
4. **Fat APK.** The release APK is 47.2 MB because it bundles `arm64-v8a`, `armeabi-v7a` and `x86_64`. `flutter build apk --split-per-abi`, or shipping an AAB, would cut per-device download size substantially.
5. **`AppDatabase.instance` is never closed** and has no disposal hook. Harmless for a single-activity app; noting it for completeness.
6. **Release signing.** `android/app/build.gradle.kts` signs release builds with the debug keystore (`signingConfig = signingConfigs.getByName("debug")`). Fine for QA and internal builds; it must be replaced before any store submission.

---

## Recommended Next Actions

Prioritised. Items 1–3 are blockers for a v0.1.0 release candidate; 4–6 should follow before wider distribution.

1. **Fix the DST off-by-one in `daysAgo`** (Issue 1) — the app exists to answer “how long since?”, and for one day a year in every DST timezone it answers wrong for every item. Normalise to UTC and add a fixed-clock regression test. Highest value per line changed.
2. **Reformat the repository and commit it** (Issue 2) — one `dart format .`, one dedicated commit, restores the project's own quality gate to green. Pair it with a CI job that runs `dart format --set-exit-if-changed .`, `flutter analyze` and `flutter test`, so the gate is enforced rather than remembered.
3. **Document the proxy workaround for `flutter test`** (Issue 3) — one line in `README.md` (`NO_PROXY=127.0.0.1,localhost`), otherwise the test suite looks catastrophically broken on any proxied machine.
4. **Move validation into `TaskService` and route creation through it** (Issue 4) — closes the gap between `ARCHITECTURE.md`/`PRODUCT_SPEC.md` and the code, and unblocks the two missing tests promised by `TEST_PLAN.md`.
5. **Resolve `createdAt` / `updatedAt`** (Issue 5) — either stamp them on insert/update or delete them from the model, schema and spec. Right now the documented data model and the database disagree.
6. **Fix the add-flow dependency injection** (Issue 6) and **guard the delete null-check** (Issue 7) — two small, low-risk changes that make the add path testable and remove a latent crash.
7. **Refresh labels on resume** (Issue 8) — add `WidgetsBindingObserver` + `_reload()` on `resumed`, so the list tells the truth after an overnight sleep.
8. **Close the coverage gaps** (Issue 9) — injectable clock for `daysAgo` (DST cases), home-screen add test, date-picker bounds test, service validation tests, and a `widget_test.dart` that actually asserts the app starts against a working database.
9. **Polish before distribution** (Issue 11) — set the launcher label to “Last Time I”; add a migration hook to `AppDatabase`; consider `--split-per-abi` or an AAB for download size.
10. **Run the manual device checklist** (`docs/TEST_PLAN.md` §3) once an emulator or phone is available — it was not possible in this environment: rotation, Android back button on every screen, and a launch-with-no-console-errors check remain unverified. The build in step 6 produces an installable `app-release.apk` ready for that pass.

---

*Checks 1–6 and 11–14 were executed; 7–10 were covered headlessly rather than on a device, as no Android runtime was available in this environment. No source code was modified during this QA pass; every proposed change above is described, not applied.*
