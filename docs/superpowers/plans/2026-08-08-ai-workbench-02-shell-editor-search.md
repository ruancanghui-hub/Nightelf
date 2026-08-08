# AI Workbench Phase 2: Desktop Shell, Editor, Search, and Metadata Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the confirmed Apple-style desktop shell, cross-resource tabs, search/command navigation, shared text editor, metadata inspector, favorites, associations, and keyboard behavior.

**Architecture:** Presentation consumes Phase 1 domain records and controller state through Riverpod providers. A shared `DocumentSession` owns editor buffers and autosave independently from resource-specific codecs. User-facing metadata is persisted in synchronized JSON files while window-only state remains local.

**Tech Stack:** Phase 1 stack plus re_editor, re_highlight, macos_ui widgets, Flutter Actions/Shortcuts, fake_async, flutter_test.

## Global Constraints

- Begin only after every Phase 1 verification command passes.
- Preserve the selected dark Apple visual direction and provide an equivalent light theme.
- Do not add Prompt-, SKILL-, MCP-, Website-, Workflow-, Git-, or secret-specific business logic.
- No shell widget may read or write files directly.
- Keep every interactive control keyboard reachable with a semantic label.
- Use exact Chinese labels from the design specification.

---

### Task 1: Establish design tokens and the macOS workbench shell

**Files:**
- Create: `lib/app/theme/workbench_colors.dart`
- Create: `lib/app/theme/workbench_theme.dart`
- Create: `lib/features/shell/presentation/workbench_shell.dart`
- Create: `lib/features/shell/presentation/workbench_toolbar.dart`
- Create: `lib/features/shell/presentation/workbench_sidebar.dart`
- Modify: `lib/app/ai_workbench_app.dart`
- Test: `test/features/shell/presentation/workbench_shell_test.dart`
- Create: `test/support/workbench_harness.dart`

**Interfaces:**
- Produces: `WorkbenchTheme.light()` and `WorkbenchTheme.dark()`.
- Produces: `WorkbenchShell(vaultState, body, onCreateVault, onOpenVault)`.
- Produces: `SidebarDestination(type, label, icon)` and a fixed destination list.

- [ ] **Step 1: Write the failing shell structure test**

```dart
testWidgets('open Vault shows the five resource destinations', (tester) async {
  await tester.pumpWidget(testApp(openVaultState()));
  for (final label in ['AI 提示词', 'SKILL 文件夹', 'MCP 配置', '网站链接', 'Workflow 文件']) {
    expect(find.text(label), findsOneWidget);
  }
  expect(find.text('收藏'), findsOneWidget);
  expect(find.text('最近使用'), findsOneWidget);
  expect(find.bySemanticsLabel('搜索资源'), findsOneWidget);
});
```

- [ ] **Step 2: Run the test and verify it fails**

Run: `flutter test test/features/shell/presentation/workbench_shell_test.dart`

Expected: FAIL because the shell and theme do not exist.

- [ ] **Step 3: Implement tokens and the three-region shell**

Define named tokens instead of inline colors: `canvas`, `sidebarMaterial`, `surface`, `surfaceRaised`, `divider`, `textPrimary`, `textSecondary`, `focusBlue`, `successGreen`, `warningAmber`, and `dangerRed`. Use `MacosScaffold` with one 240-point sidebar, a toolbar, and an injected content body. Keep translucency in macOS window/sidebar configuration only; use opaque editor surfaces.

The toolbar must render Vault name, a search field with `⌘K`, inactive sync status `未配置同步`, history, and overflow buttons. Actions unavailable in this phase must be disabled with a tooltip that names the phase dependency; available callbacks are injected.

Define `openVaultState()`, `testApp(VaultState)`, and `workbenchHarness()` in `test/support/workbench_harness.dart` using Phase 1 factories and provider overrides. The harness uses deterministic fake records and exposes controllers for keyboard/widget assertions.

- [ ] **Step 4: Verify dark/light shell rendering**

