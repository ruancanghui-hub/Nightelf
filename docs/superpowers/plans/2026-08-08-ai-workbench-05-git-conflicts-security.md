# AI Workbench Phase 5: Git Sync, Conflict Review, and Secret Safety Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement safe one-click Git synchronization, author-controlled three-way conflict review, secret scanning, Keychain-backed local secrets, and guarded full MCP configuration copying.

**Architecture:** A typed Git gateway wraps `/usr/bin/git` with argument arrays and structured results. The sync orchestrator is a deterministic state machine. Conflict collection reads Git index stages and never chooses a winner; a separate review controller requires author confirmation before commit/push. Secret scanning gates staging, while secret values live only in Keychain.

**Tech Stack:** Phase 1–4 stack plus dart:io Process, crypto, flutter_secure_storage, UTF-8 codecs, Riverpod, flutter_test, mocktail, and temporary bare Git repositories.

## Global Constraints

- Begin only after all Phase 4 verification commands pass.
- Never interpolate resource text, paths, branch names, or remote names into a shell command string.
- Never log full secret matches, Keychain values, credentials, environment values, or GitHub tokens.
- Never auto-resolve a conflict or push while any conflict lacks author confirmation.
- Keep the local checkpoint commit when a merge is aborted so no authored work is lost.
- Treat Workflow source conflicts separately from Workflow layout conflicts.
- Do not add hosted-service-specific APIs; operate through standard Git remotes.

---

### Task 1: Wrap Git discovery, status, history, and index-stage access

**Files:**
- Create: `lib/features/git_sync/domain/git_models.dart`
- Create: `lib/features/git_sync/data/git_command_runner.dart`
- Create: `lib/features/git_sync/data/git_repository.dart`
- Create: `lib/features/git_sync/data/process_git_repository.dart`
- Test: `test/features/git_sync/data/git_command_runner_test.dart`
- Test: `test/features/git_sync/data/process_git_repository_test.dart`
- Create: `test/support/git_fixture.dart`

**Interfaces:**
- Produces: `GitCommandResult(exitCode, stdout, stderr)` with redacted `toString()`.
- Produces: `GitStatus(branch, upstream, staged, unstaged, untracked, conflicts, operation)`.
- Produces: `AheadBehind(ahead, behind)` and `GitConflictPath(relativePath, stages, isBinary)`.
- Produces: repository methods `isAvailable`, `isRepository`, `init`, `status`, `currentBranch`, `remoteUrl`, `fetch`, `aheadBehind`, `log`, `readStage`, `listConflicts`, and `abortInProgressOperation`.

- [ ] **Step 1: Create the temporary Git fixture and failing gateway tests**

```dart
test('status returns untracked paths without shell parsing ambiguity', () async {
  final fixture = await GitFixture.create();
  addTearDown(fixture.dispose);
  await File('${fixture.work.path}/a file \$(name).md').writeAsString('text');
  final status = await ProcessGitRepository().status(fixture.work.path);
  expect(status.untracked, ['a file \$(name).md']);
});
```

`GitFixture.create()` must initialize one work repository with local test identity and optionally one bare remote. It must never use the developer's global Git config.

- [ ] **Step 2: Run tests and verify missing Git gateway fails**

Run: `flutter test test/features/git_sync/data`

Expected: FAIL with missing Git models/repository.

- [ ] **Step 3: Implement machine-readable Git commands**

Invoke `/usr/bin/git` with explicit arguments and working directory. Use `status --porcelain=v2 -z --branch`, `rev-list --left-right --count`, `log -z --format=...`, `ls-files -u -z`, and `show :<stage>:<path>`. Parse NUL-delimited output rather than human-formatted lines. Decode normal output as UTF-8 with replacement only for status metadata; return stage blobs as bytes.

Do not expose raw environment data in errors. Map missing executable, not-a-repository, detached HEAD, in-progress merge/rebase, missing remote, authentication, network, and generic command failures to distinct exceptions.

