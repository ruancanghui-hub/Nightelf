# AI Workbench Phase 6: Integration, Performance, Accessibility, and Internal Release Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Compose every feature into the production app, prove the complete local-first/two-device journey, meet performance and accessibility budgets, document the system, and create a reproducible unsigned internal macOS release artifact.

**Architecture:** One composition root wires real adapters to tested controllers while integration tests override them with temporary filesystem, Git, Keychain, WebView, and clock implementations. Release work is intentionally direct-distribution and unsigned; App Store sandboxing, Developer ID signing, notarization, and a final brand icon require separate owner credentials/approval.

**Tech Stack:** Full Phase 1–5 stack, Flutter integration_test, macOS runner entitlements, XCTest-backed Flutter runner, golden/widget tests, `flutter build macos --release`, and `ditto` packaging.

## Global Constraints

- Begin only after all Phase 5 verification commands pass.
- Keep the first release macOS-only and direct-distribution; do not silently add App Store entitlements or signing credentials.
- Never include a real Vault, WebView profile, secret, SSH key, Git credential, local cache, generated test repository, or developer path in the app bundle.
- Do not weaken conflict confirmation, secret scanning, source-first Workflow behavior, or Website isolation to make end-to-end tests easier.
- Do not update a golden image without opening and comparing it to the approved visual direction.
- Do not claim a signed/notarized public release; the artifact from this phase is an unsigned internal build.

---

### Task 1: Create the production composition root and startup recovery flow

**Files:**
- Create: `lib/app/app_dependencies.dart`
- Create: `lib/app/app_providers.dart`
- Create: `lib/app/startup_controller.dart`
- Modify: `lib/app/ai_workbench_app.dart`
- Modify: `lib/main.dart`
- Modify: `macos/Runner/DebugProfile.entitlements`
- Modify: `macos/Runner/Release.entitlements`
- Modify: `macos/Runner/Info.plist`
- Test: `test/app/startup_controller_test.dart`
- Test: `test/app/app_composition_test.dart`

**Interfaces:**
- Produces: `AppDependencies.production()` containing real repositories/adapters and `AppDependencies.test(...)` overrides.
- Produces: startup states `booting`, `welcome`, `openingLastVault`, `ready`, and `recoverableFailure`.
- Produces: one active Vault composition lifecycle that disposes watchers, WebViews, SQLite, editor sessions, and Git operations in order.

- [ ] **Step 1: Write failing composition and startup tests**

```dart
test('startup restores the last valid Vault before showing the shell', () async {
  final dependencies = testDependencies(lastVault: fixture.handle);
  final controller = StartupController(dependencies);
  await controller.start();
  expect(controller.state, isA<StartupReady>());
  expect((controller.state as StartupReady).vault.id, fixture.handle.manifest.id);
});

test('startup failure offers retry, choose another Vault, and forget path', () async {
  final controller = StartupController(testDependencies(openFailure: const InvalidVaultException('bad marker')));
  await controller.start();
  final state = controller.state as StartupRecoverableFailure;
  expect(state.actions, containsAll([StartupRecoveryAction.retry, StartupRecoveryAction.chooseVault, StartupRecoveryAction.forgetPath]));
});
```

- [ ] **Step 2: Run app tests and verify missing composition fails**

Run: `flutter test test/app`

Expected: FAIL with missing dependencies/startup controller.

- [ ] **Step 3: Wire real dependencies and direct-distribution permissions**

Construct each service exactly once per active Vault and expose it through provider overrides. Disable App Sandbox in DebugProfile and Release entitlements for this direct-distribution build because persistent arbitrary-folder access and `/usr/bin/git` process execution are core requirements. Keep Hardened Runtime/signing out of source unless owner credentials are explicitly configured. Set `CFBundleDisplayName` to `AI 工作台`, bundle ID to `com.ruancanghui.nightelf`, and minimum system version to `13.0`.

On Vault switch: flush editor sessions, stop watcher, close Website tabs, close SQLite, dispose metadata/index repositories, then open the new Vault. If any flush fails, cancel the switch and show the exact file.

- [ ] **Step 4: Verify lifecycle ordering and no developer paths**

Tests must record disposal order, reject a Vault switch on save failure, restore after invalid last path, and search the generated configuration strings for the current home directory. Run `plutil -p` on both entitlements and `Info.plist` to verify intended values.

Run: `dart format lib test && flutter analyze && flutter test test/app && plutil -p macos/Runner/DebugProfile.entitlements && plutil -p macos/Runner/Release.entitlements && plutil -p macos/Runner/Info.plist`

Expected: app tests PASS and plist commands exit 0.

