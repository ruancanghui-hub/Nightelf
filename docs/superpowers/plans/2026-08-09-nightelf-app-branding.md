# Nightelf App Branding Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the approved Nightelf logo to the macOS app icon, a 900 ms cold-start splash screen, and the no-Vault welcome page.

**Architecture:** Keep UI branding in a focused `NightelfSplashScreen` widget and reuse the already bundled transparent `assets/nightelf-logo.png` for in-app surfaces. `AiWorkbenchApp` owns only the one-time splash visibility flag; the splash widget owns its fade animation plus an independent 900 ms completion timer so display duration starts at mount rather than the first vsync tick. A single generated 1024 px app-icon master supplies the existing macOS iconset filenames at every required resolution.

**Tech Stack:** Flutter 3.44.8, Dart widget tests, ImageGen built-in mode, macOS asset catalogs, PNG assets, macOS Debug build.

## Global Constraints

- The splash is shown on every cold app start for exactly `900 ms` and does not perform network, Vault, or persistence work.
- The splash logo renders at exactly `128 × 128` on `Color(0xFF030B09)` with a fade-in/hold/fade-out sequence.
- The no-Vault welcome logo renders at exactly `96 × 96`; existing copy, buttons, error presentation, and Vault behavior remain unchanged.
- The sidebar keeps using its existing `34 × 34` Nightelf logo.
- Replace all seven macOS icon PNG files while preserving `Contents.json` filenames and 1x/2x mappings.
- The App Icon uses a dark black-green rounded-square ground with the emerald five-leaf mark, no magenta, text, watermark, or extra symbol.

---

### Task 1: Add the timed Nightelf startup splash

**Files:**
- Create: `lib/app/nightelf_splash_screen.dart`
- Modify: `lib/app/ai_workbench_app.dart`
- Modify: `test/app/ai_workbench_app_test.dart`
- Modify: `test/app_smoke_test.dart`

**Interfaces:**
- Consumes: bundled Flutter asset `assets/nightelf-logo.png`.
- Produces: `NightelfSplashScreen({required VoidCallback onFinished})`, which invokes `onFinished` once after its 900 ms animation.
- Produces: `ValueKey('nightelf-splash-screen')` and `ValueKey('nightelf-splash-logo')` for behavioral tests.

- [x] **Step 1: Write the failing splash lifecycle test**

Add a widget test to `test/app/ai_workbench_app_test.dart`:

```dart
testWidgets('shows the Nightelf splash for 900 ms before the app home', (
  tester,
) async {
  await tester.pumpWidget(
    const ProviderScope(child: AiWorkbenchApp(skipRestore: true)),
  );

  expect(
    find.byKey(const ValueKey('nightelf-splash-screen')),
    findsOneWidget,
  );
  expect(find.text('创建 Vault'), findsNothing);

  await tester.pump(const Duration(milliseconds: 899));
  expect(
    find.byKey(const ValueKey('nightelf-splash-screen')),
    findsOneWidget,
  );

  await tester.pump(const Duration(milliseconds: 1));
  await tester.pump();
  expect(
    find.byKey(const ValueKey('nightelf-splash-screen')),
    findsNothing,
  );
  expect(find.text('创建 Vault'), findsOneWidget);
});
```

Update existing app and smoke tests to pump `900 ms` before asserting post-splash UI.

- [x] **Step 2: Run the focused tests to verify RED**

Run:

```bash
flutter test test/app/ai_workbench_app_test.dart test/app_smoke_test.dart
```

Expected: FAIL because `nightelf-splash-screen` does not exist and the welcome page is visible immediately.

- [x] **Step 3: Implement the splash widget**

Create `lib/app/nightelf_splash_screen.dart` with a stateful widget using an `AnimationController(duration: Duration(milliseconds: 900))` and this opacity sequence:

```dart
final Animation<double> opacity = TweenSequence<double>([
  TweenSequenceItem(tween: Tween<double>(begin: 0, end: 1), weight: 22),
  TweenSequenceItem(tween: ConstantTween(1), weight: 56),
  TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0), weight: 22),
]).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
```

Render:

```dart
ColoredBox(
  key: const ValueKey('nightelf-splash-screen'),
  color: const Color(0xFF030B09),
  child: Center(
    child: FadeTransition(
      opacity: opacity,
      child: Image.asset(
        'assets/nightelf-logo.png',
        key: const ValueKey('nightelf-splash-logo'),
        width: 128,
        height: 128,
        fit: BoxFit.contain,
        semanticLabel: 'Nightelf Logo',
      ),
    ),
  ),
)
```

Start the controller and an independent `Timer(const Duration(milliseconds: 900), ...)` in `initState`. The timer calls `widget.onFinished` only while mounted. Cancel the timer and dispose the controller in `dispose`.

- [x] **Step 4: Wire the splash into `AiWorkbenchApp`**

Add `_showSplash = true` to `_AiWorkbenchAppState`. In `MacosApp.home`, render `NightelfSplashScreen` while true; its callback executes:

```dart
if (mounted) {
  setState(() => _showSplash = false);
}
```

Afterward, preserve the current `widget.hasVault` and Vault controller state branches unchanged.

- [x] **Step 5: Run the focused tests to verify GREEN**

Run:

```bash
dart format lib/app/nightelf_splash_screen.dart lib/app/ai_workbench_app.dart test/app/ai_workbench_app_test.dart test/app_smoke_test.dart
flutter test test/app/ai_workbench_app_test.dart test/app_smoke_test.dart
```

Expected: all focused tests pass with no overflow or uncaught timer/animation errors.

---