- [ ] **Step 4: Test history, remote, stage blobs, and error mapping**

Create a real conflict in `GitFixture`, assert stages 1/2/3 are readable, a binary file is detected by failed strict UTF-8 decoding, a missing remote maps correctly, and status paths containing spaces/newlines remain intact.

Run: `dart format lib test && flutter analyze && flutter test test/features/git_sync/data`

Expected: all Git gateway tests PASS.

- [ ] **Step 5: Commit the Git gateway**

```bash
git add lib/features/git_sync/domain lib/features/git_sync/data test/features/git_sync/data test/support/git_fixture.dart
git commit -m "feat: add typed Git repository gateway"
```

### Task 2: Block secrets before Git staging

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/features/security/domain/secret_finding.dart`
- Create: `lib/features/security/data/secret_scan_rules.dart`
- Create: `lib/features/security/data/secret_scanner.dart`
- Create: `lib/features/security/data/secret_ignore_repository.dart`
- Test: `test/features/security/data/secret_scanner_test.dart`
- Test: `test/features/security/data/secret_ignore_repository_test.dart`
- Create: `test/support/security_fixture.dart`

**Interfaces:**
- Produces: `SecretFinding(ruleId, relativePath, line, column, redactedPreview, fingerprint)`.
- Produces: `SecretScanner.scanFiles(vaultRoot, relativePaths) -> Future<List<SecretFinding>>`.
- Produces: ignore repository `contains(fingerprint)`, `add(fingerprint, ruleId, relativePath)`, and `remove(fingerprint)`.

- [ ] **Step 1: Add crypto and write failing detection/redaction tests**

Run: `flutter pub add crypto`

```dart
test('finds secrets but never exposes their full value', () async {
  final file = await fixture.write('mcp/server.json', '{"apiKey":"sk-test-123456789012345678901234"}');
  final findings = await const SecretScanner().scanFiles(fixture.root.path, ['mcp/server.json']);
  expect(findings.single.ruleId, 'openai-api-key');
  expect(findings.single.redactedPreview, contains('sk-t…1234'));
  expect(findings.single.toString(), isNot(contains('123456789012345678901234')));
});

test('accepts environment placeholders', () async {
  await fixture.write('mcp/server.json', '{"apiKey":"\${OPENAI_API_KEY}"}');
  expect(await const SecretScanner().scanFiles(fixture.root.path, ['mcp/server.json']), isEmpty);
});
```

- [ ] **Step 2: Run security tests and verify failure**

Run: `flutter test test/features/security/data/secret_scanner_test.dart`

Expected: FAIL with missing scanner types.

- [ ] **Step 3: Implement exact initial rules**

Add rules for PEM private key headers, `ghp_`, `github_pat_`, OpenAI-style `sk-` high-entropy values, Google `AIza`, AWS `AKIA`, and JSON/YAML keys matching `apiKey|api_key|token|password|secret|privateKey` whose values are non-empty and not `${NAME}` placeholders. Skip binary files, files over 5 MiB, `.git/`, `.ai-workbench/local/`, and ignored paths.

Fingerprint `ruleId + NUL + normalized matched value` with SHA-256. Store only fingerprint, rule ID, relative path, timestamp, and schema version `1` in `.ai-workbench/secret-scan-ignore.json`. Redact previews to at most the first 4 and last 4 visible characters.

Define `SecurityFixture.create()` and `write(relativePath, contents)` in `test/support/security_fixture.dart`; it owns and deletes one exact temporary Vault directory.

- [ ] **Step 4: Test ignore behavior and false-positive boundaries**

Test each rule, placeholder exclusions, common example values, binary skip, size skip, ignore add/remove, corrupted ignore file failure, and that serialized ignores contain no matched secret.

Run: `dart format lib test && flutter analyze && flutter test test/features/security`

Expected: all security scanner/ignore tests PASS.

- [ ] **Step 5: Commit the secret scan gate**

```bash
git add pubspec.yaml pubspec.lock lib/features/security test/features/security
git commit -m "feat: block secrets before sync"
```

### Task 3: Store local secrets in Keychain and guard full MCP copies

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/features/security/data/secret_store.dart`
- Create: `lib/features/security/data/keychain_secret_store.dart`
- Create: `lib/features/security/application/secret_template_service.dart`
- Create: `lib/features/security/presentation/full_copy_confirmation_sheet.dart`
- Modify: `lib/features/mcp/application/mcp_controller.dart`
- Modify: `lib/features/mcp/presentation/mcp_workspace.dart`
- Test: `test/features/security/application/secret_template_service_test.dart`
- Test: `test/features/mcp/application/mcp_full_copy_test.dart`
- Create: `test/features/security/support/memory_secret_store.dart`