Add two widget tests that wrap the shell with light and dark `MacosThemeData`, resize to `1440x1024`, and assert no `FlutterError` or overflow exception was recorded.

Run: `dart format lib test && flutter analyze && flutter test test/features/shell/presentation/workbench_shell_test.dart`

Expected: all shell tests PASS.

- [ ] **Step 5: Commit the visual shell**

```bash
git add lib/app lib/features/shell/presentation test/features/shell/presentation test/support/workbench_harness.dart
git commit -m "feat: add macOS workbench shell"
```

### Task 2: Add cross-resource workspace tabs

**Files:**
- Create: `lib/features/shell/domain/workspace_tab.dart`
- Create: `lib/features/shell/application/workspace_tabs_controller.dart`
- Create: `lib/features/shell/presentation/workspace_tab_strip.dart`
- Modify: `lib/features/shell/presentation/workbench_shell.dart`
- Test: `test/features/shell/application/workspace_tabs_controller_test.dart`
- Test: `test/features/shell/presentation/workspace_tab_strip_test.dart`

**Interfaces:**
- Produces: `WorkspaceTab(resourceId, type, title, relativePath)`.
- Produces: `WorkspaceTabsState(tabs, activeId)`.
- Produces: `open(WorkspaceTab)`, `activate(String resourceId)`, `close(String resourceId)`, `closeOthers(String resourceId)`, and `restore(List<WorkspaceTab>, String?)`.

- [ ] **Step 1: Write failing tab-state tests**

```dart
test('opening an existing resource activates without duplicating it', () {
  final controller = WorkspaceTabsController();
  controller.open(promptTab);
  controller.open(mcpTab);
  controller.open(promptTab);
  expect(controller.state.tabs, [promptTab, mcpTab]);
  expect(controller.state.activeId, promptTab.resourceId);
});

test('closing the active tab activates its left neighbor', () {
  final controller = WorkspaceTabsController()..open(promptTab)..open(mcpTab);
  controller.close(mcpTab.resourceId);
  expect(controller.state.activeId, promptTab.resourceId);
});
```

- [ ] **Step 2: Run controller tests and confirm failure**

Run: `flutter test test/features/shell/application/workspace_tabs_controller_test.dart`

Expected: FAIL with missing tab controller types.

- [ ] **Step 3: Implement deterministic tab behavior and UI**

Use immutable list copies. Do not key tabs by path; key by stable resource ID. Render a horizontal `WorkspaceTabStrip` beneath the toolbar with type icons, close actions, active underline, middle-click close, and a trailing plus button that opens the command palette callback.

- [ ] **Step 4: Test keyboard focus and tab restoration**

Add tests for `⌘W`, selecting a tab with keyboard focus and Return, closing the final tab to an empty workspace, and rejecting restored tabs whose resource IDs no longer exist.

Run: `dart format lib test && flutter analyze && flutter test test/features/shell`

Expected: all shell application and presentation tests PASS.

- [ ] **Step 5: Commit cross-resource tabs**

```bash
git add lib/features/shell test/features/shell
git commit -m "feat: add cross-resource workspace tabs"
```

### Task 3: Build resource browsing, global search, and the command palette

**Files:**
- Create: `lib/features/library/application/library_controller.dart`
- Create: `lib/features/library/presentation/resource_list_pane.dart`
- Create: `lib/features/library/presentation/resource_list_row.dart`
- Create: `lib/features/command_palette/domain/workbench_command.dart`
- Create: `lib/features/command_palette/application/command_palette_controller.dart`
- Create: `lib/features/command_palette/presentation/command_palette.dart`
- Modify: `lib/features/shell/presentation/workbench_sidebar.dart`
- Test: `test/features/library/application/library_controller_test.dart`
- Test: `test/features/command_palette/application/command_palette_controller_test.dart`

