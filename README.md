# Last Time I

A simple Flutter mobile app that records when you last completed an activity,
and shows how long ago it was.

Example: change the air filter on 14 July → the app shows
"Change air filter — 47 days ago".

## V1 features

- Create an item (name + date it was last completed)
- Display how long ago it was ("X days ago")
- Mark an item as completed today
- Edit an item
- Delete an item (with confirmation)
- Store everything locally on the device

## Explicitly out of scope for V1

No login/accounts, no cloud sync, no Firebase, no social features, no AI
features, no subscriptions, no advertising, no backend server, no complex
reminders.

## Getting started

Requirements:

- Flutter stable channel (3.x) — see https://docs.flutter.dev/get-started/install
- An Android device or emulator (Android-first project)

Run:

```
cd last-time-i
flutter pub get
flutter run
```

Checks before every change:

```
flutter analyze
flutter test
```

## Project documentation

- [docs/PRODUCT_SPEC.md](docs/PRODUCT_SPEC.md) — what V1 is (features, data model, rules)
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — how the code is organised (layers, folders, data flow)
- [docs/TEST_PLAN.md](docs/TEST_PLAN.md) — how we verify the app works
- [AGENTS.md](AGENTS.md) — development rules for coding agents

## Development workflow

One feature per branch → code → `flutter analyze` + `flutter test` →
pull request → review → merge into `main`.

Branches used so far: `main` (stable) · `feature/project-foundation`.
