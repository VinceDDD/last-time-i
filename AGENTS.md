# Last Time I — Development Rules

Instructions for the coding agent working on this repository.

## Product

Last Time I is a simple Flutter mobile application that records when the user
last completed an activity or task, and shows how long ago it was
(e.g. "47 days ago").

## Primary objective

Keep the application simple, maintainable, and suitable for a beginner
developer to understand.

## Technology

- Flutter
- Dart
- Android first
- Local storage only for V1
- SQLite-compatible local persistence

## Architecture

Keep UI, business logic, and persistence separated. Use:

- `models/` — plain data objects
- `repositories/` — database access
- `services/` — business logic and validation
- `screens/` — one screen per page
- `widgets/` — reusable UI pieces
- `database/` — SQLite setup
- `utils/` — helpers such as date formatting
- `test/` — unit and widget tests

The UI must never talk to the database directly. All storage goes through the
repository.

## V1 restrictions — do NOT add

- Authentication / login
- Cloud sync
- Firebase (unless specifically requested)
- Advertising
- Subscriptions
- Social functionality
- AI features
- Backend servers
- Complex reminders / notifications

## Development rules

Before editing:

1. Inspect the existing code.
2. Explain the intended change.
3. Preserve the existing architecture.

After editing:

1. Format the code.
2. Run static analysis (`flutter analyze`).
3. Run relevant unit/widget tests (`flutter test`).
4. Report failures clearly. Do not hide failing tests.

General:

- Prefer small, focused changes over large refactors.
- Do not modify unrelated files.
- Do not introduce new dependencies without explaining why.

## Testing

Run for every meaningful code change where possible:

```
flutter analyze
flutter test
```

The project must not be marked done while tests are failing.
