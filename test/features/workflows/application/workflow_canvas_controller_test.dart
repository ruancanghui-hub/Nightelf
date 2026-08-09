import 'dart:io';

import 'package:ai_workbench/features/workflows/application/workflow_canvas_controller.dart';
import 'package:ai_workbench/features/workflows/data/json_workflow_layout_repository.dart';
import 'package:ai_workbench/features/workflows/domain/workflow_graph.dart';
import 'package:ai_workbench/features/workflows/domain/workflow_layout.dart';
import 'package:ai_workbench/shared/io/atomic_file_writer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('moves nodes and preserves stored positions across reload', () async {
    final root = await Directory.systemTemp.createTemp('nightelf-canvas-');
    addTearDown(() async => root.delete(recursive: true));
    final repository = JsonWorkflowLayoutRepository(
      root: root,
      writer: AtomicFileWriter(),
    );
    final controller = WorkflowCanvasController(layoutRepository: repository);
    const graph = WorkflowGraph(
      direction: WorkflowDirection.topDown,
      nodes: [
        WorkflowNode(id: 'a', label: 'A', shape: WorkflowNodeShape.rectangle),
        WorkflowNode(id: 'b', label: 'B', shape: WorkflowNodeShape.rectangle),
      ],
      edges: [WorkflowEdge(id: 'e1', fromId: 'a', toId: 'b')],
    );

    await controller.loadGraph(workflowId: 'w1', graph: graph);
    final original = controller.layout!.positions['a']!;
    controller.moveNode('a', 12, 8);
    expect(
      controller.layout!.positions['a'],
      CanvasPoint(original.x + 12, original.y + 8),
    );
    await controller.persist();

    final reloaded = WorkflowCanvasController(layoutRepository: repository);
    await reloaded.loadGraph(workflowId: 'w1', graph: graph);
    expect(reloaded.layout!.positions['a'], controller.layout!.positions['a']);
  });
}