**Interfaces:**
- Produces: `SecretStore.read(name)`, `write(name, value)`, `delete(name)`, and `names()`.
- Produces: `SecretTemplateService.placeholderNames(String)`, `missingNames(String)`, and `resolve(String)`.
- Produces: full-copy result `cancelled`, `missingSecrets(names)`, or `copied`.

- [ ] **Step 1: Add Keychain dependency and write failing template tests**

Run: `flutter pub add flutter_secure_storage`

```dart
test('resolves only explicit environment placeholders', () async {
  final store = MemorySecretStore({'OPENAI_API_KEY': 'secret-value'});
  final service = SecretTemplateService(store);
  expect(await service.resolve('{"apiKey":"\${OPENAI_API_KEY}"}'), '{"apiKey":"secret-value"}');
  expect(await service.resolve('{"value":"$OPENAI_API_KEY"}'), '{"value":"$OPENAI_API_KEY"}');
});

test('reports all missing names without partial output', () async {
  final service = SecretTemplateService(MemorySecretStore({'A': 'one'}));
  expect(await service.missingNames('\${A} \${B} \${C}'), ['B', 'C']);
});
```

- [ ] **Step 2: Run secret template tests and verify failure**

Run: `flutter test test/features/security/application/secret_template_service_test.dart`

Expected: FAIL with missing secret store/service.

- [ ] **Step 3: Implement Keychain namespacing and resolution**

Use service name `com.ruancanghui.nightelf`, account key `<vaultId>/<NAME>`, and macOS accessibility `first_unlock_this_device`. Validate placeholder names with `[A-Z_][A-Z0-9_]*`. Resolve in memory only; do not write resolved text to disk, logs, analytics, recent items, clipboard history owned by the app, or exceptions.

Define `MemorySecretStore` in the test support file with a copied in-memory map and complete read/write/delete/names behavior.

- [ ] **Step 4: Implement guarded full copy**

The confirmation sheet names the MCP resource, lists placeholder names without values, says the clipboard may contain secrets, and exposes Cancel/Copy. Missing secrets route to a Keychain editor instead of copying partial output. After author confirmation, resolve once and pass directly to `ClipboardService.writeText`; discard the local variable after the await. Test Cancel, missing secret, confirmed copy, invalid JSON, and clipboard failure.

Run: `dart format lib test && flutter analyze && flutter test test/features/security test/features/mcp/application/mcp_full_copy_test.dart`

Expected: all Keychain/template/full-copy tests PASS with a memory store in unit tests.

- [ ] **Step 5: Commit local secret support**

```bash
git add pubspec.yaml pubspec.lock lib/features/security lib/features/mcp test/features/security test/features/mcp
git commit -m "feat: protect local MCP secrets"
```

### Task 4: Implement the no-conflict one-click sync state machine

