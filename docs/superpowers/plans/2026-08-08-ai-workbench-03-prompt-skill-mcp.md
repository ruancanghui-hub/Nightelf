# AI Workbench Phase 3: Prompt, SKILL, and MCP Workspaces Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver production-shaped resource workflows for AI prompts, SKILL folders, and MCP JSON configurations using the shared shell and editor.

**Architecture:** Each resource type owns a codec/repository and a thin workspace adapter. Shared system actions and clipboard behavior are abstracted for tests. Files remain externally editable, and imported SKILL trees retain their original structure.

**Tech Stack:** Phase 1–2 stack plus dart:convert, file_picker directory selection, macOS `/usr/bin/open`, re_editor syntax modes, flutter_test and mocktail.

## Global Constraints

- Begin only after all Phase 2 verification commands pass.
- Do not execute prompts, scripts, MCP commands, or server processes.
- Use `Process.run(executable, argumentList)` and never build shell command strings.
- Preserve third-party SKILL contents unless the author edits a file explicitly.
- Keep destructive actions behind confirmation and move to system Trash only if a tested Trash adapter is available; otherwise create a recoverable Vault-local trash entry.
- MCP full-secret copying remains disabled until Phase 5 provides `SecretStore` and author confirmation.

---

### Task 1: Add safe macOS system actions and clipboard contracts

**Files:**
- Create: `lib/shared/platform/process_runner.dart`
- Create: `lib/shared/platform/system_open_service.dart`
- Create: `lib/shared/platform/macos_system_open_service.dart`
- Create: `lib/shared/platform/clipboard_service.dart`
- Create: `lib/shared/platform/flutter_clipboard_service.dart`
- Test: `test/shared/platform/macos_system_open_service_test.dart`
- Create: `test/shared/platform/recording_platform_adapters.dart`

**Interfaces:**
- Produces: `ProcessRunner.run(String executable, List<String> arguments)`.
- Produces: `SystemOpenService.revealInFinder(String path)`, `openTerminalAt(String directoryPath)`, and `openExternalUrl(Uri uri)`.
- Produces: `ClipboardService.writeText(String text)`.

- [ ] **Step 1: Write failing argument-safety tests**

```dart
test('Finder reveal passes the path as one argument', () async {
  final runner = RecordingProcessRunner();
  final service = MacosSystemOpenService(runner);
  await service.revealInFinder('/tmp/a folder/$(unsafe)');
  expect(runner.calls.single.executable, '/usr/bin/open');
  expect(runner.calls.single.arguments, ['-R', '/tmp/a folder/\$(unsafe)']);
});

test('terminal opens the containing directory', () async {
  final runner = RecordingProcessRunner();
  await MacosSystemOpenService(runner).openTerminalAt('/tmp/vault/skills/apple-design');
  expect(runner.calls.single.arguments, ['-a', 'Terminal', '/tmp/vault/skills/apple-design']);
});
```

- [ ] **Step 2: Run tests and verify missing adapters fail**

Run: `flutter test test/shared/platform/macos_system_open_service_test.dart`

Expected: FAIL with undefined services.

- [ ] **Step 3: Implement adapters without shell interpolation**

`MacosSystemOpenService` must validate that file paths are absolute, use `/usr/bin/open`, and throw `SystemOpenException(operation, stderr)` on non-zero exit. `openExternalUrl` accepts only `http` and `https`. `FlutterClipboardService` wraps `Clipboard.setData`.

Define `RecordingProcessRunner`, `RecordingSystemOpenService`, and `RecordingClipboardService` in `recording_platform_adapters.dart`, including typed call records with `executable`, `arguments`, and copied text.

- [ ] **Step 4: Test invalid paths, URL schemes, and failures**

Add tests rejecting relative paths and `javascript:`/`file:` URLs, and surfacing a non-zero process result without retry.

Run: `dart format lib test && flutter analyze && flutter test test/shared/platform`

Expected: all shared platform tests PASS.

- [ ] **Step 5: Commit platform actions**

```bash
git add lib/shared/platform test/shared/platform
git commit -m "feat: add safe macOS system actions"
```

### Task 2: Implement Prompt Markdown CRUD and workspace behavior

