# AI Workbench Phase 1: Foundation and Vault Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a runnable macOS Flutter application that can create, validate, reopen, scan, watch, and search a local AI Workbench Vault.

**Architecture:** Domain models do not import Flutter. Filesystem and SQLite behavior live behind interfaces and are injected into a Riverpod application controller. Vault files are authoritative; the SQLite FTS5 index and app settings are local, rebuildable state.

**Tech Stack:** Flutter 3.44.8, Dart 3.12.2, macos_ui, flutter_riverpod, dart:io, path, file_picker, shared_preferences, watcher, uuid, yaml, sqlite3, sqlite3_flutter_libs, flutter_test, mocktail.

## Global Constraints

- Run all commands from the repository root.
- Reuse the existing macOS-only Flutter project named `ai_workbench` with bundle namespace `com.ruancanghui`; do not regenerate or replace the approved UI foundation.
- Set the minimum macOS deployment target to `13.0`.
- Keep domain and data services free of widget imports.
- Use files as the source of truth and keep `.ai-workbench/local/` out of Git.
- Do not add resource execution, network sync, WebView, or Git behavior in this phase.
- Every filesystem test must use `Directory.systemTemp.createTemp` and delete its exact temporary directory in `tearDown`.

---

### Task 1: Extend the existing macOS app dependency baseline

**Files:**
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock`
- Create: `test/app_smoke_test.dart`
- Modify: `macos/Podfile`
- Modify: `macos/Runner.xcodeproj/project.pbxproj`

**Interfaces:**
- Produces: `AiWorkbenchApp extends ConsumerWidget` as the root widget used by all later phases.
- Produces: the dependency lock in `pubspec.lock`.

- [ ] **Step 1: Preserve the approved UI scaffold and add Phase 1 dependencies**

```bash
flutter pub add path file_picker shared_preferences watcher uuid yaml sqlite3 sqlite3_flutter_libs collection
flutter pub add --dev mocktail
```

- [ ] **Step 2: Write the failing root-widget test**

```dart
// test/app_smoke_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_workbench/app/ai_workbench_app.dart';

