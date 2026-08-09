# Vault Drag-and-Drop Import Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let macOS users drag existing files and folders into the workbench, review the proposed resource classification, and copy confirmed items safely into a real Vault.

**Architecture:** Domain classification and import planning are pure Dart and consume the Phase 1 `VaultHandle`, `VaultPaths`, `ResourceType`, scanner, index, and application controller. A repository copies each candidate through a temporary sibling path before atomically committing it. The macOS presentation layer uses `desktop_drop` only to turn operating-system drops into paths, then renders a review sheet backed by the pure import plan.

**Tech Stack:** Existing Flutter/macOS/Riverpod stack, `dart:io`, `path`, `desktop_drop: ^0.7.1`, flutter_test, mocktail.

## Global Constraints

- Begin only after Phase 1 Tasks 2–6 pass: a real Vault can be opened, scanned, indexed and refreshed.
- Copy every accepted source into Vault; never move, rename, delete or write to the source.
- Never execute a dragged script, MCP JSON, Workflow, URL, or other resource.
- Only a recognized file/folder receives a suggested type; unknown input requires a human type selection.
- Never silently overwrite: collision default is a numbered filename such as `prompt 2.md`.
- Reject symlinks, unreadable paths and directory cycles; do not follow them outside the dropped source tree.
- Use temporary source/Vault directories in every filesystem test and delete the exact test directory in `tearDown`.
- Keep imports independently atomic and clean temporary targets after failure or cancellation.

---

### Task 1: Define import candidates, classification, and collision naming

**Files:**
- Create: `lib/features/import/domain/import_candidate.dart`
- Create: `lib/features/import/domain/import_classifier.dart`
- Create: `lib/features/import/domain/import_plan.dart`
- Create: `lib/features/import/domain/import_name_allocator.dart`
- Test: `test/features/import/domain/import_classifier_test.dart`
- Test: `test/features/import/domain/import_name_allocator_test.dart`

**Interfaces:**
- Produces `ImportCandidate(sourcePath, isDirectory, suggestedType, reason)`.
- Produces `ImportPlanItem(candidate, selectedType, title, targetBasename, isSelected)` where `selectedType` is nullable only for unclassified input.
- Produces `ImportClassifier.classify(FileSystemEntity source)` and `ImportNameAllocator.nextAvailable(String directory, String basename)`.

- [ ] **Step 1: Write failing classifier and collision tests.**

```dart
test('classifies a folder with root SKILL.md as a skill', () async {
  final source = await fixture.skillDirectory('apple-design');
  final candidate = await classifier.classify(source);
  expect(candidate.suggestedType, ResourceType.skill);
  expect(candidate.reason, '检测到 SKILL.md');
});

test('leaves an unknown extension unclassified', () async {
  final source = await fixture.file('diagram.bin');
  expect((await classifier.classify(source)).suggestedType, isNull);
});

test('allocates a numbered name without overwriting', () async {
  await File(p.join(target.path, 'prompt.md')).writeAsString('old');
  expect(await allocator.nextAvailable(target.path, 'prompt.md'), 'prompt 2.md');
});
```

- [ ] **Step 2: Run** `flutter test test/features/import/domain/import_classifier_test.dart test/features/import/domain/import_name_allocator_test.dart` **and verify the missing-type failure.**
- [ ] **Step 3: Implement the pure plan types and classifier.** Classify a root `SKILL.md` folder as Skill; `.json` as MCP; `.mmd` as Workflow; `.url` as link; `.md`/`.txt` as prompt; leave other inputs null. Use `VaultPaths.directoryFor` to derive targets only after a selected type exists.
- [ ] **Step 4: Reject symlink candidates before classification and preserve their reason. Add tests for a file symlink and directory symlink.**
- [ ] **Step 5: Run** `dart format lib test && flutter test test/features/import/domain` **and commit:** `feat: add Vault import planning`.

### Task 2: Implement atomic copy import into a Vault

**Files:**
- Create: `lib/features/import/data/vault_import_repository.dart`
- Create: `lib/features/import/application/import_controller.dart`
- Test: `test/features/import/data/vault_import_repository_test.dart`
- Test: `test/features/import/application/import_controller_test.dart`

**Interfaces:**
- Produces `Future<ImportResult> VaultImportRepository.importItem(VaultHandle vault, ImportPlanItem item)`.
- Produces `ImportResult(item, resourcePath, succeeded, failureReason)`.
- Produces `ImportController.prepare(List<String> sourcePaths)`, `setType`, `rename`, `remove`, `cancel`, and `confirm`.

- [ ] **Step 1: Write failing repository tests for copy isolation and atomic failure cleanup.**

```dart
test('copies a prompt and leaves the source unchanged', () async {
  final source = await fixture.file('original.md', '# keep me');
  final result = await repository.importItem(vault, promptItem(source.path));
  expect(await File(source.path).readAsString(), '# keep me');
  expect(await File(result.resourcePath!).readAsString(), '# keep me');
});

test('failed copy leaves no temporary or final target', () async {
  final result = await failingRepository.importItem(vault, promptItem(source.path));
  expect(result.succeeded, isFalse);
  expect(await targetDirectory.list().where((e) => e.path.contains('.importing-')).isEmpty, isTrue);
});
```

