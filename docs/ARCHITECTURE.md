# Last Time I — Architecture (V1)

## Goal

Keep the app simple, maintainable, and easy for a beginner developer to
understand. The guiding principle: **separate what the user sees (UI) from
what the app does (logic) from where data lives (storage).**

## Three layers

```
┌─────────────────────────────┐
│  UI (screens + widgets)      │  what the user sees and touches
├─────────────────────────────┤
│  Service / Repository        │  business logic + data access
├─────────────────────────────┤
│  Database (SQLite)           │  where data is actually stored
└─────────────────────────────┘
```

- **UI** never talks to the database directly.
- **Services** contain business rules (validation, date calculation).
- **Repositories** are the only place that touches the database.
- **Models** are plain data objects shared across layers.

This makes each part testable on its own and easy to change later.

## Folder structure

```
last-time-i/
├── README.md
├── AGENTS.md
├── pubspec.yaml
├── docs/
│   ├── PRODUCT_SPEC.md
│   ├── ARCHITECTURE.md
│   └── TEST_PLAN.md
├── lib/
│   ├── main.dart                  app entry point
│   ├── models/
│   │   └── task_item.dart         plain data object
│   ├── database/
│   │   └── app_database.dart      SQLite setup / schema
│   ├── repositories/
│   │   └── task_repository.dart   all database reads/writes
│   ├── services/
│   │   └── task_service.dart      business logic + validation
│   ├── screens/
│   │   ├── home_screen.dart       task list
│   │   ├── add_task_screen.dart   add a task
│   │   └── edit_task_screen.dart  edit a task
│   ├── widgets/
│   │   └── task_card.dart         one row in the list
│   └── utils/
│       └── date_formatter.dart    "47 days ago" calculation
├── test/
│   ├── task_service_test.dart
│   ├── date_formatter_test.dart
│   └── widget_test.dart
└── android/                       Android platform files (generated)
```

## Data flow example — marking a task done today

```
User taps [MARK DONE TODAY]
        │
        ▼
HomeScreen (UI)
        │  calls
        ▼
TaskService.markDoneToday(task)
        │  validates + sets lastCompletedAt = today
        ▼
TaskRepository.update(task)
        │  SQL UPDATE
        ▼
AppDatabase (SQLite)
        │
        ▼
HomeScreen rebuilds → DateFormatter.daysAgo(task)
        → shows "Today"
```

## Why this matters for learning

- Each file has **one job** — easy to read and explain.
- **Logic lives in services**, not buried in widget code, so it can be unit-tested.
- **Storage is behind a repository**, so if we ever swap SQLite for something
  else, only one file changes.