**Files:**
- Extend: `lib/features/git_sync/data/git_repository.dart`
- Extend: `lib/features/git_sync/data/process_git_repository.dart`
- Create: `lib/features/git_sync/domain/sync_state.dart`
- Create: `lib/features/git_sync/application/sync_orchestrator.dart`
- Create: `lib/features/git_sync/presentation/sync_status_button.dart`
- Create: `lib/features/git_sync/presentation/git_setup_sheet.dart`
- Create: `lib/features/git_sync/application/git_history_controller.dart`
- Create: `lib/features/git_sync/presentation/git_history_sheet.dart`
- Modify: `lib/features/shell/presentation/workbench_toolbar.dart`
- Test: `test/features/git_sync/application/sync_orchestrator_test.dart`
- Test: `test/features/git_sync/data/process_git_sync_test.dart`
- Test: `test/features/git_sync/application/git_history_controller_test.dart`

**Interfaces:**
- Adds repository methods `addPaths`, `commit`, `fastForward`, `mergeNoCommit`, `commitMerge`, `push`, and `setRemote`.
- Produces sync states `idle`, `saving`, `scanning`, `checkpointing`, `fetching`, `merging`, `awaitingConflictReview`, `pushing`, `success`, and `failure`.
- Consumes: `saveAllDocuments`, `SecretScanner`, `SecretIgnoreRepository`, and `Clock.now()`.
- Produces: `GitHistoryController.load(limit: 100)` and a read-only history sheet showing commit ID, message, author, timestamp, and changed paths.

- [ ] **Step 1: Write failing orchestrator transition tests**

```dart
test('dirty local branch checkpoints, fetches, and pushes in order', () async {
  final git = RecordingGitRepository(status: dirtyStatus, aheadBehind: const AheadBehind(ahead: 1, behind: 0));
  final orchestrator = SyncOrchestrator(git: git, scanner: cleanScanner, saveAll: saveAll, clock: fixedClock);
  await orchestrator.sync(vault);
  expect(git.calls, ['status', 'addPaths', 'commit', 'fetch', 'aheadBehind', 'push']);
  expect(orchestrator.state, isA<SyncSuccess>());
});

test('secret finding stops before add or commit', () async {
  final git = RecordingGitRepository(status: dirtyStatus);
  await SyncOrchestrator(git: git, scanner: findingScanner, saveAll: saveAll, clock: fixedClock).sync(vault);
  expect(git.calls, ['status']);
});
```

- [ ] **Step 2: Run sync tests and verify failure**

Run: `flutter test test/features/git_sync/application/sync_orchestrator_test.dart`

Expected: FAIL with missing orchestrator/state contracts.

- [ ] **Step 3: Implement explicit sync branches**

Use this decision table after save, scan, checkpoint, and fetch:

```text
ahead=0 behind=0 -> success
ahead>0 behind=0 -> push
ahead=0 behind>0 -> fast-forward, rescan/reindex, success
ahead>0 behind>0 -> merge --no-commit --no-ff with diff3 conflict style
remote branch absent -> push with upstream
```

Checkpoint message format is `sync: 2026-08-08 14:30 +0800`, produced from injected clock. Stage explicit status paths with `git add -- <paths>` after secret scan. Never stage `.ai-workbench/local`. Invoke merge as `git -c merge.conflictStyle=diff3 merge --no-commit --no-ff <upstream>`.

Wire the toolbar History action to `GitHistorySheet`. Load at most 100 commits initially, fetch the next page only on explicit author request, and keep the sheet read-only. Add controller tests for empty history, chronological parsing, changed-path grouping, and command failure.

- [ ] **Step 4: Test against real local remotes**

Cover clean equal branches, initial push, local ahead, remote ahead, clean divergence, offline fetch failure, authentication-like stderr mapping, detached HEAD, missing Git, missing remote setup, and save failure. Assert state histories and final commit graph.

Run: `dart format lib test && flutter analyze && flutter test test/features/git_sync/application/sync_orchestrator_test.dart test/features/git_sync/data/process_git_sync_test.dart`

Expected: all no-conflict sync tests PASS.

