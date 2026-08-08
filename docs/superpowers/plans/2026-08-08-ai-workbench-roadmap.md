# AI Workbench Delivery Roadmap

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver the confirmed macOS Flutter AI Workbench as six independently testable phases that an agent can execute in order.

**Architecture:** A local-first Flutter macOS application treats ordinary Vault files as the source of truth, maintains only disposable local indexes, and exposes five resource-specific workspaces through one shared shell. Git synchronization, conflict review, WebView browsing, secret handling, and Workflow canvas behavior remain behind explicit interfaces so each phase can be tested without native side effects.

**Tech Stack:** Flutter 3.44.8, Dart 3.12.2, macOS 13+, Riverpod, macos_ui, re_editor, webview_flutter/WKWebView, sqlite3 FTS5, flutter_secure_storage, dart:io Process, flutter_test and integration_test.

## Global Constraints

- Target macOS only in the first release; set `MACOSX_DEPLOYMENT_TARGET` to `13.0`.
- Preserve ordinary files and folders as the only source of truth; databases and caches must be rebuildable.
- Never execute prompts, SKILL scripts, MCP servers, or Workflow actions.
- Never silently overwrite local, external, or remote conflicting edits.
- Never commit API keys, tokens, passwords, private keys, WebView cookies, search indexes, thumbnails, or temporary files.
- Keep Website WebViews isolated from Vault filesystem APIs and from the Workflow canvas bridge.
- Keep Workflow structure editing source-first; the canvas persists presentation layout only.
- Use Chinese-first UI copy and provide keyboard navigation, dark/light themes, reduced motion, reduced transparency, and high-contrast behavior.
- Follow TDD for domain, filesystem, Git, codec, parser, index, and controller behavior.
- End every task with its focused test command and a small commit containing only that task.

---

## Dependency Order

1. [Phase 1 — Foundation and Vault](2026-08-08-ai-workbench-01-foundation-vault.md)
2. [Phase 2 — Desktop Shell, Editor, Search, and Metadata](2026-08-08-ai-workbench-02-shell-editor-search.md)
3. [Phase 3 — Prompt, SKILL, and MCP Workspaces](2026-08-08-ai-workbench-03-prompt-skill-mcp.md)
4. [Phase 4 — Website and Workflow Workspaces](2026-08-08-ai-workbench-04-web-workflow.md)
5. [Phase 5 — Git Sync, Conflict Review, and Secret Safety](2026-08-08-ai-workbench-05-git-conflicts-security.md)
6. [Phase 6 — Integration, Performance, Accessibility, and Release](2026-08-08-ai-workbench-06-integration-release.md)

Each phase starts from the previous phase's green main branch. Do not run later phases in parallel because their public interfaces depend on earlier phases.

## Specification Coverage

| Confirmed specification area | Implementing phase/tasks |
|---|---|
| Apple-style macOS shell, tabs, keyboard, responsive themes | Phase 2 Tasks 1–3 and 6; Phase 6 Task 4 |
| Local Vault, schemas, stable IDs, atomic save, external watching | Phase 1 Tasks 2–6; Phase 5 Task 6 |
| Search, favorites, collections, recent items, associations | Phase 1 Task 5; Phase 2 Tasks 3 and 5 |
| Prompt editor and copying | Phase 3 Task 2 |
| SKILL import, tree, editing, Finder and Terminal | Phase 3 Tasks 1 and 3 |
| MCP JSON editing, safe/full copy, Keychain | Phase 3 Task 4; Phase 5 Tasks 2–3 |
| Saved links and isolated in-app WKWebView | Phase 4 Tasks 1–2 |
| Mermaid source, last-valid graph, infinite canvas, layout sidecar | Phase 4 Tasks 3–5 |
| One-click Git sync and history | Phase 5 Tasks 1 and 4 |
| Text/binary/Workflow/external conflict author review | Phase 5 Tasks 5–6 |
| Secret scan and ignore fingerprints | Phase 5 Task 2 |
| Error recovery, performance, accessibility, E2E, docs, release | Phase 6 Tasks 1–6 |
| No resource execution, no cloud account, macOS-only scope | Every phase Global Constraints and Phase 6 verification |

## Implementation References

- Flutter macOS desktop: <https://docs.flutter.dev/platform-integration/desktop>
- macos_ui widgets and modern window setup: <https://pub.dev/packages/macos_ui>
- Riverpod state management: <https://pub.dev/packages/flutter_riverpod>
- re_editor desktop text editor: <https://pub.dev/packages/re_editor>
- Official Flutter WebView and WKWebView implementation: <https://pub.dev/packages/webview_flutter>
- SQLite Dart bindings: <https://pub.dev/packages/sqlite3>
- macOS Keychain-backed secure storage: <https://pub.dev/packages/flutter_secure_storage>
- Flutter InteractiveViewer API: <https://api.flutter.dev/flutter/widgets/InteractiveViewer-class.html>

## Phase Acceptance Gates

### Phase 1 gate

- A macOS app launches, creates or opens a Vault, restores the last Vault, scans resource files, and rebuilds its local search index.
- Unit tests prove atomic writes, marker validation, stable IDs, scanner behavior, and settings persistence.

### Phase 2 gate

- The confirmed Apple-style shell, resource sidebar, tabs, command palette, resource list, shared editor, metadata inspector, favorites, associations, and keyboard shortcuts work with fake repositories.
- Widget tests cover dark/light layout, tab state, save state, search, and keyboard activation.

### Phase 3 gate

- Prompt CRUD, SKILL import/tree editing, MCP JSON validation/format/copy, and Finder/terminal actions operate on real temporary Vaults.
- No resource is executed and no secret is written by the safe-copy path.

### Phase 4 gate

- Saved links open in an isolated WKWebView workspace with basic navigation.
- Common Mermaid `flowchart` source parses into a pannable, zoomable, draggable Flutter canvas; invalid source retains the last valid graph and source text.

### Phase 5 gate

- One-click sync works against temporary local remotes.
- Divergent text and binary changes stop in an author-controlled conflict review; push resumes only after every conflict is confirmed.
- Secret scanning blocks commits and Keychain-backed values never enter the Vault.

### Phase 6 gate

- The end-to-end two-clone conflict journey passes.
- Search and large Workflow budgets pass on generated fixtures.
- Accessibility/theme tests pass, `flutter analyze` is clean, all tests pass, and `flutter build macos --release` succeeds.

## Review Boundaries

- Review and merge one task at a time.
- Reject a task if its public interface differs from the `Interfaces` block without updating every downstream plan reference first.
- Reject a task that adds network access, execution behavior, cloud accounts, collaboration, or unrequested cross-platform code.
- Reject a task that updates snapshots or goldens without inspecting the rendered difference.
- Keep untracked `.cursor/`, `openspec/`, and local reference images outside implementation commits unless the user explicitly moves them into scope.