**Files:**
- Create: `lib/features/prompts/domain/prompt_document.dart`
- Create: `lib/features/prompts/data/prompt_markdown_codec.dart`
- Create: `lib/features/prompts/data/prompt_repository.dart`
- Create: `lib/features/prompts/data/file_prompt_repository.dart`
- Create: `lib/features/prompts/application/prompt_controller.dart`
- Create: `lib/features/prompts/presentation/prompt_workspace.dart`
- Test: `test/features/prompts/data/prompt_markdown_codec_test.dart`
- Test: `test/features/prompts/data/file_prompt_repository_test.dart`
- Test: `test/features/prompts/application/prompt_controller_test.dart`

**Interfaces:**
- Produces: `PromptDocument(id, title, description, tags, body, relativePath)`.
- Produces: codec `decode(String, relativePath)` and `encode(PromptDocument)`.
- Produces: repository `create`, `read`, `save`, `duplicate`, and `moveToTrash`.
- Produces: controller `copyPlainText`, `copyMarkdown`, `duplicate`, and editor session creation.

- [ ] **Step 1: Write failing codec tests with exact output**

```dart
test('prompt codec emits deterministic front matter', () {
  const document = PromptDocument(
    id: 'p1',
    title: '代码审查助手',
    description: '检查安全与性能',
    tags: ['代码', '审查'],
    body: '# 角色\n你是审查员。\n',
    relativePath: 'prompts/code-review.md',
  );
  expect(const PromptMarkdownCodec().encode(document), '''---
id: "p1"
title: "代码审查助手"
description: "检查安全与性能"
tags: ["代码", "审查"]
---
# 角色
你是审查员。
''');
});
```

- [ ] **Step 2: Run prompt tests and verify failure**

Run: `flutter test test/features/prompts/data/prompt_markdown_codec_test.dart`

Expected: FAIL with missing Prompt types.

- [ ] **Step 3: Implement codec and repository**

Encode strings using `jsonEncode`, which is valid YAML scalar syntax and produces deterministic escaping. Slug new filenames by lowercasing ASCII, replacing non-letter/number runs with `-`, preserving Chinese characters, and resolving collisions as `name-2.md`, `name-3.md`. Use `AtomicFileWriter` for save.

`moveToTrash` moves the exact prompt to `.ai-workbench/local/trash/<UTC timestamp>/prompts/...` and returns the destination path for Undo. It must not delete permanently.

- [ ] **Step 4: Implement workspace actions and tests**

`PromptWorkspace` uses `TextEditorWorkspace` with Markdown wrapping and preview. `copyPlainText` copies body only; `copyMarkdown` copies body with headings unchanged. Tests cover create, reopen, duplicate ID regeneration, collision naming, copy output, trash and Undo.

Run: `dart format lib test && flutter analyze && flutter test test/features/prompts`

Expected: all Prompt tests PASS.

- [ ] **Step 5: Commit Prompt support**

```bash
git add lib/features/prompts test/features/prompts
git commit -m "feat: add prompt workspace"
```

### Task 3: Import and browse SKILL folders

**Files:**
- Create: `lib/features/skills/domain/skill_resource.dart`
- Create: `lib/features/skills/domain/skill_tree_node.dart`
- Create: `lib/features/skills/data/skill_repository.dart`
- Create: `lib/features/skills/data/file_skill_repository.dart`
- Create: `lib/features/skills/application/skill_controller.dart`
- Create: `lib/features/skills/presentation/skill_workspace.dart`
- Create: `lib/features/skills/presentation/skill_file_tree.dart`
- Test: `test/features/skills/data/file_skill_repository_test.dart`
- Test: `test/features/skills/application/skill_controller_test.dart`
- Create: `test/support/skill_fixture.dart`

**Interfaces:**
- Produces: `SkillResource(id, title, relativeDirectory, entryRelativePath)`.
- Produces: `SkillTreeNode(name, relativePath, isDirectory, childrenLoaded)`.
- Produces: repository `importDirectory`, `listChildren`, `readTextFile`, `writeTextFile`, `duplicate`, and `moveToTrash`.
- Produces: `ImportProgress(copiedFiles, copiedBytes, currentRelativePath)` stream.

- [ ] **Step 1: Write failing import tests**