- [ ] **Step 5: Commit one-click no-conflict sync**

```bash
git add lib/features/git_sync lib/features/shell/presentation/workbench_toolbar.dart test/features/git_sync
git commit -m "feat: add one-click Git sync"
```

### Task 5: Collect three-way conflicts and apply author resolutions

**Files:**
- Create: `lib/features/git_sync/domain/conflict_review.dart`
- Create: `lib/features/git_sync/data/diff3_conflict_parser.dart`
- Create: `lib/features/git_sync/application/conflict_review_controller.dart`
- Test: `test/features/git_sync/data/diff3_conflict_parser_test.dart`
- Test: `test/features/git_sync/application/conflict_review_controller_test.dart`

**Interfaces:**
- Produces: `ConflictReviewFile(path, kind, base, ours, theirs, blocks, resolution, authorConfirmed)`.
- Produces: `ConflictBlock(id, commonBefore, ours, base, theirs, commonAfter, selected)`.
- Produces selections `unresolved`, `ours`, `theirs`, `both`, and `manual`.
- Produces controller `load`, `selectBlock`, `setManualText`, `selectWholeFile`, `confirmFile`, `abortReview`, and `finishReview`.

- [ ] **Step 1: Write failing diff3 parsing tests**

```dart
test('parses base, ours, and theirs without keeping marker lines', () {
  const text = 'before\n'
      '<<<<<<< HEAD\n'
      'ours\n'
      '||||||| base\n'
      'base\n'
      '=======\n'
      'theirs\n'
      '>>>>>>> origin/main\n'
      'after\n';
  final parsed = const Diff3ConflictParser().parse(text);
  expect(parsed.blocks.single.ours, 'ours\n');
  expect(parsed.blocks.single.base, 'base\n');
  expect(parsed.blocks.single.theirs, 'theirs\n');
  expect(parsed.render({0: ConflictSelection.theirs}), 'before\ntheirs\nafter\n');
});
```

- [ ] **Step 2: Run conflict tests and verify failure**

Run: `flutter test test/features/git_sync/data/diff3_conflict_parser_test.dart test/features/git_sync/application/conflict_review_controller_test.dart`

Expected: FAIL with missing conflict types/parser/controller.

- [ ] **Step 3: Implement conflict loading and resolution safety**

For every `git ls-files -u` path, read stages 1/2/3. Strict-decode each as UTF-8. If any stage is binary, classify the file binary and offer whole-file ours/theirs/keep-both only. For text, parse the diff3 working file and verify stage content hashes match the collected review metadata.

`selectWholeFile` requires a separate confirmation callback. `keep-both` writes ours to the original and theirs to `<stem>-remote-conflict-<UTC timestamp><extension>`, then stages both. `finishReview` must reject any unresolved or unconfirmed file.

- [ ] **Step 4: Test Workflow separation, external conflicts, abort, and resume**

Add tests that `.mmd` and its layout JSON appear as two entries, binary keep-both is recoverable, manual text cannot contain unresolved marker lines, external two-way conflict uses empty base, abort calls `git merge --abort`, and a controller reconstructed from an in-progress merge reloads the same conflict queue.

Run: `dart format lib test && flutter analyze && flutter test test/features/git_sync/data/diff3_conflict_parser_test.dart test/features/git_sync/application/conflict_review_controller_test.dart`

Expected: all conflict domain/controller tests PASS.

- [ ] **Step 5: Commit conflict resolution state**

```bash
git add lib/features/git_sync/domain/conflict_review.dart lib/features/git_sync/data/diff3_conflict_parser.dart lib/features/git_sync/application/conflict_review_controller.dart test/features/git_sync
git commit -m "feat: add author-controlled conflict resolution"
```

### Task 6: Build conflict review UI and resume sync only after approval