- [ ] **Step 5: Commit production composition**

```bash
git add lib/app lib/main.dart macos/Runner test/app
git commit -m "feat: compose production workbench app"
```

### Task 2: Prove the complete local Vault and two-device sync journeys

**Files:**
- Create: `integration_test/support/workbench_driver.dart`
- Create: `integration_test/support/two_clone_fixture.dart`
- Create: `integration_test/local_vault_journey_test.dart`
- Create: `integration_test/two_device_conflict_journey_test.dart`
- Create: `integration_test/restart_recovery_journey_test.dart`

**Interfaces:**
- Produces: deterministic driver actions `createVault`, `createPrompt`, `importSkill`, `createMcp`, `createLink`, `createWorkflow`, `relateResources`, `search`, `sync`, `resolveConflict`, and `restartHarness`.
- Produces: two-clone fixture exposing `homeClone`, `workClone`, and `bareRemote` with isolated Git identity.

- [ ] **Step 1: Write the failing local journey skeleton with real assertions**

```dart
testWidgets('creates, relates, finds, and restores all five resource types', (tester) async {
  final driver = await WorkbenchDriver.launch(tester);
  final vault = await driver.createVault('工作资源');
  final prompt = await driver.createPrompt('代码审查助手', '# 角色\n审查代码');
  final skill = await driver.importSkill(skillFixturePath);
  final mcp = await driver.createMcp('Claude MCP', '{"mcpServers": {}}');
  final link = await driver.createLink('MDN', 'https://developer.mozilla.org/');
  final workflow = await driver.createWorkflow('发布流程', 'flowchart TD\na-->b');
  await driver.relateResources(workflow.id, [prompt.id, skill.id, mcp.id, link.id]);
  expect(await driver.search('发布流程'), contains(workflow.id));
  await driver.restartHarness();
  expect(driver.activeVaultPath, vault.path);
  expect(driver.relatedResourceIds(workflow.id), [prompt.id, skill.id, mcp.id, link.id]);
});
```

- [ ] **Step 2: Run journeys and verify the driver/flows fail**

Run: `flutter test integration_test/local_vault_journey_test.dart -d macos`

Expected: FAIL until driver hooks and complete feature wiring exist.

- [ ] **Step 3: Implement deterministic integration hooks**

Inject file/directory selections through test providers rather than automating native pickers. Use a memory Keychain and deterministic clock. Use the real filesystem, codecs, scanner, index, and Git process gateway. Use a fake WebView adapter in the full journey; keep the dedicated Phase 4 native WebView test for platform coverage.

- [ ] **Step 4: Implement and pass the two-device/restart journeys**

The two-device test must edit the same Prompt line differently, push home, sync work, verify push is disabled, select remote for one block and manual for another, confirm every file, push, fetch home, and assert exact merged content. The restart test must interrupt an in-progress merge, reconstruct the application, reopen conflict review, finish, and push.

Run: `flutter test integration_test/local_vault_journey_test.dart -d macos && flutter test integration_test/two_device_conflict_journey_test.dart -d macos && flutter test integration_test/restart_recovery_journey_test.dart -d macos`

Expected: all three journeys PASS.

- [ ] **Step 5: Commit end-to-end coverage**

```bash
git add integration_test
git commit -m "test: cover complete workbench journeys"
```

### Task 3: Add repeatable performance budgets and optimize measured bottlenecks

**Files:**
- Create: `test/performance/vault_fixture_generator.dart`
- Create: `test/performance/search_index_benchmark_test.dart`
- Create: `test/performance/workflow_canvas_benchmark_test.dart`
- Create: `test/performance/resource_scan_benchmark_test.dart`
- Modify only if measurements fail: scanner/index/canvas files named by the failing benchmark profile.

**Interfaces:**
- Produces: deterministic fixture generator for 10,000 text resources and Workflow graphs of 200 and 500 nodes.
- Produces: benchmark output with elapsed times, fixture size, Flutter/Dart version, and machine architecture.

- [ ] **Step 1: Write performance tests before optimization**

```dart
test('10k resource FTS query returns within the release budget', () async {
  final records = generateResourceRecords(count: 10000, seed: 42);
  final index = SqliteSearchIndex.inMemory();
  addTearDown(index.close);
  await index.rebuild(records);
  final watch = Stopwatch()..start();
  final hits = await index.query(SearchQuery(text: '审查 performance', limit: 50));
  watch.stop();
  expect(hits, isNotEmpty);
  expect(watch.elapsed, lessThan(const Duration(milliseconds: 500)));
});
```

