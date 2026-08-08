# AI Workbench Phase 4: Website and Workflow Workspaces Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add saved Website resources with an isolated in-app WKWebView and Workflow resources with tested Mermaid source parsing plus a Flutter infinite canvas.

**Architecture:** Link records remain Markdown files while browser sessions are device-local controller state. Workflow source and layout are deliberately separate: a conservative Mermaid flowchart parser creates a graph model, and a pure Flutter canvas renders and repositions that model without rewriting source structure.

**Tech Stack:** Phase 1–3 stack plus webview_flutter 4.14.1/WKWebView, url_launcher, Flutter InteractiveViewer, CustomPainter, Stack, TransformationController, dart:convert, flutter_test and macOS integration tests.

## Global Constraints

- Begin only after all Phase 3 verification commands pass.
- Accept only `http` and `https` Website URLs.
- Never expose Vault paths, filesystem channels, Git credentials, or Workflow canvas channels to Website WebViews.
- Do not execute Website scripts outside WKWebView's normal page environment.
- Do not execute Workflow nodes or actions.
- Treat Mermaid source as authoritative and layout JSON as presentation-only state.
- Preserve invalid Workflow source and retain the last valid graph in memory.

---

### Task 1: Implement Website record CRUD and URL validation

**Files:**
- Create: `lib/features/links/domain/link_document.dart`
- Create: `lib/features/links/domain/link_validation.dart`
- Create: `lib/features/links/data/link_markdown_codec.dart`
- Create: `lib/features/links/data/link_repository.dart`
- Create: `lib/features/links/data/file_link_repository.dart`
- Test: `test/features/links/domain/link_validation_test.dart`
- Test: `test/features/links/data/link_markdown_codec_test.dart`
- Test: `test/features/links/data/file_link_repository_test.dart`

**Interfaces:**
- Produces: `LinkDocument(id, title, uri, description, tags, notes, relativePath)`.
- Produces: `LinkValidation.validate(String) -> LinkValidationResult`.
- Produces: repository `create`, `read`, `save`, `duplicate`, and `moveToTrash`.

- [ ] **Step 1: Write failing validation and codec tests**

```dart
test('normalizes a bare https host path and rejects unsafe schemes', () {
  expect(LinkValidation.validate('https://example.com/docs').uri, Uri.parse('https://example.com/docs'));
  expect(LinkValidation.validate('javascript:alert(1)').error, '仅支持 http 或 https 链接');
  expect(LinkValidation.validate('file:///tmp/secret').isValid, isFalse);
});

test('link Markdown round-trips URL and notes', () {
  final document = LinkDocument(
    id: 'l1', title: 'MDN 文档', uri: Uri.parse('https://developer.mozilla.org/'),
    description: 'Web 参考', tags: ['文档'], notes: '常用查询入口', relativePath: 'links/mdn.md',
  );
  expect(const LinkMarkdownCodec().decode(const LinkMarkdownCodec().encode(document), document.relativePath), document);
});
```

- [ ] **Step 2: Run Link tests and verify failure**

Run: `flutter test test/features/links`

Expected: FAIL with missing Link contracts.

- [ ] **Step 3: Implement safe validation, codec, and repository**

Require an absolute URI with a non-empty host and scheme exactly `http` or `https`. Lowercase only scheme and host; preserve path/query/fragment spelling. Encode deterministic YAML front matter with `id`, `title`, `url`, `description`, and `tags`; store notes in the Markdown body.

- [ ] **Step 4: Verify CRUD, duplicates, and recovery**

Tests must cover Unicode URLs accepted by Dart URI parsing, empty host rejection, filename collisions, duplicate ID regeneration, trash and Undo.

Run: `dart format lib test && flutter analyze && flutter test test/features/links`

Expected: all Link tests PASS.

- [ ] **Step 5: Commit Website record storage**

```bash
git add lib/features/links test/features/links
git commit -m "feat: add saved website records"
```