- [ ] **Step 2: Run** `flutter test test/features/import/data/vault_import_repository_test.dart` **and verify the repository is undefined.**
- [ ] **Step 3: Implement copy-to-unique-temp then rename for files and recursive directories.** Use `Directory.systemTemp` only in tests; production temporary targets must be siblings in the selected Vault destination. Never follow links. For a directory copy, retain every child path beneath the selected destination.
- [ ] **Step 4: Add tests for collision numbering, Skill tree preservation, partial batch failure, cancel cleanup, and unknown type rejected until `setType` is called.**
- [ ] **Step 5: Connect success to the Phase 1 refresh interface (`scan`, `rebuildIndex`, open imported resource); test that refresh is invoked only after atomic commit.**
- [ ] **Step 6: Run** `dart format lib test && flutter test test/features/import` **and commit:** `feat: import files into Vault atomically`.

### Task 3: Add macOS drop target and import-review sheet

**Files:**
- Modify: `pubspec.yaml`
- Modify: `macos/Runner/DebugProfile.entitlements`
- Modify: `macos/Runner/Release.entitlements`
- Create: `lib/features/import/presentation/vault_drop_target.dart`
- Create: `lib/features/import/presentation/import_review_sheet.dart`
- Modify: `lib/features/shell/presentation/workbench_shell.dart`
- Test: `test/features/import/presentation/import_review_sheet_test.dart`
- Test: `test/features/import/presentation/vault_drop_target_test.dart`

**Interfaces:**
- Consumes `DropTarget` callbacks and forwards only dropped filesystem paths to `ImportController.prepare`.
- Produces a review sheet with per-item type selector, title, target name, remove, cancel, and `复制到 Vault` actions.

- [ ] **Step 1: Write failing widget tests for the drop overlay and review controls.**

```dart
testWidgets('drop hover announces the selected destination', (tester) async {
  await tester.pumpWidget(harness(destination: ResourceType.mcp));
  await harness.enterDrop(<String>['/tmp/config.json']);
  expect(find.text('释放以导入到 MCP 配置'), findsOneWidget);
});

testWidgets('unknown input requires type selection before confirmation', (tester) async {
  await tester.pumpWidget(harness(plan: [unknownItem]));
  expect(find.bySemanticsLabel('复制到 Vault'), findsOneWidget);
  expect(tester.widget<PushButton>(find.bySemanticsLabel('复制到 Vault')).onPressed, isNull);
});
```

- [ ] **Step 2: Run** `flutter test test/features/import/presentation` **and verify the expected missing-widget failure.**
- [ ] **Step 3: Add `desktop_drop: ^0.7.1`, then implement a full-window `DropTarget`.** On enter show `释放以导入到工作台`, or `释放以导入到 <资源类型>` for a selected sidebar type. Do not start copying until the confirmation button is pressed.
- [ ] **Step 4: Implement the review sheet.** Render source path, recommendation reason, type selector, editable title/target name, collision notice, remove/cancel actions, a progress summary, success/failure counts, and retry for failed items. Disabled confirmation must have an explanatory tooltip when any selected item lacks a type.
- [ ] **Step 5: Add focus, semantics, dark/light, compact-width, multi-file, cancel, and retry widget tests.**
- [ ] **Step 6: Run** `dart format lib test && flutter analyze && flutter test test/features/import/presentation && flutter build macos --debug` **and commit:** `feat: add Vault drag-and-drop import UI`.

### Task 4: Integrate real Vault import lifecycle and regression coverage

**Files:**
- Modify: `lib/app/ai_workbench_app.dart`
- Modify: `lib/features/vault/application/vault_controller.dart`
- Modify: `lib/features/shell/presentation/workbench_shell.dart`
- Create: `integration_test/vault_drag_drop_import_test.dart`
- Modify: `README.md`

**Interfaces:**
- Consumes a real selected Vault and the completed `ImportController`.
- Produces post-import resource tabs, refresh state, and a user-visible result summary.

- [ ] **Step 1: Write a failing lifecycle integration test.**

```dart
testWidgets('confirmed import refreshes the real Vault and opens the new resource', (tester) async {
  final fixture = await VaultFixture.create();
  await tester.pumpWidget(appWithVault(fixture.vault));
  await tester.dragImport([await fixture.sourcePrompt('release.md')]);
  await tester.tap(find.bySemanticsLabel('复制到 Vault'));
  await tester.pumpAndSettle();
  expect(find.text('release'), findsWidgets);
  expect(fixture.scanner.records.single.relativePath, 'prompts/release.md');
});
```

- [ ] **Step 2: Run** `flutter test integration_test/vault_drag_drop_import_test.dart` **and verify the real import lifecycle is not yet wired.**
- [ ] **Step 3: Wire the controller through the app composition root and real Vault controller.** The app must refuse a drop before a Vault is open, with a non-destructive Chinese explanation. After success, call the existing scan/index refresh exactly once, open the imported resource, and leave source content untouched.
- [ ] **Step 4: Add a regression test proving a drop never triggers Git, Terminal, WebView, URL navigation, or resource execution.**
- [ ] **Step 5: Run** `dart format lib test integration_test && flutter analyze && flutter test && flutter test integration_test/vault_drag_drop_import_test.dart && flutter build macos --debug` **and commit:** `feat: integrate Vault drop import lifecycle`.

## Acceptance Gate

- Users can drop files and folders onto an open Vault, review classification and names, then copy accepted items into ordinary Vault paths.
- Unknown input cannot be imported until its type is manually chosen.
- Sources remain unchanged, collisions number rather than overwrite, symlinks are rejected, and failed/cancelled items leave no temporary target.
- Import does not execute any content and does not invoke Git, Terminal, WebView, or networking.
- Imported resources appear in the resource list, search index, and an open tab; all unit/widget/integration tests and a macOS debug build pass.
