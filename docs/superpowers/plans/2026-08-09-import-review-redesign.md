# Import Review Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Recreate the selected Nightelf import-review mockup as a responsive Flutter macOS review sheet while preserving the existing import workflow and data behavior.

**Architecture:** Keep `ImportController` as the single source of truth. Refactor the presentation into a stateful review shell with focused private widgets for the header, source preview, configuration form, type selector, and footer. Read preview metadata asynchronously from the selected source without changing import domain or repository APIs.

**Tech Stack:** Flutter 3.44.8, Dart 3.12.2, macos_ui, shadcn_ui wrappers, lucide_icons_flutter, flutter_test.

## Global Constraints

- Develop directly on `main` as requested.
- Preserve all existing import actions: type selection, target rename, removal, cancel, confirm, status, and failure display.
- Preserve the exact safety promise: source files are never modified.
- Use Nightelf tokens: canvas `#030B09`, panel `#0A1916`, border `#1B4D40`, emerald `#5DE7A7`.
- Use the existing Lucide icon dependency for every standard UI icon; do not generate raster replacements when an equivalent library icon exists.
- Do not modify unrelated user changes.

---

### Task 1: Lock the visual and interaction contract

**Files:**
- Modify: `test/features/import/presentation/import_review_sheet_test.dart`
- Modify: `lib/features/import/presentation/import_review_sheet.dart`

**Interfaces:**
- Consumes: `ImportController.plan`, `ImportController.setType`, `ImportController.rename`, `ImportController.remove`, `ImportController.cancel`, `ImportController.confirm`.
- Produces: keyed review regions `import-review-dialog`, `import-source-pane`, `import-config-pane`, `import-target-name`, and `import-copy-button`.

- [ ] **Step 1: Write failing widget tests**

Add tests that assert the selected mockup hierarchy, editable target name behavior, selected MCP type, source-safety copy, action semantics, and compact-width stacking.

- [ ] **Step 2: Run the focused test and verify RED**

Run: `flutter test test/features/import/presentation/import_review_sheet_test.dart`

Expected: FAIL because the new keyed regions and editable target field do not exist.

- [ ] **Step 3: Implement the responsive review shell**

Refactor `ImportReviewSheet` into a stateful presentation that renders:

- a dimmed full-screen overlay;
- an emerald shield header and icon-only close action;
- a wide two-column body above 820 logical pixels and a scrollable stacked body below it;
- source identity, file size, first 20 lines, and immutable-source path;
- classification confidence, segmented resource type selector, editable target name, and Vault destination;
- an in-dialog footer with cancel and primary copy action.

- [ ] **Step 4: Run the focused test and verify GREEN**

Run: `flutter test test/features/import/presentation/import_review_sheet_test.dart`

Expected: all import review tests pass.

- [ ] **Step 5: Refactor without changing behavior**

Extract private widgets and color/style constants inside the presentation file, dispose owned text controllers, and keep asynchronous file reads isolated in a `FutureBuilder`.

### Task 2: Verify integration and visual fidelity

**Files:**
- Modify: `design-qa.md`
- Create: `docs/design-qa/import-review-implementation.png`
- Create: `docs/design-qa/import-review-comparison.png`

**Interfaces:**
- Consumes: the selected ImageGen reference `exec-b5c6f552-b4b1-49a1-ac81-f0a34cffce21.png`.
- Produces: a reproducible design comparison and QA result.

- [ ] **Step 1: Run focused static analysis and import tests**

Run: `dart analyze lib/features/import/presentation/import_review_sheet.dart test/features/import/presentation/import_review_sheet_test.dart`

Run: `flutter test test/features/import`

- [ ] **Step 2: Build and launch the macOS application**

Run: `flutter build macos --debug`

Launch the exact Debug `.app`, open the import-review state, and exercise type selection, rename, close, and copy enablement.

- [ ] **Step 3: Capture and compare**

Capture the implementation at the reference state, combine it with the selected design in one image, and fix all P0/P1/P2 mismatches.

- [ ] **Step 4: Record QA and final verification**

Append the import-review evidence to `design-qa.md` with `final result: passed`, run `git diff --check`, and confirm the working tree contains only the intended files.

- [ ] **Step 5: Commit**

```bash
git add lib/features/import/presentation/import_review_sheet.dart \
  test/features/import/presentation/import_review_sheet_test.dart \
  docs/superpowers/plans/2026-08-09-import-review-redesign.md \
  docs/design-qa/import-review-implementation.png \
  docs/design-qa/import-review-comparison.png \
  design-qa.md
git commit -m "feat: redesign import review workspace"
```
