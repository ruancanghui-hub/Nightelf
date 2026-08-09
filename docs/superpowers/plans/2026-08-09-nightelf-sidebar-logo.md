# Nightelf Sidebar Logo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the generic Lucide leaf in the expanded sidebar brand row with the approved transparent Nightelf three-leaf logo while preserving the current 34 × 34 layout.

**Architecture:** Generate one local PNG asset from the approved screenshot reference, remove its chroma-key background to produce clean transparency, then register and render that asset through Flutter's existing asset pipeline. A focused widget assertion locks the asset name and display dimensions so later visual refactors cannot silently restore the generic icon.

**Tech Stack:** Flutter 3.44.8, Dart widget tests, PNG asset pipeline, ImageGen chroma-key cleanup script, macOS Debug build.

## Global Constraints

- Only replace the logo to the left of `Nightelf · AI 工作台` in the expanded sidebar.
- Render the logo at exactly `34 × 34` with `BoxFit.contain`.
- Preserve sidebar width, spacing, text, navigation layout, interactions, macOS app icon, and Dock icon.
- Store the transparent asset at `assets/nightelf-logo.png` with no text, shadow, watermark, screenshot background, dark rectangle, or visible color fringe.

---

### Task 1: Generate and integrate the Nightelf sidebar logo

**Files:**
- Create: `assets/nightelf-logo.png`
- Modify: `pubspec.yaml`
- Modify: `lib/features/shell/presentation/workbench_sidebar.dart:141-160`
- Modify: `test/features/overview/presentation/emerald_overview_layout_test.dart`

**Interfaces:**
- Consumes: Flutter asset loading through `Image.asset(String, width:, height:, fit:, semanticLabel:)`.
- Produces: bundled asset key `assets/nightelf-logo.png` and a 34 × 34 `Image` widget in the expanded `WorkbenchSidebar` brand row.

- [x] **Step 1: Write the failing widget assertion**

Add this assertion after the existing `Nightelf · AI 工作台` expectation in `emerald_overview_layout_test.dart`:

```dart
final logo = tester.widget<Image>(
  find.byKey(const ValueKey('nightelf-sidebar-logo')),
);
expect((logo.image as AssetImage).assetName, 'assets/nightelf-logo.png');
expect(logo.width, 34);
expect(logo.height, 34);
expect(logo.fit, BoxFit.contain);
```

- [x] **Step 2: Run the focused test to verify RED**

Run:

```bash
flutter test test/features/overview/presentation/emerald_overview_layout_test.dart
```

Expected: FAIL because no widget has the key `nightelf-sidebar-logo`.

- [x] **Step 3: Generate and validate the transparent logo asset**

Use the approved screenshot as the ImageGen reference. Generate a crisp, centered, symmetrical three-leaf Nightelf mark in emerald line art on a flat `#FF00FF` chroma-key background, with no text, shadow, watermark, glow outside the leaf silhouette, or surrounding UI. Save the generated source inside the project, then run:

```bash
python /Users/oricof4/.codex/skills/.system/imagegen/scripts/remove_chroma_key.py \
  <generated-source.png> assets/nightelf-logo.png \
  --auto-key border \
  --soft-matte \
  --transparent-threshold 12 \
  --opaque-threshold 220 \
  --despill
```

Verify with an image inspector that `assets/nightelf-logo.png` has an alpha channel, transparent corners, a centered three-leaf silhouette, and no dark rectangular background.

- [x] **Step 4: Register and render the asset**

Add the asset below the existing forest asset in `pubspec.yaml`:

```yaml
  assets:
    - assets/vault-status-forest.png
    - assets/nightelf-logo.png
```

Replace only the generic leaf icon in `WorkbenchSidebar`:

```dart
Image.asset(
  'assets/nightelf-logo.png',
  key: const ValueKey('nightelf-sidebar-logo'),
  width: 34,
  height: 34,
  fit: BoxFit.contain,
  semanticLabel: 'Nightelf Logo',
),
```

- [x] **Step 5: Format and run focused/build verification**

Run:

```bash
dart format lib/features/shell/presentation/workbench_sidebar.dart test/features/overview/presentation/emerald_overview_layout_test.dart
flutter test test/features/overview/presentation/emerald_overview_layout_test.dart
./script/build_and_run.sh --verify
```

Expected: formatting unchanged or successful, the focused test passes, the macOS Debug build succeeds, and the app launches with the new logo at the unchanged sidebar position. The pre-existing unrelated full-suite failures remain outside this visual-only change.

- [x] **Step 6: Commit the implementation**

```bash
git add assets/nightelf-logo.png pubspec.yaml \
  lib/features/shell/presentation/workbench_sidebar.dart \
  test/features/overview/presentation/emerald_overview_layout_test.dart \
  docs/superpowers/plans/2026-08-09-nightelf-sidebar-logo.md
git commit -m "feat: add Nightelf sidebar logo"
```