**Interfaces:**
- Consumes: `SearchIndex.query(SearchQuery)` and Phase 1 `ResourceRecord` values.
- Produces: `LibraryFilter(destination, query, tags)` and `LibraryState(items, selectedId, isSearching)`.
- Produces: `WorkbenchCommand(id, label, shortcutLabel, execute)`.
- Produces: command palette results that mix resource hits and registered commands.

- [ ] **Step 1: Write failing library filtering tests**

```dart
test('type destination filters before selecting a row', () async {
  final controller = LibraryController(records: [promptRecord, mcpRecord], searchIndex: fakeIndex);
  await controller.setDestination(const LibraryDestination.type(ResourceType.mcp));
  expect(controller.state.items.map((e) => e.id), [mcpRecord.id]);
  expect(controller.state.selectedId, mcpRecord.id);
});

test('blank command palette lists commands before resources', () async {
  final controller = CommandPaletteController(commands: [newPromptCommand], searchIndex: fakeIndex);
  await controller.updateQuery('');
  expect(controller.state.results.first.command?.id, 'new-prompt');
});
```

- [ ] **Step 2: Run focused tests and verify failure**

Run: `flutter test test/features/library/application/library_controller_test.dart test/features/command_palette/application/command_palette_controller_test.dart`

Expected: FAIL with missing controllers.

- [ ] **Step 3: Implement navigation and search state**

Debounce text search by 150 ms. Keep destination browsing synchronous over the current Phase 1 resource list. Use FTS only when the trimmed query is non-empty. Preserve selected ID when it still exists after filtering; otherwise select the first item or `null`.

The command palette must support these registered command IDs: `new-prompt`, `import-skill`, `new-mcp`, `new-link`, `new-workflow`, `sync-vault`, `open-vault`, `close-tab`, `open-terminal`, and `open-finder`. Unsupported actions may be disabled with an explicit reason until their phase registers a handler.

- [ ] **Step 4: Implement and test presentation behavior**

Render one grouped resource surface with lightweight row separators, not one card per row. Each row shows icon, title, description excerpt, tags, relative time, and favorite state. Test arrow-key selection, Return to invoke `onOpenResource`, and Escape to close the command palette without changing selection.

Run: `dart format lib test && flutter analyze && flutter test test/features/library test/features/command_palette`

Expected: all library and command palette tests PASS.

- [ ] **Step 5: Commit browse and command navigation**

```bash
git add lib/features/library lib/features/command_palette lib/features/shell/presentation/workbench_sidebar.dart test/features/library test/features/command_palette
git commit -m "feat: browse and search workspace resources"
```

