# AGENTS.md

Operational notes for AI coding agents working on StackTasks. Read this
before touching the codebase.

## Project shape

- Monorepo: `stacktask_mobile/` is the Flutter package; everything else
  lives at the repo root (`stack-task.png`, `assets/`, `README.md`).
- Flutter app is MVVM with `provider` for DI and per-widget
  `ChangeNotifier` controllers for transient UI state.
- `result/` → `Result<S, E>` pattern (sealed) — never throw across layer
  boundaries, return `Failure(ErrorCode(...))` instead.
- SQLite via `sqflite_common_ffi` (tests) and `sqflite` (runtime). Schema
  in `DatabaseHelper`; repo mutations append to `task_changes` so a
  future sync layer can replay.

## Layer rules

| Layer | Knows about | Does NOT know about |
|---|---|---|
| `core/models` | Dart only | Flutter, DB |
| `core/services` | Models | Flutter, DB |
| `core/repositories` | Models, DB | Flutter, ViewModels |
| `core/result` | Dart only | anything else |
| `ui/view_models` | `ChangeNotifier`, services, repos | Widgets |
| `ui/widgets` | Models, controllers | Repositories |
| `ui/screens` | ViewModels, widgets | Repositories |

Never let a widget call a repository directly. Never let a ViewModel
import `package:flutter/material.dart` (it's a `ChangeNotifier`, not a
widget). Never let a service touch the database.

## Conventions

- **No Z/scale transforms on cards.** Y offsets only. The 3D depth is
  conveyed by Y position + opacity + a small shadow, not by `scale`.
- **No visibleCount cap.** Render every card in the stack; the parent
  `SizedBox` height grows with the count.
- **No commented-out code blocks** or decorative `// --- Front card ---`
  separators.
- **No emoji in source files** unless the user explicitly asks.
- **No unused fields, methods, or imports.** If the analyzer flags it,
  delete it.
- **Naming**: `camelCase` for Dart; `snake_case` for SQL columns and
  files; `PascalCase` for widget classes.
- **Thresholds** (swipe, velocity, padding) live as `static const` on
  the controller or widget, not magic numbers in the build tree.

## Controller pattern

Each non-trivial widget owns a `ChangeNotifier` for transient state:

- `CardStackController` (`lib/src/ui/widgets/card_stack_controller.dart`)
  owns front-card drag, swipe-out animation, and selection/bypassed
  indexes for the long-press reorder gesture.
- The widget creates the controller in its `State`, calls
  `controller.dispose()` in its own `dispose`, and rebuilds affected
  children with `ListenableBuilder` (NOT a global `ListenableBuilder`
  around the whole tree — that's how you get "every card rebuilds when
  one card moves" bugs).
- The widget calls the ViewModel only on commit (e.g. on
  `onLongPressEnd`), not on every drag event.

## Long-press + drag-to-reorder

The selected card follows the finger via `offsetFromOrigin` — which is
**cumulative, not a delta**. Set the value (`=`), don't add to it
(`+=`). Setting the controller field to `delta.dx` is the most common
bug in this gesture.

`bypassedIndex` tracks which slot the card will land in. Both up
(negative Y) and down (positive Y) are supported. Use `isBypassed(i)`
to check whether a card should fade to 0.4.

## Gestures (current)

- Front card (index 0): horizontal drag → swipe left/right; vertical
  drag down → cycle to end. Long-press → enter selection mode.
- Background cards: long-press → enter selection mode. Tap is
  reserved for the Add Task modal, not for cards.
- Selection mode: drag up/down to reorder; release to commit (calls
  `onMoveCard(from, to)` → `vm.moveCardTo(from, to)`).
- Drag/swipe animations animate via `TweenAnimationBuilder` or
  `AnimatedOpacity` — no `AnimationController` boilerplate unless we
  need precise control.

## ViewModel `peekedIndex` is GONE

If you see any reference to `peekedIndex`, `peek()`, or `clearPeek()` in
`StackViewModel` or its tests, that's a regression — remove it. The
long-press flow replaced peek entirely. `StackService.peek` (the
front-card getter) is unrelated; keep it.

## Tests

- Tests live in `stacktask_mobile/test/`, mirroring `lib/src/`.
- 72 tests currently pass. Run with `flutter test`.
- Test helper `_createTestDatabase()` in
  `test/src/ui/view_models/stack_view_model_test.dart` uses
  `databaseFactoryFfi.openDatabase(inMemoryDatabasePath)` with raw SQL
  matching `DatabaseHelper`'s schema. Other repository tests use the
  same pattern.
- Never skip tests to make a bug go away. If a test fails, fix the
  code, not the test.

## Build / analyze commands

Always run before declaring work done:

    cd stacktask_mobile
    flutter analyze
    flutter test

The project should report `No issues found!` and `All tests passed!`.
If it doesn't, fix it.

## Brand assets

- SVGs live in `stacktask_mobile/assets/` and are registered in
  `pubspec.yaml` under `flutter.assets`.
- PNGs are generated from the SVGs with `rsvg-convert -w W -h H` for
  each consumer (logo@256/@512, icon-stack@64, hero@1280).
- Android launcher icons go in
  `stacktask_mobile/android/app/src/main/res/mipmap-{m,h,xh,xxh,xxxh}dpi/`.
  Adaptive icon foreground is 108×108dp at mdpi, scaled per DPI.
- Adaptive icon background is a solid color
  (`values/ic_launcher_background.xml`), not a raster.

## Out of scope (do not implement unless asked)

- iOS / macOS / Windows / Linux build polish (icons, launch screens).
- Backend sync of `task_changes`.
- Auth, accounts, cloud storage.
- Push notifications.
- Desktop (windowed) layout variants of the stack screen.
