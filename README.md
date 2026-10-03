# Bloom

A warm, playful health, fitness, nutrition, and wellness companion for iOS and Android (and web preview), built with Flutter.

**Pip** — an original hand-drawn 2D animated character (rendered live with Flutter's canvas, not a 3D model) — greets you on the Today screen, reacts to your logs, guides breathing sessions, and chats with you in offline guided mode.

## Features

- **Today** — greeting, animated companion stage with contextual speech, habit progress, calorie/macro summary (optional), steps/water/sleep cards, upcoming planned meals & workouts, activity timeline, quick actions (log meal, water, walk, workout, check-in). Customizable widgets.
- **Nutrition** — food diary by meal, searchable offline catalog (150+ foods incl. Filipino dishes & household units), serving editor with correct recalculation, custom foods, favorites, recents, recipes with per-serving nutrition, allergen flags, weekly meal planning (planned meals are never auto-counted), grocery lists, pantry with expiry reminders.
- **Move** — exercise library (64 exercises, filterable), custom workout builder, workout player with rest timer and true wall-clock timing (survives backgrounding), workout history & personal bests, walk timer with pause/resume, manual entries, step goals, weekly history with labeled data sources (no double counting).
- **Wellness** — sleep logging across midnight, mood & energy check-ins, private journal with gratitude prompts, guided breathing (animated bubble + Pip), 2-minute relaxation, energy/soreness check-ins.
- **Health log** — symptoms/notes, medication taken/skipped logs, appointments with reminders, BP/glucose/other measurements. Never interprets readings or recommends doses.
- **Companion chat** — offline guided mode with quick replies, typing indicator, inline action previews, and confirmation before writing any record. Honestly labeled: no AI service connected.
- **Motivation** — flexible streaks, habit challenges, achievements (participation only), Pip accessories unlocked by consistency.
- **Insights** — nutrition/macro/weight/activity/sleep/mood trends with week/month filters, CSV exports, PDF summary.
- **Profile & settings** — editable goals & targets (estimates explained), units, light/dark theme, reduced motion, companion visibility, biometric app lock, notification preferences, full export/delete.

All data is stored **on-device** (Hive) — no account needed, works fully offline.

## Getting started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.22+ (tested with 3.47)
- Dart 3.4+

### Run

```bash
flutter pub get
flutter run
```

### Run tests

```bash
flutter test
```

### Analyze

```bash
flutter analyze
```

### Build

```bash
flutter build apk        # Android
flutter build ipa        # iOS (macOS only)
flutter build web        # Web preview (reminders/biometric/photo persistence limited)
```

## Architecture

```
lib/
  main.dart            # init: Hive, seed data, notifications
  app.dart             # theme, biometric lock gate, onboarding/shell routing
  core/                # theme, widgets, utils (units/dates/calc), notifications, export
  data/                # models, Hive database + migrations, repositories (Riverpod)
  data/seed_*.dart     # offline reference catalogs (foods, exercises, recipes)
  companion/pip.dart   # Pip: 2D animated character + speech bubble
  features/            # onboarding, shell, today, nutrition, recipes_plan,
                       # move, wellness, progress, chat, insights, settings
```

- **State**: Riverpod `ChangeNotifierProvider` repositories per domain.
- **Storage**: Hive boxes with a versioned migration strategy (`Database.schemaVersion`).
- **Reference vs personal data**: seed catalogs are read-only constants; personal records live in Hive.

## Honest limitations

- Pip is a **2D canvas animation**, not 3D (stated in-app under Profile → About).
- Food data is **approximate reference data**; entries are marked as estimates.
- Nutrition targets are **estimates** (Mifflin-St Jeor), editable, and skipped for minors/pregnancy/specialized needs.
- No barcode scanning, photo food recognition, GPS routes, or device step-counter integration in this version — manual and timer-based logging instead.
- Chat is **scripted offline guided mode**, not live AI.
- Reminders use real OS scheduling on mobile; not supported on web preview.
- Exercise demos are text-guided instructions (no licensed video).
- Bundled **Nunito** font ensures text renders offline without Google Fonts CDN.

## Verification (Oct 3, 2026)

- `flutter analyze`: **0 errors** (3 info-level lints remain, all guarded `mounted` checks)
- `flutter test`: **25/25 passed** (units, dates, sleep-across-midnight, Mifflin guards, nutrition math, JSON round-trips)
- `flutter build web --release`: **succeeded**
- Visual verification via headless Chromium: onboarding flow completes, all 5 tabs render, light + dark mode confirmed, bundled font renders text correctly
- Seed data: 153 foods, 64 exercises, 14 recipes
