import 'dart:io';

import 'package:ai_workbench/features/workflows/data/json_workflow_layout_repository.dart';
import 'package:ai_workbench/features/workflows/domain/workflow_layout.dart';
import 'package:ai_workbench/shared/io/atomic_file_writer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('manual node positions round-trip independently from source', () async {
    final root = await Directory.systemTemp.createTemp('nightelf-layout-');
    addTearDown(() async => root.delete(recursive: true));
    final repository = JsonWorkflowLayoutRepository(
      root: root,
      writer: AtomicFileWriter(),
    );
    const layout = WorkflowLayout(
      workflowId: 'w1',
      positions: {
        'draft': CanvasPoint(100, 80),
        'check': CanvasPoint(100, 240),
      },
      viewport: WorkflowViewport(offsetX: 20, offsetY: 40, scale: 1.25),
      collapsedNodeIds: {},
    );
    await repository.save(layout);
    expect(await repository.load('w1'), layout);
  });
}