**Files:**
- Create: `lib/features/git_sync/presentation/conflict_review_workspace.dart`
- Create: `lib/features/git_sync/presentation/conflict_file_list.dart`
- Create: `lib/features/git_sync/presentation/conflict_block_view.dart`
- Create: `lib/features/git_sync/presentation/binary_conflict_view.dart`
- Modify: `lib/features/git_sync/application/sync_orchestrator.dart`
- Modify: `lib/features/resources/application/resource_workspace_registry.dart`
- Modify: `lib/features/editor/application/document_session.dart`
- Test: `test/features/git_sync/presentation/conflict_review_workspace_test.dart`
- Test: `test/features/git_sync/git_conflict_journey_test.dart`

**Interfaces:**
- Produces: one non-closable workspace tab while unresolved conflicts exist.
- Adds orchestrator `resumeAfterConflictReview()` and `abortConflictReview()`.
- Produces final author confirmation summary with file count, ours/theirs/manual counts, and destination remote/branch.

- [ ] **Step 1: Write failing UI safety tests**

```dart
testWidgets('push remains unavailable until every conflict is confirmed', (tester) async {
  final controller = conflictControllerWithTwoFiles();
  await tester.pumpWidget(conflictReviewHarness(controller));
  expect(find.widgetWithText(PushButton, '完成审核并同步'), findsOneWidget);
  expect(tester.widget<PushButton>(find.widgetWithText(PushButton, '完成审核并同步')).onPressed, isNull);
  controller.resolveAndConfirmAll();
  await tester.pump();
  expect(tester.widget<PushButton>(find.widgetWithText(PushButton, '完成审核并同步')).onPressed, isNotNull);
});
```

- [ ] **Step 2: Run presentation/journey tests and verify failure**

Run: `flutter test test/features/git_sync/presentation/conflict_review_workspace_test.dart test/features/git_sync/git_conflict_journey_test.dart`

Expected: FAIL with missing conflict presentation.

- [ ] **Step 3: Implement the Git-style review workspace**

Left pane: conflict file queue with resource type and resolution state. Main pane: block-by-block Base/本机/远端 comparison, selection buttons, and manual editor. Binary pane: metadata and three whole-file choices. Footer: Abort, unresolved count, and disabled/enabled Finish button. Whole-file choices and final finish each require separate author confirmation.

After finish: write/stage every confirmed resolution, assert `listConflicts` is empty, create merge commit `sync: resolve <N> conflicts`, push, refresh Vault/index, and move to success. On any failure after writing but before push, remain in recoverable merge state and show Retry; never abort automatically.

Route `DocumentSession.externalConflict` into the same review workspace with origin `externalFile`, an empty Base column, in-memory editor text as 本机, and disk text as 外部版本. Author confirmation updates the session buffer/file according to the selected resolution; it does not invoke Git unless the file is also part of an active Git conflict.

- [ ] **Step 4: Test the real two-clone conflict journey**

Create a bare remote plus home/work clones. Push a shared Prompt, edit the same line differently in both, push home, sync work, choose remote for one block and manual for another, confirm, push, pull home, and assert exact merged contents. Repeat with binary keep-both and Workflow source/layout conflicts.

Run: `dart format lib test && flutter analyze && flutter test test/features/git_sync test/features/security test/features/mcp && flutter build macos --debug`

Expected: all Phase 5 tests PASS and debug build succeeds.

- [ ] **Step 5: Commit Phase 5 integration**

```bash
git add lib/features/git_sync lib/features/resources test/features/git_sync
git commit -m "feat: review and resolve sync conflicts"
```

## Phase 5 Final Verification

- [ ] Run: `flutter analyze`
- [ ] Run: `flutter test`
- [ ] Run: `flutter build macos --debug`
- [ ] Run the two-clone text, binary, and Workflow conflict integration tests individually and record their exact PASS output.
- [ ] Manually verify that Cancel and Abort preserve local work, unresolved conflicts cannot push, full MCP copy requires confirmation, and Git commits contain no test secret values.