### Task 2: Build the isolated WKWebView browser workspace

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/features/web/domain/web_navigation_state.dart`
- Create: `lib/features/web/application/web_view_adapter.dart`
- Create: `lib/features/web/application/web_session_controller.dart`
- Create: `lib/features/web/data/wk_web_view_adapter.dart`
- Create: `lib/features/web/presentation/web_workspace.dart`
- Test: `test/features/web/application/web_session_controller_test.dart`
- Test: `test/features/web/presentation/web_workspace_test.dart`
- Create: `test/features/web/support/recording_web_view_adapter.dart`
- Create: `integration_test/web_workspace_macos_test.dart`

**Interfaces:**
- Produces: adapter `load(Uri)`, `goBack`, `goForward`, `reload`, `currentUri`, and navigation-state stream.
- Produces: `WebNavigationState(uri, title, canGoBack, canGoForward, isLoading, errorMessage)`.
- Produces: controller `navigate(String)`, `back`, `forward`, `reload`, `copyUrl`, and `openExternally`.

- [ ] **Step 1: Add WebView dependencies and write failing controller tests**

Run: `flutter pub add webview_flutter webview_flutter_wkwebview url_launcher`

```dart
test('navigate validates before calling the adapter', () async {
  final adapter = RecordingWebViewAdapter();
  final controller = WebSessionController(adapter: adapter, clipboard: clipboard, systemOpen: systemOpen);
  await controller.navigate('javascript:alert(1)');
  expect(adapter.loadedUris, isEmpty);
  expect(controller.state.errorMessage, '仅支持 http 或 https 链接');
});
```

- [ ] **Step 2: Run Web controller/widget tests and verify failure**

Run: `flutter test test/features/web`

Expected: FAIL with missing Web session contracts.

- [ ] **Step 3: Implement adapter and controller isolation**

Create one `WebViewController` per Website tab. Set JavaScript mode to unrestricted for normal websites but register no JavaScript channels. Use a navigation delegate to reject `file:`, custom schemes, and new-window requests that are not `http/https`; send external application schemes to `SystemOpenService` only after an explicit user action.

Define `RecordingWebViewAdapter` in the test support file with `loadedUris`, navigation call counters, a controllable state stream, and no platform dependency.

Do not set custom cookies, inject scripts, attach filesystem pickers, or share the Workflow controller. Let WKWebView maintain device-local cookies in its default persistent data store.

- [ ] **Step 4: Implement toolbar and native macOS integration test**

`WebWorkspace` renders Back, Forward, Reload/Stop, address field, Copy URL, and External Browser. Unit widget tests use a fake adapter. The macOS integration test loads a deterministic `data:` test page through a test-only adapter or local loopback fixture, verifies title/navigation state, and never contacts a public website.

Run: `dart format lib test integration_test && flutter analyze && flutter test test/features/web && flutter test integration_test/web_workspace_macos_test.dart -d macos`

Expected: controller/widget tests and the macOS WebView integration test PASS.

- [ ] **Step 5: Commit the Website workspace**

```bash
git add pubspec.yaml pubspec.lock lib/features/web test/features/web integration_test/web_workspace_macos_test.dart
git commit -m "feat: add isolated website workspace"
```

### Task 3: Parse the supported Mermaid flowchart subset

**Files:**
- Create: `lib/features/workflows/domain/workflow_graph.dart`
- Create: `lib/features/workflows/domain/workflow_diagnostic.dart`
- Create: `lib/features/workflows/data/mermaid_flowchart_parser.dart`
- Test: `test/features/workflows/data/mermaid_flowchart_parser_test.dart`

**Interfaces:**
- Produces: `WorkflowDirection { topDown, bottomUp, leftRight, rightLeft }`.
- Produces: `WorkflowNode(id, label, shape)` where shape is `rectangle`, `rounded`, `diamond`, or `plain`.
- Produces: `WorkflowEdge(id, fromId, toId, label, style)` where style is `solid`, `dotted`, or `line`.
- Produces: `WorkflowGraph(direction, nodes, edges)`.
- Produces: `MermaidParseResult.success(graph)` or `failure(List<WorkflowDiagnostic(line, column, message)>)`.

- [ ] **Step 1: Write failing parser tests for the exact supported grammar**

```dart
test('parses common nodes, labels, directions, and edges', () {
  const source = '''flowchart TD
draft[读取内容草稿] --> check{内容检查}
check -->|通过| adapt(多平台适配)
adapt -.-> output[生成发布文件]
''';
  final result = const MermaidFlowchartParser().parse(source);
  expect(result.graph!.direction, WorkflowDirection.topDown);
  expect(result.graph!.nodes.map((n) => n.id), ['draft', 'check', 'adapt', 'output']);
  expect(result.graph!.edges[1].label, '通过');
  expect(result.graph!.edges[2].style, WorkflowEdgeStyle.dotted);
});

