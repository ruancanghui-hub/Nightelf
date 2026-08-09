# AI Workbench UI Foundation: Visual Shell First

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver a runnable macOS visual prototype of the confirmed Apple-style AI Workbench before wiring any real resource management task.

**Architecture:** Flutter presentation is backed exclusively by deterministic in-memory mock records. UI state is local and immutable where practical. A narrow `WorkbenchResource` presentation model allows later Vault-backed controllers to replace mock data without moving widgets or changing navigation semantics.

**Tech Stack:** Flutter 3.44.8, Dart 3.12.2, macos_ui, flutter_riverpod, flutter_test.

## Global Constraints

- Target macOS only; set `MACOSX_DEPLOYMENT_TARGET` to `13.0`.
- Implement the dark Apple-inspired visual direction approved by the user, plus an equivalent light theme.
- Use the exact Chinese-first labels: `AI 提示词`, `SKILL 文件夹`, `MCP 配置`, `网站链接`, `Workflow 文件`, `收藏`, and `最近使用`.
- This phase is visual only: no Vault scan, filesystem read/write, Git command, network request, WebView navigation, resource execution, secret persistence, or actual terminal launch.
- Clearly render unavailable future actions as disabled with concise explanatory tooltips; do not make a control appear to work when it does not.
- Keep every interactive control keyboard reachable and expose a semantic label.
- Follow TDD: each behavior starts with a focused failing Flutter test, then minimal implementation.
- End every task with its focused test command and a small commit containing only that task.

### Task 1: Scaffold the Flutter macOS app and establish visual tokens

**Files:**
- Create Flutter project files under `lib/`, `test/`, `macos/`, and root Flutter configuration.
- Create `lib/app/ai_workbench_app.dart`, `lib/app/theme/workbench_theme.dart`, and `test/app/ai_workbench_app_test.dart`.

**Interfaces:**
- Produces `AiWorkbenchApp` as the application root.
- Produces `WorkbenchTheme.dark()` and `WorkbenchTheme.light()`.

- [ ] **Step 1: Write failing root-widget tests** for the application title and both themes.
- [ ] **Step 2: Run** `flutter test test/app/ai_workbench_app_test.dart` **and verify the failure is due to the missing app root.**
- [ ] **Step 3: Create the macOS Flutter project and implement the smallest app root/theme surface that passes the tests.** Set macOS deployment target to 13.0 and add only `macos_ui` and `flutter_riverpod` dependencies needed by this phase.
- [ ] **Step 4: Run** `dart format lib test && flutter analyze && flutter test test/app/ai_workbench_app_test.dart`.
- [ ] **Step 5: Commit:** `feat: scaffold macOS workbench app`.

### Task 2: Build the shared workbench shell with mock navigation

**Files:**
- Create `lib/features/shell/domain/workbench_resource.dart`.
- Create `lib/features/shell/application/workbench_controller.dart`.
- Create `lib/features/shell/presentation/workbench_shell.dart`, `workbench_sidebar.dart`, and `workbench_toolbar.dart`.
- Create `test/features/shell/application/workbench_controller_test.dart` and `test/features/shell/presentation/workbench_shell_test.dart`.

**Interfaces:**
- Produces `WorkbenchResource(id, type, title, subtitle, isFavorite)` and `ResourceType` with exactly five types.
- Produces `WorkbenchController` that selects a destination and mock resource deterministically.
- Produces `WorkbenchShell` with a sidebar, toolbar, list pane, and inspector/content region.