Set budgets: 10k scan under 8 seconds, index rebuild under 10 seconds, warm query under 500 ms, 500-node parse/layout under 500 ms, and 200-node first canvas pump under 1 second on the project Mac in release-profile mode.

- [ ] **Step 2: Run benchmarks and record actual baseline**

Run: `flutter test test/performance --reporter expanded`

Expected: tests either PASS or identify the exact failing budget; record every elapsed value before code changes.

- [ ] **Step 3: Optimize only measured failures**

Allowed changes: bounded filesystem concurrency of 16, batched SQLite transactions of 500 records, prepared statements, content truncation at 256 KiB per indexed file with an explicit `isContentTruncated` flag, memoized text measurement, one edge painter, visible-node culling, and minimap repaint throttling to 10 Hz. Do not change public behavior or skip files silently.

- [ ] **Step 4: Rerun benchmarks and full regression tests**

Run: `dart format lib test && flutter analyze && flutter test test/performance --reporter expanded && flutter test`

Expected: every budget PASS and the full suite remains green.

- [ ] **Step 5: Commit measured performance work**

```bash
git add test/performance lib
git commit -m "perf: meet large vault interaction budgets"
```

### Task 4: Verify accessibility, themes, responsive layout, and visual fidelity

**Files:**
- Create: `test/goldens/workbench_home_dark.png`
- Create: `test/goldens/workbench_home_light.png`
- Create: `test/goldens/workflow_canvas_dark.png`
- Create: `test/goldens/conflict_review_dark.png`
- Create: `test/visual/workbench_golden_test.dart`
- Create: `test/accessibility/workbench_semantics_test.dart`
- Create: `test/accessibility/workbench_keyboard_test.dart`
- Modify only after inspection: theme/presentation files responsible for visible mismatches.

**Interfaces:**
- Produces: four reviewed golden baselines at `1440x1024`, device pixel ratio `1.0`, deterministic clock, and fake data.
- Produces: semantics/keyboard coverage for every core journey.

- [ ] **Step 1: Write failing golden and semantics tests**

```dart
testWidgets('dark workbench matches approved direction', (tester) async {
  await tester.binding.setSurfaceSize(const Size(1440, 1024));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(goldenWorkbench(themeMode: ThemeMode.dark));
  await tester.pumpAndSettle();
  await expectLater(find.byType(WorkbenchShell), matchesGoldenFile('../goldens/workbench_home_dark.png'));
});
```

- [ ] **Step 2: Generate candidate goldens and inspect them manually**

Run: `flutter test test/visual/workbench_golden_test.dart --update-goldens`

Open every generated PNG and compare against `docs/superpowers/specs/assets/ai-workbench-visual-direction.png`. Inspect sidebar width/material, toolbar spacing, tab selection, opaque reading surfaces, typography, dividers, focus blue, canvas controls, inspector density, and conflict action hierarchy. Do not accept the generated files until these checks are written into the task handoff.

- [ ] **Step 3: Fix visible mismatches and accessibility failures**

At 1440x1024 match the approved information density without copying mock data errors. At 980 and 760 widths verify inspector/sidebar collapse. Ensure minimum pointer target 28x28 points for compact controls and 44x44 for primary controls, text contrast appropriate to system high-contrast mode, logical focus traversal, and semantic labels for every icon-only control.

- [ ] **Step 4: Run visual/accessibility suites in all system preferences**

Test light, dark, high contrast, text scale 1.0/1.3/1.6, reduced motion, and reduced transparency. Keyboard-only journey: sidebar → list → open → editor → save → tabs → sync → conflict review → cancel.

Run: `dart format lib test && flutter analyze && flutter test test/visual test/accessibility`

Expected: all golden, semantics, and keyboard tests PASS.

- [ ] **Step 5: Commit reviewed visual baselines**

```bash
git add test/goldens test/visual test/accessibility lib
git commit -m "test: verify workbench visual accessibility"
```

### Task 5: Document operation, privacy, Vault format, and recovery

**Files:**
- Create: `README.md`
- Create: `docs/architecture.md`
- Create: `docs/vault-format.md`
- Create: `docs/git-sync-and-conflicts.md`
- Create: `docs/privacy-and-secrets.md`
- Create: `docs/troubleshooting.md`
- Test: `test/documentation/documentation_links_test.dart`

**Interfaces:**
- Produces: user and contributor documentation matching implemented commands, paths, schema version, and product boundaries.

- [ ] **Step 1: Write a failing documentation link test**

