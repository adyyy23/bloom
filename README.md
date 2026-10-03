# Bloom

A warm, playful health, fitness, nutrition, and wellness companion for iOS and Android (and web preview), built with Flutter.

**Pip** — an original hand-drawn 2D animated character (rendered live with Flutter's canvas, not a 3D model) — greets you on the Today screen, reacts to your logs, guides breathing sessions, and chats with you in offline guided mode.

## Features

- **Today** — greeting, interactive **3D Human Body Visualizer** with natural anatomical proportions, floor contact shadow, $360^\circ$ rotation, angle preset buttons (Front, 3/4, Side, Back, Reset), and Current vs. Goal preview toggle. Concise Body Metrics summary with verified WHO/CDC adult BMI classification, clinical info modal, powder blue featured movement routine panel, habit progress, calorie/macro summary, steps/water/sleep cards, upcoming planned meals & workouts, activity timeline, and refined violet/neutral quick actions. Pip companion shortcut and streak rhythm badges in top bar.
- **Visualizer Customization** — full bottom sheet with live mini 3D preview, metric inputs (weight, height, waist, hips, chest), body frame width, facial profile presets, 6 inclusive skin tones, 4 hairstyles, 5 hair colors, 3 clothing styles, and 5 sportswear colors.
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
flutter build web        # Web preview
```

## Architecture

```
lib/
  main.dart                      # init: Hive, seed data, notifications
  app.dart                       # theme, biometric lock gate, onboarding/shell routing
  core/                          # theme, widgets, utils (units/dates/calc/clinical BMI), notifications, export
  data/                          # models, Hive database + migrations, repositories (Riverpod)
  data/seed_*.dart               # offline reference catalogs (foods, exercises, recipes)
  companion/
    human_body_mesh.dart         # 3D anatomical mesh (783 vertices, 1360 faces), morph targets & AvatarConfig
    human_visualizer.dart        # 3D rasterizer, multi-source studio lighting, clay shader, camera controls
    edit_measurements_sheet.dart # Customization sheet with live mini 3D preview
    pip.dart                     # Pip: 2D animated character + speech bubble
  features/                      # onboarding, shell, today, nutrition, recipes_plan,
                                 # move, wellness, progress, chat, insights, settings
```

- **3D Rasterizer**: Hardware-accelerated canvas renderer projecting 3D polygons with Painter's depth sorting, back-face culling, Key/Fill/Rim lighting, and Blinn-Phong clay specular sheen.
- **State**: Riverpod `ChangeNotifierProvider` repositories per domain.
- **Storage**: 25 persistent Hive boxes with versioned migration strategy (`Database.schemaVersion`).
- **Reference vs personal data**: seed catalogs are read-only constants; personal records live in Hive.

## Verification & Clinical Standards

- `flutter analyze`: **0 errors, 0 warnings**
- `flutter test`: **32/32 passed** (units, dates, sleep-across-midnight, clinical adult WHO/CDC BMI categories, pediatric guardrails, pregnancy/nursing exemptions, AvatarConfig JSON round-trip, bounded 3D mesh morphing)
- `flutter build web`: succeeded
- Clinical disclaimer displayed: *"Approximate visualization — not a body scan."*
- Seed data: 153 foods, 64 exercises, 14 recipes