```dart
test('imports a valid SKILL directory without flattening it', () async {
  final source = await skillFixture({
    'SKILL.md': '# Apple Design',
    'references/motion.md': '# Motion',
    'assets/icon.png': [0, 1, 2, 3],
  });
  addTearDown(source.dispose);
  final imported = await repository.importDirectory(source.directory).last;
  expect(imported.skill.entryRelativePath, 'skills/apple-design/SKILL.md');
  expect(File('${vault.path}/skills/apple-design/references/motion.md').existsSync(), isTrue);
  expect(File('${vault.path}/skills/apple-design/assets/icon.png').readAsBytesSync(), [0, 1, 2, 3]);
});
```

- [ ] **Step 2: Run SKILL tests and confirm failure**

Run: `flutter test test/features/skills/data/file_skill_repository_test.dart`

Expected: FAIL with missing repository and fixture helpers.

- [ ] **Step 3: Implement validated recursive copy**

Require a root `SKILL.md`. Reject the Vault root, a destination already inside the source, symlinks resolving outside the selected source, and files larger than 50 MiB without an injected `confirmLargeFile` returning true. Copy in 1 MiB chunks and emit progress after every completed file. Resolve folder collision as `name-2`, `name-3`.

Define `skillFixture(Map<String, Object> entries)` in `test/support/skill_fixture.dart`; String values write UTF-8, `List<int>` values write bytes, and the returned fixture exposes `directory` plus exact recursive cleanup.

- [ ] **Step 4: Implement lazy tree and editor dispatch**

`listChildren` returns only immediate children, directories first, then case-insensitive names. `SkillWorkspace` opens supported text extensions in `TextEditorWorkspace`, images in a preview pane, and unknown binaries through `SystemOpenService`. Add tests for lazy listing, text save, binary external open, Finder reveal, terminal open, trash and Undo.

Run: `dart format lib test && flutter analyze && flutter test test/features/skills`

Expected: all SKILL tests PASS.

- [ ] **Step 5: Commit SKILL support**

```bash
git add lib/features/skills test/features/skills
git commit -m "feat: add SKILL folder workspace"
```

### Task 4: Implement MCP JSON editing, validation, formatting, and safe copying

**Files:**
- Create: `lib/features/mcp/domain/mcp_document.dart`
- Create: `lib/features/mcp/domain/json_diagnostic.dart`
- Create: `lib/features/mcp/data/json_validation_service.dart`
- Create: `lib/features/mcp/data/mcp_repository.dart`
- Create: `lib/features/mcp/data/file_mcp_repository.dart`
- Create: `lib/features/mcp/application/mcp_controller.dart`
- Create: `lib/features/mcp/presentation/mcp_workspace.dart`
- Test: `test/features/mcp/data/json_validation_service_test.dart`
- Test: `test/features/mcp/data/file_mcp_repository_test.dart`
- Test: `test/features/mcp/application/mcp_controller_test.dart`

**Interfaces:**
- Produces: `McpDocument(id, title, description, tags, jsonText, relativePath)`.
- Produces: `JsonValidationResult.valid(value)` or `invalid(JsonDiagnostic(line, column, message))`.
- Produces: controller `validate`, `format`, `copySafeTemplate`, `requestFullCopy`, and `openTerminal`.
- Consumes later: Phase 5 `SecretTemplateService.resolve(String template)`; inject `null` until then.

- [ ] **Step 1: Write failing JSON diagnostic tests**

```dart
test('reports one-based line and column for malformed JSON', () {
  const source = '{\n  "mcpServers": {\n  }\n';
  final result = const JsonValidationService().validate(source);
  expect(result.isValid, isFalse);
  expect(result.diagnostic!.line, 4);
  expect(result.diagnostic!.column, greaterThanOrEqualTo(1));
});

test('formats valid JSON with two-space indentation and final newline', () {
  expect(const JsonValidationService().format('{"a":1}'), '{\n  "a": 1\n}\n');
});
```

- [ ] **Step 2: Run MCP tests and confirm failure**

Run: `flutter test test/features/mcp/data/json_validation_service_test.dart`

Expected: FAIL with missing validation service.

- [ ] **Step 3: Implement JSON repository and diagnostics**