test('rejects unsupported subgraph without losing source location', () {
  final result = const MermaidFlowchartParser().parse('flowchart TD\nsubgraph A\nend');
  expect(result.diagnostics.single.line, 2);
  expect(result.diagnostics.single.message, contains('首版暂不支持 subgraph'));
});
```

- [ ] **Step 2: Run parser tests and verify failure**

Run: `flutter test test/features/workflows/data/mermaid_flowchart_parser_test.dart`

Expected: FAIL with missing parser and graph models.

- [ ] **Step 3: Implement a line-oriented conservative parser**

Support headers `flowchart` or `graph` followed by `TD`, `TB`, `BT`, `LR`, or `RL`; ignore blank lines and lines starting `%%`; allow semicolon-separated statements. Support node identifiers matching `[A-Za-z_][A-Za-z0-9_-]*`, node forms `id[label]`, `id(label)`, `id{label}`, bare `id`, and edges `-->`, `---`, `-.->` with optional `|label|`.

Reject unsupported syntax with diagnostics rather than guessing. Preserve first declaration order. A later node declaration may fill a label/shape for an earlier bare reference but may not redefine it inconsistently.

- [ ] **Step 4: Add malformed and Unicode label coverage**

Test missing header, missing target, duplicate conflicting declaration, unknown direction, comments, semicolons, Unicode labels, whitespace, and empty graph.

Run: `dart format lib test && flutter analyze && flutter test test/features/workflows/data/mermaid_flowchart_parser_test.dart`

Expected: all parser tests PASS.

- [ ] **Step 5: Commit the Mermaid parser**

```bash
git add lib/features/workflows/domain lib/features/workflows/data/mermaid_flowchart_parser.dart test/features/workflows/data
git commit -m "feat: parse Mermaid workflow graphs"
```

### Task 4: Persist Workflow layout and implement the Flutter infinite canvas

**Files:**
- Create: `lib/features/workflows/domain/workflow_layout.dart`
- Create: `lib/features/workflows/data/workflow_layout_repository.dart`
- Create: `lib/features/workflows/data/json_workflow_layout_repository.dart`
- Create: `lib/features/workflows/application/workflow_canvas_controller.dart`
- Create: `lib/features/workflows/presentation/workflow_canvas.dart`
- Create: `lib/features/workflows/presentation/workflow_node_card.dart`
- Create: `lib/features/workflows/presentation/workflow_edge_painter.dart`
- Create: `lib/features/workflows/presentation/workflow_minimap.dart`
- Test: `test/features/workflows/data/json_workflow_layout_repository_test.dart`
- Test: `test/features/workflows/application/workflow_canvas_controller_test.dart`
- Test: `test/features/workflows/presentation/workflow_canvas_test.dart`

**Interfaces:**
- Produces: `WorkflowViewport(offsetX, offsetY, scale)`.
- Produces: plain Dart `CanvasPoint(x, y)`, plus `WorkflowLayout(workflowId, positions, viewport, collapsedNodeIds)`.
- Produces: controller `loadGraph`, `moveNode`, `setViewport`, `fitToView`, `selectNodes`, and `persist`.

- [ ] **Step 1: Write failing layout and controller tests**

```dart
test('manual node positions round-trip independently from source', () async {
  final repository = JsonWorkflowLayoutRepository(root: vaultRoot, writer: AtomicFileWriter());
  const layout = WorkflowLayout(
    workflowId: 'w1',
    positions: {'draft': CanvasPoint(100, 80), 'check': CanvasPoint(100, 240)},
    viewport: WorkflowViewport(offsetX: 20, offsetY: 40, scale: 1.25),
    collapsedNodeIds: {},
  );
  await repository.save(layout);
  expect(await repository.load('w1'), layout);
});
```

- [ ] **Step 2: Run canvas tests and verify failure**

Run: `flutter test test/features/workflows/data/json_workflow_layout_repository_test.dart test/features/workflows/application/workflow_canvas_controller_test.dart`

Expected: FAIL with missing layout and controller types.

- [ ] **Step 3: Implement layout persistence and deterministic auto-layout**

Store `.ai-workbench/workflow-layouts/<workflowId>.json` with schema version `1`. Serialize doubles explicitly and sort node IDs. For nodes lacking stored positions, use a deterministic layered layout based on graph direction, 220-point node width, 92-point node height, 80-point sibling gap, and 120-point level gap. Never change positions already stored for surviving node IDs; remove orphan positions only after a confirmed source save.

- [ ] **Step 4: Build and test the canvas**

Use `InteractiveViewer(constrained: false, minScale: 0.15, maxScale: 4.0, boundaryMargin: EdgeInsets.all(100000))`. Render edges with one `CustomPainter` beneath a `Stack` of `WorkflowNodeCard` widgets. Convert drag deltas through the current scale before calling `moveNode`. Provide Select, Fit, Zoom Out, percentage, Zoom In, Lock, and minimap controls with semantic labels.

Widget tests must drag one node and assert only layout changes, zoom and fit without exceptions, select by click, marquee-select multiple nodes, and render 200 nodes without overflow.

Run: `dart format lib test && flutter analyze && flutter test test/features/workflows/data/json_workflow_layout_repository_test.dart test/features/workflows/application/workflow_canvas_controller_test.dart test/features/workflows/presentation/workflow_canvas_test.dart`

Expected: all layout/canvas tests PASS.

- [ ] **Step 5: Commit the Workflow canvas**

```bash
git add lib/features/workflows test/features/workflows
git commit -m "feat: add Workflow infinite canvas"
```

### Task 5: Add Workflow source sessions, last-valid graph behavior, and resource associations

**Files:**
- Create: `lib/features/workflows/domain/workflow_document.dart`
- Create: `lib/features/workflows/data/workflow_repository.dart`
- Create: `lib/features/workflows/data/file_workflow_repository.dart`
- Create: `lib/features/workflows/application/workflow_controller.dart`
- Create: `lib/features/workflows/presentation/workflow_workspace.dart`
- Modify: `lib/features/resources/application/resource_workspace_registry.dart`
- Modify: `lib/features/command_palette/application/command_palette_controller.dart`
- Test: `test/features/workflows/application/workflow_controller_test.dart`
- Test: `test/features/workflows/presentation/workflow_workspace_test.dart`
- Test: `test/features/resources/web_workflow_journey_test.dart`

**Interfaces:**
- Produces: `WorkflowDocument(id, title, source, extension, relativePath)`.
- Produces: controller modes `canvas` and `source`, state `currentGraph`, `lastValidGraph`, `diagnostics`, and `layout`.
- Produces: handlers for `new-link` and `new-workflow` commands.

- [ ] **Step 1: Write the failing last-valid graph test**

```dart
test('invalid source keeps the last valid graph and dirty source', () async {
  final controller = workflowController(initialSource: 'flowchart TD\na-->b');
  await controller.load();
  final validGraph = controller.state.currentGraph;
  controller.updateSource('flowchart TD\na--');
  expect(controller.state.diagnostics, isNotEmpty);
  expect(controller.state.currentGraph, validGraph);
  expect(controller.state.source, 'flowchart TD\na--');
});
```

- [ ] **Step 2: Run Workflow integration tests and verify failure**

Run: `flutter test test/features/workflows/application/workflow_controller_test.dart test/features/workflows/presentation/workflow_workspace_test.dart`

Expected: FAIL with missing document/workspace/controller integration.

- [ ] **Step 3: Implement source-first Workflow state**

Use `DocumentSession` for source saving. Parse after 200 ms of idle editing. Update `lastValidGraph` only on successful parse. Switching to canvas with diagnostics keeps the last graph and shows a non-modal error banner with line/column and `返回源码`.

For `.md`, enable the canvas only when exactly one supported Mermaid flowchart code block is selected; preserve all surrounding Markdown. Treat `.yaml` and `.json` Workflow files as syntax-highlighted text documents with metadata/associations and no canvas toggle. Never interpret or execute their fields.

Render the right inspector's related Prompt, SKILL, MCP, and Website IDs using Phase 2 metadata. Clicking one opens its stable resource ID in a new workspace tab. Canvas movement saves only layout JSON and never rewrites `.mmd`.

- [ ] **Step 4: Test full Website and Workflow journeys**

Use a temporary Vault to create/open/edit one Link; create a `.mmd`, switch source/canvas, drag nodes, reopen and restore layout; introduce invalid source and retain the previous graph; add related resources and open each in the expected tab.

Run: `dart format lib test && flutter analyze && flutter test test/features/links test/features/web test/features/workflows test/features/resources && flutter build macos --debug`

Expected: all Phase 4 unit/widget tests PASS and debug build succeeds.

- [ ] **Step 5: Commit Phase 4 integration**

```bash
git add lib/features/workflows lib/features/resources lib/features/command_palette test/features/workflows test/features/resources
git commit -m "feat: integrate web and Workflow workspaces"
```

## Phase 4 Final Verification

- [ ] Run: `flutter analyze`
- [ ] Run: `flutter test`
- [ ] Run: `flutter test integration_test/web_workspace_macos_test.dart -d macos`
- [ ] Run: `flutter build macos --debug`
- [ ] Manually open one saved website and one Workflow with four nodes; verify browser navigation, source/canvas switching, pan, zoom, node drag, minimap, association opening, invalid-source retention, and zero Workflow execution controls.
