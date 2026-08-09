# Website Link Workspace Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the live website-link detail workspace to match the approved Nightelf mockup while preserving the existing Vault, clipboard, metadata, external-open, and embedded WebView behavior.

**Architecture:** Keep `LinkController` and the existing repositories as the source of truth. Split the UI into a testable browser frame, a responsive link workspace, and a link-specific inspector; `WorkspaceContent` routes live website links directly to this composed workspace so the generic header and inspector are not duplicated.

**Tech Stack:** Flutter 3.44, Dart 3.12, `macos_ui`, `lucide_icons_flutter`, `webview_flutter`, `webview_flutter_wkwebview`, Flutter widget tests.

## Global Constraints

- The selected visual target is `/Users/oricof4/.codex/generated_images/019fe106-c5c0-7fe2-8558-de8127e899e2/exec-bce54acd-1b6c-4489-9003-10637f96186e.png`.
- Only the website-link detail workspace changes; the primary sidebar, resource-list behavior, Vault format, repositories, and non-link editors remain unchanged.
- Existing actions remain real: rename, save notes, copy link, open externally, browse internally, edit metadata tags, and toggle favorite.
- The embedded browser continues to allow only `http` and `https`; existing external-scheme isolation remains intact.
- Wide layout uses preview plus inspector; narrow layout stacks the inspector below a bounded preview without overflow.
- Use the existing Lucide package because it matches the approved mockup's line-icon language; add no raster assets or dependencies.

---

### Task 1: Browser Frame Presentation

**Files:**
- Modify: `lib/features/links/presentation/link_in_app_browser.dart`
- Create: `test/features/links/presentation/link_browser_frame_test.dart`

**Interfaces:**
- Consumes: the existing WebView controller state (`url`, history availability, loading, error).
- Produces: `LinkBrowserFrame`, a presentational widget that accepts callbacks and a child content widget while `LinkInAppBrowser` retains WebView ownership.

- [ ] **Step 1: Write the failing browser-frame widget tests**

  Add tests that pump `LinkBrowserFrame` with a fake content child and assert the address, semantic actions `后退`, `前进`, `刷新页面`, and `在外部浏览器打开`, disabled history states, loading/error visibility, rounded preview clipping, and no overflow at 560 px width.

- [ ] **Step 2: Run the focused test and verify RED**

  Run: `flutter test test/features/links/presentation/link_browser_frame_test.dart`

  Expected: compilation fails because `LinkBrowserFrame` does not exist.

- [ ] **Step 3: Implement the minimal browser frame**

  Extract the browser chrome from `_LinkInAppBrowserState.build` into `LinkBrowserFrame`. Use a 52 px dark toolbar, Lucide arrow/refresh/external-link icons, a flexible read-only address surface, a loading indicator, an inline error status, and the existing clipped WebView as `child`.

- [ ] **Step 4: Run the focused test and verify GREEN**

  Run: `flutter test test/features/links/presentation/link_browser_frame_test.dart`

  Expected: all tests pass without overflow exceptions.

---

### Task 2: Responsive Link Workspace and Inspector

**Files:**
- Modify: `lib/features/links/presentation/link_workspace.dart`
- Modify: `lib/features/workspaces/presentation/workspace_content.dart`
- Create: `test/features/links/presentation/link_workspace_test.dart`

**Interfaces:**
- Consumes: `LinkController`, `WorkbenchResource`, optional `MetadataController`, `onToggleFavorite`, and `onRenamed`.
- Produces: a responsive `LinkWorkspace` with keys `link-workspace-header`, `link-browser-pane`, and `link-details-inspector`, plus an injectable `browserBuilder` for deterministic widget tests.

- [ ] **Step 1: Write the failing wide and compact workspace tests**

  Create a real temporary-file `LinkController`, create a link with title, URL, tags, and notes, then pump `LinkWorkspace` with a fake browser builder. Assert the approved header, address, saved status, title field, tag chips, notes field, favorite state, last-visited row, copy action, external-open action, and the two-column wide layout. Pump again at compact width and assert no exception while preview and inspector remain visible.

- [ ] **Step 2: Run the focused test and verify RED**

  Run: `flutter test test/features/links/presentation/link_workspace_test.dart`

  Expected: failures for missing constructor arguments, keys, and redesigned controls.

- [ ] **Step 3: Implement the selected visual structure**

  Replace the dense title/action/url form with: (1) a 70 px identity header, (2) a large browser pane, and (3) a 286 px `链接信息` inspector. Bind title submission to `rename`, notes completion to `updateDraftNotes` plus `save`, metadata tags to `MetadataController.updateTags`, favorite to metadata or the supplied fallback callback, copy to `copyUrl`, and external-open to `openExternally`.

- [ ] **Step 4: Route live website links without duplicate generic chrome**

  In `WorkspaceContent`, detect a live website-link resource and return the composed `LinkWorkspace` directly inside the existing focus/border shell. Pass the selected resource, metadata controller, favorite callback, and rename callback. Leave every other resource type on the existing generic path.

- [ ] **Step 5: Run focused tests and verify GREEN**

  Run: `flutter test test/features/links/presentation/link_browser_frame_test.dart test/features/links/presentation/link_workspace_test.dart test/features/workspaces/presentation/workspace_content_test.dart`

  Expected: new link tests pass and existing workspace tests retain their previous expectations.

---

### Task 3: Verification and Visual QA

**Files:**
- Create: `design-qa.md`
- Modify only if needed after evidence: the Task 1/2 production and test files.

**Interfaces:**
- Consumes: approved source mockup and a macOS application screenshot at the same link-selected state.
- Produces: a passing `design-qa.md` with source path, implementation screenshot path, viewport, focused comparisons, findings, fixes, and `final result: passed`.

- [ ] **Step 1: Format and analyze**

  Run: `dart format lib test`

  Run: `dart analyze lib test`

  Expected: formatting is stable and analysis reports no issues.

- [ ] **Step 2: Run the focused suite and macOS build**

  Run: `flutter test test/features/links test/features/workspaces/presentation/workspace_content_test.dart`

  Run: `flutter build macos --debug`

  Expected: tests and build exit 0.

- [ ] **Step 3: Launch and capture the website-link state**

  Run the debug app, open a Vault website link, size the window to match the design's landscape state, and capture the rendered implementation.

- [ ] **Step 4: Compare the source and implementation**

  Put the approved source and implementation screenshot into the same comparison input. Record typography, spacing, colors, icon fidelity, WebView framing, copy, and responsive layout in `design-qa.md`. Fix every P0/P1/P2 issue and recapture until the report ends with `final result: passed`.

- [ ] **Step 5: Commit the verified implementation**

  Stage only the plan, link-workspace source/tests, and QA evidence, then commit with `feat: redesign website link workspace`.