### Task 2: Brand the no-Vault welcome page

**Files:**
- Modify: `lib/app/ai_workbench_app.dart`
- Modify: `test/app/ai_workbench_app_test.dart`

**Interfaces:**
- Consumes: `assets/nightelf-logo.png`.
- Produces: `ValueKey('nightelf-welcome-logo')` on a `96 × 96` `Image` widget.

- [x] **Step 1: Write the failing welcome-logo assertion**

Extend the existing welcome-screen widget test after pumping through the splash:

```dart
final logo = tester.widget<Image>(
  find.byKey(const ValueKey('nightelf-welcome-logo')),
);
expect((logo.image as AssetImage).assetName, 'assets/nightelf-logo.png');
expect(logo.width, 96);
expect(logo.height, 96);
expect(logo.fit, BoxFit.contain);
expect(find.text('创建 Vault'), findsOneWidget);
expect(find.text('打开 Vault'), findsOneWidget);
```

- [x] **Step 2: Run the focused test to verify RED**

Run:

```bash
flutter test test/app/ai_workbench_app_test.dart
```

Expected: FAIL because `nightelf-welcome-logo` is absent.

- [x] **Step 3: Replace only the generic welcome icon**

In `_WelcomeScaffold`, replace `Icon(LucideIcons.leafyGreen, ...)` with:

```dart
Image.asset(
  'assets/nightelf-logo.png',
  key: const ValueKey('nightelf-welcome-logo'),
  width: 96,
  height: 96,
  fit: BoxFit.contain,
  semanticLabel: 'Nightelf Logo',
),
```

Remove the `lucide_icons_flutter` import from this file only if no other symbols use it.

- [x] **Step 4: Run the focused tests to verify GREEN**

Run:

```bash
dart format lib/app/ai_workbench_app.dart test/app/ai_workbench_app_test.dart
flutter test test/app/ai_workbench_app_test.dart test/app_smoke_test.dart
```

Expected: all focused tests pass; the existing buttons and copy remain present.

---

### Task 3: Replace the complete macOS App Icon set

**Files:**
- Replace: `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png`
- Replace: `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png`
- Replace: `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png`
- Replace: `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png`
- Replace: `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png`
- Replace: `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png`
- Replace: `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png`
- Create: `test/app/nightelf_brand_assets_test.dart`

**Interfaces:**
- Consumes: ImageGen output for a square 1024 px Nightelf icon master.
- Produces: seven PNG files referenced by the unchanged `AppIcon.appiconset/Contents.json`.

- [x] **Step 1: Write the failing icon-asset test**

Create `test/app/nightelf_brand_assets_test.dart`. Load the seven files with `File`, decode each with `ui.instantiateImageCodec`, and assert the literal expected width/height map:

```dart
const expectedSizes = <String, int>{
  'app_icon_16.png': 16,
  'app_icon_32.png': 32,
  'app_icon_64.png': 64,
  'app_icon_128.png': 128,
  'app_icon_256.png': 256,
  'app_icon_512.png': 512,
  'app_icon_1024.png': 1024,
};
```

For the 1024 image, read the center RGBA pixel and assert `green > red` and `green > blue`, proving the default blue Flutter mark is no longer the icon's central palette. Parse `Contents.json` with `jsonDecode` and assert that the referenced filename set equals `expectedSizes.keys`.

- [x] **Step 2: Run the asset test to verify RED**

Run:

```bash
flutter test test/app/nightelf_brand_assets_test.dart
```

Expected: FAIL on the center-pixel emerald palette assertion against the current Flutter default icon.

- [x] **Step 3: Generate the 1024 px master with ImageGen**

Use the current Nightelf logo as the shape reference. Generate a macOS app icon with a dark `#030B09` rounded-square ground, centered emerald `#5DE7A7` five-leaf emblem, 18% optical safe margin, restrained inner green glow, and no magenta, text, watermark, extra symbol, or transparent hole inside the rounded square.

Copy the final ImageGen output into the project as `app_icon_1024.png`, inspect it visually, and verify it is 1024 × 1024.

- [x] **Step 4: Generate every mapped icon size from the master**

Use `sips` to resample the master into the existing literal filenames:

```bash
ICON_DIR=macos/Runner/Assets.xcassets/AppIcon.appiconset
for size in 16 32 64 128 256 512; do
  sips -z "$size" "$size" "$ICON_DIR/app_icon_1024.png" \
    --out "$ICON_DIR/app_icon_${size}.png"
done
```

Keep `Contents.json` unchanged.

- [x] **Step 5: Run focused tests, build, and launch**

Run:

```bash
flutter test test/app/nightelf_brand_assets_test.dart
flutter test test/app/ai_workbench_app_test.dart test/app_smoke_test.dart test/features/overview/presentation/emerald_overview_layout_test.dart
./script/build_and_run.sh --verify
```

Expected: all focused tests pass, the macOS Debug build succeeds, the process remains running, the splash appears first, the no-Vault page uses the 96 px logo, and the Dock shows the Nightelf icon instead of Flutter's default icon.

- [x] **Step 6: Commit the branding implementation**

```bash
git add lib/app/nightelf_splash_screen.dart lib/app/ai_workbench_app.dart \
  test/app/ai_workbench_app_test.dart test/app_smoke_test.dart \
  test/app/nightelf_brand_assets_test.dart \
  macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png \
  macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png \
  macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png \
  macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png \
  macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png \
  macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png \
  macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png \
  docs/superpowers/plans/2026-08-09-nightelf-app-branding.md
git commit -m "feat: brand Nightelf app launch experience"
```
