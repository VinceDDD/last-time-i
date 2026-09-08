# Last Time I — Product Specification (V1)

## What it is

Last Time I is a simple Flutter mobile application that records when the user
last completed an activity or task, and shows how long ago it was.

Example: you change your air filter on 14 July 2026. The app shows
"Change air filter — 47 days ago". Tomorrow it shows "48 days ago" — it updates
automatically, because the number is calculated from today's date, not stored.

## V1 features

1. **Create an item** — enter a name and the date it was last completed.
2. **Display "X days ago"** — computed from today minus `lastCompletedAt`.
3. **Mark an item as completed today** — one tap sets `lastCompletedAt = today`,
   and the display changes to "Today".
4. **Edit an item** — rename it, or change the last-completed date.
5. **Delete an item** — with a confirmation dialog ("This cannot be undone").
6. **Save everything locally** — SQLite-compatible storage on the device.

## Non-goals for V1 (explicitly excluded)

- Login / accounts
- Cloud sync
- Firebase
- Social features
- AI features
- Subscriptions
- Advertising
- Backend server
- Complex reminders / notifications

Anything in this list is intentionally out of scope for the first release.

## Data model

One main object:

| Field            | Type     | Notes                              |
|------------------|----------|------------------------------------|
| `id`             | int      | Primary key, auto-increment        |
| `name`           | String   | Task / activity name               |
| `lastCompletedAt`| DateTime | Date it was last completed (date only) |
| `createdAt`      | DateTime | When the item was created          |
| `updatedAt`      | DateTime | When the item was last modified    |

Example row:

```
id:              17
name:            Change air filter
lastCompletedAt: 2026-07-14
createdAt:       2026-08-20
updatedAt:       2026-08-29
```

## Rules

- **Never store text like "47 days ago".** Always compute it dynamically:
  `daysAgo = today - lastCompletedAt`.
- **Future dates are not allowed.** The last-completed date must be today or earlier.
- **Name cannot be blank.**
- Dates are stored in ISO format (`YYYY-MM-DD`) so they sort and compare reliably.

## Definitions

- **"X days ago"** = whole days between `lastCompletedAt` and today, ignoring time of day.
  - 0 days → "Today"
  - 1 day  → "1 day ago"
  - 2+ days → "2 days ago", "47 days ago", ...