void main() {
  testWidgets('shows the no-vault welcome state', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AiWorkbenchApp()));
    expect(find.text('打开 AI 工作台'), findsOneWidget);
    expect(find.text('创建 Vault'), findsOneWidget);
    expect(find.text('打开 Vault'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run the test and verify the missing app fails**

Run: `flutter test test/app_smoke_test.dart`

Expected: FAIL because the approved UI app does not yet expose a real no-Vault state.

- [ ] **Step 4: Add the minimal macOS app root**

```dart
// lib/app/ai_workbench_app.dart (extend the existing app; do not replace its theme or workbench shell)
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

class AiWorkbenchApp extends ConsumerWidget {
  const AiWorkbenchApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MacosApp(
      title: 'AI 工作台',
      themeMode: ThemeMode.system,
      darkTheme: MacosThemeData.dark(),
      theme: MacosThemeData.light(),
      home: const MacosScaffold(
        children: [
          ContentArea(
            builder: (context, scrollController) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('打开 AI 工作台'),
                  PushButton(controlSize: ControlSize.large, onPressed: null, child: Text('创建 Vault')),
                  PushButton(controlSize: ControlSize.large, onPressed: null, child: Text('打开 Vault')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

```dart
// lib/main.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_workbench/app/ai_workbench_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: AiWorkbenchApp()));
}
```

- [ ] **Step 5: Set macOS 13.0 and run baseline checks**

Set `platform :osx, '13.0'` in `macos/Podfile` and every `MACOSX_DEPLOYMENT_TARGET` value in `macos/Runner.xcodeproj/project.pbxproj` to `13.0`.

Run: `dart format lib test && flutter analyze && flutter test test/app_smoke_test.dart && flutter build macos --debug`

Expected: analyzer exit 0, one passing widget test, and a successful debug app build.

- [ ] **Step 6: Commit the scaffold**

```bash
git add pubspec.yaml pubspec.lock test/app_smoke_test.dart macos
git commit -m "chore: add Vault foundation dependencies"
```

### Task 2: Define Vault and resource domain contracts

**Files:**
- Create: `lib/shared/domain/resource_type.dart`
- Create: `lib/features/vault/domain/vault_manifest.dart`
- Create: `lib/features/vault/domain/vault_handle.dart`
- Create: `lib/features/vault/domain/resource_record.dart`
- Create: `lib/features/vault/data/vault_paths.dart`
- Test: `test/features/vault/domain/vault_models_test.dart`
- Create: `test/support/resource_factories.dart`

**Interfaces:**
- Produces: `enum ResourceType { prompt, skill, mcp, link, workflow }`.
- Produces: `VaultManifest.fromJson(Map<String, Object?>)` and `toJson()`.
- Produces: `VaultHandle(root, manifest)` with convenience getters `id` and `name`, plus `ResourceRecord(id, type, relativePath, title, description, tags, modifiedAt, searchableText)`.
- Produces: `VaultPaths` constants and path helpers used by every repository.

- [ ] **Step 1: Write failing model and path tests**

```dart
// test/features/vault/domain/vault_models_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_workbench/features/vault/data/vault_paths.dart';
import 'package:ai_workbench/features/vault/domain/vault_manifest.dart';
import 'package:ai_workbench/shared/domain/resource_type.dart';

void main() {
  test('manifest JSON round-trips version and id', () {
    const manifest = VaultManifest(version: 1, id: 'vault-1', name: '我的资源库');
    expect(VaultManifest.fromJson(manifest.toJson()), manifest);
  });

  test('resource directories are stable', () {
    expect(VaultPaths.directoryFor(ResourceType.prompt), 'prompts');
    expect(VaultPaths.directoryFor(ResourceType.skill), 'skills');
    expect(VaultPaths.directoryFor(ResourceType.mcp), 'mcp');
    expect(VaultPaths.directoryFor(ResourceType.link), 'links');
    expect(VaultPaths.directoryFor(ResourceType.workflow), 'workflows');
  });
}
```

- [ ] **Step 2: Run the test and verify undefined contracts fail**

Run: `flutter test test/features/vault/domain/vault_models_test.dart`

Expected: FAIL with missing imports or undefined classes.

- [ ] **Step 3: Implement immutable domain models**

```dart
// lib/shared/domain/resource_type.dart
enum ResourceType { prompt, skill, mcp, link, workflow }
```

```dart
// lib/features/vault/domain/vault_manifest.dart
class VaultManifest {
  const VaultManifest({required this.version, required this.id, required this.name});
  final int version;
  final String id;
  final String name;

  factory VaultManifest.fromJson(Map<String, Object?> json) => VaultManifest(
        version: json['version']! as int,
        id: json['id']! as String,
        name: json['name']! as String,
      );

  Map<String, Object?> toJson() => {'version': version, 'id': id, 'name': name};

  @override
  bool operator ==(Object other) => other is VaultManifest && other.version == version && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(version, id, name);
}
```

Implement `VaultHandle`, `ResourceRecord`, and `VaultPaths` with the exact constructor field names listed in the Interfaces block. `VaultPaths` must expose `marker = '.ai-vault.json'`, `metadataRoot = '.ai-workbench'`, `localRoot = '.ai-workbench/local'`, `resourceMetadata = '.ai-workbench/resources'`, `workflowLayouts = '.ai-workbench/workflow-layouts'`, and `directoryFor(ResourceType)`.

In `test/support/resource_factories.dart`, define named factories `promptRecord`, `skillRecord`, `mcpRecord`, `linkRecord`, and `workflowRecord`. Each accepts overrides for every `ResourceRecord` field and supplies deterministic defaults; later plans use only these factories for domain fixtures.

- [ ] **Step 4: Run model tests and analyzer**

Run: `dart format lib/shared/domain lib/features/vault test/features/vault && flutter analyze && flutter test test/features/vault/domain/vault_models_test.dart`

Expected: analyzer exit 0 and both tests PASS.

- [ ] **Step 5: Commit the domain contracts**

```bash
git add lib/shared/domain lib/features/vault/domain lib/features/vault/data/vault_paths.dart test/features/vault/domain test/support/resource_factories.dart
git commit -m "feat: define vault domain contracts"
```

### Task 3: Create and open Vaults with atomic writes

**Files:**
- Create: `lib/shared/io/atomic_file_writer.dart`
- Create: `lib/features/vault/data/vault_repository.dart`
- Create: `lib/features/vault/data/file_vault_repository.dart`
- Test: `test/shared/io/atomic_file_writer_test.dart`
- Test: `test/features/vault/data/file_vault_repository_test.dart`

**Interfaces:**
- Produces: `AtomicFileWriter.writeString(File target, String contents)`.
- Produces: `abstract interface class VaultRepository` with `Future<VaultHandle> create(Directory root, String name)` and `Future<VaultHandle> open(Directory root)`.
- Produces: `InvalidVaultException`, `UnsupportedVaultVersionException`, and `VaultAlreadyExistsException`.

- [ ] **Step 1: Write failing atomic-write and Vault tests**

```dart
test('create writes marker, standard folders, and gitignore', () async {
  final root = await Directory.systemTemp.createTemp('nightelf-vault-');
  addTearDown(() => root.delete(recursive: true));
  final repository = FileVaultRepository(idFactory: () => 'vault-id');

  final handle = await repository.create(root, '工作资源');

  expect(handle.manifest.id, 'vault-id');
  expect(File('${root.path}/.ai-vault.json').existsSync(), isTrue);
  for (final name in ['prompts', 'skills', 'mcp', 'links', 'workflows', 'assets']) {
    expect(Directory('${root.path}/$name').existsSync(), isTrue);
  }
  expect(File('${root.path}/.gitignore').readAsStringSync(), contains('.ai-workbench/local/'));
});

test('open rejects a directory without a marker', () async {
  final root = await Directory.systemTemp.createTemp('nightelf-invalid-');
  addTearDown(() => root.delete(recursive: true));
  expect(() => FileVaultRepository().open(root), throwsA(isA<InvalidVaultException>()));
});
```

- [ ] **Step 2: Run the focused tests and confirm failure**

Run: `flutter test test/shared/io/atomic_file_writer_test.dart test/features/vault/data/file_vault_repository_test.dart`

Expected: FAIL because the writer and repository are undefined.

- [ ] **Step 3: Implement atomic writes and Vault initialization**

`AtomicFileWriter.writeString` must write to `${target.path}.nightelf-tmp`, call `flush: true`, and rename the temporary file over the target only after the write completes. `FileVaultRepository.create` must reject an existing marker, create every standard directory, create `.ai-workbench/local`, write marker JSON with version `1`, and write a `.gitignore` containing these exact lines:

```text
.ai-workbench/local/
.env
.env.*
*.nightelf-tmp
```

`open` must reject missing markers, malformed JSON, and any version other than `1`.

- [ ] **Step 4: Verify failure safety and successful creation**

Add a test-only injectable write callback that throws before rename; assert the original target contents remain unchanged and the exception is surfaced.

Run: `dart format lib test && flutter analyze && flutter test test/shared/io/atomic_file_writer_test.dart test/features/vault/data/file_vault_repository_test.dart`

Expected: all focused tests PASS and analyzer exit 0.

- [ ] **Step 5: Commit Vault persistence**

```bash
git add lib/shared/io lib/features/vault/data test/shared/io test/features/vault/data
git commit -m "feat: create and open local vaults"
```

### Task 4: Scan resources and assign stable identities

**Files:**
- Create: `lib/features/vault/data/front_matter_reader.dart`
- Create: `lib/features/vault/data/resource_identity_store.dart`
- Create: `lib/features/vault/data/resource_scanner.dart`
- Test: `test/features/vault/data/front_matter_reader_test.dart`
- Test: `test/features/vault/data/resource_scanner_test.dart`

**Interfaces:**
- Produces: `FrontMatterReader.read(String text) -> FrontMatterDocument(metadata, body)`.
- Produces: `ResourceIdentityStore.resolve({required ResourceType type, required String relativePath, String? embeddedId}) -> Future<String>`.
- Produces: `ResourceScanner.scan(VaultHandle vault) -> Future<List<ResourceRecord>>`.

- [ ] **Step 1: Write failing front matter and scanner tests**

```dart
test('reads YAML front matter without removing body whitespace', () {
  const source = '---\nid: prompt-1\ntitle: 审查助手\ntags: [代码, 审查]\n---\n正文\n';
  final document = const FrontMatterReader().read(source);
  expect(document.metadata['id'], 'prompt-1');
  expect(document.metadata['tags'], ['代码', '审查']);
  expect(document.body, '正文\n');
});

test('scanner maps standard folders to resource types', () async {
  final fixture = await createVaultFixture({
    'prompts/review.md': '---\nid: p1\ntitle: 审查助手\n---\n检查代码',
    'mcp/claude.json': '{"mcpServers": {}}',
    'skills/apple-design/SKILL.md': '# Apple Design',
  });
  addTearDown(fixture.dispose);
  final records = await fixture.scanner.scan(fixture.handle);
  expect(records.map((e) => e.type), containsAll([ResourceType.prompt, ResourceType.mcp, ResourceType.skill]));
  expect(records.singleWhere((e) => e.relativePath == 'prompts/review.md').id, 'p1');
});
```

Create `test/support/vault_fixture.dart` with a `VaultFixture` that owns one exact temporary directory, a `VaultHandle`, a `ResourceScanner`, and `Future<void> dispose()`.

- [ ] **Step 2: Run tests and confirm parser/scanner failure**

Run: `flutter test test/features/vault/data/front_matter_reader_test.dart test/features/vault/data/resource_scanner_test.dart`

Expected: FAIL with undefined parser, fixture, or scanner types.

- [ ] **Step 3: Implement deterministic scanning**

The scanner must:

- treat each immediate directory under `skills/` containing `SKILL.md` as one Skill resource;
- treat supported files under the other four standard directories as resources;
- ignore hidden files, `.ai-workbench/`, `.git/`, temporary files, and symlink targets outside the Vault;
- read embedded `id`, `title`, `description`, and `tags` when front matter exists;
- use filename/folder name as title fallback;
- store non-embedded identity mappings atomically in `.ai-workbench/resources/index.json`;
- sort by resource type index, case-insensitive title, then relative path.

- [ ] **Step 4: Verify rescans preserve IDs**

Add a test that scans an MCP file twice with a new `ResourceScanner` instance and verifies the same sidecar ID is returned. Add a test that an external symlink to a directory outside the Vault is ignored.

Run: `dart format lib test && flutter analyze && flutter test test/features/vault/data test/features/vault/domain`

Expected: all Vault data and domain tests PASS.

- [ ] **Step 5: Commit scanning and identities**

```bash
git add lib/features/vault/data test/features/vault/data test/support/vault_fixture.dart
git commit -m "feat: scan and identify vault resources"
```

### Task 5: Build the disposable SQLite FTS search index

**Files:**
- Create: `lib/features/search/domain/search_query.dart`
- Create: `lib/features/search/domain/search_hit.dart`
- Create: `lib/features/search/data/search_index.dart`
- Create: `lib/features/search/data/sqlite_search_index.dart`
- Test: `test/features/search/data/sqlite_search_index_test.dart`

**Interfaces:**
- Produces: `SearchQuery(text, types, tags, limit)` with default `limit = 50`.
- Produces: `SearchHit(record, snippet, rank)`.
- Produces: `SearchIndex.rebuild(Iterable<ResourceRecord>)`, `upsert(ResourceRecord)`, `remove(String id)`, and `query(SearchQuery)`.

- [ ] **Step 1: Write failing FTS tests**

```dart
test('searches title, tags, description, and content with a type filter', () async {
  final index = SqliteSearchIndex.inMemory();
  addTearDown(index.close);
  await index.rebuild([
    promptRecord(id: 'p1', title: '代码审查助手', tags: const ['审查'], searchableText: '安全与性能'),
    mcpRecord(id: 'm1', title: '文件服务', searchableText: 'filesystem'),
  ]);

  final hits = await index.query(SearchQuery(text: '审查', types: const {ResourceType.prompt}));

  expect(hits.map((e) => e.record.id), ['p1']);
  expect(hits.single.snippet, contains('审查'));
});
```

- [ ] **Step 2: Run the test and verify it fails**

Run: `flutter test test/features/search/data/sqlite_search_index_test.dart`

Expected: FAIL with missing search contracts.

- [ ] **Step 3: Implement the FTS5 schema and queries**

Use an ordinary `resources` table plus an FTS5 virtual table with columns `id UNINDEXED`, `title`, `description`, `tags`, `content`. Store `ResourceType.name` and relative path in the ordinary table. Wrap full rebuilds in a transaction. Escape user input into quoted FTS terms rather than concatenating operators. Return an empty list for blank queries; blank browsing is handled by the resource list, not FTS.

```sql
CREATE VIRTUAL TABLE resource_fts USING fts5(
  id UNINDEXED,
  title,
  description,
  tags,
  content,
  tokenize='unicode61'
);
```

- [ ] **Step 4: Verify updates, removals, and malformed search input**

Add tests proving `upsert` changes results, `remove` removes both table rows, Chinese tokens match, and input containing quotes or `*` cannot break the SQL statement.

Run: `dart format lib test && flutter analyze && flutter test test/features/search/data/sqlite_search_index_test.dart`

Expected: all search index tests PASS.

- [ ] **Step 5: Commit the local search index**

```bash
git add lib/features/search test/features/search
git commit -m "feat: add disposable vault search index"
```

### Task 6: Orchestrate Vault restore, file watching, and index refresh

**Files:**
- Create: `lib/features/settings/data/app_settings_repository.dart`
- Create: `lib/features/settings/data/shared_preferences_app_settings.dart`
- Create: `lib/features/vault/application/vault_state.dart`
- Create: `lib/features/vault/application/vault_controller.dart`
- Create: `lib/features/vault/data/vault_change_watcher.dart`
- Modify: `lib/app/ai_workbench_app.dart`
- Test: `test/features/vault/application/vault_controller_test.dart`
- Test: `test/features/vault/data/vault_change_watcher_test.dart`
- Create: `test/features/vault/application/vault_controller_fakes.dart`

**Interfaces:**
- Produces: `AppSettingsRepository.readLastVaultPath()` and `writeLastVaultPath(String?)`.
- Produces: `VaultChangeWatcher.watch(Directory root) -> Stream<Set<String>>`, debounced to one relative-path set per 250 ms burst.
- Produces: `VaultState.closed`, `opening`, `open(handle, resources)`, and `failure(message)`.
- Produces: `VaultController.restoreLastVault()`, `createVault(Directory, String)`, `openVault(Directory)`, `closeVault()`, and `refreshPaths(Set<String>)`.

- [ ] **Step 1: Write failing controller tests with fakes**

```dart
test('restores a valid last Vault and rebuilds the index', () async {
  final repository = FakeVaultRepository.opening(handle);
  final scanner = FakeResourceScanner([record]);
  final index = RecordingSearchIndex();
  final settings = MemoryAppSettings(lastVaultPath: handle.root.path);
  final controller = VaultController(repository: repository, scanner: scanner, index: index, settings: settings);

  await controller.restoreLastVault();

  expect(controller.state.handle, handle);
  expect(controller.state.resources, [record]);
  expect(index.rebuiltWith, [record]);
});
```

- [ ] **Step 2: Run controller and watcher tests to confirm failure**

Run: `flutter test test/features/vault/application/vault_controller_test.dart test/features/vault/data/vault_change_watcher_test.dart`

Expected: FAIL because the application contracts do not exist.

- [ ] **Step 3: Implement lifecycle orchestration**

Use a plain testable `VaultController` class first; expose it through a Riverpod provider in `ai_workbench_app.dart`. On open/create: set opening, open repository, scan, rebuild index, save last path, subscribe watcher, then set open. On failure: cancel watcher, retain the actionable Chinese error, and never delete or initialize the selected directory implicitly.

Define `FakeVaultRepository.opening(VaultHandle)`, `FakeResourceScanner(List<ResourceRecord>)`, `RecordingSearchIndex.rebuiltWith`, and `MemoryAppSettings(lastVaultPath)` in `vault_controller_fakes.dart`; implement every interface method and throw `UnimplementedError` only for a method the focused controller test cannot call.

The watcher must ignore `.git`, `.ai-workbench/local`, `*.nightelf-tmp`, and its own index database files. `refreshPaths` may rescan the Vault in Phase 1; later phases can optimize targeted parsing without changing the interface.

- [ ] **Step 4: Add restore failure behavior and run the phase suite**

Add a test that a missing last path clears the setting and returns `VaultState.closed` instead of an error. Add a watcher test that three writes inside 250 ms emit one path set.

Run: `dart format lib test && flutter analyze && flutter test && flutter build macos --debug`

Expected: analyzer exit 0, all tests PASS, and debug build succeeds.

- [ ] **Step 5: Commit the Phase 1 orchestration**

```bash
git add lib/features/settings lib/features/vault/application lib/features/vault/data/vault_change_watcher.dart lib/app/ai_workbench_app.dart test/features/vault
git commit -m "feat: restore and watch active vault"
```

## Phase 1 Final Verification

- [ ] Run: `flutter analyze`
- [ ] Run: `flutter test`
- [ ] Run: `flutter build macos --debug`
- [ ] Launch once with `flutter run -d macos`, create a temporary Vault, quit, relaunch, and verify the same Vault reopens.
- [ ] Record the exact test count and build result in the task handoff before starting Phase 2.
