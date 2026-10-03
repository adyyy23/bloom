# Human stage and home screen review

The opening screen now uses a peach header, large original human on a curved white foreground, compact recorded metrics, powder-blue featured movement card, violet controls and floating white navigation. Appearance has a live preview and separate Save, Cancel and Reset actions. Every exposed appearance enum changes geometry or a rendered material; accessories include a 3D headband and spectacles.

## Renderer and data

The renderer projects real vertices, sorts far-to-near faces, culls back faces, computes smooth vertex lighting, and draws contact shadows. It uses Flutter Canvas `drawVertices`, not a static image, WebView, or GLB viewer. It fits camera framing to the current projected bounds, including hair, hands and shoes. Horizontal drag and front, quarter, side, back and reset controls remain operable with reduced motion. Idle rendering is capped at approximately 30 updates/second and stopped through viewport checks, TickerMode and app lifecycle state.

Appearance saves only the existing `misc.avatarConfig` key. Save success is committed to in-memory state after storage succeeds. Measurement edits log only changed valid values, convert lb/in to kg/cm, and leave blank optional entries unchanged. Latest measurement records take precedence over legacy avatar circumferences. Goal visualization never writes records or replaces the recorded weight/BMI summaries. When measurements are absent, the illustration explicitly uses sample proportions and recorded metrics show missing values.

Height, weight and optional circumferences produce bounded regional changes. Head/face and hands remain stable; legs expand about their own axes. This is an approximate illustration, not a body scan, fat/muscle estimate, diagnosis, or prediction of goal appearance.

BMI guidance: https://www.cdc.gov/bmi/adult-calculator/bmi-categories.html (checked 2026-10-03). CDC adult categories apply at age 20+. Unknown age does not receive a category; because only birth year is stored, the youngest possible age in the year is used conservatively. Pregnancy/nursing and specialized clinical guidance keep the existing applicability guards. The 18.5–<25 interval is labeled “Standard range”; BMI never supplies an overall health verdict.

## Validation and screenshots

Baseline: 32 existing tests passed. Flutter 3.47.6 / Dart 3.13.5 required CardThemeData and DialogThemeData compatibility updates. Minimum supported Flutter is now 3.32; SDK-pinned dependencies were refreshed in the lock file.

Implemented checks: 40 tests cover existing nutrition/unit/date/profile/morph behavior, new model geometry, front/side/back/custom views, appearance save/reload/cancel isolation, goal isolation, Wellness navigation, 320px dark and 768px layouts, unchanged measurement saves, imperial conversion, and persisted meals/calories/weight/workouts/walking/water/sleep/journal records. Tests run against temporary storage, not user records.

`flutter analyze --no-pub --no-fatal-infos`: no errors or warnings; informational lint/deprecation notices remain. `flutter build web --no-pub --no-wasm-dry-run`: JavaScript web build passes; existing CupertinoIcons font warning remains. This is not a Wasm compatibility claim.

Screenshots in `docs/review`: before, after, front, side, back, customized. These are actual Flutter software-renderer test captures at a 390×844 logical mobile viewport, 2× pixel density. Baseline capture uses current-SDK theme compatibility and bundled-font hydration so geometry/layout can be compared. It is not a browser screenshot.

## Limits requiring device review

A live web-browser preview could not be inspected: local Chrome was denied its Unix socket by this environment, and the cloud browser rejected localhost (`ERR_BLOCKED_BY_CLIENT`). Web compilation and Flutter software rendering passed, but CanvasKit/browser behavior and browser persistence remain unverified. No running public preview is supplied.

Android SDK/emulator and Xcode/iOS simulator are unavailable. Native iOS/Android builds, touch performance, keyboard behavior on real devices, lifecycle transitions on devices, and the rest of every screen's end-to-end logging UI still need device review. The model has smooth geometry and detailed features, but is a procedural stylized human rather than an artist-rigged production character. Garments have no fabric simulation; shadows and lighting are analytic. Mobile performance is not benchmarked. Preserve the PR as a draft until browser/device review is complete; do not merge automatically.

Model provenance/license and regeneration: `assets/models/BLOOM_HUMAN_LICENSE.md`.
