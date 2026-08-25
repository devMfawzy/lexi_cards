# lexi_cards

A spaced-repetition flashcard app, Anki-style, built in Flutter. You create decks, add cards, and review them on a schedule driven by the SM-2 algorithm — the same family of algorithm Anki and SuperMemo use. Rate a card Again/Hard/Good/Easy and the app decides when you'll see it next.

I built this as a portfolio piece to show a complete, non-trivial Flutter app: clean architecture, BLoC state management, local persistence, and a scheduling algorithm with actual logic worth unit testing — not just CRUD screens.

## What's in it

- **Decks & cards** — create decks, add cards to them, delete either.
- **Review sessions** — due cards are pulled per deck (overdue learning/relearning cards first, then cards due today, then new cards), shown one at a time with a flip animation, and rated on a 4-button scale.
- **SM-2 scheduling** — new cards go through short learning steps (1m → 10m) before graduating into day-scale review intervals. Ease factor adjusts per rating, lapses send a card back to relearning. Config lives in one place (`sm2_config.dart`) so the constants aren't scattered through the scheduler.
- **Stats screen** — every review was already being logged (`ReviewLog`: rating, interval before/after, ease before/after) but nothing surfaced it. Added a screen for current/longest streak, retention rate, and 7-day bar charts for reviews done vs. cards coming due.

## Architecture

Feature-first, clean-architecture-ish split. Each feature under `lib/features/` has:

```
domain/        entities + usecases — no Flutter, Hive, or bloc imports
data/          Hive models, local datasource, repository implementation
presentation/  Cubit + pages/widgets
```

`CardRepository` is the interface the domain layer talks to; `CardRepositoryImpl` is the only thing that knows Hive exists. Usecases are thin — mostly one-liners delegating to the repository — except `GetReviewStats`, which does the actual streak/retention/forecast computation and takes an injectable `now` so tests don't depend on the wall clock.

Wiring:
- `get_it` for DI (registered in `core/di/injection_container.dart`)
- `go_router` for navigation (`core/router/app_router.dart`)
- `flutter_bloc` (Cubit, not full Bloc — no event layer needed here)

## Stack

- Flutter 3.44 / Dart 3.10
- `flutter_bloc`, `equatable`
- `hive_ce` for local storage (no backend — everything's on-device)
- `go_router`, `get_it`, `uuid`
- `mocktail` + `bloc_test` for tests

## Running it

```
flutter pub get
flutter run
```

Runs on iOS, Android, and web — no platform-specific setup beyond the usual Flutter toolchain.

## Tests

```
flutter test
```

Two things are actually worth testing here, and both are covered:

- `sm2_scheduler_test.dart` — every state transition (new → learning → review, lapses into relearning, ease-factor floor, interval compounding) against a fixed `now`.
- `get_review_stats_test.dart` — streak edge cases (gap breaks it, "reviewed yesterday but not yet today" still counts as active, same-day reviews don't double-count) and retention math.

## What's not here yet

Single review queue per deck, no card editing after creation, no reminders/notifications, no sync — it's local-only. These are the obvious next steps if this grows past a portfolio piece.

## Author

Mohamed Fawzy — [github.com/devMfawzy](https://github.com/devMfawzy)
