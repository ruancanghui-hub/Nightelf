import 'dart:io';

import 'package:ai_workbench/features/editor/data/document_storage.dart';
import 'package:ai_workbench/features/workflows/application/workflow_controller.dart';
import 'package:ai_workbench/features/workflows/data/file_workflow_repository.dart';
import 'package:ai_workbench/features/workflows/data/json_workflow_layout_repository.dart';
import 'package:ai_workbench/features/workflows/domain/workflow_graph.dart';
import 'package:ai_workbench/features/workflows/domain/workflow_layout.dart';
import 'package:ai_workbench/shared/io/atomic_file_writer.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryDocumentStorage implements DocumentStorage {
  final Map<String, String> files = {};

  @override
  Future<DateTime> modifiedAt(String absolutePath) async =>
      DateTime.utc(2026, 8, 9);

  @override
  Future<String> read(String absolutePath) async {
    final text = files[absolutePath];
    if (text == null) {
      return File(absolutePath).readAsString();
    }
    return text;
  }

  @override
  Future<void> writeAtomically(String absolutePath, String contents) async {
    files[absolutePath] = contents;
  }
}

void main() {
  test('invalid source keeps the last valid graph and dirty source', () async {
    final root = await Directory.systemTemp.createTemp('nightelf-wf-ctrl-');
    addTearDown(() async {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    });
    final storage = _MemoryDocumentStorage();
    final controller = WorkflowController(
      repository: FileWorkflowRepository(
        vaultRoot: root,
        writer: AtomicFileWriter(),
        idFactory: () => 'w1',
      ),
      layoutRepository: JsonWorkflowLayoutRepository(
        root: root,
        writer: AtomicFileWriter(),
      ),
      vaultRootPath: root.path,
      storage: storage,
      parseDebounce: Duration.zero,
    );
    addTearDown(controller.dispose);

    await controller.create(title: '流程', source: 'flowchart TD\na-->b\n');
    // Seed memory storage with the created file so later dirty flushes stay in-memory.
    final absolutePath = controller.session!.descriptor.absolutePath;
    storage.files[absolutePath] = await File(absolutePath).readAsString();

    final validGraph = controller.currentGraph;
    expect(validGraph, isNotNull);

    controller.updateSource('flowchart TD\na--');
    await Future<void>.delayed(Duration.zero);
    expect(controller.diagnostics, isNotEmpty);
    expect(controller.currentGraph, validGraph);
    expect(controller.source, contains('a--'));
  });

  test('adds component nodes to source graph and canvas layout', () async {
    final root = await Directory.systemTemp.createTemp('nightelf-wf-ctrl-');
    addTearDown(() async {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    });
    final storage = _MemoryDocumentStorage();
    final controller = WorkflowController(
      repository: FileWorkflowRepository(
        vaultRoot: root,
        writer: AtomicFileWriter(),
        idFactory: () => 'w1',
      ),
      layoutRepository: JsonWorkflowLayoutRepository(
        root: root,
        writer: AtomicFileWriter(),
      ),
      vaultRootPath: root.path,
      storage: storage,
      parseDebounce: Duration.zero,
    );
    addTearDown(controller.dispose);

    await controller.create(title: '流程', source: 'flowchart TD\nstart[开始]\n');
    final absolutePath = controller.session!.descriptor.absolutePath;
    storage.files[absolutePath] = await File(absolutePath).readAsString();
    await controller.setMode(WorkflowViewMode.canvas);

    final node = await controller.addComponentNode(
      WorkflowComponentNodeType.prompt,
      position: const CanvasPoint(320, 180),
    );

    expect(node.id, 'prompt_1');
    expect(controller.source, contains('prompt_1(AI 提示词)'));
    expect(
      controller.currentGraph!.nodes,
      contains(
        const WorkflowNode(
          id: 'prompt_1',
          label: 'AI 提示词',
          shape: WorkflowNodeShape.rounded,
        ),
      ),
    );
    expect(
      controller.canvasController.layout!.positions['prompt_1'],
      const CanvasPoint(320, 180),
    );
    expect(controller.canvasController.selectedNodeIds, {'prompt_1'});
  });
}