Use `jsonDecode` and convert `FormatException.offset` into one-based line/column by counting newlines before the offset. Preserve invalid text on disk and in the editor. Store MCP metadata in `.ai-workbench/resources/metadata.json`, not inside JSON.

`copySafeTemplate` must copy the editor text exactly, including `${ENV_VAR}` placeholders, only after valid JSON. `requestFullCopy` must return `FullCopyUnavailable` until Phase 5 injects a secret resolver; it must never silently fall back to template copying under a “full” label.

- [ ] **Step 4: Build the MCP workspace and test actions**

Show line numbers, JSON highlighting, inline diagnostic row, Format, `复制安全模板`, disabled/available `复制完整配置`, `在终端打开`, tags and description. Tests cover invalid save retention, format preserving semantic value, safe copy exactness, terminal directory, duplicate IDs, trash and Undo.

Run: `dart format lib test && flutter analyze && flutter test test/features/mcp`

Expected: all MCP tests PASS.

- [ ] **Step 5: Commit MCP support**

```bash
git add lib/features/mcp test/features/mcp
git commit -m "feat: add MCP configuration workspace"
```

### Task 5: Register resource commands and complete the three-workspace navigation

**Files:**
- Create: `lib/features/resources/application/resource_workspace_registry.dart`
- Create: `lib/features/resources/presentation/resource_workspace_host.dart`
- Modify: `lib/features/command_palette/application/command_palette_controller.dart`
- Modify: `lib/features/library/presentation/resource_list_pane.dart`
- Modify: `lib/features/shell/presentation/workbench_shell.dart`
- Test: `test/features/resources/presentation/resource_workspace_host_test.dart`
- Test: `test/features/resources/resource_journey_test.dart`

**Interfaces:**
- Produces: `ResourceWorkspaceFactory.build(ResourceRecord)` selected by `ResourceType`.
- Produces: concrete handlers for `new-prompt`, `import-skill`, and `new-mcp` commands.
- Produces: shared confirmation sheet result `confirm`, `cancel`, or `confirmAndDoNotAskForSession` for recoverable trash actions.

- [ ] **Step 1: Write the failing dispatch test**

```dart
testWidgets('workspace host dispatches by resource type', (tester) async {
  await tester.pumpWidget(resourceHostHarness(promptRecord));
  expect(find.byType(PromptWorkspace), findsOneWidget);
  await tester.pumpWidget(resourceHostHarness(skillRecord));
  expect(find.byType(SkillWorkspace), findsOneWidget);
  await tester.pumpWidget(resourceHostHarness(mcpRecord));
  expect(find.byType(McpWorkspace), findsOneWidget);
});
```

- [ ] **Step 2: Run journey tests and verify missing integration fails**

Run: `flutter test test/features/resources`

Expected: FAIL with missing host and command handlers.

- [ ] **Step 3: Wire factories, commands, refresh, and metadata**

After create/import/duplicate/trash/Undo, refresh the Vault controller and index, update metadata references, and activate the resulting resource tab. If the active resource moves to trash, close its tab only after the move succeeds.

- [ ] **Step 4: Test end-to-end temporary Vault journeys**

Test create Prompt → edit → autosave → copy → duplicate; import SKILL → open nested Markdown → save → reveal; create MCP → invalid edit → diagnostic → fix → format → safe copy. Use fake platform/clipboard adapters and a real temporary Vault.

Run: `dart format lib test && flutter analyze && flutter test test/features/prompts test/features/skills test/features/mcp test/features/resources && flutter build macos --debug`

Expected: all Phase 3 tests PASS and debug build succeeds.

- [ ] **Step 5: Commit Phase 3 integration**

```bash
git add lib/features/resources lib/features/command_palette lib/features/library lib/features/shell test/features/resources
git commit -m "feat: integrate text resource workspaces"
```

## Phase 3 Final Verification

- [ ] Run: `flutter analyze`
- [ ] Run: `flutter test`
- [ ] Run: `flutter build macos --debug`
- [ ] Manually create one Prompt and one MCP config, import one SKILL folder, edit each, copy the Prompt and safe MCP template, reveal the SKILL in Finder, and open its directory in Terminal.
- [ ] Verify no command or script from any resource was executed.