- [ ] **Step 1: Write failing controller and widget tests** proving the five destination labels, 收藏/最近使用 sections, and deterministic selection after changing a destination.
- [ ] **Step 2: Run** `flutter test test/features/shell/application/workbench_controller_test.dart test/features/shell/presentation/workbench_shell_test.dart` **and verify expected missing-type/widget failures.**
- [ ] **Step 3: Implement a three-region Apple-style shell using only deterministic mock records.** Toolbar shows Vault name `我的 AI 工作台`, global search with `⌘K`, disabled `未配置同步`, history, and view actions. Use semantic labels for interactive controls.
- [ ] **Step 4: Add a dark and light 1440x1024 layout test with no overflow or FlutterError. Run** `dart format lib test && flutter analyze && flutter test test/features/shell`.
- [ ] **Step 5: Commit:** `feat: add workbench navigation shell`.

### Task 3: Add tabs, search/palette, resource list, and inspector frame

**Files:**
- Create `lib/features/shell/domain/workspace_tab.dart`, `lib/features/shell/application/workspace_tabs_controller.dart`, and `lib/features/shell/presentation/workspace_tab_strip.dart`.
- Create `lib/features/library/presentation/resource_list_pane.dart`.
- Create `lib/features/command_palette/presentation/command_palette.dart`.
- Create corresponding tests under `test/features/shell/`, `test/features/library/`, and `test/features/command_palette/`.

**Interfaces:**
- Produces `WorkspaceTab(resourceId, title, type)` and tab open/activate/close behavior keyed by id.
- Produces global search results against mock records and a `⌘K` command palette entry point.

- [ ] **Step 1: Write failing tests** for deduplicated tab opening, closing an active tab to its left neighbor, mock resource filtering by query, and opening the palette with `⌘K`.
- [ ] **Step 2: Run the focused tests and verify failure before adding production code.**
- [ ] **Step 3: Implement the tab strip, resource rows, search state, command palette overlay, and fixed inspector metadata card.** Do not introduce persistence or a real search index.
- [ ] **Step 4: Run** `dart format lib test && flutter analyze && flutter test test/features/shell test/features/library test/features/command_palette`.
- [ ] **Step 5: Commit:** `feat: add mock workspace navigation`.

### Task 4: Render the five workspace visual shells and complete UI polish

**Files:**
- Create `lib/features/workspaces/presentation/prompt_workspace.dart`, `skill_workspace.dart`, `mcp_workspace.dart`, `website_workspace.dart`, `workflow_workspace.dart`, and `workspace_content.dart`.
- Create `test/features/workspaces/presentation/workspace_content_test.dart`.
- Modify shell/presentation files only as needed to insert the selected workspace.

**Interfaces:**
- Prompt and SKILL render editable-looking source surfaces with an explicitly mocked save state.
- MCP renders a read-only JSON-style preview with disabled `复制配置` and `在终端打开` controls and explanatory tooltips.
- Website renders a clearly non-navigating internal-browser visual frame.
- Workflow renders a Mermaid/source-and-canvas visual frame with static nodes and explicit mock status.

- [ ] **Step 1: Write failing widget tests** that select each mock type and assert its defining workspace elements and disabled future controls.
- [ ] **Step 2: Run** `flutter test test/features/workspaces/presentation/workspace_content_test.dart` **and verify the expected failure.**
- [ ] **Step 3: Implement the five visual workspace shells, preserving one shared hierarchy and an Apple-style dark material treatment.** Use static mock content only; do not add editors, WebView, canvas interaction, clipboard, Process, or filesystem APIs.
- [ ] **Step 4: Add a compact-width layout test and keyboard-focus checks for the sidebar, search, tabs, and inspector actions. Run** `dart format lib test && flutter analyze && flutter test`.
- [ ] **Step 5: Build and inspect the macOS app:** `flutter build macos --debug`; then commit `feat: complete visual workspace framework`.

## UI Foundation Acceptance Gate

- `flutter test`, `flutter analyze`, and `flutter build macos --debug` pass.
- The app launches into the dark Apple-style shell and can navigate all five visual mock workspaces.
- No UI action reads/writes a Vault, launches a terminal, opens a WebView, runs a resource, invokes Git, or accesses a network.
- Later phases can replace the mock controller and workspace adapters without changing the shell’s primary layout.