Create a Dart test that scans Markdown links with relative targets, resolves them from the containing document, and fails for a missing local target. Also assert README contains `flutter run -d macos`, `flutter test`, `flutter build macos --release`, and the statement `AI 工作台不会执行提示词、SKILL、MCP 或 Workflow。`.

- [ ] **Step 2: Run the documentation test and verify failure**

Run: `flutter test test/documentation/documentation_links_test.dart`

Expected: FAIL because the documents do not exist.

- [ ] **Step 3: Write exact user and developer documentation**

README: product purpose, screenshot, requirements, run/test/build commands, internal-release warning, and feature list. Architecture: module/interface map and data flow. Vault format: every directory/file, schema `1`, front matter examples, sidecar identity, layout JSON, ignored local state, and migration policy. Git guide: remote setup, sync state machine, conflict review, abort/recovery, and company policy warning. Privacy guide: Keychain, placeholders, scanning, clipboard warning, WebView cookies, and no telemetry. Troubleshooting: Git missing/auth/offline, invalid Vault, corrupt metadata/index rebuild, JSON/Mermaid diagnostics, WebView load errors, merge recovery, and backup instructions.

- [ ] **Step 4: Verify docs against code constants**

Run: `dart format test/documentation && flutter test test/documentation/documentation_links_test.dart && rg -n "T[B]D|T[O]DO|implement la[t]er" README.md docs`

Expected: link test PASS and `rg` returns no unresolved planning markers in user documentation.

- [ ] **Step 5: Commit documentation**

```bash
git add README.md docs test/documentation
git commit -m "docs: explain workbench operation and recovery"
```

### Task 6: Produce and inspect the unsigned internal release artifact

**Files:**
- Create: `tool/verify_release_bundle.sh`
- Create: `docs/internal-release-checklist.md`
- Generated, not committed: `dist/Nightelf-macos-arm64.zip`
- Modify: `.gitignore`

**Interfaces:**
- Produces: repeatable bundle verification script returning non-zero on leaked files, incorrect metadata, unexpected entitlements, missing executable, or invalid bundle structure.

- [ ] **Step 1: Write the release verification script before building**

The script must accept one `.app` path, run `plutil` against `Contents/Info.plist`, verify bundle ID `com.ruancanghui.nightelf`, display name `AI 工作台`, minimum system `13.0`, executable presence, and absence of `.env`, `.git`, `.ai-workbench`, `user-context`, `generated_images`, `OPENAI_API_KEY`, developer home paths, and test fixtures. It must run `codesign -d --entitlements :-` and report that the build is unsigned/ad-hoc rather than notarized.

- [ ] **Step 2: Run the full verification gate before release build**

Run: `flutter clean && flutter pub get && dart format --output=none --set-exit-if-changed lib test integration_test && flutter analyze && flutter test && flutter test integration_test/local_vault_journey_test.dart -d macos && flutter test integration_test/two_device_conflict_journey_test.dart -d macos && flutter test integration_test/restart_recovery_journey_test.dart -d macos`

Expected: every command exits 0. Stop immediately on the first failure.

- [ ] **Step 3: Build, verify, and package**

```bash
flutter build macos --release
bash tool/verify_release_bundle.sh build/macos/Build/Products/Release/nightelf.app
mkdir -p dist
ditto -c -k --sequesterRsrc --keepParent build/macos/Build/Products/Release/nightelf.app dist/Nightelf-macos-arm64.zip
shasum -a 256 dist/Nightelf-macos-arm64.zip > dist/Nightelf-macos-arm64.zip.sha256
```

Add `dist/` to `.gitignore`. Do not commit generated archives.

- [ ] **Step 4: Perform the internal release smoke test**

Extract the ZIP to a new temporary directory, launch the app, create a new Vault, create/open all five resource types, open one local deterministic website fixture, render one Workflow, configure a temporary bare Git remote, sync, quit, relaunch, and verify restoration. Record macOS version, architecture, app SHA-256, test counts, and the unsigned/not-notarized limitation in `docs/internal-release-checklist.md`.

- [ ] **Step 5: Commit release tooling and checklist**

```bash
git add .gitignore tool/verify_release_bundle.sh docs/internal-release-checklist.md
git commit -m "chore: add internal macOS release gate"
```

## Phase 6 Final Verification

- [ ] Run the exact full gate from Task 6 Step 2 again after the final commit.
- [ ] Run: `flutter build macos --release`
- [ ] Run: `bash tool/verify_release_bundle.sh build/macos/Build/Products/Release/nightelf.app`
- [ ] Compare `git status --short` against the intended untracked local files and verify no generated archive is staged.
- [ ] Publish implementation only after reporting exact analyzer, test, integration, build, bundle, and smoke-test evidence.