### Task 4: Implement the shared text editor and autosave session

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/features/editor/domain/document_descriptor.dart`
- Create: `lib/features/editor/data/document_storage.dart`
- Create: `lib/features/editor/data/file_document_storage.dart`
- Create: `lib/features/editor/application/document_session.dart`
- Create: `lib/features/editor/presentation/text_editor_workspace.dart`
- Test: `test/features/editor/application/document_session_test.dart`
- Test: `test/features/editor/presentation/text_editor_workspace_test.dart`

**Interfaces:**
- Produces: `DocumentDescriptor(resourceId, absolutePath, language, readOnly)`.
- Produces: `DocumentStorage.read`, `writeAtomically`, and `modifiedAt`.
- Produces: `DocumentSession.load()`, `updateText(String)`, `saveNow()`, `handleExternalChange(DateTime)`, and states `loading`, `clean`, `dirty`, `saving`, `externalConflict`, `failure`.
- Produces: `TextEditorWorkspace(session, showPreview, previewBuilder)`.

- [ ] **Step 1: Add the editor dependency and write the failing autosave test**

Run: `flutter pub add re_editor re_highlight`

```dart
fakeAsync((async) {
  final storage = RecordingDocumentStorage(initialText: 'one');
  final session = DocumentSession(descriptor: descriptor, storage: storage, autosaveDelay: const Duration(milliseconds: 600));
  session.updateText('two');
  async.elapse(const Duration(milliseconds: 599));
  expect(storage.writes, isEmpty);
  async.elapse(const Duration(milliseconds: 1));
  expect(storage.writes, ['two']);
  expect(session.state.isClean, isTrue);
});
```

- [ ] **Step 2: Run the test and verify it fails**

Run: `flutter test test/features/editor/application/document_session_test.dart`

Expected: FAIL with missing document session types.

- [ ] **Step 3: Implement storage and session state**

Reuse `AtomicFileWriter` from Phase 1. Capture the file mtime immediately after successful read/write. If a watcher reports a newer mtime while state is clean, reload. If state is dirty or saving, move to `externalConflict` with both buffer and disk text; do not write either version.

Use `CodeLineEditingController` from `re_editor` inside `TextEditorWorkspace`, line numbers for JSON/YAML/Shell, optional wrapping for Markdown, and `⌘S` wired to `saveNow`.

- [ ] **Step 4: Verify editing, preview, error, and disposal behavior**

Add tests that typing marks dirty, save failure retains the buffer, a dirty external change creates conflict state, clean external change reloads, and disposing flushes a dirty buffer once.

Run: `dart format lib test && flutter analyze && flutter test test/features/editor`

Expected: all editor tests PASS.

- [ ] **Step 5: Commit the shared editor**

```bash
git add pubspec.yaml pubspec.lock lib/features/editor test/features/editor
git commit -m "feat: add autosaving text editor"
```

### Task 5: Persist favorites, collections, recent items, and associations

**Files:**
- Create: `lib/features/metadata/domain/resource_metadata.dart`
- Create: `lib/features/metadata/data/metadata_repository.dart`
- Create: `lib/features/metadata/data/json_metadata_repository.dart`
- Create: `lib/features/metadata/application/metadata_controller.dart`
- Create: `lib/features/metadata/presentation/metadata_inspector.dart`
- Create: `lib/features/metadata/presentation/collection_sidebar_section.dart`
- Create: `lib/features/metadata/presentation/collection_editor_sheet.dart`
- Test: `test/features/metadata/data/json_metadata_repository_test.dart`
- Test: `test/features/metadata/application/metadata_controller_test.dart`

**Interfaces:**
- Produces: `ResourceMetadata(resourceId, description, tags, relatedResourceIds, isFavorite)`.
- Produces: `CollectionRecord(id, name, resourceIds)`.
- Produces: `MetadataSnapshot(resources, collections, recentResourceIds)`.
- Produces: repository `load`, `saveResource`, `saveCollection`, `deleteCollection`, and `recordRecent`.

- [ ] **Step 1: Write failing persistence tests**

```dart
test('favorite and associations survive repository reconstruction', () async {
  final root = await Directory.systemTemp.createTemp('nightelf-meta-');
  addTearDown(() => root.delete(recursive: true));
  final first = JsonMetadataRepository(root: root, writer: AtomicFileWriter());
  await first.saveResource(const ResourceMetadata(
    resourceId: 'workflow-1',
    description: '发布流程',
    tags: ['内容'],
    relatedResourceIds: ['prompt-1', 'mcp-1'],
    isFavorite: true,
  ));
  final snapshot = await JsonMetadataRepository(root: root, writer: AtomicFileWriter()).load();
  expect(snapshot.resources['workflow-1']!.relatedResourceIds, ['prompt-1', 'mcp-1']);
  expect(snapshot.resources['workflow-1']!.isFavorite, isTrue);
});
```

- [ ] **Step 2: Run metadata tests and verify failure**

Run: `flutter test test/features/metadata/data/json_metadata_repository_test.dart`

Expected: FAIL with missing metadata repository.

- [ ] **Step 3: Implement synchronized metadata files**

Persist exact files `.ai-workbench/favorites.json`, `.ai-workbench/collections.json`, and `.ai-workbench/resources/metadata.json`. Persist recent items in `.ai-workbench/local/recent.json` because recency is device-local. Use schema version `1`, stable resource IDs, atomic writes, and deterministic key ordering.

- [ ] **Step 4: Add inspector and missing-reference tests**

`MetadataInspector` must edit description/tags, toggle favorite, and select related resources. Missing related IDs render as `缺失资源` with remove and relink actions; never delete them automatically. Add controller tests for idempotent favorite toggles, tag trimming/deduplication, and recent list cap of 50.

`CollectionSidebarSection` must list synchronized collections beneath the fixed destinations. `CollectionEditorSheet` must create, rename, and delete a collection and add/remove stable resource IDs. Deleting a collection never deletes its resources. Add widget/controller tests for collection CRUD, duplicate-name rejection, missing-member display, and sidebar filtering by the selected collection.

Run: `dart format lib test && flutter analyze && flutter test test/features/metadata`

Expected: all metadata tests PASS.

- [ ] **Step 5: Commit metadata behavior**

```bash
git add lib/features/metadata test/features/metadata
git commit -m "feat: add resource metadata and associations"
```

### Task 6: Wire keyboard commands, restoration, accessibility, and responsive shell states

**Files:**
- Create: `lib/features/shell/application/workbench_intents.dart`
- Create: `lib/features/shell/application/workbench_shortcuts.dart`
- Create: `lib/features/shell/data/workspace_restoration_repository.dart`
- Modify: `lib/features/shell/presentation/workbench_shell.dart`
- Modify: `lib/features/shell/presentation/workbench_toolbar.dart`
- Test: `test/features/shell/application/workbench_shortcuts_test.dart`
- Test: `test/features/shell/presentation/workbench_accessibility_test.dart`

**Interfaces:**
- Produces: intents for command palette, quick open, save, sync, close tab, sidebar focus, and content focus.
- Produces: local restoration of open resource IDs, active resource ID, sidebar width, and inspector visibility.

- [ ] **Step 1: Write failing shortcut tests**

```dart
testWidgets('command K opens and Escape closes the command palette', (tester) async {
  await tester.pumpWidget(workbenchHarness());
  await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
  await tester.pump();
  expect(find.bySemanticsLabel('命令面板'), findsOneWidget);
  await tester.sendKeyEvent(LogicalKeyboardKey.escape);
  await tester.pump();
  expect(find.bySemanticsLabel('命令面板'), findsNothing);
});
```

- [ ] **Step 2: Run shortcut/accessibility tests and verify failure**

Run: `flutter test test/features/shell/application/workbench_shortcuts_test.dart test/features/shell/presentation/workbench_accessibility_test.dart`

Expected: FAIL because intents and semantic wiring are absent.

- [ ] **Step 3: Implement shortcuts and local restoration**

Map `⌘K`, `⌘P`, `⌘S`, `⌘⇧S`, and `⌘W` to explicit intents. Disable sync intent until Phase 5 registers its action. Store workspace restoration under `.ai-workbench/local/workspace.json`; discard resource IDs not present in the current Vault scan.

- [ ] **Step 4: Verify compact width, semantics, and reduced effects**

At widths below 980 points collapse the inspector; below 760 collapse sidebar labels but preserve icons and tooltips. Tests must assert semantic labels for search, sync, every sidebar destination, tab close, favorite, inspector toggle, and editor save status. With reduced motion enabled, page transitions must use zero translation and at most 200 ms opacity transition.

Run: `dart format lib test && flutter analyze && flutter test test/features/shell test/features/library test/features/editor test/features/metadata`

Expected: all Phase 2 focused tests PASS.

- [ ] **Step 5: Commit Phase 2 integration**

```bash
git add lib/features/shell lib/features/library lib/features/command_palette lib/features/editor lib/features/metadata test/features
git commit -m "feat: integrate workbench navigation and editor"
```

## Phase 2 Final Verification

- [ ] Run: `flutter analyze`
- [ ] Run: `flutter test`
- [ ] Run: `flutter build macos --debug`
- [ ] Launch at 1440x1024 and 760x700 in light and dark modes; inspect overflow, focus order, text contrast, selected states, and divider alignment.
- [ ] Record exact tests/build results before Phase 3.
